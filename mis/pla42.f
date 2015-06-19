      SUBROUTINE PLA42        
C        
C     THIS ROUTINE PROCESSES THE SCRATCH DATA BLOCK ECPTS, WHICH IS THE 
C     ECPTNL DATA BLOCK APPENDED WITH THE PROPER DISPLACEMENT VECTOR    
C     COMPONENTS, AND CREATES THE STIFFNESS MATRIX KGGNL AND THE UPDATED
C     ECPTNL, ECPTNL1.  ECPTNL1, NAMED ECPTO IN THIS ROUTINE, DOES NOT  
C     CONTAIN DISPLACEMENT VECTOR COMPONENTS.        
C        
      INTEGER         SYSBUF,BUFFR1,BUFFR2,BUFFR3,CSTM,ECPTS,ECPTO,GPCT,
     1                DIT,PLACNT,PLANOS,SETNO,FROWIC,EOR,CLSRW,OUTRW,   
     2                BUFFR4,PLSETN,FILE,ECPTOT        
      DOUBLE PRECISION DZ,DPWORD,DDDDDD        
      DIMENSION       DZ(1),Z(1),IZ(1),INPVT(2),NAME(2),MCBKGG(7),P(4), 
     1                ECPTOT(7),PLANOS(2),IP(4),NWDSP2(40),TUBSAV(16)   
      COMMON /BLANK / PLACNT,PLSETN,PLFACT(2)        
      COMMON /SYSTEM/ SYSBUF,ISKPU(53),IPREC        
      COMMON /CONDAS/ PI,TWOPI,RADEG,DEGRA,S4PISQ        
CZZ   COMMON /ZZPL42/ Z        
      COMMON /ZZZZZZ/ Z        
      COMMON /PLA42S/ XXXXXX(325)        
      COMMON /PLA42D/ DDDDDD(300)        
      COMMON /PLA42E/ ECPT(100)        
      COMMON /PLA42C/ NPVT,GAMMA,GAMMAS,IPASS,ICSTM,NCSTM,IGPCT,NGPCT,  
     1                IPOINT,NPOINT,I6X6K,N6X6K,CSTM,MPT,ECPTS,GPCT,    
     2                DIT,KGGNL,ECPTO,INRW,OUTRW,EOR,NEOR,CLSRW,JMAX,   
     3                FROWIC,LROWIC,NROWSC,NLINKS,NWORDS(40),IOVRLY(40),
     4                LINK(40),NOGO        
      COMMON /ZBLPKX/ DPWORD,DUM(2),INDEX        
      COMMON /PLA4ES/ WORDES(300)        
      COMMON /PLA4UV/ WORDUV(25)        
      EQUIVALENCE     (Z(1),IZ(1),DZ(1)) ,(P(1),IP(1))        
      DATA    NAME  / 4HPLA4,4H2   /, PLANOS / 1103,  11    /        
      DATA    NWDSP2/ 20,   0,  19,   0,   0,        
     1                33,   0,   0,  27,  20,        
     2                5*0,        
     3                32,  27,  32,  38,   0,        
     4                13*0,     45,      6*0/        
C        
C        
      DO 5 I = 1,40        
    5 IOVRLY(I) = 1        
C        
C     DETERMINE SIZE OF VARIABLE CORE AND SET UP BUFFERS        
C        
      IZMAX  = KORSZ(Z)        
      BUFFR1 = IZMAX  - SYSBUF        
      BUFFR2 = BUFFR1 - SYSBUF        
      BUFFR3 = BUFFR2 - SYSBUF        
      BUFFR4 = BUFFR3 - SYSBUF        
      LEFTT  = BUFFR4 - 1        
      IPASS  = PLACNT - 1        
      IPR    = IPREC        
C        
C     READ THE CSTM INTO CORE        
C        
      FILE  = CSTM        
      NCSTM = 0        
      ICSTM = 0        
      CALL OPEN (*20,CSTM,Z(BUFFR1),INRW)        
      CALL SKPREC (CSTM,1)        
      CALL READ (*9020,*10,CSTM,Z(ICSTM+1),LEFTT,EOR,NCSTM)        
      CALL MESAGE (-8,0,NAME)        
   10 LEFTT = LEFTT - NCSTM        
C        
C     PRETRD SETS UP SUBSEQUENT CALLS TO TRANSD        
C        
      CALL PRETRD (Z(ICSTM+1),NCSTM)        
      CALL PRETRS (Z(ICSTM+1),NCSTM)        
      CALL CLOSE  (CSTM,CLSRW)        
   20 IMAT = NCSTM        
C        
C     SEARCH THE MPT FOR THE PLAFACT CARDS.        
C        
      FILE = MPT        
      CALL PRELOC (*9010,Z(BUFFR1-3),MPT)        
      CALL LOCATE (*9040,Z(BUFFR1-3),PLANOS,IFLAG)        
C        
C     FIND THE CORRECT PLA SET NO.        
C        
   30 CALL FREAD (MPT,SETNO,1,0)        
      IF (SETNO .EQ. PLSETN) GO TO 50        
   40 CALL FREAD (MPT,NN,1,0)        
      IF (NN .EQ. (-1)) GO TO 30        
      GO TO 40        
C        
C     SKIP THE PROPER NO. OF WORDS ON THE PLFACT CARD SO THAT GAMMA AND 
C     GAMMAS (GAMMA STAR) WILL BE CORRECTLY COMPUTED.        
C        
   50 IF (PLACNT .LE. 4) GO TO 60        
      CALL FREAD (MPT,0,-(PLACNT-4),0)        
   60 NWDSRD = 4        
      IF (PLACNT .LT. 4) NWDSRD = PLACNT        
      CALL FREAD (MPT,P,NWDSRD,0)        
      IF (PLACNT - 3) 70,80,90        
   70 GAMMAS = 0.0        
      PLFACT(1) = P(2) - P(1)        
      GAMMA = PLFACT(1)/P(1)        
      GO TO 100        
   80 WORD = P(2) - P(1)        
      PLFACT(1) = P(3) - P(2)        
      GAMMAS = WORD/P(1)        
      GAMMA  = PLFACT(1)/WORD        
      GO TO 100        
   90 WORD = P(3) - P(2)        
      PLFACT(1) = P(4) - P(3)        
      GAMMAS = WORD/(P(2)-P(1))        
      GAMMA  = PLFACT(1)/WORD        
  100 PLFACT(2) = 0.0        
      CALL CLOSE (MPT,CLSRW)        
C        
C     CALL PREMAT TO READ MPT AND DIT INTO CORE.  NOTE NEGATIVE FILE NO.
C     FOR DIT TO TRIGGER PLA FLAG IN SUBROUTINE PREMAT.        
C        
      CALL PREMAT (Z(IMAT+1),Z(IMAT+1),Z(BUFFR1),LEFTT,MATCR,MPT,-DIT)  
      LEFTT = LEFTT - MATCR        
      IGPCT = NCSTM + MATCR        
C        
C     OPEN KGGNL, ECPTO, ECPTS, AND GPCT        
C        
      IFILE = KGGNL        
      CALL GOPEN  (KGGNL,Z(BUFFR1),1)        
      CALL MAKMCB (MCBKGG,KGGNL,0,6,IPR)        
      CALL GOPEN  (ECPTO,Z(BUFFR2),1)        
      CALL MAKMCB (ECPTOT,ECPTO,0,0,0)        
      CALL GOPEN  (ECPTS,Z(BUFFR3),0)        
      CALL GOPEN  (GPCT,Z(BUFFR4),0)        
C        
C     READ THE FIRST TWO WORDS OF NEXT GPCT RECORD INTO INPVT(1).       
C     INPVT(1) IS THE PIVOT POINT.  INPVT(1) .GT. 0 IMPLIES THE PIVOT   
C     POINT IS A GRID POINT.  INPVT(1) .LT. 0 IMPLIES THE PIVOT POINT   
C     IS A SCALAR POINT.  INPVT(2) IS THE NUMBER OF WORDS IN THE        
C     REMAINDER OF THIS RECORD OF THE GPCT.        
C        
  130 FILE = GPCT        
      CALL READ (*1000,*700,GPCT,INPVT(1),2,NEOR,IFLAG)        
      NGPCT = INPVT(2)        
      CALL FREAD (GPCT,IZ(IGPCT+1),NGPCT,1)        
      IF (INPVT(1) .LT. 0) GO TO 700        
C        
C     FROWIC IS THE FIRST ROW IN CORE. (1 .LE. FROWIC .LE. 6)        
C        
      FROWIC = 1        
C        
C     DECREMENT THE AMOUNT OF CORE REMAINING.        
C        
      LEFT = LEFTT - 2*NGPCT        
      IF (LEFT .LE. 0) CALL MESAGE (-8,0,NAME)        
      IPOINT = IGPCT + NGPCT        
      NPOINT = NGPCT        
      I6X6K  = IPOINT + NPOINT        
      I6X6K  = (I6X6K - 1)/2 + 2        
C        
C     CONSTRUCT THE POINTER TABLE, WHICH WILL ENABLE SUBROUTINE PLA4B TO
C     INSERT THE 6 X 6 MATRICES INTO KGGNL.        
C        
      IZ(IPOINT+1) = 1        
      I1 = 1        
      I  = IGPCT        
      J  = IPOINT + 1        
  140 I1 = I1 + 1        
      IF (I1 .GT. NGPCT) GO TO 150        
      I  = I + 1        
      J  = J + 1        
      INC= 6        
      IF (IZ(I) .LT. 0) INC = 1        
      IZ(J) = IZ(J-1) + INC        
      GO TO 140        
C        
C     JMAX = NO. OF COLUMNS OF KGGNL THAT WILL BE GENERATED WITH THE    
C     CURRENT GRID POINT.        
C        
  150 INC   = 5        
      ILAST = IGPCT  + NGPCT        
      JLAST = IPOINT + NPOINT        
      IF (IZ(ILAST) .LT. 0) INC = 0        
      JMAX  = IZ(JLAST) + INC        
C        
C     IF 2*6*JMAX .LT. LEFT, THERE ARE NO SPILL LOGIC PROBLEMS FOR KGGNL
C     SINCE THE WHOLE DOUBLE PRECISION SUBMATRIX OF ORDER 6 X JMAX CAN  
C     FIT IN CORE.        
C        
      ITEMP = 6*JMAX        
      IF (2*ITEMP .LT. LEFT) GO TO 170        
      NAME(2) = INPVT(1)        
      CALL MESAGE (30,85,NAME)        
      NROWSC = 3        
  160 IF (2*NROWSC*JMAX .LT. LEFT) GO TO 180        
      NROWSC = NROWSC - 1        
      IF (NROWSC .EQ. 0) CALL MESAGE (-8,0,NAME)        
      GO TO 160        
  170 NROWSC = 6        
C        
C     LROWIC IS THE LAST ROW IN CORE. (1 .LE. LROWIC .LE. 6)        
C        
  180 LROWIC = FROWIC + NROWSC - 1        
C        
C     ZERO OUT THE KGGD SUBMATRIX IN CORE.        
C        
  185 LOW = I6X6K + 1        
      LIM = I6X6K + JMAX*NROWSC        
      DO 190 I = LOW,LIM        
  190 DZ(I) = 0.0D0        
C        
C     INITIALIZE THE LINK VECTOR TO -1.        
C        
      DO 200 I = 1,NLINKS        
  200 LINK(I) = -1        
C        
C     TURN FIRST PASS INDICATOR ON.        
C        
      IFIRST = 1        
C        
C     READ THE 1ST WORD OF THE ECPT RECORD, THE PIVOT POINT, INTO NPVT. 
C     IF NPVT .LT. 0, THE REMAINDER OF THE ECPT RECORD IS NULL SO THAT  
C     1 OR 6 NULL COLUMNS MUST BE GENERATED        
C        
      FILE = ECPTS        
      CALL FREAD (ECPTS,NPVT,1,0)        
      IF (NPVT .LT. 0) GO TO 700        
C        
C     WRITE PIVOT POINT ON ECPTNL1 (ECPTO)        
C        
      CALL WRITE (ECPTO,NPVT,1,NEOR)        
C        
C     READ THE NEXT ELEMENT TYPE INTO THE CELL ITYPE.        
C        
  220 CALL READ (*9020,*500,ECPTS,ITYPE,1,NEOR,IFLAG)        
C        
C     READ THE ECPT ENTRY FOR THE CURRENT TYPE INTO THE ECPT ARRAY. THE 
C     NUMBER OF WORDS TO BE READ WILL BE NWORDS(ITYPE).        
C        
      IF (NWORDS(ITYPE) .LE. 0) CALL MESAGE (-30,61,NAME)        
      CALL FREAD (ECPTS,ECPT,NWORDS(ITYPE),0)        
      ITEMP = IOVRLY(ITYPE)        
C        
C     IF THIS IS THE 1ST ELEMENT READ ON THE CURRENT PASS OF THE ECPT   
C     CHECK TO SEE IF THIS ELEMENT IS IN A LINK THAT HAS ALREADY BEEN   
C     PROCESSED.        
C        
      IF (IFIRST .EQ. 1) GO TO 230        
C        
C     THIS IS NOT THE FIRST PASS.  IF ITYPE(TH) ELEMENT ROUTINE IS IN   
C     CORE, PROCESS IT.        
C        
      IF (ITEMP .EQ. LINCOR) GO TO 235        
C        
C     THE ITYPE(TH) ELEMENT ROUTINE IS NOT IN CORE.  IF THIS ELEMENT    
C     ROUTINE IS IN A LINK THAT ALREADY HAS BEEN PROCESSED READ THE NEXT
C     ELEMENT.        
C        
      IF (LINK(ITEMP) .EQ. 1) GO TO 220        
C        
C     SET A TO BE PROCESSED LATER FLAG FOR THE LINK IN WHICH THE ELEMENT
C     RESIDES        
C        
      LINK(ITEMP) = 0        
      GO TO 220        
C        
C     SINCE THIS IS THE FIRST ELEMENT TYPE TO BE PROCESSED ON THIS PASS 
C     OF THE ECPT RECORD, A CHECK MUST BE MADE TO SEE IF THIS ELEMENT   
C     IS IN A LINK THAT HAS ALREADY BEEN PROCESSED.  IF IT IS SUCH AN   
C     ELEMENT, WE KEEP IFIRST = 1 AND READ THE NEXT ELEMENT.        
C        
  230 IF (LINK(ITEMP) .EQ. 1) GO TO 220        
C        
C     SET THE CURRENT LINK IN CORE = ITEMP AND IFIRST = 0        
C        
      LINCOR = ITEMP        
      IFIRST = 0        
C        
C     CALL THE PROPER ELEMENT ROUTINE.        
C        
C                     ROD      BEAM      TUBE     SHEAR     TWIST       
C                       1         2         3         4         5       
  235 GO TO   (       240,      999,      250,      999,      999,      
C                   TRIA1     TRBSC     TRPLT     TRMEM    CONROD       
C                       6         7         8         9        10       
     1                260,      999,      999,      270,      240,      
C                   ELAS1     ELAS2     ELAS3     ELAS4     QDPLT       
C                      11        12        13        14        15       
     2                999,      999,      999,      999,      999,      
C                   QDMEM     TRIA2     QUAD2     QUAD1     DAMP1       
C                      16        17        18        19        20       
     3                280,      290,      300,      310,      999,      
C                   DAMP2     DAMP3     DAMP4      VISC     MASS1       
C                      21        22        23        24        25       
     4                999,      999,      999,      999,      999,      
C                   MASS2     MASS3     MASS4     CONM1     CONM2       
C                      26        27        28        29        30       
     5                999,      999,      999,      999,      999,      
C                  PLOTEL     REACT     QUAD3       BAR      CONE       
C                      31        32        33        34        35       
     6                999,      999,      999,      320,      999,      
C                   TRIARG    TRAPRG    CTORDRG    CORE      CAP        
C                      36        37        38        39        40       
     7                999,      999,      999,      999,     999),ITYPE 
C        
C     ROD, CONROD        
C        
  240 CALL PKROD        
C        
C     IF THE ELEMENT IS A TUBE, RESTORE THE SAVED ECPTNL ENTRY AND STORE
C     THE UPDATED VARIABLES IN PROPER SLOTS.        
C        
      IF (ITYPE .NE. 3) GO TO 400        
      DO 245 I = 1,16        
  245 ECPT(I)  = TUBSAV(I)        
      ECPT(17) = ECPT(18)        
      ECPT(18) = ECPT(19)        
      ECPT(19) = ECPT(20)        
      GO TO 400        
C        
C     THIS IS A TUBE ELEMENT.  REARRANGE THE ECPT FOR THE TUBE SO THAT  
C     IT IS IDENTICAL TO THE ONE FOR THE ROD.        
C        
C     SAVE THE ECPT ENTRY FOR THE TUBE EXCEPT FOR THE 3 WORDS WHICH WILL
C     BE UPDATED BY THE PKROD ROUTINE AND THE TRANSLATIONAL COMPONENTS  
C     OF THE DISPLACEMENTS VECTORS.        
C        
  250 DO 255 I = 1,16        
  255 TUBSAV(I) = ECPT(I)        
C        
C     COMPUTE AREA, TORSIONAL INERTIA TERM AND STRESS COEFFICIENT.      
C        
      D = ECPT(5)        
      T = ECPT(6)        
      DMT = D - T        
      A = DMT*T*PI        
      FJ= .25*A*(DMT**2 + T**2)        
      C = D/2.0        
C        
C     MOVE THE END OF THE ECPT ARRAY DOWN ONE SLOT SO THAT ENTRIES 7    
C     THROUGH  25 WILL BE MOVED TO POSITIONS 8 THROUGH 26.        
C        
      M = 26        
      DO 257 I = 1,19        
      ECPT(M) = ECPT(M-1)        
  257 M = M - 1        
      ECPT(5) = A        
      ECPT(6) = FJ        
      ECPT(7) = C        
      GO TO 240        
C        
C     TRIA1        
C        
  260 CALL PKTRI1        
      GO TO 400        
C        
C     TRMEM        
C        
  270 CALL PKTRM        
      GO TO 400        
C        
C     QDMEM        
C        
  280 CALL PKQDM        
      GO TO 400        
C        
C     TRIA2        
C        
  290 CALL PKTRI2        
      GO TO 400        
C        
C     QUAD2        
C        
  300 CALL PKQAD2        
      GO TO 400        
C        
C     QUAD1        
C        
  310 CALL PKQAD1        
      GO TO 400        
C        
C     BAR        
C        
  320 CALL PKBAR        
C        
C     WRITE ELEMENT TYPE AND UPDATED ECPT ENTRY ONTO ECPTNL1 (ECPTO)    
C        
  400 CALL WRITE (ECPTO,ITYPE,1,NEOR)        
      CALL WRITE (ECPTO,ECPT,NWDSP2(ITYPE),NEOR)        
      ECPTOT(2) = ECPTOT(2) + 1        
      GO TO 220        
C        
C     AT STATEMENT NO. 500 WE HAVE HIT AN EOR ON THE ECPT FILE.  SEARCH 
C     THE LINK VECTOR TO DETERMINE IF THERE ARE LINKS TO BE PROCESSED.  
C        
  500 LINK(LINCOR) = 1        
      DO  510 I = 1,NLINKS        
      IF (LINK(I) .EQ. 0) GO TO 520        
  510 CONTINUE        
      GO TO 525        
C        
C     SINCE AT LEAST ONE LINK HAS NOT BEEN PROCESSED THE ECPT FILE MUST 
C     BE BACKSPACED.        
C        
  520 CALL BCKREC (ECPTS)        
      GO TO 150        
  525 IF (NOGO .EQ. 1) CALL MESAGE (-61,0,0)        
C        
C     AT THIS POINT BLDPK THE NUMBER OF ROWS IN CORE ONTO THE KGGNL FILE
C        
      I1 = 0        
  540 I2 = 0        
      IBEG = I6X6K + I1*JMAX        
      CALL BLDPK (2,IPR,IFILE,0,0)        
  550 I2 = I2 + 1        
      IF (I2 .GT. NGPCT) GO TO 570        
      JJ = IGPCT + I2        
      INDEX = IABS(IZ(JJ)) - 1        
      LIM = 6        
      IF (IZ(JJ) .LT. 0) LIM = 1        
      JJJ = IPOINT + I2        
      KKK = IBEG + IZ(JJJ) - 1        
      I3  = 0        
  560 I3  = I3 + 1        
      IF (I3 .GT. LIM) GO TO 550        
      INDEX = INDEX + 1        
      KKK = KKK + 1        
      DPWORD = DZ(KKK)        
      IF (DPWORD .NE. 0.0D0) CALL ZBLPKI        
      GO TO 560        
  570 CALL BLDPKN (IFILE,0,MCBKGG)        
      I1 = I1 + 1        
      IF (I1 .LT. NROWSC) GO TO 540        
C        
C     WRITE AN EOR ON ECPTO        
C        
      CALL WRITE (ECPTO,0,0,EOR)        
C        
C     TEST TO SEE IF THE LAST ROW IN CORE, LROWIC, = THE TOTAL NO. OF   
C     ROWS TO BE COMPUTED = 6.  IF IT IS, WE ARE DONE.  IF NOT, THE     
C     ECPTS MUST BE BACKSPACED.        
C        
      IF (LROWIC .EQ. 6) GO TO 130        
      CALL BCKREC (ECPTS)        
      FROWIC = FROWIC + NROWSC        
      LROWIC = LROWIC + NROWSC        
      GO TO 185        
  700 IF (NOGO .EQ. 1) CALL MESAGE (-61,0,0)        
C        
C     HERE WE HAVE A PIVOT POINT WITH NO ELEMENTS CONNECTED, SO THAT    
C     NULL COLUMNS MUST BE OUTPUT ON THE KGGD FILE.        
C        
      FILE = ECPTS        
      LIM  = 6        
      IF (INPVT(1) .LT. 0) LIM = 1        
      DO 710 I = 1,LIM        
      CALL BLDPK  (2,IPR,IFILE,0,0)        
  710 CALL BLDPKN (KGGNL,0,MCBKGG)        
      CALL SKPREC (ECPTS,1)        
C        
C     WRITE PIVOT POINT ON ECPTO        
C        
      CALL WRITE (ECPTO,NPVT,1,EOR)        
      GO TO 130        
C        
C     CHECK NOGO FLAG. IF NOGO = 1, TERMINATE EXECUTION        
C        
 1000 IF (NOGO .EQ. 1) CALL MESAGE (-61,0,0)        
C        
C     WRAP UP BEFORE RETURN        
C        
      CALL CLOSE (ECPTS,CLSRW)        
      CALL CLOSE (ECPTO,CLSRW)        
      CALL CLOSE (GPCT,CLSRW)        
      CALL CLOSE (KGGNL,CLSRW)        
      MCBKGG(3) = MCBKGG(2)        
      CALL WRTTRL (MCBKGG)        
      CALL WRTTRL (ECPTOT)        
      RETURN        
C        
C     ERROR RETURNS        
C        
 9010 CALL MESAGE (-1,FILE,NAME)        
 9020 CALL MESAGE (-2,FILE,NAME)        
 9040 CALL MESAGE (-4,FILE,NAME)        
  999 CALL MESAGE (-30,92,ITYPE)        
      RETURN        
      END        