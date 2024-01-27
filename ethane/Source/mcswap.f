**==mcswap.spg  processed by SPAG 4.52O  at 18:10 on 19 Jul 1996
      SUBROUTINE MCSWAP(En, Vir, Attempt, Acc, Iseed)
c     ---exchange a particle bewteen the two boxes
 
      IMPLICIT NONE
 
      INCLUDE 'parameter.inc'
      INCLUDE 'conf.inc'
      INCLUDE 'potential.inc'
      INCLUDE 'system.inc'
      INCLUDE 'chem.inc'
 
      DOUBLE PRECISION En, Vir, RANF, enn, virn, eno, viro,
     &                 xn(chainlength), yn(chainlength),
     &                 zn(chainlength), arg, CORU, vola, vold, rhoan,
     &                 rhoao, rhodn, rhodo, dele, dtaila, dtaild,
     &                 rosenbluthn, xk(ntrialor), yk(ntrialor), 
     &                 zk(ntrialor), enk(ntrialor), prob, treshold
      INTEGER Attempt, Iseed, o, iadd, idel, jb, idi, Acc, k, i
      DIMENSION En(*), Vir(*)
 
 
      Attempt = Attempt + 1
c     ===select a box at random
      IF (RANF(Iseed).LT.0.5D0) THEN
         iadd = 1
         idel = 2
      ELSE
         iadd = 2
         idel = 1
      END IF

      vola = BOX(iadd)**3
      vold = BOX(idel)**3

c     ---add first particle to box iadd
      xn(1) = BOX(iadd)*RANF(Iseed)
      yn(1) = BOX(iadd)*RANF(Iseed)
      zn(1) = BOX(iadd)*RANF(Iseed)
c     ---calculate energy of this particle
      jb = 1
      o = NPART + 1
!  check if there is a chain to be created
      if (chainlength .gt. 1) then
            rosenbluthn = 0.D0
            do i = 1,chainlength-1
                  !  chain with one particle has an internal energy of zero thus the probaility of creating
                  ! of a trial insertion is equeal
                  do k = 1,ntrialor
                        ! random on a sphere
                        xk(k) = xk(i) + optbondlength * 
     &                  sin(RANF(iseed) * PI) * 
     &                  cos(RANF(iseed) * 2.D0 * PI)
                        yk(k) = yk(i) + optbondlength * 
     &                  sin(RANF(iseed) * PI) * 
     &                  sin(RANF(iseed) * 2.D0 * PI)
                        zk(k) = zk(i) + optbondlength * 
     &                  cos(RANF(iseed) * PI)

                        CALL ENERI(xk(k), yk(k), zk(k), o, jb,
     &                             enk(k),virn, iadd, 1)
                        rosenbluthn = rosenbluthn + 
     &                  exp(-1 * BETA * enk(k))
                  end do

                  ! get the second particle with the rosenbloth probability
                  prob = 0.D0
                  treshold = RANF(iseed)
                  k = 1
                  do while (prob .lt. treshold)
                        prob = prob + (exp(-1.D0 * BETA * enk(k)) 
     &                  / rosenbluthn)
                        k = k + 1
                  end do

                  xn(2) = xk(k)
                  yn(2) = yk(k)
                  zn(2) = zk(k)
                  CALL ENERI(xn(:), yn(:), zn(:), o, jb, enn, virn,
     &                       iadd, chainlength)
            end do
      else
            ! one particle no chain (old calculation)
            CALL ENERI(xn(1), yn(1), zn(1), o, jb, enn, virn, iadd, 1)
      end if

c     ---calculate contibution to the chemical potential:
      arg = -BETA*enn
      IF (TAILCO) THEN
         rhoan = (NPBOX(iadd)+1)/vola
         arg = -BETA*(enn+2*CORU(RC(iadd),rhoan))
      END IF
      CHP(iadd) = CHP(iadd) + vola*EXP(arg)/DBLE(NPBOX(iadd)+1)
      IF (NPBOX(iadd).EQ.NPART) CHP(iadd) = CHP(iadd) + vola*EXP(arg)
     &    /DBLE(NPBOX(iadd)+1)
      ICHP(iadd) = ICHP(iadd) + 1
 

c     ---delete particle from box b:
      IF (NPBOX(idel).EQ.0) THEN
         RETURN
      END IF
      idi = 0
      ! get particle to delete from the right box 
      DO WHILE (idi.NE.idel)
         o = INT(NPART*RANF(Iseed)) + 1
         idi = ID(o)
      END DO
      ! calculate energy of partcile to be removed
      CALL ENERI(X(o,:), Y(o,:), Z(o,:), o, jb, eno, viro, idel,
     &           chainlength)
 
c     ---acceptence test:
      dele = enn - eno + LOG(vold*(NPBOX(iadd)+1)/(vola*NPBOX(idel)))
     &       /BETA
      IF (TAILCO) THEN
c        ---tail corrections:
         rhoao = NPBOX(iadd)/vola
         dtaila = (NPBOX(iadd)+1)*CORU(RC(iadd), rhoan) - NPBOX(iadd)
     &            *CORU(RC(iadd), rhoao)
         rhodn = (NPBOX(idel)-1)/vold
         rhodo = NPBOX(idel)/vold
         dtaild = (NPBOX(idel)-1)*CORU(RC(idel), rhodn) - NPBOX(idel)
     &            *CORU(RC(idel), rhodo)
         dele = dele + dtaila + dtaild
      END IF
      IF (RANF(Iseed).LT.EXP(-BETA*dele)) THEN
c        ---accepted:
         Acc = Acc + 1
         NPBOX(iadd) = NPBOX(iadd) + 1
         X(o,:) = xn(:)
         Y(o,:) = yn(:)
         Z(o,:) = zn(:)
         ID(o) = iadd
         En(iadd) = En(iadd) + enn
         IF (TAILCO) En(iadd) = En(iadd) + dtaila
         Vir(iadd) = Vir(iadd) + virn
         NPBOX(idel) = NPBOX(idel) - 1
         En(idel) = En(idel) - eno
         IF (TAILCO) En(idel) = En(idel) + dtaild
         Vir(idel) = Vir(idel) - viro
      END IF
      RETURN
      END
