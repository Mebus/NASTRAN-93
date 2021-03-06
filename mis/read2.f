      SUBROUTINE READ2 (MAA,PHIA,SCR1,NORM,IA,USET,MI,LAMA,IPOUT,SCR2,  
     1                  EPSI,SCR3)        
C        
C     COMPUTE MODAL MASS AND NORMALIZES VECTORS ACCORDING TO POINT,     
C     MASS, OR MAX.  ALSO LOOKS FOR LARGE OFF DIAGONAL TERM        
C        
      INTEGER         POINT,SYSBUF,PHIA,SCR1,IX(7),IPHIA(7),SCR2,       
     1                IHEAD(10),SCR3,STURM,NAM(2)        
      REAL            LFREQ,CORE(13)        
      DOUBLE PRECISION DCORE(1),DXMAX        
      DIMENSION       IM(7),IHEAD1(10)        
      COMMON /CONDAS/ CONSTS(5)        
CZZ   COMMON /ZZREA2/ ICORE(1)        
      COMMON /ZZZZZZ/ ICORE(1)        
      COMMON /SYSTEM/ SYSBUF        
      COMMON /PACKX / ITA1,ITB1,II1,JJ1,INCUR1        
      COMMON /UNPAKX/ ITB,II,JJ,INCUR        
      COMMON /OUTPUT/ HEAD(1)        
      COMMON /STURMX/ STURM,SHFTPT,KEEP,PTSHFT,NR        
      COMMON /GIVN  / GIVENS,TITLE1(100),LFREQ,TITLE2(4),NNV        
      EQUIVALENCE     (CONSTS(2),TPHI), (IX(2),NCOL), (IX(3),NROW),     
     1                (CORE(1),ICORE(1),DCORE(1)), (DXMAX,XMAX)        
      DATA    IHEAD1/ 21,9,8*0  /        
      DATA    IHEAD / 21,6,7*0,7/        
      DATA    MASS,   POINT     / 4HMASS,4HPOIN/        
      DATA    MAX   / 4HMAX     /        
      DATA    NAM   / 4HREAD,1H2/        
C        
C     READ2  SHOULD NORMALIZE  PHIA  ACCORDING TO NORM +METHOD        
C        
      LCORE = KORSZ(CORE)        
C        
C     DECIDE IF MI WANTED        
C        
      IMI   = 0        
      IX(1) = MI        
      CALL RDTRL (IX)        
      IF (IX(1) .GT. 0) GO TO 10        
      EPSI = 0.0        
      IMI  = -1        
      IF (NORM .EQ. MASS) NORM = MAX        
   10 IX(1) = PHIA        
      CALL RDTRL (IX)        
      CALL MAKMCB (IPHIA,PHIA,IX(3),IX(4),IX(5))        
C        
C     SET UP TO HANDLE IDENTITY MATRIX        
C        
      IDEN  = 0        
      IM(1) = MAA        
      CALL RDTRL (IM)        
      IF (IM(4) .EQ. 8) IDEN = 1        
C        
C     FIND TYPE OF NORMALIZATION        
C        
      IF (NORM .EQ. MASS) GO TO 310        
      IPONT = 1        
      IF (NORM  .EQ. POINT) GO TO 30        
      IF (IA.LT.1 .OR. IA.GT.NROW) GO TO 20        
C        
C     TYPE IS  MAX        
C        
   20 IPONT = 0        
C        
C     POINT        
C        
   30 ASSIGN 40 TO ICOPY        
      GO TO 420        
C        
   40 CONTINUE        
C        
C     PROCESS PHIA - NORMALIZE - COPY TO PHIA        
C        
      LCORE = LCORE - SYSBUF        
      CALL GOPEN (SCR1,CORE(LCORE+1),0)        
      LCORE = LCORE - SYSBUF        
      CALL GOPEN (PHIA,CORE(LCORE+1),1)        
      ITB   = IX(5)        
      JJ    = NROW        
      II    = 1        
      INCUR = 1        
      ITA1  = ITB        
      ITB1  = ITB        
      INCUR1= 1        
      DO 130 I = 1,NCOL        
      CALL UNPACK (*100,SCR1,CORE(3))        
      II1 = II        
      JJ1 = JJ        
      JJJ = 1        
      IF (ITB .EQ. 2) GO TO 66        
      DO 60 J = 1,NROW        
      IF (ABS(CORE(J+2)) .GT. ABS(CORE(JJJ+2))) JJJ = J        
   60 CONTINUE        
      JJJ = JJJ + 2        
      IF (IPONT .NE. 1) GO TO 62        
      JJJ = IA + 2        
      IF (ABS(CORE(JJJ)) .LE. 1.0E-15) GO TO 90        
   62 XMAX = CORE(JJJ)        
      DO 64 J = 1,NROW        
      CORE(J+2) = CORE(J+2)/XMAX        
   64 CONTINUE        
      GO TO 90        
   66 DO 68 J = 1,NROW        
      IF (DABS(DCORE(J+1)) .GT. DABS(DCORE(JJJ+1))) JJJ = J        
   68 CONTINUE        
      JJJ = JJJ + 1        
      IF (IPONT .NE. 1) GO TO 70        
      JJJ = IA + 1        
      IF (DABS(DCORE(JJJ)) .LE. 1.0D-15) GO TO 90        
   70 DXMAX = DCORE(JJJ)        
      DO 72 J = 1,NROW        
      DCORE(J+1) = DCORE(J+1)/DXMAX        
   72 CONTINUE        
   90 CALL PACK (CORE(3),PHIA,IPHIA)        
      GO TO 130        
  100 II1 = 1        
      JJ1 = 1        
      CALL PACK (CORE,PHIA,IPHIA)        
  130 CONTINUE        
      CALL CLOSE (PHIA,1)        
      CALL CLOSE (SCR1,1)        
C        
C     COMPUTE MODAL MASS        
C        
  140 IF (IMI  .LT. 0) GO TO 170        
      IF (IDEN .EQ. 0) GO TO 160        
      ASSIGN 150 TO ICOPY        
      GO TO 420        
  150 CALL SSG2B (PHIA,SCR1,0,MI,1,ITB,1,SCR3)        
      GO TO 170        
C        
  160 CALL SSG2B (MAA,PHIA,0,SCR2,0,ITB,1,SCR3)        
      CALL SSG2B (PHIA,SCR2,0,MI,1,ITB,1,SCR3)        
C        
C     COMPUTE GENERALIZED STIFFNESS        
C        
C        
C     COMPUTE FREQUENCY ETC        
C        
  170 ITB  = 1        
      II   = 1        
      JJ   = NCOL        
      INCUR= 1        
      IMSG = 0        
      CALL GOPEN (LAMA,CORE(LCORE+1),0)        
      CALL READ (*500,*172,LAMA,CORE(1),LCORE,1,NLAMA)        
      GO TO 520        
C        
C     NLAMA IS THE NUMBER OF EIGENVALUES FOUND   NCOL IS TH NUMBER OF   
C     VECTORS        
C        
C        
C     BRING IN THE ORDER FOUND        
C        
  172 KK = NLAMA + 2*NCOL + 8        
C        
C     KK IS THE POINTER TO THE ORDER FOUND        
C     L1 AND  L2 ARE COUNTERS FOR MISSING LOW FREQ. BELOW SHIFT POINTS  
C     STURM AND KEEP WERE SAVED IN SDCOMP, SHFTPT AND PTSHFT IN FEER    
C     AND INVPWR (REAL SYMMETRIC EIGENVALUE PROBLEM ONLY)        
C        
      CALL READ (*500,*171,LAMA,ICORE(KK+1),LCORE,1,IFLAG)        
      GO TO 520        
  171 CALL CLOSE (LAMA,1)        
      CALL GOPEN (LAMA,CORE(LCORE+1),1)        
      CALL WRITE (LAMA,IHEAD(1),50,0)        
      CALL WRITE (LAMA,HEAD(1),96,1)        
      LCORE = LCORE + SYSBUF        
      CORE(NLAMA+6) = 0.0        
      CORE(NLAMA+7) = 0.0        
      IF (IMI .LT. 0) GO TO 180        
      CALL GOPEN (MI,CORE(LCORE+1),0)        
      L1 = STURM        
      L2 = KEEP        
      SHFTPT = SHFTPT + 1.E-10        
      PTSHFT = PTSHFT + 1.E-10        
  180 DO 210 I = 1,NLAMA        
      ICORE(NLAMA+1) = I        
      L = KK + I        
      ICORE(NLAMA+2) = ICORE(L)        
      CORE(NLAMA+3)  = CORE(I)        
      CORE(NLAMA+4)  = SQRT(ABS(CORE(I)))        
      CORE(NLAMA+5)  = CORE(NLAMA+4)/TPHI        
      IF (CORE(I).GT.1.E-10 .AND. CORE(I).LE.SHFTPT) L1 = L1 - 1        
      IF (CORE(I).GT.1.E-10 .AND. CORE(I).LE.PTSHFT) L2 = L2 - 1        
      IF (IMI .LT.  0) GO TO 200        
      IF (I .GT. NCOL) GO TO 195        
      L = NLAMA + I + 7        
      K = L - 1 + I        
      CALL UNPACK (*195,MI,CORE(L))        
      CORE(NLAMA+6) = CORE(K)        
      CORE(NLAMA+7) = CORE(K)*CORE(NLAMA+3)        
      CORE(L) = CORE(K)        
C        
C     ZERO OUT GENERALIZED MASS AND GENERALIZED STIFFNESS FOR THE RIGID 
C     BODY MODE OF ZERO FREQUENCY        
C        
C     (G.C.  3/92        
C     NEXT 4 NEW LINES CAUSED DEMO T03121A TO DIE. MORE STUDY IS NEEDED)
C        
C     IF (CORE(I) .GE. 0.0) GO TO 200        
C     CORE(NLAMA+3) = 0.0        
C     CORE(NLAMA+4) = 0.0        
C     CORE(NLAMA+5) = 0.0        
      GO TO 200        
C        
C     NO MORE VECTORS        
C     REPLACE STURM BY SMALLER OF L1 OR L2, IF NOT ALL LOWER MODES FOUND
C     SET STRUM TO   -1 IF THERE IS NOT ENOUGH INFORMATION,        
C     SET STRUM TO -999 IF DIAG 37 IS REQUESTED (NOT TO PRINT MESSAGE). 
C        
  195 CORE(NLAMA+6) = 0.0        
      CORE(NLAMA+7) = 0.0        
  200 CALL WRITE (LAMA,CORE(NLAMA+1),7,0)        
  210 CONTINUE        
      IF (L1 .LT.  0) L1 = 0        
      IF (L2 .LT.  0) L2 = 0        
      IF (L1 .GT. L2) L1 = L2        
      IF (STURM.NE.-1 .AND. L1.GE.0) STURM = L1        
      IF (STURM.GT.NR .AND. NR.GT.0) STURM = STURM - NR        
      IF (KEEP.LE.0 .AND. PTSHFT.GT.0.) STURM = -1        
      CALL SSWTCH (37,J)        
      IF (J .EQ. 1) STURM = -999        
      CALL CLOSE (LAMA,1)        
      IF (IMI .LT. 0) GO TO 220        
      CALL CLOSE (MI,1)        
  220 IMSG  = 0        
      XMAX  = 0.        
      XMAX1 = 0.        
      ISTOR = 0        
      JSTOR = 0        
C        
C     EPSI = 0 IMPLIES TO NOT CHECK MODAL MASS TERMS        
C        
      IF (EPSI .EQ. 0.0) GO TO 270        
      CALL GOPEN (MI,CORE(LCORE+1),0)        
      DO 260 I = 1,NCOL        
      M    = NLAMA + I + 7        
      MCOL = M + NCOL        
      CALL UNPACK (*540,MI,CORE(MCOL))        
      IF (CORE(M) .EQ. 0) GO TO 260        
      DO 250 J = 1,NCOL        
      IF (I .EQ. J) GO TO 260        
      K  = MCOL  + J - 1        
      MM = NLAMA + J + 7        
      IF (CORE(MM) .EQ. 0.0) GO TO 250        
      GM = ABS(CORE(K))/SQRT(ABS(CORE(M)*CORE(MM)))        
      IF (GM .GT. XMAX1) GO TO 240        
  230 CONTINUE        
      IF (GM .LE. EPSI) GO TO 250        
      IMSG = IMSG + 1        
      XMAX = AMAX1(XMAX,GM)        
      GO TO 250        
  240 XMAX1 = GM        
      ISTOR = I        
      JSTOR = J        
      GO TO 230        
  250 CONTINUE        
  260 CONTINUE        
C        
      CALL CLOSE (MI,1)        
      IF (IMSG   .NE.  0) CALL MESAGE (34,XMAX,EPSI)        
  270 IF (GIVENS .EQ. .0) GO TO 275        
      IF (NNV    .NE.  0) GO TO 275        
      IF (LFREQ  .GT. .0) GO TO 600        
  275 CALL GOPEN (IPOUT,CORE(LCORE+1),0)        
      CALL READ (*510,*280,IPOUT,CORE(1),LCORE,1,IFLAG)        
      GO TO 520        
  280 CALL CLOSE (IPOUT,1)        
      CALL GOPEN (IPOUT,CORE(LCORE+1),1)        
      IHEAD1(3) = ICORE(1)        
      CALL WRITE (IPOUT,IHEAD1,10,0)        
      I0 = 0        
      CORE (I0+ 9) = XMAX1        
      ICORE(I0+10) = ISTOR        
      ICORE(I0+11) = JSTOR        
      ICORE(I0+12) = IMSG        
      ICORE(I0+13) = STURM        
      CALL WRITE (IPOUT,CORE(2),40,0)        
      CALL WRITE (IPOUT,HEAD,96,1)        
      IF (ICORE(1) .NE. 1) GO TO 290        
      IFLAG = IFLAG - 12        
      IHEAD1( 3) = 3        
      IHEAD1(10) = 6        
      CALL WRITE (IPOUT,IHEAD1,50,0)        
      CALL WRITE (IPOUT,HEAD,96,1)        
      IF (IFLAG .EQ. 0) GO TO 290        
      CALL WRITE (IPOUT,CORE(13),IFLAG,0)        
  290 CALL CLOSE (IPOUT,1)        
      IX(1) = IPOUT        
      CALL WRTTRL (IX)        
      RETURN        
C        
C     COMPUTE UNNORMALIZED MODAL MASS        
C        
  310 ASSIGN 320 TO ICOPY        
      GO TO 420        
  320 IF (IDEN .EQ. 0) GO TO 330        
C        
C     MASS MATRIX IS IDENTITY        
C        
      CALL SSG2B (PHIA,SCR1,0,MI,1,IPHIA(5),1,SCR3)        
      GO TO 340        
C        
  330 CALL SSG2B (MAA,PHIA,0,SCR2,0,IPHIA(5),1,SCR3)        
      CALL SSG2B (PHIA,SCR2,0,MI,1,IPHIA(5),1,SCR3)        
C        
C     BRING IN DIAGONALS        
C        
  340 LCORE = LCORE - SYSBUF        
      CALL GOPEN (MI,CORE(LCORE+1),0)        
      ITB = IPHIA(5)        
      II  = 1        
      JJ  = NCOL        
      IF (ITB .NE. 2) GO TO 356        
      DO 350 J = 1,NCOL        
      CALL UNPACK (*348,MI,DCORE(NCOL+1))        
      K = NCOL + J        
      DCORE(J) = 1.0D0/DSQRT(DABS(DCORE(K)))        
      GO TO 350        
  348 DCORE(J) = 0.0D0        
  350 CONTINUE        
      GO TO 362        
  356 DO 360 J = 1,NCOL        
      CALL UNPACK (*358,MI,CORE(NCOL+1))        
      K = NCOL + J        
      CORE(J) = 1.0/SQRT(ABS(CORE(K)))        
      GO TO 360        
  358 CORE(J) = 0.0        
  360 CONTINUE        
  362 CALL CLOSE (MI,1)        
C        
C     DIVIDE EACH TERM BY SQRT (MI)        
C        
      CALL GOPEN (SCR1,CORE(LCORE+1),0)        
      LCORE = LCORE - SYSBUF        
      CALL GOPEN (PHIA,CORE(LCORE+1),1)        
      II = 1        
      JJ = NROW        
      INCUR = 1        
      ITA1  = ITB        
      ITB1  = ITB        
      NCOL2 = ITB*NCOL        
      NROW2 = ITB*NROW        
      II1   = 1        
      JJ1   = NROW        
      INCUR1= 1        
      DO 410 I = 1,NCOL        
      CALL UNPACK (*390,SCR1,CORE(NCOL2+1))        
      IF (ITB .NE. 2) GO TO 368        
      DO 366 J = 1,NROW        
      K = NCOL + J        
  366 DCORE(K) = DCORE(K)*DCORE(I)        
      GO TO 380        
  368 DO 370 J = 1,NROW        
      K = NCOL+J        
  370 CORE(K) = CORE(K)*CORE(I)        
  380 CALL PACK (CORE(NCOL2+1),PHIA,IPHIA)        
      GO TO 410        
  390 DO 400 J = 1,NROW2        
      K = NCOL2 + J        
  400 CORE(K) = 0.0        
      GO TO 380        
  410 CONTINUE        
      CALL CLOSE (PHIA,1)        
      CALL CLOSE (SCR1,1)        
      GO TO 140        
C        
C     COPY ROUTINE - PHIA TO SCR1        
C        
  420 LCORE = LCORE - SYSBUF        
      CALL GOPEN (PHIA,CORE(LCORE+1),0)        
      LCORE = LCORE - SYSBUF        
      CALL GOPEN (SCR1,CORE(LCORE+1),1)        
      DCORE(1) = 0.0D+0        
      ITB   = IX(5)        
      ITA1  = ITB        
      ITB1  = ITB        
      INCUR = 1        
      INCUR1= 1        
      DO 440 JJJ = 1,NCOL        
      II = 0        
      CALL UNPACK (*435,PHIA,CORE(3))        
      II1 = II        
      JJ1 = JJ        
      CALL PACK (CORE(3),SCR1,IPHIA)        
      GO TO 440        
  435 II1 = 1        
      JJ1 = 1        
      CALL PACK (CORE,SCR1,IPHIA)        
  440 CONTINUE        
      CALL CLOSE (PHIA,1)        
      CALL CLOSE (SCR1,1)        
      LCORE = LCORE + 2*SYSBUF        
      GO TO ICOPY, (40,320,150)        
  490 CALL MESAGE (-2,IP1,NAM)        
  500 IP1 = LAMA        
      GO TO 490        
  510 IP1 = IPOUT        
      GO TO 490        
  520 CALL MESAGE (-8,0,NAM)        
  530 CALL MESAGE (-3,LAMA,NAM)        
  540 CALL MESAGE (-5,MI,NAM)        
C        
C        
      ENTRY READ5 (IPOUT)        
C     ===================        
C        
C     PUT OUT EIGENVALUE SUMMARY IN CASE NO EIGENVALUES FOUND        
C        
      LCORE = KORSZ(CORE) - SYSBUF        
      ISTOR = 0        
      JSTOR = 0        
      IMSG  = 0        
      XMAX1 = 0.        
      IX(2) = 1        
      DO 560 I = 3,7        
      IX(I) = 0        
  560 CONTINUE        
      GO TO 275        
C        
C     REARRANGE THE EIGENVALUE TABLE, IF NECESSARY, FOR GIVENS METHOD   
C        
  600 CALL GOPEN (LAMA,CORE(LCORE+1),0)        
      CALL SKPREC (LAMA,1)        
      NWORDS = 7*NLAMA        
      CALL READ (*500,*530,LAMA,CORE(1),NWORDS,1,NWRDS)        
      REFREQ = CORE(3)        
      DO 640 I = 2,NLAMA        
      J = 7*(I-1) + 3        
      IF (CORE(J) .GE. REFREQ) GO TO 640        
      REFREQ = CORE(J)        
      GO TO 660        
  640 CONTINUE        
      GO TO 740        
  660 CALL BCKREC (LAMA)        
      CALL CLOSE (LAMA,2)        
      CALL GOPEN (LAMA,CORE(LCORE+1),3)        
      DO 700 I = 1,NLAMA        
      IF (CORE(3) .EQ. REFREQ) GO TO 720        
      T2 = CORE(2)        
      T3 = CORE(3)        
      T4 = CORE(4)        
      T5 = CORE(5)        
      T6 = CORE(6)        
      T7 = CORE(7)        
      DO 680 J = 2,NLAMA        
      K = 7*(J-2)        
      CORE(K+2) = CORE(K+ 9)        
      CORE(K+3) = CORE(K+10)        
      CORE(K+4) = CORE(K+11)        
      CORE(K+5) = CORE(K+12)        
      CORE(K+6) = CORE(K+13)        
      CORE(K+7) = CORE(K+14)        
  680 CONTINUE        
      K = 7*(NLAMA-1)        
      CORE(K+2) = T2        
      CORE(K+3) = T3        
      CORE(K+4) = T4        
      CORE(K+5) = T5        
      CORE(K+6) = T6        
      CORE(K+7) = T7        
  700 CONTINUE        
  720 CALL WRITE (LAMA,CORE(1),NWORDS,1)        
  740 CALL CLOSE (LAMA,1)        
      GO TO 275        
      END        
