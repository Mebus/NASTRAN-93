      SUBROUTINE XYPLOT        
C        
C     XYPLOT IS AN OUTPUT MODULE        
C        
C     INFORMATION SUPPLIED BY XYTRAN THROUGH DATA BLOCK XYPLOT        
C     IS INTERPRETED AND OUTPUT TO EITHER PLT1(BCD TAPE FILE) OR        
C     PLT2(BINARY TAPE FILE) FOR PLOTTING ON AN OFF-LINE PLOTTER.       
C        
C        
      EXTERNAL        LSHIFT,RSHIFT        
      INTEGER         EXPO,ISYM(2),IX(1),LTTN(10),LTTP(10),D4,        
     1                OUTAPE,RSHIFT,SYSBUF,XYPLT        
      REAL            NUMS,TLTV(22),X(1),Y(1),XY(2),CHRSCL,CSCALE       
      CHARACTER       UFM*23,UWM*25,UIM*29,SFM*25,SWM*27        
      COMMON /XMSSG / UFM,UWM,UIM,SFM,SWM        
      COMMON /MACHIN/ MACH,IHALF        
      COMMON /SYSTEM/ KSYSTM(65)        
CZZ   COMMON /ZZXYPL/ Z(1)        
      COMMON /ZZZZZZ/ Z(1)        
      COMMON /XXPARM/ IPLTBF,ICMRA,IFSKP,PNAM1,PNAM2,IPTDN,NPENS,       
     1                PAPSZX,PAPSZY,PTYP1,PTYP2,JPSZ(8),PC(8,2),        
     2                SPARE,YA(115)        
      COMMON /PLTDAT/ MODEL,IPLTNR,XWMIN,YLOW,AXMAX,YUP,XWMAX,YWMAX,    
     1                XEDGE,YEDGE,XA(9),CHRSCL,        
     2                XYMAX(2),CNTPI,CCH,CCV,ALL,MNP,APO(2),ITP,LTAPE   
      COMMON /XYPLIN/ IDSB,NFRM,NCRV,IDPE,NCOM,IDMJ,ITBF,        
     1                NWFR,ISKP,D1  ,XMIN,XMAX,YMIN,YMAX,        
     2                XTIC,XDTC,XLTC,NXDG,IXPR,NXTT,IXVS,        
     3                IXDT,YTIC,YDTC,YLTC,NYDG,IYPR,NYTT,        
     4                IYVS,IYDT,ITTC,IBTC,ILTC,IRTC,LOGX,        
     5                LOGY,IXAX,XINT,IYAX,YINT,ICRV,D2(2),        
     6                IPENS,IPENN,SKP5(5),TITL(32),SBTL(32),        
     7                CLBL(32),CVTL(32),XATL(32),YATL(32),        
     8                IXGD,IYGD,D3(37),CSCALE,IPSZ,NPLT,XPAP,        
     9                YPAP,NCMR,D4(13)        
      EQUIVALENCE     (KSYSTM( 1),SYSBUF), (KSYSTM( 2),OUTAPE),        
     1                (KSYSTM( 9),NLPP  ), (KSYSTM(12),NLINES),        
     2                (Z(1),X(1),IX(1),XY(1)), (XY(2),Y(1))        
      DATA    LPLTMD, LCMR, XLPAP, YLPAP / -1, -1, -1.0, -1.0   /       
      DATA    XYPLT / 101   /        
      DATA    NRWD  , IRDRW ,ICLSRW /        
     1        300   , 0     ,1      /        
      DATA    IPLUS , IE, LEP, LEM  / 1H+, 1HE, 4H1E+ , 4H1E-   /       
      DATA    LTTN  / 8,  8, 5, 4, 3, 2, 2, 1, 1, 1 / ,        
     1        LTTP  / 15,15,10, 6, 3, 1, 1, 7, 7, 7 / ,        
     2        TLTV  / 3.,6.,2.,5.,8.,2.,4.,6.,8.,2.,3.,5.,7.,9.,2.,3.,  
     3                4.,5.,6.,7.,8.,9. /        
C        
C        
C     DEFINITION OF COMMON BLOCK /PLTDAT/ CONTENTS        
C        
C     MODEL  - MODEL NUMBER OF THE CURRENT PLOTTER.        
C     IPLTNR - NUMBER OF CURRENT PLOTTER IN USE        
C     XWMIN  - MINIMUM X VALUE OF PLOTTING REGION IN PLOTTER COUNTS     
C     YLOW   - MIN. Y VALUE OF PLOT. REGION(AFTER TITLES)        
C              IN PLOTTER COUNTS        
C     AXMAX  - MAX. X VALUE OF PLOT. REGION(LESS MARGIN)        
C              IN PLOTTER COUNTS        
C     YUP    - MAX. Y VALUE OF PLOT. REGION(LESS MARGIN)        
C              IN PLOTTER COUNTS        
C     XWMAX  - ACTUAL MAXIMUM REGION SIZE IN X DIRECTION        
C              IN PLOTTER COUNTS        
C     YWMAX  - ACTUAL MAXIMUM REGION SIZE IN Y DIRECTION        
C              IN PLOTTER COUNTS        
C     XEDGE  - MARGIN OF X EDGE IN PLOTTER COUNTS (TABLE PLOTTERS ONLY) 
C     YEDGE  - MARGIN OF Y EDGE IN PLOTTER COUNTS (TABLE PLOTTERS ONLY) 
C     XA     - SPARES        
C        
C     THE FOLLOWING SYMBOLIC VALUES PERTAIN TO THE CURRENT PLOTTER.     
C     AND ARE SET WHEN STPLOT OR PLTSET IS CALLED.        
C        
C     XYMAX - X AND Y FRAME LIMITS IN PLOTTER COUNTS.        
C     CNTPI - PLOTTER COUNTS PER INCH.        
C     CCH   - HORIZONTAL PLOTTER COUNTS PER SINGLE CHARACTER        
C     CCV   - VERTICAL PLOTTER COUNTS PER SINGLE CHARACTER        
C     ALL   - MAXIMUM LINE LENGTH DRAWN WITH SINGLE COMMAND        
C             (PLOTTER COUNT)        
C     MNP   - MAXIMUM NUMBER OF PENS        
C     APOX  - ACTUAL PLOTTER X ORIGIN IN PLOTTER COUNTS        
C     APOY  - ACTUAL PLOTTER Y ORIGIN IN PLOTTER COUNTS        
C             NOTE - INCREMENTAL PLOTTERS USE AS CURRENT PEN POSITION.  
C     ITP   - PLOTTER TYPE.        
C     LTAPE - GINO NAME OF THE PLOT TAPE.        
C        
C     DEFINITION OF I.D. RECORD CONTENTS OF INPUT DATA FILE /XYPLIN/    
C        
C     IDSB - SUBCASE I.D.               NFRM - FRAME NUMBER        
C     NCRV - CURVE NUMBER               IDPE - POINT OR ELEMENT I.D.    
C     NCOM - COMPONENT NUMBER           IDMJ - VECTOR NUMBER        
C     ITBF - BOTTOM TOP FULL FRAME IND. NWFR - NEW AXIS AND LABEL IND.  
C     ISKP - FRAME SKIP NUMBER          D1   - SPARE        
C     XMIN - MINIMUM X DATA FOR CURVE   XMAX - MAXIMUM X DATA FOR CURVE 
C     YMIN - MINIMUM Y DATA FOR CURVE   YMAX - MAXIMUM Y DATA FOR CURVE 
C     XTIC - FIRST X TICK VALUE         XDTC - VALUE BETWEEN X TICKS    
C     XLTC - HIGHEST X-VALUE ON FRAME.  NXDG - MAX. DIGITS FOR X-TICKS  
C     IXPR - 10 POWER ON PRINTED X TICK NXTT - TOTAL NUMBER OF X TICKS  
C     IXVS - X TICKS BETWEEN LABELS     IXDT - DELTA PRINT VALUE X TICKS
C     YTIC - FIRST Y TICK VALUE         YDTC - VALUE BETWEEN Y TICKS    
C     YLTC - HIGHEST Y-VALUE ON FRAME.  NYDG - MAX. DIGITS FOR Y-TICKS  
C     IYPR - 10 POWER ON PRINTED Y TICK NYTT - TOTAL NUMBER OF Y TICKS  
C     IYVS - Y TICKS BETWEEN LABELS     IYDT - DELTA PRINT VALUE Y TICKS
C     ITTC - TICKS W/WO VALUES - TOP    IBTC - TICKS W/WO VALUES - BOTTM
C     ILTC - TICKS W/WO VALUES - LEFT   IRTC - TICKS W/WO VALUES - RIGHT
C     LOGX - LINEAR/LOG - X DIRECTION   LOGY - LINEAR/LOG - Y DIRECTION 
C     IXAX - X AXIS/NO AXIS INDICATOR   XINT - X AXIS  Y INTERCEPT      
C     IYAX - Y AXIS/NO AXIS INDICATOR   YINT - Y AXIS  X INTERCEPT      
C     ICRV - POINT/LINE PLOT INDICATOR  D2   - SPARES        
C     TITL - PLOT TITLE                 SBTL - PLOT SUBTITLE        
C     CLBL - PLOT LABEL                 CVTL - PLOT CURVE TITLE        
C     XATL - X AXIS TITLE               YATL - Y AXIS TITLE        
C     IXGD - X GRID LINES               IYGD - Y GRID LINES        
C     D3   - SPARES                     IPNR - PEN COLOR        
C     IPSZ - PEN SIZE                   NPLT - TYPE OF PLOTTER        
C     XPAP - PAPER SIZE(IN.) X DIR.     YPAP - PAPER SIZE(IN.) Y DIR.   
C     NCMR - CAMERA NR. FOR SC-4020     D4   - XYTRAN INTERNAL FLAGS    
C        
C        
C     SET IOPN=0 (PLOT TAPE CLOSED) AND NERR=0 (NUMBER OF ID RECORDS    
C     WITH WRONG WORD COUNT).  WHEN NERR=5, XYPLOT ASSUMES BAD INPUT    
C     FILE AND ABANDONS OPERATION.        
C        
      MB1  = KORSZ(Z) - SYSBUF        
      IPCHG= 0        
      IOPN = 0        
      CALL OPEN (*920,XYPLT,Z(MB1),IRDRW)        
   99 CALL FWDREC (*960,XYPLT)        
      NERR = 0        
C        
C     READ I.D. RECORD ON INPUT DATA FILE        
C        
  100 CALL READ (*960,*120,XYPLT,IDSB,NRWD+1,1,NACT)        
  110 NERR = NERR + 1        
      IF (NERR .GE. 5) GO TO 940        
      GO TO 100        
  120 IF (NACT .NE. NRWD) GO TO 110        
C        
C     SKIP DATA IF IT WAS FOR THE PAPERPLOTER ONLY        
C        
      IF (D4(2) .LE. 0) GO TO 99        
      IF (NWFR  .NE. 0) GO TO 270        
C        
C     READ DATA PAIRS FROM INPUT DATA FILE FOR CURVE TO BE PLOTTED      
C        
  130 CALL READ (*960,*250,XYPLT,Z,MB3,0,NACT)        
C        
C     SET IFIN TO SHOW MORE DATA REMAINING TO BE READ FROM RECORD.      
C     SET L AS INDEX TO LAST LEGITIMATE X VALUE OF DATA PAIRS IN CORE.  
C        
      IFIN = 0        
      L    = MB3 - 1        
  140 IF (IX(L) .NE. 1) GO TO 150        
      L = L - 2        
      IF (L .LE. 0) GO TO 240        
C        
C     CONVERT DATA POINTS TO PLOTTER COUNTS AND PLOT SYMBOL AT EACH     
C     LEGITIMATE POINT WHEN REQUIRED.        
C        
  150 IF (ICRV .NE. 0) CALL SYMBOL (0,0,0,-1)        
C        
      ISYM(1) = IABS(ICRV) + NCRV - 1        
      ISYM(2) = 0        
C        
      DO 190 I = 1,L,2        
      IF (IX(I) .EQ.    1) GO TO 190        
      IF (X(I) .GT. XMAXS) GO TO 180        
      IF (X(I) .LT. XMINS) GO TO 180        
      IF (LOGXS .LE.    0) GO TO 160        
      X(I) = ALOG10(X(I))        
  160 X(I) = XDR*X(I)+XC        
      IF (Y(I) .GT. YMAXS) GO TO 180        
      IF (Y(I) .LT. YMINS) GO TO 180        
      IF (LOGYS .LE.    0) GO TO 170        
      Y(I) = ALOG10(Y(I))        
  170 Y(I) = YDR*Y(I) + YC        
      IF (ICRV .NE. 0) CALL SYMBOL (X(I),Y(I),ISYM,0)        
      GO TO 190        
  180 IX(I  ) = 1        
      IX(I+1) = 1        
  190 CONTINUE        
      IF (ICRV .NE. 0) CALL SYMBOL (0,0,0,1)        
C        
C     PLOT LINES BETWEEN LEGITIMATE POINTS WHEN REQUIRED        
C        
      IF (ICRV.LT.0 .AND. IPENN.GT.0) ICRV = -ICRV        
      IF (ICRV .LT. 0) GO TO 240        
      CALL LINE (0,0,0,0,0,-1)        
      OLDX = X(1)        
      OLDY = Y(1)        
      IF (IPCHG .EQ. 1) GO TO 193        
      ICPEN = IPSZ        
      IF (IPENS .EQ. 0) GO TO 192        
      ICPEN = IPENS        
      IPCHG = 1        
      GO TO 192        
  193 IF (ICPEN .EQ. IPENN) ICPEN = IPENS - 1        
      ICPEN = ICPEN + 1        
  192 CONTINUE        
      DO 230 I = 1,L,2        
      IF (IX(I) .EQ. 1) GO TO 220        
      T1 = OLDX - X(I)        
      T2 = OLDY - Y(I)        
      IF (T1) 210,200,210        
  200 IF (T2) 210,230,210        
  210 CALL LINE (OLDX,OLDY,X(I),Y(I),ICPEN,0)        
      OLDX = X(I)        
      OLDY = Y(I)        
      GO TO 230        
  220 OLDX = X(I+2)        
      OLDY = Y(I+2)        
  230 CONTINUE        
      CALL LINE (0,0,0,0,0,1)        
  240 IF (IFIN) 100,130,100        
C        
C     ALL DATA PAIRS IN CORE, SET IFIN TO SHOW NO MORE DATA REMAINS     
C     FOR PRESENT CURVE.  IF ODD NUMBER OF DATA VALUES OUTPUT WARNING   
C     MESSAGE AND CONTINUE.  SET L AS INDEX TO LAST X VALUE OF DATA     
C     PAIRS.        
C        
  250 IFIN = 1        
      IF (NACT .EQ. (NACT/2)*2) GO TO 260        
      NACT = NACT - 1        
      WRITE (OUTAPE,990) UWM,NFRM,NCRV        
      NLINES = NLINES + 2        
      IF (NLINES .GE. NLPP) CALL PAGE        
  260 L = NACT - 1        
      IF (L) 100,100,140        
C        
C     NEW AXIS, LABELS, ETC. ARE NEEDED.        
C        
C     NASTRAN PLOTTING SOFTWARE INITIALIZATION.        
C        
  270 IF (ITBF.GE.0 .AND. IOPN.NE.0) CALL STPLOT (-1)        
      IPLTNR = RSHIFT(NPLT,IHALF)        
      MODEL  = NPLT - LSHIFT(IPLTNR,IHALF) - 100        
      IF (NCMR .GT. 0) ICMRA=NCMR        
      IFSKP  = ISKP        
      CSCALE = CHRSCL        
      IF (CSCALE .LT. 1.) CSCALE = 1.0        
      IF (XPAP   .GT. 0.) PAPSZX = XPAP        
      IF (YPAP   .GT. 0.) PAPSZY = YPAP        
      DO 280 I = 1,NPENS        
  280 JPSZ(I) = IPSZ        
      IF (ITBF .GE. 0) GO TO 284        
C        
C     LOWER HALF MAY NOT CHANGE FRAME OR PLOTTER OR CALL PLTSET        
C        
C     IF (NCMR .NE. LCMR  ) GO TO 925        
      IF (XPAP .NE. XLPAP ) GO TO 925        
      IF (YPAP .NE. YLPAP ) GO TO 925        
      IF (NPLT .NE. LPLTMD) GO TO 925        
      GO TO 286        
C        
  284 CALL PLTSET        
      LCMR  = NCMR        
      XLPAP = XPAP        
      YLPAP = YPAP        
      LPLTMD= NPLT        
      MB2   = MB1 - IPLTBF        
      MB3   = 2*((MB2-1)/2)        
C        
C     SET VALUES FOR FULL FRAME PLOTTING        
C        
  286 YWMIN= 0.        
      YLOW = 4.*CCV        
      YXTR = (YWMAX+YLOW)/2.        
C        
C     START A NEW PLOT IF NECESSARY.        
C        
      IF (ITBF .LT. 0) GO TO 290        
      CALL SOPEN (*930,LTAPE,Z(MB2),IPLTBF)        
      IOPN = 1        
      CALL STPLOT (NFRM)        
  290 CALL PRINT (0,0,0,0,0,-1)        
      IF (ITBF) 300,320,310        
C        
C     MODIFY VALUE FOR LOWER HALF FRAME PLOTTING        
C        
  300 YUP = YXTR        
      GO TO 330        
C        
C     MODIFY VALUE FOR UPPER HALF FRAME PLOTTING        
C        
  310 YLOW = YXTR        
C        
C     SAVE YLOW AND EXPAND REGION SIZE FOR PRINTING OF TITLES.  RESTORE 
C     YLOW AFTER PRINTING THE FOUR CURVE TITLES AT BOTTOM OF FRAME.     
C        
  320 XPRM = XWMIN        
      YPRM = YWMIN        
      Y1T  = YLOW        
      YLOW = YWMIN        
      CALL PRINT (XPRM,YPRM,1,CLBL(1),32,0)        
      YPRM = YPRM + CCV        
      CALL PRINT (XPRM,YPRM,1,SBTL(1),32,0)        
      YPRM = YPRM + CCV        
      CALL PRINT (XPRM,YPRM,1,TITL(1),32,0)        
      YPRM = YPRM + CCV        
      CALL PRINT (XPRM,YPRM,1,CVTL(1),32,0)        
      YLOW = Y1T        
C        
C     OUTPUT X AND Y AXES TITLES        
C        
  330 YPRM = YLOW        
      XPRM = XWMIN + 8.*CCH        
      CALL PRINT (XPRM,YPRM,1,XATL(1),32,0)        
      YPRM = YUP - 2*CCV        
      XPRM = XWMIN        
      CALL PRINT (XPRM,YPRM,2,YATL(1),32,0)        
      CALL TIPE (0,0,0,0,0,1)        
C        
C     MEANING OF SYMBOLS USED        
C     XDR,XC,YDR,YC - FACTORS TO CONVERT ENGINEERING UNITS TO PLOTTER   
C                     COUNTS IN X AND Y DIRECTIONS.        
C     CONVERSION IS - PLOTTER COUNTS = ENG. UNITS * XDR  +  XC        
C        
C     JTC,J1T,J2T,J3T,J4T,J5T - TEMPORARY INTEGER VALUES        
C     T1,T2,T3,T4,X1T,Y1T     - TEMPORARY REAL VALUES        
C        
C     TEST XMAX,XMIN,YMAX, AND YMIN FOR COMPATIBILITY        
C        
      N  = 0        
  340 DX = XLTC - XTIC        
      DY = YLTC - YTIC        
      IF (DX.GT.0.0 .AND. DY.GT.0.0) GO TO 440        
      IF (N .NE.  0) GO TO 350        
      IF (DX.LE.0.0) XLTC = XTIC + XDTC*FLOAT(NXTT+1)        
      IF (DY.LE.0.0) YLTC = YTIC + YDTC*FLOAT(NYTT+1)        
      N = 1        
      GO TO 430        
  350 N = 2        
      IF (DX .GT. 0.0) GO TO 360        
      XLTC = XTIC + 10.0        
      XDTC = 2.0        
      NXTT = 0        
  360 IF (DY .GT. 0.0) GO TO 430        
      YLTC = YTIC + 10.0        
      YDTC = 2.0        
      NYTT = 4        
C        
C     PRINT WARNING (N=NO. OF PASSES TO CORRECT)        
C        
  430 WRITE (OUTAPE,1010) UWM,N,NFRM        
      NLINES = NLINES + 2        
      IF (NLINES .GE. NLPP) CALL PAGE        
      IF (N .EQ. 1) GO TO 340        
C        
C     SAVE XMAX, XMIN, YMAX, YMIN, LOGX AND LOGY FOR USE IF NEXT        
C     I.D. RECORD IS NOT A NEW FRAME        
C        
  440 LOGXS = LOGX        
      LOGYS = LOGY        
      XMINS = XTIC        
      XMAXS = XLTC        
      YMINS = YTIC        
      YMAXS = YLTC        
C        
C     CALCULATE CONVERSION FACTORS        
C        
      XPL = XWMAX - 7.*CCH        
      XPS = XWMIN + 8.*CCH        
      YPL = YUP   - 2.*CCV        
      YPS = YLOW  + 2.*CCV        
C        
C     PUT FRAME AT X AND Y MAXIMUM AND MINIMUM LIMITS        
C        
      IF (IXGD.EQ.0 .AND. IYGD.EQ.0) GO TO 450        
      CALL AXIS (0,0,0,0,0,-1)        
      CALL AXIS (XPS,YPS,XPS,YPL,IPSZ,0)        
      CALL AXIS (XPS,YPL,XPL,YPL,IPSZ,0)        
      CALL AXIS (XPL,YPL,XPL,YPS,IPSZ,0)        
      CALL AXIS (XPL,YPS,XPS,YPS,IPSZ,0)        
      CALL AXIS (0,0,0,0,0,+1)        
  450 IF (LOGX .LE. 0) GO TO 460        
      XTIC = ALOG10(XTIC)        
      XLTC = ALOG10(XLTC)        
      DX   = XLTC - XTIC        
      IF (IYAX .EQ. 1) YINT = ALOG10(YINT)        
  460 IF (LOGY .LE. 0) GO TO 470        
      YTIC = ALOG10(YTIC)        
      YLTC = ALOG10(YLTC)        
      DY   = YLTC - YTIC        
      IF (IXAX .EQ. 1) XINT = ALOG10(XINT)        
  470 XDR = (XPL-XPS)/DX        
      XC  = (XPS*XLTC-XPL*XTIC)/DX        
      YDR = (YPL-YPS)/DY        
      YC  = (YPS*YLTC-YPL*YTIC)/DY        
C        
C     PREPARE TO CREATE + LABEL ANY REQUESTED TIC MARKS IN THE        
C     X-DIRECTION.        
C        
      IF (ITTC.EQ.0 .AND. IXAX.NE.1 .AND. IBTC.EQ.0 .AND. IYGD.EQ.0)    
     1    GO TO 575        
      NDG = 0        
      IF (LOGX .GT. 0) GO TO 480        
      DTC = XDTC        
      IF (DTC.GT.0. .AND. NXTT.GT.0) GO TO 477        
      NTT = 0        
      GO TO 485        
  477 NTT = NXTT        
      XTS = XTIC*XDR + XC        
      IF (ITTC.LE.0 .AND. IBTC.LE.0) GO TO 485        
      NDG  = MIN0(NXDG+1,6)        
      EXPO = NDG + IXPR - 2        
      NUMS = XTIC/10.**EXPO        
      DL   = DTC/10.**EXPO        
      LSTEP= MAX0(IXVS+1,1)        
      GO TO 485        
  480 NTT = LOGX + 1        
      XTS = XTIC*XDR + XC        
      DTC = 1.        
      NDG = 4        
      IF (LOGX .GT. 10) GO TO 485        
      ILL  = LTTP(LOGX)        
      NITK = LTTN(LOGX)        
C        
  485 DO 555 K = 1,3        
      LABEL = 1        
      LOG = XTIC - 1.0 + SIGN(0.1,XTIC)        
      GO TO (490,495,500), K        
C        
C     TICS + LABELS AT THE TOP.        
C        
  490 ITC= ITTC        
      YT = YPL        
      YL = YT + CCV        
      GO TO 505        
C        
C     TICS ALONG THE X-AXIS.        
C        
  495 ITC = 0        
      IF (IXAX .EQ. 1) ITC = -1        
      IF (ITC  .EQ. 0) GO TO 505        
      YT = XINT*YDR + YC        
      CALL AXIS (0,0,0,0,0,-1)        
      CALL AXIS (XPL,YT,XPS,YT,IPSZ,0)        
      GO TO 505        
C        
C     TICS + LABELS AT THE BOTTOM.        
C        
  500 ITC= IBTC        
      YT = YPS        
      YL = YT - CCV        
C        
  505 IF (ITC.EQ.0 .OR. NTT.LE.0) GO TO 555        
      CALL TIPE (0,0,0,0,0,-1)        
      DO 545 J = 1,NTT        
      R = XTS + DTC*XDR*FLOAT(J-1)        
      CALL TIPE (R,YT,1,IPLUS,1,0)        
      IF (LOGX .GT. 0) GO TO 530        
      IF (ITC.LT.0 .OR. LABEL.NE.J) GO TO 545        
C        
C     LABEL THIS LINEAR TIC MARK.        
C        
      IFIELD = NDG        
      RNUM   = NUMS + DL*FLOAT(J-1)        
      IF (RNUM) 510,525,515        
  510 IFIELD = IFIELD + 1        
  515 T = ABS(RNUM)        
      IF (T .GE. 1.E-4) GO TO 525        
      IF (T .GE. 5.E-5) GO TO 520        
      RNUM = 0.        
      GO TO 525        
  520 RNUM = SIGN(1.E-4,RNUM)        
  525 CALL TYPFLT (R,YL,1,RNUM,IFIELD,0)        
      LABEL = LABEL + LSTEP        
      IF (LABEL .LE. NTT) GO TO 545        
      R = R + FLOAT(IFIELD)*CCH        
      CALL TIPE (R,YL,1,IE,1,0)        
      CALL TYPINT(R+CCH,YL,1,EXPO,0,0)        
      GO TO 545        
C        
C     LABEL THIS LOGARITHMIC CYCLE TIC MARK.        
C        
  530 LOG = LOG + 1        
      IF (ITC .LT. 0) GO TO 535        
      I = LEP        
      IF (LOG .LT. 0) I = LEM        
      CALL PRINT (R-CCH,YL,1,I,1,0)        
      CALL TYPINT (R+2.*CCH,YL,1,IABS(LOG),0,0)        
  535 IF (LOGX.GT.10 .OR. J.EQ.NTT) GO TO 545        
C        
C     CREATE + LABEL THE LOGARITHMIC INTRACYCLE TIC MARKS WITHIN THIS   
C     CYCLE.        
C        
      DO 540 I = 1,NITK        
      L = ILL + I - 1        
      T = XDR*(ALOG10(TLTV(L))+FLOAT(LOG)) + XC        
      CALL TIPE (T,YT,1,IPLUS,1,0)        
      IF (ITC .LT. 0) GO TO 540        
      L = TLTV(L) + .01        
      CALL TYPINT (T,YL,1,L,1,0)        
  540 CONTINUE        
C        
  545 CONTINUE        
      CALL TIPE (0,0,0,0,0,+1)        
  555 CONTINUE        
      IF (IYGD.EQ.0 .OR. NTT.LE.0) GO TO 575        
C        
C     DRAW THE Y-DIRECTION GRID NETWORK.        
C        
      CALL AXIS (0,0,0,0,0,-1)        
      LOG = XTIC - 1.0 + SIGN(0.1,XTIC)        
      K = 1        
      DO 570 J = 1,NTT        
      K = -K        
      R = XTS + DTC*XDR*FLOAT(NTT-J)        
      IF (K .GT. 0) CALL AXIS (R,YPL,R,YPS,IPSZ,0)        
      IF (K .LT. 0) CALL AXIS (R,YPS,R,YPL,IPSZ,0)        
      IF (LOGX.LE.0 .OR. LOGX.GT.10 .OR. J.EQ.NTT) GO TO 570        
C        
C     DRAW THE Y-DIRECTION GRID LINES WITHIN THIS LOGARITHMIC CYCLE.    
C        
      LOG = LOG + 1        
      DO 565 I = 1,NITK        
      L = ILL + NITK - I        
      T = XDR*(ALOG10(TLTV(L))+FLOAT(LOG)) + XC        
      K = -K        
      IF (K .GT. 0) CALL AXIS (T,YPL,T,YPS,IPSZ,0)        
      IF (K .LT. 0) CALL AXIS (T,YPS,T,YPL,IPSZ,0)        
  565 CONTINUE        
C        
  570 CONTINUE        
      CALL AXIS (0,0,0,0,0,+1)        
C        
C     PREPARE TO CREATE + LABEL ANY REQUESTED TIC MARKS IN THE        
C     Y-DIRECTION.        
C        
  575 IF (ILTC.EQ.0 .AND. IYAX.NE.1 .AND. IRTC.EQ.0 .AND. IXGD.EQ.0)    
     1    GO TO 130        
      NDG = 0        
      IF (LOGY .GT. 0) GO TO 580        
      DTC = YDTC        
      IF (DTC.GT.0. .AND. NYTT.GT.0) GO TO 577        
      NTT = 0        
      GO TO 585        
  577 NTT = NYTT        
      YTS = YTIC*YDR + YC        
      IF (ILTC.LE.0 .AND. IRTC.LE.0) GO TO 585        
      NDG  = MIN0(NYDG+1,6)        
      EXPO = NDG + IYPR - 2        
      NUMS = YTIC/10.**EXPO        
      DL   = DTC/10.**EXPO        
      LSTEP= MAX0(IYVS+1,1)        
      GO TO 585        
  580 NTT = LOGY + 1        
      YTS = YTIC*YDR + YC        
      DTC = 1.        
      NDG = 4        
      IF (LOGY .GT. 10) GO TO 585        
      ILL = LTTP(LOGY)        
      NITK= LTTN(LOGY)        
C        
  585 DO 655 K = 1,3        
      LABEL = 1        
      LOG = YTIC - 1.0 + SIGN(0.1,YTIC)        
      GO TO (590,595,600), K        
C        
C     TICS + LABELS ON THE LEFT SIDE.        
C        
  590 ITC= ILTC        
      XT = XPS        
      XL = XT - CCH*FLOAT(NDG+1)        
      GO TO 605        
C        
C     TICS ALONG THE Y-AXIS.        
C        
  595 ITC = 0        
      IF (IYAX .EQ. 1) ITC = -1        
      IF (ITC  .EQ. 0) GO TO 605        
      XT = YINT*XDR + XC        
      CALL AXIS (0,0,0,0,0,-1)        
      CALL AXIS (XT,YPL,XT,YPS,IPSZ,0)        
      GO TO 605        
C        
C     TICS + LABELS ON THE RIGHT SIDE.        
C        
  600 ITC= IRTC        
      XT = XPL        
      XL = XT + CCH        
C        
  605 IF (ITC.EQ.0 .OR. NTT.LE.0) GO TO 655        
      CALL TIPE (0,0,0,0,0,-1)        
      DO 645 J = 1,NTT        
      S = YTS + DTC*YDR*FLOAT(J-1)        
      CALL TIPE (XT,S,1,IPLUS,1,0)        
      IF (LOGY .GT. 0) GO TO 630        
      IF (ITC.LT.0 .OR. LABEL.NE.J) GO TO 645        
C        
C     LABEL THIS LINEAR TIC MARK.        
C        
      IFIELD = NDG        
      RNUM   = NUMS + DL*FLOAT(J-1)        
      IF (RNUM) 610,625,615        
  610 IFIELD = IFIELD + 1        
  615 T = ABS(RNUM)        
      IF (T .GE. 1.E-4) GO TO 625        
      IF (T .GE. 1.E-5) GO TO 620        
      RNUM = 0.        
      GO TO 625        
  620 RNUM = SIGN(1.E-4,RNUM)        
  625 CALL TYPFLT (XL,S,1,RNUM,-IFIELD,0)        
      LABEL  = LABEL + LSTEP        
      YLABEL = S        
      GO TO 645        
C        
C     LABEL THIS LOGARITHMIC CYCLE TIC MARK.        
C        
  630 LOG = LOG + 1        
      IF (ITC .LT. 0) GO TO 635        
      I = LEP        
      IF (LOG .LT. 0) I = LEM        
      CALL PRINT (XL,S,1,I,1,0)        
      CALL TYPINT (XL+3.*CCH,S,1,IABS(LOG),0,0)        
  635 IF (LOGY.GT.10 .OR. J.EQ.NTT) GO TO 645        
C        
C     CREATE + LABEL THE LOGARITHMIC INTRACYCLE TIC MARKS WITHIN THIS   
C     CYCLE.        
C        
      DO 640 I = 1,NITK        
      L = ILL + I - 1        
      T = YDR*(ALOG10(TLTV(L))+FLOAT(LOG)) + YC        
      CALL TIPE (XT,T,1,IPLUS,1,0)        
      IF (ITC .LT. 0) GO TO 640        
      L = TLTV(L) + .01        
      CALL TYPINT (XL,T,1,L,1,0)        
  640 CONTINUE        
C        
  645 CONTINUE        
      IF (ITC.LT.0 .OR. LOGY.GT.0) GO TO 650        
      CALL TIPE (XL,YLABEL-CCV,1,IE,1,0)        
      CALL TYPINT (XL+CCH,YLABEL-CCV,1,EXPO,0,0)        
  650 CALL TIPE (0,0,0,0,0,+1)        
  655 CONTINUE        
      IF (IXGD.EQ.0 .OR. NTT.LE.0) GO TO 130        
C        
C     DRAW THE X-DIRECTION GRID NETWORK.        
C        
      CALL AXIS (0,0,0,0,0,-1)        
      LOG = YTIC - 1.0 + SIGN(0.1,YTIC)        
      K = 1        
      DO 670 J = 1,NTT        
      K = -K        
      S = YTS + DTC*YDR*FLOAT(NTT-J)        
      IF (K .GT. 0) CALL AXIS (XPS,S,XPL,S,IPSZ,0)        
      IF (K .LT. 0) CALL AXIS (XPL,S,XPS,S,IPSZ,0)        
      IF (LOGY.LE.0 .OR. LOGY.GT.10 .OR. J.EQ.NTT) GO TO 670        
C        
C     DRAW THE X-DIRECTION GRID LINES WITHIN THIS LOGARITHMIC CYCLE...  
C        
      LOG = LOG + 1        
      DO 665 I = 1,NITK        
      L = ILL + NITK - I        
      T = YDR*(ALOG10(TLTV(L))+FLOAT(LOG)) + YC        
      K = -K        
      IF (K .GT. 0) CALL AXIS (XPS,T,XPL,T,IPSZ,0)        
      IF (K .LT. 0) CALL AXIS (XPL,T,XPS,T,IPSZ,0)        
  665 CONTINUE        
C        
  670 CONTINUE        
      CALL AXIS (0,0,0,0,0,+1)        
      GO TO 130        
C        
C     OUTPUT WARNING NESSAGES, CLOSE INPUT FILE AND PLOT TAPE AND RETURN
C        
  920 RETURN        
  925 WRITE (OUTAPE,1020) SWM        
      GO TO 950        
  930 WRITE (OUTAPE,1000) UWM,LTAPE        
      GO TO 950        
  940 WRITE (OUTAPE,980) UWM        
  950 NLINES = NLINES + 2        
      IF (NLINES .GE. NLPP) CALL PAGE        
  960 CALL CLOSE (XYPLT,ICLSRW)        
      IF (IOPN .NE. 0) CALL STPLOT (-1)        
      RETURN        
C        
  980 FORMAT (A25,' 992, XYPLOT INPUT DATA FILE ID. RECORDS TOO SHORT.',
     1       '  XYPLOT ABANDONED.')        
  990 FORMAT (A25,' 993, XYPLOT FOUND ODD NR. OF VALUES FOR DATA PAIRS',
     1       ' IN FRAME',I5,', CURVE NR.',I5,'.  LAST VALUE IGNORED.')  
 1000 FORMAT (A25,' 994, XYPLOT OUTPUT FILE NAME ',A4,' NOT FOUND.',    
     1       '  XYPLOT ABANDONED.')        
 1010 FORMAT (A25,' 997, NR.',I4,'.  FRAME NR.',I5,' INPUT DATA ',      
     1       'INCOMPATIBLE.  ASSUMPTIONS MAY PRODUCE INVALID PLOT.')    
 1020 FORMAT (A27,' 998, XYPLOT PLOTTER OR FRAME MAY NOT CHANGE FOR ',  
     1       'LOWER FRAME.  XYPLOT ABANDONED.')        
      END        
