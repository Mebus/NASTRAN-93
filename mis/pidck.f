      SUBROUTINE PIDCK (PFILE,GEOM2,NOPID,Z)        
C        
C     THIS ROUTINE CHECKS THE UNIQUNESS OF PROPERTY IDS FOR ALL ELEMENTS
C     THAT HAVE PID FIELDS        
C        
C     IT SHOULD BE CALLED ONLY ONCE BY IFP        
C     IT DOES NOT OPEN NOR CLOSE ANY GINO FILE.        
C        
C     DESIGN REQUIREMENT -        
C        
C     IF PID IS REFERENCED BY AN ELEMENT, THE PID MUST RESIDE ON THE    
C     THIRD FIELD OF THE ELEMENT INPUT CARD.        
C     INPUT FILES - GEOM2 AND PROPERTY FILE (EPT).        
C        
C     THIS VERSION INCLUDES SPECIAL HANDLING OF THE CQUAD4 AND CTRIA3   
C     ELEMENTS WHICH USE AND SHARE MORE THAN ONE STANDARD PROPERTY CARD.
C     THE PROPERTY TYPE IDS OF THE PSHELL, PCOMP, PCOMP1 AND PCOMP2     
C     MUST NOT BE INTERRUPTED BY ANOTHER PROPERTY TYPE. (I.E. NO OTHER  
C     PROPERTY TYPE SHOULD HAVE AN ID PLACED IN BETWEEN 5502 THRU 5802).
C     NOTICE THAT THE PSHELL CARD HAS FIXED LENGTH WHILE THE 3 PCOMPI   
C     CARDS HAVE VARIABLE LENGTH.        
C        
C     WRITTEN BY G.CHAN/UNISYS, SEPT. 1983        
C        
      LOGICAL         ABORT        
      INTEGER         PFILE,    GEOM2,    Z(1),     NAME(2),        
     1                FLAG,     X(3),     QUAD4,    PSHELL,        
     2                PCOMP(3)        
      CHARACTER       UFM*23,   UWM*25,   UIM*29        
      COMMON /XMSSG / UFM,      UWM,      UIM        
      COMMON /SYSTEM/ IBUF,     NOUT,     ABORT,    SKIP(42),        
     1                KDUM(9)        
      COMMON /GPTA1 / NELEM,    LAST,     INCR,     NE(1)        
      DATA    QUAD4 , PSHELL,   PCOMP                      /        
     1         5408 , 5802,     5502,     5602,     5702   /        
      DATA    NAME  / 4HPIDC,   4HK       /        
C        
C     UPDATE /GPTA1/ IF DUMMY ELEMENTS ARE PRESENT        
C        
      DO 90 I = 1,9        
      IF (KDUM(I) .EQ. 0) GO TO 90        
      K  = KDUM(I)        
      NG = K/10000000        
      NC = (K-NG*10000000)/10000        
      NP = (K-NG*10000000 - NC*10000)/10        
      K  = (51+I)*INCR        
      NE(K+ 6) = 2 + NG + NC        
      NE(K+ 9) = 2 + NP        
      NE(K+10) = NG        
 90   CONTINUE        
C        
C     CREATE A PROPERTY ID TABLE IN Z FROM /GPTA1/ DATA BLOCK FOR THOSE 
C     ELEMENTS THAT HAVE PROPERTY CARDS        
C     4 WORDS PER ENTRY        
C       WORD 1, PROPERTY TYPE CODE  (EPT-ID)        
C       WORD 2, LENGTH OF PROPERTY CARD  (EPTWDS)        
C       WORD 3, ELEMENT TYPE CODE   (ECT-ID)        
C       WORD 4, LENGTH OF ELEMENT CARD (ECTWDS), PLUS POINTER TO GPTA1  
C        
      II = 0        
      DO 100 I = 1,LAST,INCR        
      IF (NE(I+6) .EQ. 0) GO TO 100        
      Z(II+1) = NE(I+6)        
      Z(II+2) =-NE(I+8)        
      Z(II+3) = NE(I+3)        
      Z(II+4) = NE(I+5)*10000 + I        
      II = II + 4        
 100  CONTINUE        
C        
C     ADD 3 MORE PROPERTY CARDS (PCOMP, PCOMP1, PCOMP2) FOR CQUAD4 (64) 
C     AND CTRIA3        
C     NOTE - THESE THREE ARE OPEN-ENDED, AND WE SET WORD 2 TO -8888     
C          - WE GIVE THEM LOCALLY NEW QUAD4 IDS IN THE 3RD WORD, SO THAT
C            ELEMENT CQUAD4 AND ELEMENT CTRIA3 WILL PICK THEM UP VIA    
C            THE PSEHLL DATA LATER.        
C        
      I = (64-1)*INCR + 1        
      IF (NE(I+3) .NE. QUAD4) CALL MESAGE (-37,0,NAME)        
      DO 105 J = 1,3        
      Z(II+1) = PCOMP(J)        
      Z(II+2) = -8888        
      Z(II+3) = QUAD4 - J        
      Z(II+4) = NE(I+5)*10000 + I        
      II = II + 4        
 105  CONTINUE        
C        
C     SORT THIS 4-ENTRY Z-TABLE BY THE FIRST WORD.        
C     SET WORD 2 TO -9999 IF ELEMENT USES THE SAME PROPERTY CARD AS THE 
C     PREVIOUS ELEMENT.        
C        
      I4 = II/4        
      CALL SORT (0,0,4,1,Z,II)        
      DO 110 I = 5,II,4        
      IF (Z(I) .EQ. Z(I-4)) Z(I+1) = -9999        
 110  CONTINUE        
C        
C     READ FROM PFILE ALL PID INTO REMAINING CORE. REPLACE WORD 2 IN THE
C     Z-TABLE BY PID BEGIN-ENDING POINTERS        
C        
      JJ = II + 1        
      IF (NOPID .EQ. 1) GO TO 210        
      CALL REWIND (PFILE)        
 120  CALL FWDREC (*360,PFILE)        
 130  CALL READ (*190,*190,PFILE,X,3,0,FLAG)        
      IF (X(1) .EQ. 65535) GO TO 190        
      CALL BISLOC (*120,X(1),Z,4,I4,K)        
 140  KP1 = K + 1        
      IF (Z(KP1) .NE. -9999) GO TO 150        
      K = K - 4        
      GO TO 140        
 150  NWDS = -Z(KP1)        
      IF (NWDS .LE. 0) GO TO 120        
      KOMP = 0        
      IF (NWDS .NE. 8888) GO TO 155        
      KOMP = 1        
      NWDS = 8        
 155  Z(KP1) = (JJ*10000) + (JJ-1)        
      JB = JJ        
 160  CALL READ (*360,*130,PFILE,Z(JJ),NWDS,0,FLAG)        
      IF (KOMP .EQ. 0) GO TO 167        
 165  CALL READ (*360,*130,PFILE,J,1,0,FLAG)        
      IF (J .NE. -1) GO TO 165        
 167  JE = MOD(Z(KP1),10000)        
      IF (JE .LT. JB) GO TO 180        
      DO 170 J = JB,JE        
      IF (Z(JJ) .EQ. Z(J)) GO TO 160        
 170  CONTINUE        
 180  Z(KP1) = Z(KP1) + 1        
      JJ = JJ + 1        
      GO TO 160        
 190  CALL REWIND (PFILE)        
      JJ = JJ - 1        
      IF (JJ .LE. II) NOPID = -1        
C        
C     RESET THE PSHELL POINTERS TO INCLUDE THE PCOMP GROUP IDS.        
C     MAKE SURE THIS GROUP ARE ALL TOGETHER, NOT SEPERATED BY OTHER     
C     PROPERTY CARD        
C     THERE ARE 2 PSHELL CARDS, ONE FROM CQUAD4 AND ONE FROM CTRIA3,    
C     MAKE SURE THE FIRST PSHELL POINTER IS USED        
C        
      CALL BISLOC (*210,PSHELL,Z,4,I4,KP1)        
      IF (Z(KP1+1) .EQ. -9999) KP1 = KP1 - 4        
      IF (Z(KP1- 4).NE.PCOMP(3) .OR. Z(KP1-8).NE.PCOMP(2) .OR.        
     1    Z(KP1-12).NE.PCOMP(1)) GO TO 380        
      J = Z(KP1+1)        
      IF (J .LE. 0) J = 0        
      JB = J/10000        
      JE = MOD(J,10000)        
      IF (JB .EQ. 0) JB = 9999999        
      DO 200 I = 1,3        
      CALL BISLOC (*370,PCOMP(I),Z,4,I4,K)        
      IF (Z(K+1) .LE. 0) GO TO 200        
      J = Z(K+1)/10000        
      K = MOD(Z(K+1),10000)        
      IF (J .LT. JB) JB = J        
      IF (K .GT. JE) JE = K        
 200  CONTINUE        
      IF (JB .NE. 9999999) Z(KP1+1) = (JB*10000) + JE        
C        
C     RESET POINTERS FOR THOSE PROPERTY ID COMMON TO MORE THAN ONE TYPE 
C     OF ELEMENTS, AND        
C     MOVE THE THIRD ENTRY IN THE Z-TABLE TO FIRST, FOR ELEMENT SORT    
C        
 210  DO 220 I = 1,II,4        
      Z(I) = Z(I+2)        
      J = I + 1        
      IF (Z(J) .GT. 0) GO TO 220        
      IF (Z(J) .EQ. -9999) Z(J) = Z(J-4)        
 220  CONTINUE        
      CALL SORT (0,0,4,1,Z,II)        
C        
C     READ IN CONNECTING ELEMENTS, ONE BY ONE, FROM GEOM2 FILE, AND     
C     CHECK THE EXISTENCE OF THE PROPERTY ID IF IT IS SPECIFIED.        
C        
      KK = JJ + 1        
      CALL REWIND (GEOM2)        
 230  CALL FWDREC (*360,GEOM2)        
 240  CALL READ (*300,*300,GEOM2,X,3,0,FLAG)        
      CALL BISLOC (*230,X(1),Z,4,I4,K)        
      NWDS = Z(K+3)/10000        
      IF (NWDS .LE. 0) GO TO 230        
      J = Z(K+1)        
      IF (J .LE. 0) GO TO 270        
      JB = J/10000        
      JE = MOD(J,10000)        
 250  CALL READ (*360,*240,GEOM2,Z(KK),NWDS,0,FLAG)        
      JJ1 = Z(KK+1)        
      DO 260 J = JB,JE        
      IZ = IABS(Z(J))        
      IF (JJ1 .NE. IZ) GO TO 260        
      Z(J) = -IZ        
      GO TO 250        
 260  CONTINUE        
      CALL MESAGE (30,10,Z(KK))        
      ABORT = .TRUE.        
      GO TO 250        
 270  J = MOD(Z(K+3),10000)        
      CALL MESAGE (30,11,NE(J))        
      ABORT = .TRUE.        
      GO TO 230        
 300  CALL REWIND (GEOM2)        
      IF (ABORT .OR. NOPID.NE.0) GO TO 350        
C        
C     PREPARE AN ACTIVE PROPERTY ID LIST FOR SUBROUTINE MATCK        
C        
      J  = II + 1        
      II = 1        
      DO 320 I = J,JJ        
      IF (Z(I) .GE. 0) GO TO 310        
      II = II + 1        
      Z(II) = -Z(I)        
      GO TO 320        
 310  Z(KK) = Z(I)        
      KK = KK + 1        
 320  CONTINUE        
      Z(1) = II        
C        
C     Z(2,...II) CONTAINS A LIST OF ACTIVE PROPERTY IDS, UN-SORTED,     
C     REFERENCED BY ELEMENTS IN GEOM2 FILE.  Z(1) = LENGTH OF THIS LIST 
C        
      JJ1 = JJ + 1        
      KK  = KK - 1        
      IF (KK .LT. JJ1) RETURN        
      WRITE  (NOUT,330) UIM        
 330  FORMAT (A29,', THE FOLLOWING PROPERTY IDS ARE PRESENT BUT NOT ',  
     1        'USED -')        
      WRITE  (NOUT,340) (Z(J),J=JJ1,KK)        
 340  FORMAT (/5X,12I9)        
      RETURN        
C        
C     SET Z(1) TO ZERO IF NO ACTIVE PROPERTY LIST EXISTS.        
C        
 350  Z(1) = 0        
      RETURN        
C        
 360  J = -2        
      GO TO 400        
 370  WRITE  (NOUT,375)        
 375  FORMAT ('0*** CAN NOT LOCATE PSHELL OR PCOMP DATA IN /GPTA1/')    
      GO TO 390        
 380  WRITE  (NOUT,385) Z(KP1),PSHELL,Z(KP1-4),PCOMP(3),        
     1                  Z(KP1-8),PCOMP(2),Z(KP1-12),PCOMP(1)        
 385  FORMAT ('0*** ERROR IN /GPTA1/ PCOMP ARRANGEMENT',(/3X,2I7))      
 390  J = -37        
 400  CALL MESAGE (J,0,NAME)        
      RETURN        
      END        
