      SUBROUTINE DUMPER        
C        
C     THIS SUBROUTINE DUMPS THE OSCAR        
C        
      EXTERNAL         LSHIFT,RSHIFT,ANDF        
      INTEGER          IXTRA(3),CON1,CON2        
      INTEGER          RECNO,DMAPNO,OP,OSCAR(1),OS(5),RSHIFT,INAME(2),  
     1                 TP,AP,ANDF,VPS,PTYPE,BL,EL,ML,CL,CEITBL        
      DIMENSION        RA(4),ROSCAR(1),LOCO(300),AVPS(1),IHD(96)        
      DOUBLE PRECISION DPREC,DPREC1        
      COMMON /OUTPUT/ ITITLE(96),IHEAD(96)        
CZZ   COMMON /ZZXGPI/ CORE(1)        
      COMMON /ZZZZZZ/ CORE(1)        
      COMMON /XGPI2 / LMPL,MPLPNT,MPL(1)        
      COMMON /XVPS  / VPS(1)        
      COMMON /XCEITB/ CEITBL(1)        
      COMMON /SYSTEM/ SYSBUF,OP,JUNK5(6),NLPP,JUNK6(2),NLINES        
      COMMON / XGPIC/ JUNK22(28),NOSGN        
      EQUIVALENCE     (VPS(1),AVPS(1)), (DPREC,RA(1)), (DPREC1,RA(3)),  
     1                (OSCAR(1),ROSCAR(1),OS(5)), (CORE(1),OS(1)),      
     2                (IOSBOT,OS(3))        
      DATA   MASK1,   MASK2,      MASK3,        MASK4,      MASK5     / 
     1       32767,   32768, 1073676288,   1073741824,     983040     / 
      DATA   CON1,    CON2 /     4HCONS,4HTANT                        / 
      DATA   IHD/2*4H    ,4H COS,4HMIC ,4H/ NA,4HSTRA,4HN DM,4HAP C,    
     1             4HOMPI,4HLER ,4H- OS,4HCAR ,4HLIST,4HING ,82*4H    / 
      DATA   IXTRA/4H(CON,4HTINU,4HED)  /        
      DATA   ION, IOFF /  4HON  ,4HOFF  /        
C        
   10 FORMAT (20X,2A4,5H(I  ),2X,I10)        
   20 FORMAT (20X,2A4,5H(R  ),2X,E15.6)        
   30 FORMAT (20X,2A4,5H(BCD),5X,2A4)        
   40 FORMAT (20X,2A4,5H(RDP),2X,D24.15)        
C        
C     INITIALIZE LOCO ARRAY - POINTS TO FIRST WORD IN MPL FOR MOD I     
C        
      J = 1        
      I = 1        
   50 LOCO(I) = J        
      J = J + MPL(J)        
      IF (J .GT. LMPL) GO TO 60        
      I = I + 1        
      GO TO 50        
   60 CONTINUE        
C        
      I = 1        
      DO 70 K=1,96        
      IHEAD(K) = IHD(K)        
   70 CONTINUE        
      CALL PAGE        
      DO 80 K=1,3        
      IHEAD(K+14) = IXTRA(K)        
   80 CONTINUE        
C        
C     PROCESS ENTRY HEADER        
C        
   90 IF (MI .EQ. 11) GO TO 910        
      NWE   = OSCAR(I  )        
      RECNO = OSCAR(I+1)        
      MI    = RSHIFT(OSCAR(I+2),16)        
      MSAVE = LOCO(MI)        
      ITYPE = OSCAR(I+2) - LSHIFT(RSHIFT(OSCAR(I+2),16),16)        
      IEXFLG= IOFF        
      IF (OSCAR(I+5).LT.0) IEXFLG = ION        
      DMAPNO = ANDF(NOSGN,OSCAR(I+5))        
      NLINES = NLINES + 4        
      IF (NLINES .LT. NLPP) GO TO 100        
      CALL PAGE        
      NLINES = NLINES + 4        
  100 CONTINUE        
      WRITE  (OP,110)        
  110 FORMAT (/1X,18(4H****))        
      WRITE  (OP,120) RECNO,ITYPE,IEXFLG,OSCAR(I+3),OSCAR(I+4),DMAPNO   
  120 FORMAT (2X,20HOSCAR RECORD NUMBER ,I3,5X,14HMODULE TYPE = ,I2,    
     1        5X,16HEXECUTE FLAG -- , A4, /2X,        
     2        15HMODULE NAME -  ,2A4,5X,21HDMAP INSTRUCTION NO. ,I3)    
      I   = I + 6        
      NWE = NWE - 6        
      GO TO (130,130,800,540), ITYPE        
  130 IO  = 1        
      NIP = OSCAR(I)        
      NLINES = NLINES + 2        
      IF (NLINES .LT. NLPP) GO TO 140        
      CALL PAGE        
      NLINES = NLINES + 2        
  140 CONTINUE        
      WRITE  (OP,150) NIP        
  150 FORMAT (/10X,29HSUMMARY OF INPUT DATA BLOCKS(,I2,2H ) )        
      J = 1        
  160 INAME(1) = OSCAR(I+1)        
      INAME(2) = OSCAR(I+2)        
      NTU = ANDF(OSCAR(I+3),MASK1)        
      TP  = RSHIFT(ANDF(OSCAR(I+3),MASK2),15)        
      LTU = RSHIFT(ANDF(OSCAR(I+3),MASK3),16)        
      AP  = RSHIFT(ANDF(OSCAR(I+3),MASK4),30)        
      IF (INAME(1).EQ.0 .AND. IO.EQ.1) GO TO 190        
      IF (INAME(1).EQ.0 .AND. IO.EQ.0) GO TO 220        
      NLINES = NLINES + 1        
      IF (NLINES .LT. NLPP) GO TO 170        
      CALL PAGE        
      NLINES = NLINES + 1        
  170 CONTINUE        
      WRITE  (OP,180) INAME(1),INAME(2),AP,LTU,TP,NTU        
  180 FORMAT (20X,2A4,3X,I1,1H/,I5,1H/,I1,1H/,I5)        
      GO TO 250        
  190 NLINES = NLINES + 1        
      IF (NLINES .LT. NLPP) GO TO 200        
      CALL PAGE        
      NLINES = NLINES + 1        
  200 CONTINUE        
      WRITE  (OP,210) J        
  210 FORMAT (20X,24H********INPUT DATA BLOCK,I3,8H IS NULL)        
      GO TO 250        
  220 NLINES = NLINES + 1        
      IF (NLINES .LT. NLPP) GO TO 230        
      CALL PAGE        
      NLINES = NLINES + 1        
  230 CONTINUE        
      WRITE  (OP,240) J        
  240 FORMAT (20X,25H********OUTPUT DATA BLOCK,I3,8H IS NULL)        
  250 I = I + 3        
      J = J + 1        
      IF (J .LE. NIP) GO TO 160        
      IF (ITYPE .EQ. 2 ) IO = 0        
C        
C     PROCESS OUTPUT DATA BLOCKS        
C        
      IF (IO .EQ. 0) GO TO 280        
      IO  = 0        
      I   = I + 1        
      NIP = OSCAR(I)        
      NLINES = NLINES + 2        
      IF (NLINES .LT. NLPP) GO TO 260        
      CALL PAGE        
      NLINES = NLINES + 2        
  260 CONTINUE        
      WRITE  (OP,270) NIP        
  270 FORMAT (/10X,30HSUMMARY OF OUTPUT DATA BLOCKS(,I2,2H ))        
      J = 1        
      GO TO 160        
C        
C     PROCESS PARAMETER SECTION        
C        
  280 I = I + 2        
      NPARM = OSCAR(I)        
      IF (NPARM .EQ. 0) GO TO 530        
      J = 1        
      MPLP = MSAVE + 7        
      NLINES = NLINES + 2        
      IF (NLINES .LT. NLPP) GO TO 290        
      CALL PAGE        
      NLINES = NLINES + 2        
  290 CONTINUE        
      WRITE  (OP,300) NPARM        
  300 FORMAT (/10X,22HSUMMARY OF PARAMETERS(,I2,2H ))        
  310 IF (OSCAR(I+1)) 440,440,320        
C        
C     SEARCH MPL FOR TYPE OF VARIABLE        
C        
  320 INAME(1) = CON1        
      INAME(2) = CON2        
      KK = IABS(MPL(MPLP))        
      NLINES = NLINES + 1        
      IF (NLINES .LT. NLPP) GO TO 330        
      CALL PAGE        
      NLINES = NLINES + 1        
  330 CONTINUE        
      GO TO (340,360,370,390,400,420), KK        
  340 WRITE (OP,10) INAME(1),INAME(2),OSCAR(I+2)        
  350 I = I + 2        
      IF (MPL(MPLP) .GT. 0 ) MPLP = MPLP+1        
      MPLP = MPLP+1        
      J = J+1        
      IF (J .GT. NPARM) GO TO 530        
      GO TO 310        
  360 WRITE (OP,20) INAME(1),INAME(2),ROSCAR(I+2)        
      GO TO 350        
  370 WRITE (OP,30) INAME(1),INAME(2),OSCAR(I+2),OSCAR(I+3)        
  380 I = I + 3        
      IF (MPL(MPLP) .GT. 0) MPLP = MPLP+2        
      MPLP = MPLP + 1        
      J = J + 1        
      IF (J .GT. NPARM) GO TO 530        
      GO TO 310        
  390 RA(1) = ROSCAR(I+2)        
      RA(2) = ROSCAR(I+3)        
      WRITE (OP,40) INAME(1),INAME(2),DPREC        
      GO TO 380        
  400 WRITE  (OP,410) INAME(1),INAME(2),ROSCAR(I+2),ROSCAR(I+3)        
  410 FORMAT (20X,2A4,5H(CSP),2X,2E15.6)        
      GO TO 380        
  420 RA(1) = ROSCAR(I+2)        
      RA(2) = ROSCAR(I+3)        
      RA(3) = ROSCAR(I+4)        
      RA(4) = ROSCAR(I+5)        
      WRITE  (OP,430) INAME(1),INAME(2),DPREC,DPREC1        
  430 FORMAT (20X,2A4,5H(CDP),2X,2D24.15)        
      I = I + 5        
      IF (MPL(MPLP) .GT. 0) MPLP = MPLP+4        
      MPLP = MPLP+1        
      J = J + 1        
      IF (J .GT. NPARM) GO TO 530        
      GO TO 310        
  440 IVPS = ANDF(NOSGN,OSCAR(I+1))        
      INAME(1) = VPS(IVPS-3)        
      INAME(2) = VPS(IVPS-2)        
      PTYPE = RSHIFT(ANDF(VPS(IVPS-1),MASK5),16)        
      NLINES = NLINES + 1        
      IF (NLINES .LT. NLPP) GO TO 450        
      CALL PAGE        
      NLINES = NLINES + 1        
  450 CONTINUE        
      GO TO (460,470,480,490,500,510), PTYPE        
  460 WRITE (OP,10) INAME(1),INAME(2),VPS(IVPS)        
      GO TO 520        
  470 WRITE (OP,20) INAME(1),INAME(2),AVPS(IVPS)        
      GO TO 520        
  480 WRITE (OP,30) INAME(1),INAME(2),VPS(IVPS),VPS(IVPS+1)        
      GO TO 520        
  490 RA(1) = AVPS(IVPS  )        
      RA(2) = AVPS(IVPS+1)        
      WRITE (OP,40) INAME(1),INAME(2),DPREC        
      GO TO 520        
  500 WRITE (OP,410) INAME(1),INAME(2),AVPS(IVPS),AVPS(IVPS+1)        
      GO TO 520        
  510 RA(1) = AVPS(IVPS  )        
      RA(2) = AVPS(IVPS+1)        
      RA(3) = AVPS(IVPS+2)        
      RA(4) = AVPS(IVPS+3)        
      WRITE (OP,430) INAME(1),INAME(2),DPREC,DPREC1        
  520 I = I + 1        
      J = J + 1        
      IF (MPL(MPLP) .GT. 0) MPLP = MPLP + PTYPE/3 + 1        
      IF (PTYPE .EQ. 6) MPLP = MPLP + 1        
      MPLP = MPLP + 1        
      IF (J .GT. NPARM) GO TO 530        
      GO TO 310        
C        
C     HAVE COMPLETED FUNCTIONAL MODULE        
C        
  530 I = I + 2        
      IF (ITYPE .EQ. 2) I = I - 1        
      GO TO 90        
C        
C     PROCESS EXECUTIVE MODULES        
C        
  540 IF (MI - 3) 550,550,600        
C        
C     PROCESS CHKPNT        
C        
  550 NDB = OSCAR(I)        
      NLINES = NLINES + 2        
      IF (NLINES .LT. NLPP) GO TO 560        
      CALL PAGE        
      NLINES = NLINES + 2        
  560 CONTINUE        
      WRITE  (OP,570) NDB        
  570 FORMAT (/10X,31HDATA BLOCKS TO BE CHECKPOINTED(,I2,2H ))        
      IST  = I + 1        
      IFIN = IST + 2 * NDB - 1        
      NPAGE = (10+NDB)/10+1        
      NLINES = NLINES + NPAGE        
      IF (NLINES .LT. NLPP) GO TO 580        
      CALL PAGE        
      NLINES = NLINES + NPAGE        
  580 CONTINUE        
      IF (NDB .NE. 0) WRITE(OP,590) (OSCAR(K),K=IST,IFIN)        
      I = I + 2*NDB+1        
  590 FORMAT ((20X,10(2A4,2X)),/)        
      GO TO 90        
  600 IF (MI - 8) 610,610,670        
C        
C     PROCESS SAVE        
C        
  610 NPARM  = OSCAR(I)        
      NLINES = NLINES + 2        
      IF (NLINES .LT. NLPP) GO TO 620        
      CALL PAGE        
      NLINES = NLINES + 2        
  620 CONTINUE        
      WRITE  (OP,630) NPARM        
  630 FORMAT (/10X,23HPARAMETERS TO BE SAVED(,I2,2H ))        
  640 FORMAT (20X,2A4,2X,I5)        
      J = 1        
  650 IVPS = OSCAR(I+1)        
      INAME(1) = VPS(IVPS-3)        
      INAME(2) = VPS(IVPS-2)        
      NLINES   = NLINES + 1        
      IF (NLINES .LT. NLPP) GO TO 660        
      CALL PAGE        
      NLINES = NLINES + 1        
  660 CONTINUE        
      WRITE (OP,640) INAME(1),INAME(2),OSCAR(I+2)        
      J = J + 1        
      I = I + 2        
      IF (J .LE. NPARM) GO TO 650        
      I = I + 1        
      GO TO 90        
  670 NDB = OSCAR(I)        
      NWE = NWE - 1        
      NLINES = NLINES + 2        
      IF (NLINES .LT. NLPP) GO TO 680        
      CALL PAGE        
      NLINES = NLINES + 2        
  680 CONTINUE        
      IF (MI .EQ.  9) WRITE (OP,690) NDB        
      IF (MI .EQ. 10) WRITE (OP,700) NDB        
  690 FORMAT (/10X,25HDATA BLOCKS TO BE PURGED( ,I2,2H ))        
  700 FORMAT (/10X,26HDATA BLOCKS TO BE EQUIVED(,I2,2H ))        
      IST  = I + 1        
      IFIN = IST + 2*NDB - 1        
      IF (MI .NE. 10) GO TO 730        
      NTU = RSHIFT(OSCAR(IST+2),16)        
      LTU = OSCAR(IST+2) - LSHIFT(NTU,16)        
      NLINES = NLINES + 1        
      IF (NLINES .LT. NLPP) GO TO 710        
      CALL PAGE        
      NLINES = NLINES + 1        
  710 CONTINUE        
      WRITE  (OP,720) OSCAR(IST),OSCAR(IST+1),NTU,LTU        
  720 FORMAT (20X,19HPRIMARY DATA BLOCK ,2A4,3X,I5,1H/,I5)        
      IST  = IST  + 3        
      IFIN = IFIN + 1        
      NWE  = NWE  - 3        
  730 CONTINUE        
      NPAGE  = (10+NDB)/10+1        
      NLINES = NLINES + NPAGE        
      IF (NLINES .LT. NLPP) GO TO 740        
      CALL PAGE        
      NLINES = NLINES + NPAGE        
  740 CONTINUE        
      WRITE  (OP,750)(OSCAR(K),K=IST,IFIN)        
  750 FORMAT ((20X,10(2A4,2X)),/)        
      NWE = NWE - 2*NDB + 2        
      IF (MI .EQ. 9) NWE = NWE - 2        
      IVPS = OSCAR(IFIN+1)        
      NLINES = NLINES + 1        
      IF (NLINES .LT. NLPP) GO TO 760        
      CALL PAGE        
      NLINES = NLINES + 1        
  760 CONTINUE        
      IF (IVPS .LT. 0) WRITE (OP,770)        
  770 FORMAT (20X,35HDEFAULT PARAMETER - ALWAYS NEGATIVE)        
      IF (IVPS .LT. 0) GO TO 790        
      WRITE  (OP,780) VPS(IVPS-3),VPS(IVPS-2)        
  780 FORMAT (20X,21HCONTROL PARAMETER IS ,2A4)        
  790 CONTINUE        
      I = I + 2*NDB + 2        
      IF (MI .EQ. 10 ) I = I + 1        
      NWE = NWE - 1        
      IF (NWE .GT. 0) GO TO 670        
      GO TO 90        
C        
C     PROCESS CONTROL INSTRUCTIONS        
C        
  800 IRN = RSHIFT(OSCAR(I),16)        
      IF (MI .EQ. 11 .OR. MI .EQ. 12) GO TO 810        
      NLINES = NLINES + 2        
      IF (NLINES .LT. NLPP) GO TO 810        
      CALL PAGE        
      NLINES = NLINES + 2        
  810 CONTINUE        
      IF (MI.NE.11 .AND. MI.NE.12) WRITE (OP,820) IRN        
  820 FORMAT (/10X,25HRE-ENTRY RECORD NUMBER = ,I4)        
      IF (MI .EQ. 6) GO TO 900        
      IW = OSCAR(I) - LSHIFT(IRN,16)        
      IF (MI .NE. 7) GO TO 860        
C        
C     CONDITIONAL INSTRUCTION        
C        
      NLINES = NLINES + 2        
      IF (NLINES .LT. NLPP) GO TO 840        
      CALL PAGE        
      NLINES = NLINES + 2        
  840 CONTINUE        
      WRITE  (OP,850) VPS(IW-3),VPS(IW-2)        
  850 FORMAT (/10X,21HPARAMETER FOR COND = ,2A4)        
      GO TO 900        
  860 BL = RSHIFT(CEITBL(IW-1),16)        
      EL = CEITBL(IW-1) - LSHIFT(BL,16)        
      ML = RSHIFT(CEITBL(IW),16)        
      CL = CEITBL(IW  ) - LSHIFT(ML,16)        
      NLINES = NLINES + 2        
      IF (NLINES .LT. NLPP) GO TO 870        
      CALL PAGE        
      NLINES = NLINES + 2        
  870 CONTINUE        
      IF (MI .EQ. 5) WRITE (OP,880) BL,EL,ML,CL,CEITBL(IW+1),        
     1    CEITBL(IW+2)        
      IF (MI.EQ.11 .OR. MI.EQ.12) WRITE (OP,890) EL,ML,CL        
  880 FORMAT (/20X,I5,1H/,I5,5X,I5,1H/,I5,5X,2A4)        
  890 FORMAT (/20X,5X,1H/,I5,5X,I5,1H/,I5)        
  900 I = I + 1        
      GO TO 90        
  910 RETURN        
      END        
