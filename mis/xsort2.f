      SUBROUTINE XSORT2        
C        
C     XSORT2 REPLACES XSORT FOR SPEED AND EFFICIENCY        
C        
C     XSORT2 REQUIRES IFP MODULE TO USE RCARD2 ROUTINE INSTEAD OF       
C     RCARD (DUE TO THE ASTERISK POSITION IN DOUBLE FIELD INPUT        
C     CARD HAS NOT BEEN MOVED TO COLUMN 8)        
C        
C     XSORT2 READS BULKDATA CARDS FROM THE INPUT TAPE, ADJUSTS THE      
C     FIELDS, PERFORMS AN ALPHA-NUMERIC SORT ON THE CARD IMAGES FROM    
C     LEFT TO RIGHT, INSERTS CONTINUATION CARDS IN THEIR PROPER        
C     POSITION, AND PLACES THE RESULTING SORTED IMAGES ON THE NEW       
C     PROBLEM TAPE, NPTP.        
C        
C     THIS ROUTINE DOES NOT USE XRECPS, RPAGE, INITCO, XFADJ, XFADJ1,   
C     XBCDBI, XPRETY, EXTINT, INTEXT, CRDFLG, ISFT, AND THE CHARACTER   
C     FUNCTIONS KHRFNi.        
C     IT CALLS ONLY SORT2K - TO SORT IN-CORE DATA USING TWO SORT KEYS   
C              AND  BISLC2 - BINARY SEARCH USING TWO SORTED KEYS        
C        
C     XSORT2 NEW LOGIC -        
C        
C     1.  INPUT BULKDATA CARDS ARE READ INTO OPEN CORE, EXCEPT CONTINU- 
C         ATION (* OR +), DELETE (/), COMMENT ($), AND BLANK CARDS.     
C     2.  WHEN CORE IS FULL, OR LAST INPUT DATA READ, SORT DATA IN CORE 
C         AND WRITE THE ENTIRE SORTED DATA TO SEQUENTIAL GINO FILE 303. 
C     3.  REPEAT 1 AND 2, AND WRITE DATA TO GINO FILES 304,305,306 ETC. 
C         IF NECESSARY. UP TO 30 FILES ARE ALLOWED.        
C     4.  ALL CONTINUATION CARDS ARE WRITEN TO GINO FILE 302. ALL       
C         DELETES TO 301. BLANK AND COMMENT CARDS ARE IGNORED.        
C     5.  WHEN ALL INPUT DATA CARDS ARE READ AND SAVED IN GINO FILE(S), 
C         RE-LOAD THE DELETE CARDS FROM 301 INTO OPEN CORE SPACE, AND   
C         COPY OPTP TO 301 WITH DESIGNATED CARDS DELETED.        
C     6.  COMPUTE BUFFER SPACE (AT THE END OF OPEN CORE) AND THE WORK   
C         SPACE (AT THE BEGINNING OF OPEN CORE) NEEDED FOR FILE MERGE   
C         OPERATION, AND READ INTO CORE ALL CONTINUATION CARDS USING    
C         THE REMAINING CORE SPACE.        
C     7.  IF CORE SPACE IS NOT BIG ENOUGH TO HOLD ALL CONTINUATION      
C         CARDS, CREATE A CONTINUATION-INDEX TABLE IN CORE, AND MOVE THE
C         CONTINUATION CARDS TO A NEW GINO FILE, WITH LARGE BLOCKS OF   
C         CONTINUATION CARDS        
C     8.  PRE-MERGE BULKDATA GINO FILES TO SAVE BUFFER SPACE IF MORE    
C         THAN 9 GINO FILES WERE USED IN STEP 3.        
C         PERFORM A 2-TO-1 MERGE IF 10 TO 17 FILES WERE INVOLVED, OR    
C         A 3-TO-1 MERGE IF MORE THAN 17 FILES WERE USED IN STEP 3.     
C         THE MERGE FILES ARE SAVED IN 302,303,304,305 ETC.        
C     9.  MERGE ALL FILES IN SORTED ORDER, AND INSERT CONTINUATION CARDS
C         WHEN NECESSARY. THE MERGED RESULTS ARE WRITTEN TO NPTP        
C     10. ECHO ANY CONTINUATION CARD WHICH HAS NO PARENT AND THEREFORE  
C         NOT USED. MAKE SURE NO REDUNDANT MESSAGE FOR THE 'REMAINING'  
C         CONTINUATION CARDS OF ONE 'PARENT'        
C        
C     NOTES FOR XREAD AND FFREAD ROUTINES, WHICH HAVE DONE SOME        
C     IMPORTANT PRELIMINARY TASK -        
C        
C      1. XSORT2 CALLS XREAD WHICH CALLS FFREAD TO READ ALL INPUT DATA, 
C         IN BOTH FIXED-FIELD AND FREE-FIELD FORMATS. UNSORTED INPUT    
C         DATA IS NOW PRINTED BY FFREAD IF 'ECHO=UNSORT' IS REQUESTED.  
C      2. ALL 10 BULKDATA FIELDS ARE LEFT-ADJUSTED IF INPUT ARE IN      
C         FREE-FIELD FORMAT. XREAD LEFT-ADJUSTED ALL FIELDS FOR THE     
C         FIXED-FIELD INPUT CASE.        
C      3. XREAD PRE-CHECK ANY CONTINUATION, COMMENT, DELETE, BLANK, AND 
C         ENDDATA CARDS, AND SET APPROPRIATE FLAGS IN BUF4 CONTROL ARRAY
C      4. THE FIRST THREE BULKDATA FIELDS ARE CONVERTED TO INTERNAL     
C         INTEGER CODES AND SAVED IN BUF4 CONTROL ARRAY. THESE INTERNAL 
C         CODES ARE READY FOR SORTING.        
C      5. XREAD HANDLES BOTH SINGLE-FIELD AND/OR DOUBLE-FIELD INPUT     
C         AND PASS ON THE FIRST 3 BULKDATA FIELD INFORMATION INDENTI-   
C         CALLY TO THE BUF4 CONTROL ARRAY.        
C      6. XREAD/FFREAD COMPLETELY ELIMINATE THE REVERSE-STORAGE PROBLEM 
C         OF THE VAX MACHINE.  I.E.        
C         THE CONSTANT 'ABCD' IS STORED INTERNALLY AS 'DCBA' IN THE VAX 
C      7. IN DOUBLE-FIELD INPUT, THE ASTERISK (*) IN FIELD 1 REMAINS    
C         WHERE IT IS. (THE OLD XSORT MOVED IT TO COL. 8 THEN TO COL. 1.
C         SUBROUTINE RCARD MUST BE MODIFIED TO HANDLE THIS DOUBLE-FIELD 
C         CASE)        
C      8. NO LEADING BCD-ZEROS IN FIELD 2 IF THAT FIELD CONTAINS AN     
C         INTEGER NUMBER, AND THE NUMBER IS NOT RIGHT ADJUSTED (I.E.    
C         XSORT2 TREATS FIELD 2 INTEGER THE SAME WAY AS INTEGERS IN ALL 
C         OTHER FILEDS, NAMELY LEFT ADJUSTED WITH TRAILING BLANKS       
C      9. IF THE 1ST FIELD OF THE 2ND CARD IS BLANK, A UNIQUE CONTINUA- 
C         TION SYMBOL IS INSERTED INTO THE 1ST FIELD, AND THE SAME      
C         SYMBOL IS ADDED TO THE 10TH FIELD OF THE PREVIOUS CARD        
C        
C     SCRATCH FILE LIMITATION IN LINK1 -        
C     SEMDBD ALLOCATES ONLY 15 SCRATCH FILES. SINCE XCSA AND XGPI USE   
C     THE LAST SCRATCH FILE FOR RIGID FORMAT, XSORT2, PROGRAMMED UP TO  
C     30 FILES, IS THEREFORE PHYSICALLY LIMITTED TO 14 SCRATCH FILES.   
C        
C     WRITTEN BY G.CHAN/UNISYS   10/1987        
C        
      IMPLICIT INTEGER (A-Z)        
      EXTERNAL        LSHIFT,RSHIFT,ANDF,ORF        
      LOGICAL         ONLY1,DEBUG        
      INTEGER         Y(25,1),BUF(50),IBUFX(10),ITAPE(10),TEMP(2),      
     1                NAME(2),BULKDA(2),PARAM(2),CDCNT(3),KSMB(3),      
     2                FUB(25)        
      CHARACTER       UFM*23,UWM*25,UIM*29,SFM*25,HEAD4*28,HEAD(3)*56   
      COMMON /XMSSG / UFM,UWM,UIM,SFM        
      COMMON /MACHIN/ MACH,IJHALF(2),LQRO        
      COMMON /XSORTX/ BUF4(4),TABLE(255)        
      COMMON /SYSTEM/ BUFSZ,NOUT,NOGO,IN,DUM3(10),        
     1                DATE(4),ECHO,DUM4,APPRC,DUM5(9),HICORE, DUM6(7),  
     2                NBPC,NBPW,DUM7(28),SUBS,DUM8(12),CPFLG,DUM9(8),   
     3                LPCH        
      COMMON /OUTPUT/ DUM10(96),HEAD1(32),HEAD2(32),HEAD3(32)        
CZZ   COMMON /ZZXST2/ Z(1)        
      COMMON /ZZZZZZ/ Z(1)        
      COMMON /NAMES / RD,RDREW,WRT,WRTREW,REW,NOREW,EOFNRW        
      COMMON /STAPID/ DUM11(12),KUMF        
      COMMON /XECHOX/ FFFLAG,ECHOU,ECHOS,ECHOP,IXSORT,WASFF,NCARD,      
     1                F3LONG,DUM12        
      COMMON /IFPX0 / DUM13(2),IBITS(1)        
      COMMON /IFPX1 / NUMX1,ICARDS(2)        
      COMMON /TWO   / ITWO(32)        
      EQUIVALENCE     (Y(1,1),Z(1)),      (BUF41,BUF4(1)),        
     1                (IBUFX(1),BUF(26)), (ITAPE(1),BUF(38))        
      DATA    HEAD  , HEAD4 /        
     1       ' I N P U T   B U L K   D A T A   D E C K   E C H O      ',
     2       '     S O R T E D   B U L K    D A T A    E C H O        ',
     3       ' ---1--- +++2+++ ---3--- +++4+++ ---5--- +++6+++ ---7---',
     4       ' +++8+++ ---9--- +++10+++   '/    ,I25    /25            /
      DATA    NAME         ,CDCNT               ,OPTP   ,NPTP   ,BLANK /
     1        4HXSOR,4HT2  ,4HCARD,4HCOUN,4HT   ,4HOPTP ,4HNPTP ,4H    /
      DATA    TAPE1 ,TAPE2 ,TAPE3 ,MAXSCR,BULKDA        ,PARAM         /
     1        301   ,302   ,303   ,314   ,4HBULK,4HDATA ,4HPARA ,4HM   /
      DATA    KSMB  /4H+C0N,4H+CQN,4H+CON  /    ,DEBUG  /.FALSE.       /
C        
C     DIAG 47 CAN BE RE-ACTIVATED FOR PROGRAM DEBUG CHECKING        
C        
C     CALL SSWTCH (47,J)        
C     IF (J .EQ. 1) DEBUG = .TRUE.        
C        
C     TURN ON XSORT FLAG AND FREE-FIELD FLAG FOR XREAD AND FFREAD       
C        
      IXSORT = 1        
      FFFLAG = 1234        
C        
C     CHECK UMF REQUEST        
C        
      IF (KUMF .LE.  0) GO TO 110        
      WRITE  (NOUT,100) UFM        
  100 FORMAT (A23,' - USER MASTER FILE, UMF, IS  NOT SUPPORTED BY NEW ',
     1        'XSORT ROUTINE', /5X,        
     2        'ADD A ''DIAG 42'' CARD AND RESUBMIT YOUR NASTRAN JOB')   
C 100 FORMAT (A23,' - USER MASTER FILE, UMF, IS NO LONGER SUPPORTED BY',
C    1        ' NASTRAN',/5X,'(NOTE - RELEASE 87 WAS THE LAST VERSION ',
C    2        'THAT SUPPORTED UMF OPERATION)')        
      CALL MESAGE (-37,0,NAME)        
C        
C     INITIALIZE XSORT2        
C        
  110 ECHOU = 0        
      ECHOS = 0        
      ECHOP = 0        
      NCARD = 0        
      CMMT  = 0        
      NCONT = 0        
      NDELE = 0        
      FULL  = 0        
      EXH   = 0        
      TAPECC= 0        
      BSIZE = 3        
      RESTR = 0        
      CASE  = 1        
      KONTN = 10010000        
      KSMBI = KSMB(1)        
      IF (APPRC .LT. 0) RESTR = 1        
      IF (RESTR .EQ. 1) KSMBI = KHRFN3(KSMB(1),DATE(2),-2,0)        
      J     = COMPLF(0)        
      LARGE = RSHIFT(J,1   )        
      LES1B = RSHIFT(J,NBPC)        
      IF (MOD(LQRO,10) .EQ. 1) LES1B = LSHIFT(J,NBPC)        
      IF (ECHO .LT. 0) GO TO 120        
      ECHOU = ANDF(ECHO,1)        
      ECHOS = ANDF(ECHO,2)        
      ECHOP = ANDF(ECHO,4)        
      IF (CPFLG .NE. 0) ECHOS = 1        
C        
C     SET UP UNSORTED HEADING        
C        
C     (UNSORTED INPUT DATA IS NOW PRINTED BY FFREAD ROUTINE BECAUSE     
C      XREAD HAS BEEN MODIFIED TO RETURN ALL 10 DATA FIELDS LEFT-       
C      ADJUSTED)        
C        
  120 DO 130 J = 1,96        
  130 HEAD1(J) = BLANK        
      IMHERE = 130        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,RESTR,APPRC,SUBS        
  140 FORMAT (//,' *** XSORT2/IMHERE =',6I5)        
      READ (HEAD(1),150) (HEAD1(J),J=11,24)        
      READ (HEAD(3),150) (HEAD3(J),J= 7,20)        
      READ (HEAD 4 ,150) (HEAD3(J),J=21,27)        
  150 FORMAT (14A4)        
      IF (ECHOU .NE. 0) CALL PAGE        
C        
C     GET AVAILABLE CORE        
C     IF IBM MACHINE, LIMIT AVAILABLE CORE SIZE TO 1,000,000 WORDS, SUCH
C     THAT DATA WILL BE SAVED IN PRIMARY FILES ONLY, AND NO SPILL INTO  
C     SECONDARY FILES.        
C        
      NZZ   = KORSZ(Z)        
      IBUF1 = NZZ   - BUFSZ        
      IBUF2 = IBUF1 - BUFSZ        
      IBUF3 = IBUF2 - BUFSZ        
      NZ    = IBUF3 - 1        
      IF (MACH  .EQ. 2) NZ = MIN0(NZ,1000000)        
      IF (NZ .LT. 2500) CALL MESAGE (-8,2500,NAME)        
      NZ25  = NZ/25        
C        
C     OPEN TAPE1, GINO FILE 301 FOR DELETE (SLASH) CARDS        
C     AND  TAPE2, GINO FILE 302 FOR CONTINUATION CARDS        
C     SET  TAPE TO TAPE3, GINO FILE 303, FOR BULKDATA CARDS        
C     UP TO 30 FILES ARE ALLOWED FOR REGUALR BULKDATA CARDS        
C     (CURRENTLY /XFIST/ IN SEMDBD IS SET UP ONLY TO SCRATCH FILE 315.  
C     I.E. UP TO 13 (OR 12, IF DECK CONTAINS MANY CONTINUATION CARDS)   
C     FILES CAN BE USED HERE)        
C        
      IMHERE = 170        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,NZ25        
      CALL OPEN (*2900,TAPE1,Z(IBUF1),WRTREW)        
      CALL OPEN (*2910,TAPE2,Z(IBUF2),WRTREW)        
      TAPE = TAPE3 - 1        
  170 TAPE = TAPE  + 1        
      IF (TAPE .LE. 314) GO TO 180        
      IF (DEBUG) WRITE (NOUT,2955)        
      CALL MESAGE (-8,-NZZ,NAME)        
  180 CALL OPEN (*2960,TAPE,Z(IBUF3),WRTREW)        
      WRTTN = 0        
C        
C        
C     START READING INPUT CARDS VIA XREAD/FFREAD.        
C        
C        
C     ADDITIONAL INFORMATION FROM XREAD NOT MENTIONED PREVIOUSLY -      
C        
C      1. BUF4(1) = BUF4(2) =-1 INDICATE BULKDATA IS A COMMENT CARD     
C         BUF4(1) = BUF4(2) =-2 INDICATE BULKDATA IS A CONTINUATION CARD
C         BUF4(1) = BUF4(2) =-3 INDICATE BULKDATA IS A DELETE CARD, WITH
C                   DELETE RANGE SAVED IN BUF4(3) AND BUF4(4)        
C         BUF4(1) =-3 AND BUF4(4) =-4 IF TRASH WAS FOUND IN DELETE CARD.
C                   THAT IS, TRASH AFTER SLASH IN BULKDATA FIELD 1      
C         BUF4(1) = BUF4(4) =-5 INDICATE A  BLANK   CARD WAS READ       
C         BUF4(1) = BUF4(4) =-9 INDICATE AN ENDDATA CARD WAS READ       
C      2. IF BULKDATA FIELD 2 IS AN INTEGER INPUT, THE CORRECT INTEGER  
C                 VALUE IS SAVED IN BUF4(3)        
C         IF BULKDATA FIELD 3 IS AN INTEGER INPUT, THE CORRECT INTEGER  
C                 VALUE IS SAVED IN BUF4(4)        
C      3. IF THE DATA IN FIELD 2 AND/OR 3 ARE F.P. NUMBER, THEIR INTEGER
C                 VALUES (NOT EXACT) ARE SAVED IN BUF4(3) AND/OR BUF4(4)
C                 THESE VALUES ARE USED ONLY FOR SORTING        
C      4. IF BULKDATA FIELD 2 IS NOT NUMERIC, THE FIRST 6 CHARACTERS ARE
C                 CONVERTED TO INTERNAL INTEGER CODE AND SAVED IN BUF4(3
C         IF THE REMAINING 2 CHARACTERS ARE NOT BLANKS, THEY ARE SAVED  
C                 IN BUF4(4)        
C      5. IF BUF4(4) IS NOT USED BY 4, IT HOLDS THE INTERNAL CODE OR THE
C                 INTEGER VALUE FOR FIELD 3 OF THE ORIGINAL BULKDATA.   
C        
C     WORK SPACE -                                     NZ        
C      1                                               /        
C     ------------------------------------------------------------------
C     !                 OPEN CORE, Z                    !    !    !    !
C     ------------------------------------------------------------------
C     !<----------INPUT CARDS, 25 WORDS EACH----------->!<----GINO---->!
C                (20-WORD CARD IMAGE, 4 CONTRL               BUFFERS    
C               CONTROL WORDS, 1 INDEX POINTER)        
C        
C        
C     SUMMARY OF COUNTERS -        
C        
C     NCONT = TOTAL CONTINUATION CARDS COUNT, ON INPUT BULK DATA DECK   
C             AND ON RESTART OPTP FILE        
C     NDELE = TOTAL COUNT ON RESTART DELETE CARDS        
C     CMMT  = TOTAL COUNT ON NON-ESSENTIAL CARDS (COMMENTS, BLANKS, AND 
C             RESTART DELETE CARDS) OF INPUT BULK DATA DECK        
C     KONTN = SYMBOL COUNTER FOR AUTO-CONTINUAION GENERATION        
C     KOUNT = DELETE RANGE COUNTER, USED ONLY IN 800-820 AREA        
C     NCARD = TOTAL INPUT BULK DATA CARDS COUNT, INCLUDING NON-ESSENTIAL
C             CARDS; CONTINUATION CARDS AND CARDS ON OPTP ARE EXCLUDED  
C     COUNT = CURRENT CORE COUNT ON INPUT CARDS FROM BULK DATA DECK, ALL
C             NON-ESSENTIAL AND CONTINUATION CARDS ARE EXCLUDED        
C     NBULK = NO. OF ACTIVE BULK DATA INPUT CARDS        
C           = NCARD-CMMT = SUM OF ALL COUNT's        
C     NOTE  - NO CARD COUNT ON THE OPTP FILE BEFORE ASSEMBLING NPTP FILE
C        
      COUNT = 0        
  200 IF (COUNT .LT. NZ25) GO TO (212,214,207,210,210,210), CASE        
C                                   1,  2,  3,  4,  5,  6 = CASE        
      CASE = 1        
      IF (WASFF .LE. 0) GO TO 340        
C        
C     (200 THRU 215) SPECIAL HANDLING OF CONTINUATION CARD(S) WITH FIRST
C     FIELD BLANK DURING FREE-FIELD INPUT.   REGULAR CONTINUATION CARD  
C     (FIRST FIELD NOT BLANK) OR FIXED-FIELD INPUT CARDS (BOTH PARENT   
C     AND CHILD) ARE NOT CONSIDERED HERE.        
C        
C        EXAMPLE -     CBAR,10,20, 1 2 3  9)2        
C                      ,,, .5 .5 .5        
C        
C     WE NEED TO CREATE A UNIQUE CONTINUATION SYMBOL FOR THE 1ST FIELD, 
C     AND ADD THE SAME SYMBOL TO THE 10TH FIELD OF THE PREVIOUS CARD.   
C     SET BUF41 FLAG TO -2.        
C                                                                WAITING
C     AT THIS POINT,                                             CARD IN
C        CASE 1, NO CARD IS WAITING FOR PROCESSING               -------
C        CASE 2, CORE WAS FULL AND WAS EMPTIED OUT. A NON-           BUF
C                CONTINUATION CARD WAS READ AND AWAITS PROCESSING       
C        CASE 3, CORE WAS FULL AND EMPTIED. A CONTINUATION CARD      BUF
C                WAS READ AND AWAITS PROCESSING.        
C        CASE 4, CORE NOT FULL, A CONT.CARD WAS READ. THE NEXT CARD  FUB
C                IS NOT A CONT.CARD. THE CONT.CARD WAS PROCESSED,       
C                AND THE NON-CONT. CARD  AWAITS PROCESSING.        
C        CASE 5, CORE NOT FULL, A CONT.CARD WAS READ AND THE NEXT    FUB
C                CARD IS ALSO A CONT.CARD. THE FIRST CONT.CARD        
C                WAS PROCESSED, AND THE SECOND CONT.CARD AWAITS        
C                PROCESSING.        
C        CASE 6, CONTINUE FROM PROCESSING CASES=4,5                  FUB
C        
C ... CASES 2 AND 3 -        
C     CORE IS FULL, READ ONE MORE CARD AND SEE THE NEW CARD IS A SPECIAL
C     CONTINUATION CARD OR NOT        
C     IF IT IS, UPDATE THE 10TH FIELD OF THE PARENT CARD BEFORE        
C     SENDING THE ENTIRE CORE FOR SORTING        
C        
      IMHERE = 202        
  202 CALL XREAD (*208,BUF)        
      IF (BUF41.EQ.-1 .OR. BUF41.EQ.-5) GO TO 202        
      CASE = 2        
      IF (BUF(1).NE.BLANK .OR. BUF(2).NE.BLANK) IF (BUF41+2) 340,203,340
  203 BUF41X = -2        
      CASE = 3        
      GO TO 205        
C        
C ... CASES 4 AND 5 -        
C     CORE IS NOT FULL, A SPECIAL CONTINUATION CARD WAS JUST READ       
C        
  204 IF (WASFF .LE. 0) GO TO 214        
      CASE  = 4        
      BUF41 = -2        
  205 KONTN = KONTN + 1        
      IF (KONTN .EQ. 10020000) KSMBI = KSMB(2)        
      IF (KONTN .EQ. 10030000) KSMBI = KSMB(3)        
      IMHERE = 205        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,KONTN,COUNT,NZ25,CASE        
      CALL INT2A8 (*3140,KONTN,BUF(1))        
      BUF(1) = KSMBI        
      IF (COUNT .LE. 0) GO TO 208        
      Y(19,COUNT) = BUF(1)        
      Y(20,COUNT) = BUF(2)        
      IF (CASE-3) 340,340,207        
C        
  206 CASE = 6        
      IF (BUF41 .EQ. -9) GO TO 350        
C        
  207 CALL XREAD (*207,FUB)        
      IF (BUF41.EQ.-1 .OR. BUF41.EQ.-5) GO TO 207        
      FUB41 = BUF41        
      BUF41 = -2        
      IF (FUB(1).NE.BLANK .OR. FUB(2).NE.BLANK) GO TO 215        
      FUB41 = -2        
      CASE  = 5        
      KONTN = KONTN + 1        
      IF (KONTN .EQ. 10020000) KSMBI = KSMB(2)        
      IF (KONTN .EQ. 10030000) KSMBI = KSMB(3)        
      IMHERE  = 207        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,KONTN,COUNT,NZ25,CASE        
      CALL INT2A8 (*3140,KONTN,FUB(1))        
      FUB(1)  = KSMBI        
      BUF(19) = KSMBI        
      BUF(20) = FUB(2)        
      GO TO 217        
C        
  208 NOGO  = 1        
      WRITE  (NOUT,209) SFM,IMHERE        
  209 FORMAT (A25,'.  IMHERE =',I6)        
      GO TO 214        
C        
  210 DO 211 I = 1,25        
  211 BUF(I) = FUB(I)        
      BUF41  = FUB41        
      IF (CASE-5) 214,206,214        
  212 CALL XREAD (*3120,BUF)        
      IF (BUF(1).EQ.BLANK .AND. BUF(2).EQ.BLANK) GO TO 204        
  214 CASE = 1        
C        
C     IGNORE COMMENT CARD (-1) OR BLANK CARD (-5)        
C        
  215 IF (BUF41.NE.-1 .AND. BUF41.NE.-5) GO TO 216        
      CMMT = CMMT + 1        
      GO TO 212        
C        
C     TEST FOR ENDDATA CARD (-9)        
C        
  216 IF (BUF41 .EQ. -9) GO TO 350        
C        
C     IF THIS IS A CONTINUATION CARD (-2), ADD ONE CONTROL WORD ABOUT   
C     RESTART, AND WRITE IHE CARD OUT TO TAPE2        
C     (THE CONTROL WORD WILL FLAG THE PARENT BIT TO BE SET FOR RESTART  
C     WHEN THIS CONTINUATION CARD IS MERGED INTO NPTP)        
C        
      IF (BUF41 .NE. -2) GO TO 230        
  217 BUF(21) = RESTR        
      CALL WRITE (TAPE2,BUF(1),21,0)        
      IF (DEBUG) WRITE (NOUT,220) BUF(1),BUF(2),BUF(21)        
  220 FORMAT (5X,'A CONTINUATION CARD - ',2A4,',  CONT.FLAG=',I9)       
      NCONT = NCONT + 1        
      GO TO 200        
C        
C     IF THIS IS A DELETE CARD (-3), REJECT IT IF EXTRANEOUS DATA IN    
C     FIELD 1 OTHERWISE WRITE THE RANGE OF DELETION ON TAPE1        
C        
  230 IF (BUF41 .NE. -3) GO TO 300        
      CMMT = CMMT + 1        
      IF (BUF4(4) .NE. -4) GO TO 250        
      CALL PAGE2 (2)        
      WRITE  (NOUT,240) UFM        
  240 FORMAT (A23,' 221, EXTRANEOUS DATA IN FIELD 1 OF BULK DATA ',     
     1       'DELETE CARD.')        
      NOGO = -2        
C        
  250 IF (BUF4(3) .EQ. -3) GO TO 270        
      IF (BUF4(4) .EQ. -3) BUF4(4) = BUF4(3)        
      BUF4(3) = BUF4(3) - 2000000000        
      BUF4(4) = BUF4(4) - 2000000000        
      CALL WRITE (TAPE1,BUF4(3),2,0)        
      IF (DEBUG) WRITE (NOUT,260) BUF4(3),BUF4(4)        
  260 FORMAT (5X,'A DELETE CARD -',I11,1H,,I11)        
      NDELE  = NDELE + 1        
      GO TO 200        
  270 WRITE  (NOUT,280) UFM        
  280 FORMAT (A23,' 221, NO DATA IN FIELD 2 OF BULK DATA DELETE CARD')  
      NOGO = -1        
      GO TO 200        
C        
C     REGULAR BULKDATA CARDS.        
C     SAVE 20 WORDS OF BUF, 4 WORDS FROM BUF4 AND CORE COUNTER IN OPEN  
C     CORE SPACE Y (25 WORDS TOTAL)        
C     SET RESTART BITS IF THIS IS A RESTART RUN        
C     RETURN TO READ NEXT BULKDATA CARD        
C        
  300 COUNT = COUNT + 1        
      WRTTN = 1        
      DO 310 I = 1,20        
  310 Y(I,COUNT) = BUF(I)        
      DO 320 I = 1,4        
  320 Y(I+20,COUNT) = BUF4(I)        
      Y(25  ,COUNT) = COUNT        
      IF (DEBUG) WRITE (NOUT,330) COUNT,Y(1,COUNT),Y(2,COUNT)        
  330 FORMAT (5X,'SAVED IN CORE   COUNT=',I5,3X,2A4)        
      IF (RESTR .EQ. 0) GO TO 200        
      ASSIGN 200 TO CRDFLG        
      FROM = 330        
      GO TO 2800        
C        
C     OPEN CORE BUFFER FULL, ENDDATA CARD HAS NOT BEEN ENCOUNTERED      
C        
  340 FULL = 1        
      GO TO 400        
C        
C     ENDDATA CARD FOUND, SET FLAG        
C        
  350 FULL  = -1        
      IMHERE= 350        
      NCARD = NCARD - 1        
      NBULK = NCARD - CMMT        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,NCARD,NCONT,NDELE        
      CALL PAGE2 (2)        
      IF (ECHOU .NE. 1) GO TO 370        
      WRITE  (NOUT,360) NCARD        
  360 FORMAT (//24X,'TOTAL COUNT=',I7)        
      GO TO 400        
  370 WRITE  (NOUT,380) NCARD,CMMT        
  380 FORMAT (//24X,'(NO. OF UNSORTED BULK DATA CARDS READ =',I6,       
     1       ', INCLUDING',I4,' COMMENT CARDS)')        
C        
C     SORT CARD IMAGES SAVED IN THE OPEN CORE SPACE BY MODIFIED SHELL   
C     METHOD.        
C     SORT BY 21ST, 22ND, 23RD, AND 24TH CONTROL WORDS ONLY        
C     ONLY THE LAST 5 WORDS (21ST THRU 25TH) ARE MOVED INTO SORTED      
C     ORDER, THE FIRST 20 WORDS REMAIN STATIONARY.        
C        
  400 IF (WRTTN .EQ.    0) GO TO 580        
      IF (COUNT .GT. NZ25) CALL MESAGE (-37,0,NAME)        
      M  = COUNT        
      IMHERE = 400        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,COUNT        
  410 M  = M/2        
      IF (M .EQ. 0) GO TO 500        
      J  = 1        
      K  = COUNT - M        
  420 I  = J        
  430 N  = I + M        
      IF (Y(21,I) - Y(21,N)) 490,440,470        
  440 IF (Y(22,I) - Y(22,N)) 490,450,470        
  450 IF (Y(23,I) - Y(23,N)) 490,460,470        
  460 IF (Y(24,I) - Y(24,N)) 490,490,470        
  470 DO 480 L = 21,25        
      TEMPX  = Y(L,I)        
      Y(L,I) = Y(L,N)        
  480 Y(L,N) = TEMPX        
      I = I - M        
      IF (I .GE. 1) GO TO 430        
  490 J = J + 1        
      IF (J-K) 420,420,410        
C        
C     END OF CORE SORT.        
C     WRITE THE SORTED BULKDATA CARDS TO FILE, 24 WORDS EACH RECORD     
C     IN ORDER GIVEN BY THE 25TH WORD.        
C     IF ONLY ONE SCRATCH FILE (TAPE3) IS USED IN RECEIVING BULKDATA,   
C     CHECK ANY DUPLICATE CARD.        
C        
  500 IMHERE = 500        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,COUNT,MAXC        
      ONLY1 = .FALSE.        
      IF (FULL.EQ.-1 .AND. TAPE.EQ.TAPE3) ONLY1=.TRUE.        
      BASE = 25        
      DO 570 I = 1,COUNT        
      IF (ONLY1) BASE = MOD(I,2)*25        
      J = Y(25,I)        
      DO 510 K = 1,20        
  510 BUF(K+BASE) = Y(K,J)        
      DO 520 K = 21,24        
  520 BUF(K+BASE) = Y(K,I)        
      IF (.NOT.ONLY1) GO TO 550        
      IF (I  .EQ.  1) GO TO 540        
      DO 530 K = 1,20        
      IF (BUF(K+BASE) .NE. BUF(K+OBASE)) GO TO 540        
  530 CONTINUE        
      BUF(21+BASE) = -6        
      BUF(22+BASE) = -6        
  540 OBASE = BASE        
  550 CALL WRITE (TAPE,BUF(BASE+1),24,0)        
      IF (DEBUG) WRITE (NOUT,560) TAPE,(BUF(K+BASE),K=1,8)        
     1                                ,(BUF(K+BASE),K=21,24)        
  560 FORMAT (5X,'WRITE TO ',I3,4(2X,2A4), /9X,'INT.CODE=',4I12)        
  570 CONTINUE        
      CALL WRITE (TAPE,0,0,1)        
  580 CALL CLOSE (TAPE,REW)        
      IMHERE = 580        
      IF (DEBUG) WRITE (NOUT,140) IMHERE        
C        
C     REPEAT READING BULKDATA CARDS INTO CORE IF NECESSARY        
C        
C     IF NO DATA WRITTEN TO CURRENT FILE (e.g. UN-MODIFIED RESTART),    
C     REDUCE TAPE COUNT BY ONE        
C        
      IF (FULL .NE. -1) GO TO 170        
      IF (WRTTN .EQ. 0) TAPE = TAPE - 1        
C        
C     CLOSE DELETE CARD FILE, TAPE 1.        
C     CONTINUATION CARD FILE, TAPE 2, IS STILL IN USE        
C        
      CALL WRITE (TAPE1,0,0,1)        
      CALL CLOSE (TAPE1,REW  )        
C        
C     TEST FOR COLD-START WITH NO BULKDATA        
C        
C     APPRC = APPROACH FLAG (1 DMAP, 2 DISP, 3 HEAT, 4 AERO)        
C     SUBS  = SUBSTRUCTURING FLAG        
C        
      IMHERE = 585        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,COUNT,APPRC,WRTTN,RESTR,SUBS   
      IF (WRTTN.EQ.1 .OR. RESTR.EQ.1 .OR. SUBS.NE.0) GO TO 600        
      CALL CLOSE (TAPE2,REW)        
      ECHOS = 1        
      IF (APPRC .EQ. 1) GO TO 1600        
      CALL PAGE2 (2)        
      WRITE  (NOUT,590) UFM        
  590 FORMAT (A23,' 204, COLD START NO BULK DATA.')        
      NOGO = -2        
      GO TO 3200        
C        
C     IF MODIFIED RESTART - TURN ON SORT ECHO FLAG IF ECHO IS NOT 'NONO'
C     IF NOT A RESTART JOB - JUMP TO 1000        
C        
  600 IF (NBULK.GT.1 .AND. RESTR.EQ.1) ECHOS = 1        
C     IF (APPRC.EQ.1 .OR.  SUBS .NE.0) ECHOS = 1        
      IF (ECHO  .EQ. -2) ECHOS = 0        
      IF (RESTR .EQ.  0) GO TO 1000        
C        
C     THIS IS A RESTART JOB, PROCESS OPTP FILE -        
C        
C     OPEN OPTP AND LOCATE WHERE BULK DATA BEGINS        
C        
      IMHERE = 610        
      IF (DEBUG) WRITE (NOUT,140) IMHERE        
      CALL OPEN (*3080,OPTP,Z(IBUF3),RDREW)        
  610 CALL SKPFIL (OPTP,+1)        
      CALL READ (*3040,*3040,OPTP,BUF(1),2,1,J)        
      IF (BUF(1).NE.BULKDA(1) .OR. BUF(2).NE.BULKDA(2)) GO TO 610       
      IF (NBULK.GT.0 .OR. NDELE.NE. 0) GO TO 640        
C        
C     UN-MODIFIED RESTART, WITH NO NEW BULKDATA CARD AND NO DELETE -    
C     SETUP SORTED HEADER FOR OLD BULK DATA CARDS IF ECHO FLAG IS ON,   
C     COPY THE REST OF OPTP DIRECTLY TO NPTP, AND JOB DONE        
C        
C        
      IMHERE = 620        
      IF (DEBUG) WRITE (NOUT,140) IMHERE        
      CALL OPEN  (*3100,NPTP,Z(IBUF1),WRT)        
      CALL WRITE (NPTP,BULKDA,2,1)        
      NCARD = 0        
      IF (ECHOS .EQ. 0) GO TO 620        
      READ (HEAD(2),150) (HEAD1(J),J=11,24)        
      HEAD2(4) = CDCNT(1)        
      HEAD3(4) = CDCNT(2)        
      HEAD3(5) = CDCNT(3)        
      CALL PAGE        
  620 CALL READ  (*630,*630,OPTP,BUF(1),20,1,J)        
      CALL WRITE (NPTP,BUF(1),20,1)        
      NCARD = NCARD + 1        
      IF (ECHOP .NE. 0) WRITE (LPCH,1750) (BUF(J),J=1,20)        
      IF (ECHOS .EQ. 0) GO TO 620        
      CALL PAGE2 (-1)        
      WRITE (NOUT,1730) NCARD,(BUF(J),J=1,20)        
      GO TO 620        
  630 CALL EOF   (NPTP)        
      CALL CLOSE (NPTP,  REW)        
      CALL CLOSE (OPTP,NOREW)        
      CALL CLOSE (TAPE2, REW)        
      IF (ECHOP .NE. 0) WRITE (LPCH,2320)        
      CALL PAGE2 (-1)        
      IF (ECHOS .NE. 0) WRITE (NOUT,2300)        
      IF (ECHOS .EQ. 0) WRITE (NOUT, 635) UIM,NCARD        
  635 FORMAT (A29,1H,,I8,' SORTED BULKD DATA CARDS PROCESSED FROM OPTP',
     1        ' FILE TO NPTP, UN-MODIFIED')        
      GO TO 2700        
C        
C     MODIFIED RESTART WITH NEW BULKDATA CARDS, WITH OR WITHOUT DELETE  
C        
  640 IMHERE = 640        
      IF (DEBUG) WRITE (NOUT,140) IMHERE        
      IC   = 1        
      LEFT = NZ        
      IF (NDELE .EQ. 0) GO TO 710        
      IF (RESTR .EQ. 1) GO TO 660        
      CALL PAGE2 (-1)        
      WRITE  (NOUT,650) UWM        
  650 FORMAT (A25,' 205, COLD START, DELETE CARDS IGNORED.')        
      GO TO 710        
C        
C     RESTART WITH DELETE CARD(S) -        
C     MOVE THE DELETE CARDS  INTO CORE AND FREE TAPE1.        
C     SORT THE DELETE CARDS, CHECK FOR AND ELIMINATE OVERLAPS AND       
C     REDUNDANCIES        
C        
  660 CALL OPEN (*2900,TAPE1,Z(IBUF1),RDREW)        
      CALL READ (*2900,*670,TAPE1,Z(1),LEFT,1,LEN)        
      CALL MESAGE (-8,TAPE1,NAME)        
  670 CALL CLOSE  (TAPE1,REW    )        
C        
      CALL SORT (0,0,2,1,Z(1),LEN)        
      Z(LEN+1) = LARGE        
      DO 680 I = 2,LEN,2        
      Z(I) = Z(I)+1        
      IF (Z(I) .LT. Z(I-1)) Z(I) = Z(I-1)        
      IF (Z(I) .LT. Z(I+1)) GO TO 680        
      Z(I  ) = -1        
      Z(I+1) = -1        
  680 CONTINUE        
      J = 0        
      DO 690 I = 1,LEN        
      IF (Z(I) .LT. 0) GO TO 690        
      J = J + 1        
      Z(J) = Z(I)        
  690 CONTINUE        
      IF (J .GT. 0) LEN = J        
      LEFT = NZ - LEN        
      IC   = LEN + 1        
      Z(IC)  = LARGE        
      IMHERE = 700        
      IF (DEBUG) WRITE (NOUT,700) IMHERE,(Z(I),I=1,LEN)        
  700 FORMAT (/,' *** IMHERE =',I5,(/,3X,10(I7,I5)))        
      IF (MOD(LEN,2) .NE. 0) GO TO 3140        
      GO TO 800        
C        
C     IF MODIFIED RESTART WITH NO DELETE, SET DELETE RANGE BEGINNING AT 
C     INFINITY        
C        
  710 Z(1)   = LARGE        
      IMHERE = 710        
      IF (DEBUG) WRITE (NOUT,140) IMHERE        
C        
C     WE ARE STILL IN PROCESSING RESTART - COPY OPTP TO TAPE1, SKIP     
C     APPROPRIATE RECORDS AS SPECIFIED BY THE DELETE CARDS NOW IN       
C     OPEN CORE, Z(1) THRU Z(LEN)        
C        
C     SEND A CARD FROM OPTP TO YREAD (AN ENTRY POINT IN XREAD) FOR      
C     RE-PROCESSING. UPON RETURN FROM YREAD, BUF4 ARRAY HOLDS THE       
C     INTERNAL INTEGER CODE GOOD FOR SORTING AND OTHER FUNCTIONS.       
C        
C     IF IT IS A CONTINUATION CARD, COPY THE FULL CARD (20 WORDS)       
C     AND ONE CONTROL WORD TO TAPE2.        
C     OTHERWISE COPY 24 WORDS (20-BUF AND 4-BUF4) TO TAPE1.        
C        
C     IF A CONTINUATION CARD IS DELETED, THE RESTART BITS OF THE        
C     PARENT CARD SHOULD BE FLAGGED        
C        
  800 IMHERE  = 800        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,RESTR,TAPE1        
      CALL OPEN (*2900,TAPE1,Z(IBUF1),WRTREW)        
      KOUNT   = 0        
      POINT   = 1        
      ONOFF   = 1        
      ZPOINT  = Z(POINT)        
      BUF(19) = 0        
  810 TEMP(1) = BUF(19)        
      TEMP(2) = BUF(20)        
      CALL READ (*900,*900,OPTP,BUF(1),20,1,J)        
      KOUNT   = KOUNT + 1        
      IF (KOUNT .LT. ZPOINT) GO TO 820        
      POINT   = POINT + 1        
      ZPOINT  = Z(POINT)        
      ONOFF   = ONOFF*(-1)        
  820 CALL YREAD (*3060,BUF)        
      IMHERE  = 830        
      IF (DEBUG .AND. ONOFF.EQ.-1) WRITE (NOUT,830) IMHERE,KOUNT,       
     1                             (BUF(J),J=1,6)        
  830 FORMAT (' IMHERE=',I5,'.  DELETED FROM OPTP ==>',I5,2H- ,6A4)     
      IF (BUF41 .EQ. -2) GO TO 870        
      IF (ONOFF .EQ. +1) GO TO 840        
C        
C     ANY DELETED CARD, EXCEPT CONTINUATION CARD, MUST RESET        
C     RESTART CARD FLAG        
C        
      ASSIGN 810 TO CRDFLG        
      FROM = 830        
      GO TO 2800        
C        
C     REGULAR BULKDATA CARD FROM OPTP -        
C     SAVE FIRST FIELD IN KARD1/2 JUST IN CASE THIS IS A PARENT OF      
C     A CONTINUATION CARD WHICH FALLS INSIDE A DELETE RANGE.        
C        
C     NOTE- CARDS FROM OPTP ARE IN SORTED ORDER, AND NO CARD COUNT HERE 
C        
  840 DO 850 J = 1,4        
  850 BUF(J+20) = BUF4(J)        
      CALL WRITE (TAPE1,BUF(1),24,0)        
      IF (DEBUG) WRITE (NOUT,860) (BUF(J),J=1,6),BUF(21)        
  860 FORMAT (' IMHERE=860, OPTP==>TAPE1  ',6A4,'==>',I9)        
      KARD1 = BUF(1)        
      KARD2 = BUF(2)        
      IF (KARD1.NE.PARAM(1) .OR. KARD2.NE.PARAM(2)) GO TO 810        
      KARD1 = BUF(3)        
      KARD2 = BUF(4)        
      GO TO 810        
C        
C     CONTINUATION CARD FROM OPTP -        
C        
C     IF BOTH PARENT AND THIS CONTINUATION CARD IN NOT IN DELETE RANGE  
C     SEND THIS CONTINUATION CARD TO TAPE2 WITH RESTART CONTROL WORD    
C     SET TO ZERO.        
C     IF PARENT IS NOT DELETED, BUT THIS CONTINUATION CARD IS, WE NEED  
C     TO FLAG PARENT        
C     IF PARENT IS ALSO IN DELETE RANGE, SKIP THIS CONTINUATION CARD.   
C        
  870 IF (ONOFF .EQ. +1) GO TO 890        
      IF (KARD1 .EQ. -1) GO TO 810        
      IF (BUF(1).EQ.TEMP(1) .AND. BUF(2).EQ. TEMP(2)) GO TO 810        
      FROM  = 860        
      ASSIGN 880 TO CRDFLG        
      GO TO 2810        
  880 KARD1 = -1        
      GO TO 810        
  890 BUF(21) = 0        
      CALL WRITE (TAPE2,BUF(1),21,0)        
      NCONT = NCONT + 1        
      GO TO 810        
C        
C     OPTP IS SUCCESSFULLY MOVED TO TAPT1 AND TAPE2. CLOSE FILES        
C        
  900 CALL CLOSE (OPTP ,NOREW)        
      CALL WRITE (TAPE1,0,0,1)        
      CALL WRITE (TAPE2,0,0,1)        
      CALL CLOSE (TAPE1,REW  )        
C        
C     PREPARE FOR FILE MERGE -        
C        
C     SELECT METHOD USED TO BRING CONTINUATION CARDS INTO CORE AND      
C     COMPUTE NUMBER OF BUFFERS NEEDED FOR FILE PRE-MERGE.        
C        
C     METHOD 1 - NO FILE PRE-MERGE IF THERE IS NO CONINUATION CARDS, OR 
C                ENOUGH SPACE IN CORE TO HOLD ALL CONTINUATION CARDS,   
C                BUFFERS AND SCRATCH ARRAYS FOR ALL SCRATCH DATA FILES  
C     METHOD 2 - ALL CONTINUATION CARDS, IN 3-WORD TABLE AND 20-WORD    
C                CARD IMAGES, AND ALL GINO BUFFERS, OR REDUCED GINO     
C                BUFFERS, FIT INTO CORE        
C     METHOD 3 - CONTINUATION 3-WORD TABLE AND ALL GINO BUFFERS, OR     
C                REDUCED GINO BUFFERS, FIT INTO CORE        
C     METHOD 4 - FATAL, INSUFFICIENT CORE        
C        
 1000 CALL CLOSE (TAPE2,REW)        
      METHOD = 1        
      N23    = 1        
      NFILES = TAPE - TAPE3 + 1        
      REDUCE = 1        
      IF (NFILES .GE. 10) REDUCE = 2        
      IF (NFILES .GT. 17) REDUCE = 3        
      J      = 0        
      IF (RESTR .EQ. 1) J = 1        
      MAXC   = (NZZ-(BUFSZ+25)*(NFILES+J))/21        
      IF (NCONT .LE. MAXC) REDUCE = 1        
      NFILER = (NFILES+REDUCE-1)/REDUCE + J        
      IMHERE = 1010        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,REDUCE,NFILES,NFILER        
      IF (NCONT) 1020,1100,1020        
 1010 SIZE   = (NFILER+1)*BUFSZ + NFILER*25        
      SIZE   = SIZE + BUFSZ        
      LEFT   = NZZ - SIZE        
      MAXC   = LEFT/N23        
      IMHERE = 1020        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,METHOD,NFILES,NFILER,N23,NCONT 
      IF (NCONT .LE. MAXC) GO TO 1100        
      GO TO (1020,1030,1040), METHOD        
 1020 METHOD = 2        
      N23    = 23        
      GO TO 1010        
 1030 METHOD = 3        
      N23    = 3        
      GO TO 1010        
C        
C     INSUFFICIENT CORE, COMPUTE HOW MUCH MORE NEEDED        
C        
 1040 J = NCONT*N23 - LEFT        
      CALL MESAGE (-8,J,NAME)        
C        
C     ALLOCATE BUFFER SPACE AND REDEFINE AVAILABLE CORE SPACE, NZ       
C     ALLOCATE SPACES AT THE BEGINNING OF CORE SPACE FOR BULKDATA       
C     TO BE BROUGHT BACK FROM VARIOUS FILES.        
C        
C     IC     = POINTER, WHERE CONTINUATION TABLE BEGINS        
C     IB     = POINTER, WHERE CONTINUATION  DATA BEGINS        
C     NFILES = TOTAL NUMBER OF FILES USED BEFORE FILE REDUCTION,        
C              RESTART TAPE1 NOT INCLUDED        
C     NFILER = REDUCED NUMBER OF FILES THAT HOLD BULKDATA INPUT CARDS,  
C              RESTART TAPE1 INCLUDED        
C     TAPECC = AN ADDITIONAL FILE USED ONLY IN METHOD 3 (NOT INCLUDED   
C              IN NFILES AND NFILER)        
C        
 1100 IMHERE = 1100        
      IF (DEBUG .OR. NFILES.GT.10 .OR. NCONT.GT.1000)        
     1    WRITE (NOUT,1110) UIM,METHOD,NFILER,HICORE,NCONT        
 1110 FORMAT (A29,' FROM XSORT -  METHOD',I3,' WAS SELECTED TO PROCESS',
     1        ' CONTINUATION CARDS', /5X,'NO. OF FILES USED =',I4,4X,   
     2        'HICORE =',I7,' WORDS', 4X,'NO. OF CONT. CARDS =',I7)     
      NZ   = IBUF1        
      DO 1120 I = 1,NFILER        
      NZ   = NZ - BUFSZ        
 1120 IBUFX(I) = NZ        
      IF (NCONT .GT. 0) NZ = NZ - BUFSZ        
      IBUFC= NZ        
      NZ   = NZ - 1        
      IC   = NFILER*25 + 1        
      IB   = IC + NCONT*3        
      NZIB = NZ - IB + 1        
      LEFT = NZ - IC + 1        
C        
C     NEED A STORAGE SPACE FOR AT LEASE 100 CONTINUATION CARDS        
C        
      IF (NZIB .LT. 2100) CALL MESAGE (-8,-2100+NZIB,NAME)        
C        
C     METHOD 1, NO CONTINUATION CARD IN BULKDATA, SKIP TO 1280        
C        
      IF (METHOD .EQ. 1) GO TO 1280        
C        
C     WORKING SPACE FOR THE CONTINUATION TABLE AND CONTINUATION CARD    
C     IMAGES -        
C        
C                  IC                 IB                   NZ        
C                  /                  /                    /        
C     ------------------------------------------------------------------
C     ! ! ! !..Y..!                  !                     !  !  !  !  !
C     ------------------------------------------------------------------
C     ! SPACE FOR !<--CONTINUATION-->!<--AVAILABLE SPACE-->!<--GINO--->!
C       DATA FROM     INDEX TABLE        FOR CONTINUATION     BUFFERS   
C       FILES 303,   (3 WORDS EACH)      CARD IMAGES        
C       304,...                          (21 WORDS EACH)        
C       FOR FILE      (PART 1 AERA)        
C       MERGE                            (PART 2 AREA)        
C        
      IMHERE = 1125        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,METHOD,N23        
      CALL OPEN (*2910,TAPE2,Z(IBUF2),RDREW)        
      IF (METHOD .EQ. 3) GO TO 1200        
C        
C     METHOD 2 -        
C        
C     OPEN CORE IS DIVIDED INTO 2 PARTS - A 3-WORD CONTINUATION TABLE   
C     IN PART 1, AND 21-WORD CONTINUATION CARD IMAGES IN PART 2.        
C        
C     3-WORD TABLE IN PART 1 HOLDS THE 2-BCD CONTIUATION SYMBOLS, WITH  
C     THE FIRST BYTE (A + OR *) ZERO OUT, AND AN INDEX POINTER. THIS    
C     TABLE WILL BE SORTED, AND WILL BE USED BY BISLC2 TO LOCATE THE    
C     CARD IMAGES SAVED EITHER IN PART 2, OR IN TAPECC FILE.        
C        
      IMHERE = 1130        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,METHOD,NCONT,IC,IB        
      CALL READ (*3000,*1130,TAPE2,Z(IB),NZIB,1,LEN)        
      CALL MESAGE (-8,0,NAME)        
 1130 K = LEN + IB - 1        
      I = IC        
      DO 1140 J = IB,K,21        
      Z(I  ) = ANDF(Z(J),LES1B)        
      Z(I+1) = Z(J+1)        
      Z(I+2) = J        
 1140 I = I + 3        
      GO TO 1270        
C        
C     METHOD 3 -        
C        
C     COMPUTE NCCI (NO. OF CONTINUATION CARD IMAGES) THAT PART 2 AREA   
C     (FROM Z(IB) THRU Z(NZ)) CAN HOLD AT A GIVEN TIME.        
C     CREATE IN CORE A CONTINUATION TABLE WITH INDEX POINTERS (SAME     
C     AS METHOD 2) IN PART 1 AREA.        
C     FILL THE REMAINING PART 2 AREA WITH NCCI CARDS, AND WRITE THIS    
C     BLOCK OF CARDS OUT TO A NEW SCRATCH FILE, TAPECC. REPEAT THIS     
C     PROCESS FOR THE REST OF THE CONTINUATION CARDS.        
C     THE INDEX POINTERS IN PART 1 (METHOD 3 ONLY) ALSO INCLUDE THE     
C     DATA BLOCK NUMBER INFORMATION        
C        
 1200 NCCI = NZIB/21        
      IF (NCCI .GE. 10000000) NCCI = 10000000 - 1        
      NZIB   = NCCI*21        
      TAPECC = NFILES + TAPE3        
      IMHERE = 1200        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,METHOD,TAPECC,NCCI        
      IF (TAPECC .GT. MAXSCR) GO TO 2951        
      CALL OPEN (*2950,TAPECC,Z(IBUFC),WRTREW)        
      BK  = 0        
      I   = IC        
      IF (NCCI.GE.750 .OR. MACH.LE.2 .OR. NBPW.EQ.64) GO TO 1220        
      J   = ((NCONT*23 - NZ+IC +999)/1000)*1000        
      WRITE  (NOUT,1210) UIM,J,HICORE        
 1210 FORMAT (A29,', DUE TO UNUSUAL LARGE NUMBER OF CONTINUATION CARDS',
     1       ' PRESENT IN THE BULKDATA DECK', /5X,'AN ADDITION OF',I7,  
     2       ' WORDS TO OPEN CORE SPACE COULD MAKE LINK1 MORE EFFICIENT'
     3,      /5X,'CURRENTLY NASTRAN HICORE IS',I7,' WORDS')        
      IF (NCCI .LT. 100) NOGO = -3        
 1220 BK  = BK + 10000000        
      J   = IB        
      TOP = NZIB        
      CALL READ (*1260,*1230,TAPE2,Z(IB),TOP,0,LEN)        
      GO TO 1240        
 1230 TOP = LEN        
 1240 TOP = TOP + IB - 1        
 1250 Z(I  ) = ANDF(Z(J),LES1B)        
      Z(I+1) = Z(J+1)        
      Z(I+2) = J + BK        
      I   = I + 3        
      J   = J + 21        
      IF (J .LT. TOP) GO TO 1250        
      CALL WRITE (TAPECC,Z(IB),NZIB,1)        
      GO TO 1220        
 1260 CALL CLOSE (TAPECC,REW)        
 1270 CALL CLOSE (TAPE2 ,REW)        
      LEN = I - IC        
      IF (LEN .GT. 3) CALL SORT2K (0,0,3,1,Z(IC),LEN)        
C        
C     NO PRE-MERGING FILES IF REDUCE IS 1 (I.E. LESS THAN 10 SCRATCH    
C     FILES WERE USED TO HOLD THE RAW BULKDATA, OR ENOUGH CORE TO HOLD  
C     EVERYTHING)        
C        
 1280 IF (REDUCE .EQ. 1) GO TO 1600        
C        
C     PRE-MERGE        
C     =========        
C        
C     AT THIS POINT, CONTINUATION CARD IMAGES ARE EITHER IN CORE OR IN  
C     SCRATCH FILE TAPECC, AND TAPE2 IS FREE FOR RE-USE.        
C     ALL GINO BUFFERS ARE FREE        
C        
C     IF TOO MANY FILES WERE USED TO SAVE BULKDATA, MERGE THEM TO REDUCE
C     THE TOTAL NUMBER OF FILES GOING TO BE USED (I.E. TO REDUCE BUFFER 
C     SPACE IN THE MERGE PHASE COMING NEXT)        
C        
C     PERFORM A 2-TO-1 MERGE IF NUMBER OF FILES PRESENTLY IS 10-17.     
C        
C     FILEB + FILEC == FILEA      E.G.  303 + 304 == 302        
C                                       305 + 306 == 303        
C                                       307 + 308 == 304  ETC.        
C     OR        
C     PERFORM A 3-TO-1 MERGE IF NUMBER OF FILES PRESENTLY IS 18-30.     
C        
C     FILEB+FILEC+FILED == FILEA  E.G.  303+304+305==302        
C                                       306+307+308==303        
C                                       309+310+311==304  ETC.        
C        
C     NOTE - 301 IS EITHER NOT USED, OR USED BY THE 'MODIFIED' OPTP     
C        
      IMHERE = 1290        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,NFILES,NFILER,REDUCE        
      FILEA  = 301        
      FILE   = 302 - REDUCE        
C        
      DO 1580 III = 1,NFILES,REDUCE        
      FILE = FILE+REDUCE        
C        
C ... CHECK LAST DO-LOOP CONDITION        
C     IF ONE   FILE  LEFT, QUIT MERGING        
C     IF TWO   FILES LEFT, DO A 2-TO-1 MERGE        
C     IF THREE FILES LEFT, CONTINUE        
C        
      IF (NFILES-III .LE. 0) GO TO 1420        
C        
      FILEA = FILEA + 1        
      CALL OPEN (*2930,FILEA,Z(IBUF1),WRTREW)        
      IMHERE= 1300        
      EXH   = 0        
      DO 1300 L = 1,REDUCE        
      FILEX = FILE + L        
      IBUFL = IBUFX(L)        
      ITAPE(L) = 1        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,FILEX,J        
      CALL OPEN (*2940,FILEX,Z(IBUFL),RDREW)        
      CALL READ (*3000,*2980,FILEX,Y(1,L),24,0,I)        
 1300 CONTINUE        
C        
C     PICK THE SMALLEST CONTROL WORDS FROM Y(21,22,23,24 OF A,B,C)      
C        
 1310 II = 1        
      DO 1380 L = 2,REDUCE        
      IF (Y(21,L) - Y(21,II)) 1370,1320,1380        
 1320 IF (Y(21,L) .EQ. LARGE) GO TO 1380        
      IF (Y(22,L) - Y(22,II)) 1370,1330,1380        
 1330 IF (Y(23,L) - Y(23,II)) 1370,1340,1380        
 1340 IF (Y(24,L) - Y(24,II)) 1370,1350,1380        
C        
C     FIRST 3 BULKDATA FIELDS THE SAME, CHECK POSSIBLE DUPLICATE CARD   
C     SET 21ST AND 22ND CONTROL WORDS TO -6 IF IT IS A DUPLICATE        
C        
 1350 DO 1360 J = 7,20        
      IF (Y(J,L) .NE. Y(J,II)) GO TO 1380        
 1360 CONTINUE        
      Y(21,II) = -6        
      Y(22,II) = -6        
      NOGO = -1        
      GO TO 1370        
C        
 1370 II = L        
 1380 CONTINUE        
      IMHERE = 1380        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,II        
C        
      IF (Y(1,II) .EQ. LARGE) CALL MESAGE (-61,0,NAME)        
      CALL WRITE (FILEA,Y(1,II),24,0)        
      FILEX = II + FILE        
      CALL READ (*2980,*1400,FILEX,Y(1,II),24,0,J)        
      IF (DEBUG) WRITE (NOUT,1390) FILEX,Y(1,II),Y(2,II)        
 1390 FORMAT (5X,'TO PRE-MERGE FILE',I5,3X,2A4)        
      GO TO 1310        
C        
C ... ONE OF THE FILES IS EXHAUSTED        
C        
 1400 EXH = EXH + 1        
      ITAPE(II) = 0        
      IF (EXH .GE. REDUCE-1) GO TO 1420        
      DO 1410 J = 1,24        
 1410 Y(J,II) = LARGE        
      IMHERE  = 1410        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,EXH        
      GO TO 1310        
C        
C ... ONLY ONE FILE LEFT WHICH HAS NOT BEEN EXHAUSTED        
C        
 1420 FILEX = FILE + 1        
      IF (ITAPE(2) .EQ. 1) FILEX = FILE + 2        
      IF (ITAPE(3) .EQ. 1) FILEX = FILE + 3        
      IMHERE = 1420        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,FILEX        
      DO 1430 J = 1,24        
 1430 Z(J) = Y(J,FILEX)        
C        
C     THIS REMAINING FILE COULD BE VERY BIG. IT COULD BE OPTP        
C        
      LEFT24 = ((LEFT-24)/24)*24        
 1440 FULL = 1        
      CALL READ (*3000,*1450,FILEX,Z(I25),LEFT24,0,LEN)        
      FULL = 0        
      LEN  = LEFT24        
 1450 IF (LEN .LT. 24) GO TO 1560        
C        
C ... CHECK ANY DUPLICATE IN THIS GROUP, SET THE 21ST AND 22ND CONTROL  
C     WORDS TO -6 IF DUPLICATE        
C     THEN WRITE THE REST TO FILEA        
C        
      DO 1540 L = 1,LEN,24        
      I = L - 1        
      K = I + 24        
      DO 1500 J = 21,24        
      IF (Z(I+J) .NE. Z(K+J)) GO TO 1520        
 1500 CONTINUE        
      DO 1510 J = 7,20        
      IF (Z(I+J) .NE. Z(K+J)) GO TO 1520        
 1510 CONTINUE        
      Z(I+21) = -6        
      Z(I+22) = -6        
 1520 CALL WRITE (FILEA,Z(L),24,0)        
      IF (DEBUG) WRITE (NOUT,1530) FILEA,Z(L),Z(L+1)        
 1530 FORMAT (5X,'TO FILEA',I5,3X,2A4)        
 1540 CONTINUE        
C        
C     IF FILE HAS NOT BEEN EXHAUSTED, GO BACK FOR MORE        
C        
      IF (FULL .EQ. 1) GO TO 1560        
      DO 1550 J = 1,24        
 1550 Z(J) = Z(LEN+J)        
      GO TO 1440        
C        
 1560 CALL WRITE (FILEA,Z(LEN+1),24,1)        
      IF (DEBUG) WRITE (NOUT,1530) FILEA,Z(LEN+1),Z(LEN+2)        
      DO 1570 L = 1,REDUCE        
      FILEX = FILE + L        
      CALL CLOSE (FILEX,REW)        
 1570 CONTINUE        
C        
 1580 FILE = FILE + REDUCE        
C        
C     END OF PRE-MERGE        
C        
C        
C     SET UP SORTED HEADING IF APPLICABLE        
C        
 1600 IF (NBULK .LE. 1) GO TO 1620        
      CALL PAGE2 (2)        
      WRITE  (NOUT,1610) UIM        
 1610 FORMAT (A29,' 207, BULK DATA DECK IS NOT SORTED. NASTRAN WILL ',  
     1        'RE-ORDER THE INPUT DECK.')        
 1620 IF (F3LONG.EQ.0 .OR. ECHOS.EQ.0) GO TO 1640        
      CALL PAGE2 (2)        
      WRITE  (NOUT,1630) UIM        
 1630 FORMAT (A29,' 207A, SIX CHARACTERS OF NASTRAN BCD NAME IN THE ',  
     1        'THIRD FIELD WERE USED DURING RE-ORDERING DECK')        
 1640 IF (ECHOS .EQ. 0) GO TO 1650        
      READ (HEAD(2),150) (HEAD1(J),J=11,24)        
      HEAD2(4) = CDCNT(1)        
      HEAD3(4) = CDCNT(2)        
      HEAD3(5) = CDCNT(3)        
      CALL PAGE        
C        
C     FINAL FILE MERGE, ADD CONTINUATION CARD AS NEEDED. RESULTS IN NPTP
C           ==========        
C        
C     ASSIGN BUFFER SPACES FOR THE SCRATCH FILES, RESERVE IBUF1 FOR NPTP
C        
C     OPEN SCRATCH DATA FILES (303,304,305... OR        ==METHODS 1,2== 
C     PREVIOUSLY SAVED         303,304,305...301  OR        
C                              302,303,304,305... OR    ==METHOD  3  == 
C                              302,303,304,305,...,301)        
C     AND READ INTO Y SPACE THE FIRST RECORD OF EACH SCRATCH FILE       
C        
C     OPEN NPTP FOR MERGED RESULT        
C        
C        
 1650 CALL OPEN  (*3100,NPTP,Z(IBUF1),WRT)        
      CALL WRITE (NPTP,BULKDA,2,1)        
      IF (NBULK+NDELE .EQ. 0) GO TO 2290        
      IF (TAPECC .NE. 0) CALL OPEN (*2950,TAPECC,Z(IBUFC),RD)        
      RECX   = LARGE        
      NCARD  = 0        
      EXH    = 0        
      IMHERE = 1700        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,NCONT,NFILER        
C        
C     IF NO CONTINUATION CARDS, AND ONLY ONE FILE IS USED TO STORE      
C     BULKDATA INPUT CARDS, MOVE DATA FROM TAPE3 (COLD START JOB), OR   
C     FROM TAPE1 (RESTART JOB WITH DELETE ONLY AND NO NEW BULK DATA)    
C     INTO NPTP DIRECTLY. OTHERWISE, JUMP TO 1760        
C        
      IF (.NOT.(NCONT.EQ.0 .AND. NFILER.EQ.1)) GO TO 1760        
      TAPE = TAPE3        
      IF (RESTR .EQ. 1) TAPE = TAPE1        
      CALL OPEN (*2920,TAPE,Z(IBUF2),RDREW)        
      LEFT24 = ((IBUF2-1)/24)*24        
 1700 FULL = 1        
      K    = 1        
      CALL READ (*3000,*1710,TAPE,Z(1),LEFT24,0,J)        
      FULL = 0        
      J    = LEFT24        
 1710 CALL WRITE (NPTP,Z(K),20,1)        
      IF (DEBUG) WRITE (NOUT,1720) Z(K),Z(K+1)        
 1720 FORMAT (5X,'WRITE TO NPTP',4X,2A4)        
      NCARD = NCARD + 1        
      L = K + 19        
      IF (ECHOS .EQ. 0) GO TO 1740        
      CALL PAGE2 (-1)        
      WRITE  (NOUT,1730) NCARD,(Z(I),I=K,L)        
 1730 FORMAT (13X,I8,1H-,8X,20A4)        
 1740 IF (ECHOP .NE. 0) WRITE (LPCH,1750) (Z(I),I=K,L)        
 1750 FORMAT (20A4)        
      K = K + 24        
      IF (K .LT. J) GO TO 1710        
      IMHERE = 1750        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,FULL,J        
      IF (FULL .EQ. 0) GO TO 1700        
      CALL EOF (NPTP)        
      CALL CLOSE (NPTP,REW)        
      CALL CLOSE (TAPE,REW)        
      IF (ECHOP .NE. 0) WRITE (LPCH,2320)        
      IF (ECHOS .EQ. 0) GO TO 2700        
      CALL PAGE2 (-1)        
      WRITE (NOUT,2300)        
      GO TO 2700        
C        
C     OPEN AND READ IN THE FIRST DATA RECORD FROM ALL FILES        
C        
 1760 IMHERE = 1760        
      TAPE = TAPE2        
      IF (REDUCE .GT. 1) TAPE = TAPE2 - 1        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,REDUCE,NFILER,TAPE        
      EMPTY = 0        
      DO 1800 II = 1,NFILER        
      TAPE = TAPE + 1        
      IF (II.EQ.NFILER .AND. RESTR.EQ.1) TAPE = TAPE1        
      ITAPE(II) = TAPE        
      IIBUF = IBUFX(II)        
      CALL OPEN (*2960,TAPE,Z(IIBUF),RDREW)        
      CALL READ (*3000,*1780,TAPE,Y(1,II),24,0,J)        
      IF (DEBUG) WRITE (NOUT,1770) TAPE,II,Y(1,II),Y(2,II)        
 1770 FORMAT (5X,'SETTING MERGE TABLE.  TAPE,II =',2I4,2X,2A4)        
      GO TO 1800        
 1780 EMPTY = EMPTY + 1        
      CALL CLOSE (TAPE,REW)        
      DO 1790 I = 1,24        
 1790 Y(I,II) = LARGE        
 1800 CONTINUE        
      EXH = -1        
      DO 1810 II = 1,NFILER        
      IF (Y(21,II) .EQ. -6) GO TO 1830        
 1810 CONTINUE        
 1820 EXH = EMPTY        
      II  = 1        
      IF (NFILER-1) 1980,1980,1900        
 1830 L = II        
      GO TO 2220        
C        
C     START MERGING FILES        
C        
C     PICK THE SMALLEST CONTROL WORDS IN 21ST, 22ND, 23RD AND 24TH      
C     WORDS OF EACH Y RECORD AND WRITE IT TO MERGE FILE NPTP, 20 WORDS  
C     EACH. REPLACE THE CHOSEN RECORD BY NEXT RECORD OF THE SAME FILE   
C        
 1900 II = 1        
      DO 1970 L = 2,NFILER        
      IF (Y(21,L) - Y(21,II)) 1960,1910,1970        
 1910 IF (Y(1,L)  .EQ. LARGE) GO TO 1970        
      IF (Y(22,L) - Y(22,II)) 1960,1920,1970        
 1920 IF (Y(23,L) - Y(23,II)) 1960,1930,1970        
 1930 IF (Y(24,L) - Y(24,II)) 1960,1940,1970        
C        
C ... FIRST 3 BULKDATA FIELDS ARE THE SAME, CHECK POSSIBLE DUPLICATE    
C     CARDS        
C        
 1940 DO 1950 J = 7,20        
      IF (Y(J,II) .NE. Y(J,L)) GO TO 1970        
 1950 CONTINUE        
      GO TO 2220        
C        
 1960 II = L        
 1970 CONTINUE        
C        
 1980 CALL WRITE (NPTP,Y(1,II),20,1)        
      NCARD = NCARD + 1        
      IF (ECHOS .EQ. 0) GO TO 1990        
      CALL PAGE2 (-1)        
      WRITE (NOUT,1730) NCARD,(Y(J,II),J=1,20)        
 1990 IF (ECHOP .NE. 0) WRITE (LPCH,1750) (Y(J,II),J=1,20)        
      IF (NCONT .EQ. 0) GO TO 2200        
      IF (RESTR .EQ. 0) GO TO 2000        
C        
C     IF THIS IS A RESTART JOB, SAVE THE FIRST FIELD, IN CASE THIS IS   
C     THE PARENT OF A CONTINUATION CARD THAT CAME FROM NEW BULK DATA    
C        
      KARD1 = Y(1,II)        
      KARD2 = Y(2,II)        
      IF (KARD1.NE.PARAM(1) .OR. KARD2.NE.PARAM(2)) GO TO 2000        
      KARD1 = Y(3,II)        
      KARD2 = Y(4,II)        
C        
C     INSERT CONTINUATION CARD IF NEEDED        
C        
 2000 IF (NOGO .EQ.  -3) GO TO 2200        
      TEMPX   = Y(19,II)        
      TEMP(1) = ANDF(TEMPX,LES1B)        
      TEMP(2) = Y(20,II)        
 2010 IF (TEMPX.EQ.BLANK .AND. TEMP(2).EQ.BLANK) GO TO 2200        
      CALL BISLC2 (*2140,TEMP(1),Z(IC),NCONT,BSIZE,LOC)        
      K = LOC*BSIZE + IC - 1        
      L = Z(K)        
      IF (L .LT. 0) GO TO 2150        
      Z(K) = -L        
      IF (L .GT. 10000000) GO TO 2050        
 2020 DO 2030 I = 1,20        
      BUF(I) = Z(L)        
 2030 L = L + 1        
      IF (RESTR.EQ.0 .OR. KARD1.EQ.-1 .OR. Z(L).EQ.0) GO TO 2120        
C         ----------     -------------    -----------        
C    I.E. NO RESTART     ALREADY DONE     BULKDATA CARD        
C                                         NOT FLAGGED        
C        
C     SET THE PARENT'S RESTART BIT IF ABOVE CONDITIONS NOT MET        
C        
      ASSIGN 2040 TO CRDFLG        
      FROM = 2040        
      GO TO 2810        
 2040 KARD1 = -1        
      GO TO 2120        
C        
C     READ IN CONTINUATION CARD IMAGE FROM TAPECC FILE        
C        
 2050 REC = L/10000000        
      L   = L - REC*10000000        
      IF (REC-RECX) 2060,2020,2110        
 2060 CALL REWIND (TAPECC)        
      IF (REC .EQ. 1) GO TO 2090        
      SKIP = REC - 1        
 2070 DO 2080 J = 1,SKIP        
      CALL FWDREC (*3020,TAPECC)        
 2080 CONTINUE        
 2090 CALL READ (*3020,*2100,TAPECC,Z(IB),NZIB,1,LEN)        
      RECX = REC        
      GO TO 2020        
 2100 CALL MESAGE (-37,0,NAME)        
 2110 SKIP = REC - RECX - 1        
      IF (SKIP) 2100,2090,2070        
C        
C     GOT THE CONTINUATION CARD, WRITE IT OUT TO NPTP        
C     CHECK WHETHER IT ASKS FOR MORE CONTINUATION CARD        
C        
 2120 CALL WRITE (NPTP,BUF,20,1)        
      NCARD = NCARD + 1        
      IF (ECHOS .EQ. 0) GO TO 2130        
      CALL PAGE2 (-1)        
      WRITE (NOUT,1730) NCARD,(BUF(J),J=1,20)        
 2130 IF (ECHOP .NE. 0) WRITE (LPCH,1750) (BUF(J),J=1,20)        
      TEMPX   = BUF(19)        
      TEMP(1) = ANDF(TEMPX,LES1B)        
      TEMP(2) = BUF(20)        
      GO TO 2010        
C        
C     CONTINUATION CARD NOT FOUND. ASSUME THE 10TH FIELD IS USER'S      
C     COMMENT        
C        
 2140 GO TO 2200        
C        
C     DUPLICATE PARENT - ERROR        
C        
 2150 CALL PAGE2 (-1)        
      IF (ECHOS .NE. 0) GO TO 2155        
      WRITE  (NOUT,2152) UFM,Z(-L),Z(-L+1)        
 2152 FORMAT (A23,' 208A, ',2A4,' IS DUPLECATE CONTINUATION MARK.')     
      GO TO 2180        
 2155 WRITE  (NOUT,2160) UFM        
 2160 FORMAT (A23,' 208, PREVIOUS CARD IS A DUPLICATE PARENT.')        
      IF (DEBUG) WRITE (NOUT,2170) LOC,BSIZE,IC,K,L,TEMPX,TEMP(2)       
 2170 FORMAT ('  LOC,BSIZE,IC,K,L =',5I8,2(2H /,A4),1H/)        
 2180 NOGO = -1        
C        
C     REPLACE THE MERGED RECORD BY THE NEXT RECORD OF THE SAME FILE     
C        
 2200 TAPE   = ITAPE(II)        
      IMHERE = 2200        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,TAPE,II        
      CALL READ (*3000,*2270,TAPE,Y(1,II),24,0,J)        
      IF (DEBUG) WRITE (NOUT,2210) TAPE,II,Y(1,II),Y(2,II),        
     1                             (Y(J,II),J=21,24)        
 2210 FORMAT (5X,'REPLACING - TAPE,II=',2I4,3X,2A4,4I12)        
      IF (Y(21,II) .NE. -6) IF (EXH) 1820,1900,1900        
 2220 CALL PAGE2 (-2)        
      NCARD = NCARD + 1        
      CALL WRITE (NPTP,Y(1,II),20,1)        
      WRITE  (NOUT,1730) NCARD,(Y(J,II),J=1,20)        
      WRITE  (NOUT,2230) UWM        
 2230 FORMAT (A25,' 208, PREVIOUS CARD IS A DUPLICATE')        
C     NOGO = -1        
      IF (.NOT.DEBUG) GO TO 2200        
      DO 2250 K = 1,NFILER        
      WRITE  (NOUT,2240) K,(Y(J,K),J=1,24)        
 2240 FORMAT (1X,I2,3H)  ,20A4,2H /,4I8)        
 2250 CONTINUE        
      WRITE  (NOUT,2260) II,L        
 2260 FORMAT (//5X,'DUPLICATE  II,L=',2I8)        
      GO TO 2200        
C        
C     A SCRATCH FILE IS JUST EXHAUSTED, SET THE CORRESPONDING RECORD    
C     A SET OF VERY LARGE NUMBERS        
C     IF ALL FILES ARE EXHAUSTED, MERGING DONE        
C        
 2270 EXH = EXH + 1        
      CALL CLOSE (TAPE,REW)        
      IMHERE = 2270        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,TAPE,EXH,NFILER,NCARD        
      IF (EXH .GE. NFILER) GO TO 2290        
      DO 2280 I = 1,24        
 2280 Y(I,II) = LARGE        
      GO TO 1900        
C        
C     MERGING DONE. EVERY THING IN NPTP.        
C        
 2290 CALL EOF (NPTP)        
      CALL CLOSE (NPTP,REW)        
      IMHERE = 2290        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,EXH,NFILER        
      IF (ECHOS .EQ. 0) GO TO 2310        
      CALL PAGE2 (-1)        
      WRITE  (NOUT,2300)        
 2300 FORMAT (30X,'ENDDATA')        
 2310 IF (ECHOP .NE. 0) WRITE (LPCH,2320)        
 2320 FORMAT ('ENDDATA')        
C        
C     CHECK AND IDENTIFY PARENTLESS CONTINUATION CARDS        
C     MAKE SURE TO EXCLUDE ANY BROKEN CONTINUATION CARDS SUPPOSEDLY     
C     CONNECTED TO ONE PARENT        
C        
      IF (NCONT.EQ.0 .OR. NOGO.EQ.-3) GO TO 2700        
      IMHERE = 2330        
      IF (DEBUG) WRITE (NOUT,140) IMHERE,NCONT,IC        
      RECX = LARGE        
      J = IC + BSIZE - 1        
      DO 2490 I = 1,NCONT        
      L = Z(J)        
 2400 IF (L  .LT. 0) GO TO 2490        
      IMHERE = 2400        
      IF (DEBUG) WRITE (NOUT,2480) IMHERE,Z(J-2),Z(J-1),L        
      IF (L .LE. 10000000) GO TO 2470        
      REC = L/10000000        
      L   = L - REC*10000000        
      IF (REC-RECX) 2410,2470,2450        
 2410 CALL REWIND (TAPECC)        
      IF (REC .EQ. 1) GO TO 2440        
      SKIP = REC - 1        
 2420 DO 2430 K = 1,SKIP        
      CALL FWDREC (*3020,TAPECC)        
 2430 CONTINUE        
 2440 CALL READ (*3020,*2620,TAPECC,Z(IB),NZIB,1,LEN)        
      RECX = REC        
      GO TO 2470        
 2450 SKIP = REC - RECX - 1        
      IF (SKIP) 2460,2440,2420        
 2460 CALL MESAGE (-37,0,NAME)        
 2470 TEMP(1) = ANDF(Z(L+18),LES1B)        
      TEMP(2) = Z(L+19)        
      IMHERE  = 2470        
      IF (DEBUG) WRITE (NOUT,2480) IMHERE,TEMP,L        
 2480 FORMAT ('  IMHERE=',I5,'  LOOKING FOR - ',2A4,I14)        
      IF (TEMP(1).EQ.BLANK .AND. TEMP(2).EQ.BLANK) GO TO 2490        
      LOC = LOC + 1        
      IF (TEMP(1).NE.Z(LOC+IC) .OR. TEMP(2).NE. Z(LOC*NCONT+IC))        
     1    CALL BISLC2 (*2490,TEMP(1),Z(IC),NCONT,BSIZE,LOC)        
      K = LOC*BSIZE + IC - 1        
      L = Z(K)        
      Z(K) = -IABS(Z(K))        
      GO TO 2400        
 2490 J = J + BSIZE        
C        
      J  = IC + BSIZE - 1        
      II = 0        
      RECX   = LARGE        
      IMHERE = 2600        
      DO 2610 I = 1,NCONT        
      IF (Z(J) .LT. 0) GO TO 2610        
      IF (II   .EQ. 1) GO TO 2510        
      II = 1        
      CALL PAGE1        
      WRITE  (NOUT,2500) UFM        
 2500 FORMAT (A23,' 209, THE FOLLOWING CONTINUATION INPUT CARDS HAVE ', 
     1       'NO PARENTS',//)        
      NOGO = -1        
 2510 CALL PAGE2 (1)        
      L = Z(J)        
      IF (L .GT. 10000000) GO TO 2540        
 2520 M = L + 19        
      WRITE  (NOUT,2530) (Z(K),K=L,M)        
 2530 FORMAT (10X,20A4)        
      GO TO 2610        
C        
 2540 REC = L/10000000        
      L   = L - REC*10000000        
      IF (REC-RECX) 2550,2520,2600        
 2550 CALL REWIND (TAPECC)        
      IF (REC .EQ. 1) GO TO 2580        
      SKIP = REC - 1        
 2560 DO 2570 K = 1,SKIP        
      CALL FWDREC (*3020,TAPECC)        
 2570 CONTINUE        
 2580 CALL READ (*3020,*2620,TAPECC,Z(IB),NZIB,1,LEN)        
      RECX = REC        
      GO TO 2520        
 2600 SKIP = REC - RECX - 1        
      IF (SKIP) 2620,2580,2560        
 2610 J = J + BSIZE        
      GO TO 2700        
 2620 CALL MESAGE (-2,TAPECC,NAME)        
C        
C     CLOSE CONTINUAION CARD FILE TAPECC, IF IT WAS OPENED        
C     DISABLE FREE-FIELD INPUT OPTION IN XREAD.        
C        
 2700 IF (TAPECC .GT. 0) CALL CLOSE (TAPECC,REW)        
      FFFLAG = 0        
      WASFF  = 0        
      IF (NOGO .NE. -3) GO TO 2730        
      WRITE  (NOUT,2710) UFM        
 2710 FORMAT (A23,' 3008, CONTINUATION CARDS WERE NOT ADDED TO SORTED ',
     1       'BULKDATA DECK DUE TO INSUFFICIENT CORE CONDITION.')       
      IF (CPFLG .NE. 0) WRITE (NOUT,2720)        
 2720 FORMAT (5X,'THE NPTP FILE OR TAPE GENERATED IN THIS RUN IS NOT ', 
     1       'SUITABLE FOR RESTART')        
      CALL MESAGE (-61,0,0)        
 2730 IF (NOGO .NE. 0) NOGO = 1        
      IF (.NOT. DEBUG) GO TO 3200        
C        
C     DEBUG NPTP ECHO        
C        
      IMHERE = 2730        
      WRITE (NOUT,140) IMHERE,FFFLAG,WASFF        
      CALL OPEN (*3100,NPTP,Z(IBUF1),RDREW)        
 2740 CALL SKPFIL (NPTP,+1)        
      CALL READ (*2770,*2770,NPTP,BUF(1),2,1,J)        
      IF (BUF(1).NE.BULKDA(1) .OR. BUF(2).NE.BULKDA(2)) GO TO 2740      
 2750 CALL READ (*2770,*2770,NPTP,BUF(1),20,1,J)        
      WRITE  (NOUT,2760) (BUF(J),J=1,10),(BUF(J),J=17,20)        
 2760 FORMAT (' ==NPTP==>',5(1X,2A4),'...',2(1X,2A4))        
      GO TO 2750        
 2770 CALL CLOSE (NPTP,REW)        
      GO TO 3200        
C        
C        
C     INTERNAL ROUTINE TO SET RESTART BITS - CRDFLG        
C        
C     BITS SET ONLY IF JOB IS A RESTART RUN, AND        
C       1. ALL NEW BULK DATA CARDS,   EXCEPT CONTINUATION CARDS        
C       2. ALL DELETED CARDS IN OPTP, EXCEPT CONTINUATION CARDS        
C       3. THE PARENTS OF THE CONTINUATION CARDS IN 1 AND 2        
C        
 2800 KARD1 = BUF(1)        
      KARD2 = BUF(2)        
      IF (KARD1.NE.PARAM(1) .OR. KARD2.NE.PARAM(2)) GO TO 2810        
      KARD1 = BUF(3)        
      KARD2 = BUF(4)        
 2810 IMHERE = 2810        
      IF (DEBUG) WRITE (NOUT,2820) IMHERE,FROM,NOGO,KARD1,KARD2        
 2820 FORMAT (/,' *** IMHERE',I5,', FROM',I5,', NOGO=',I3,3X,2A4)       
      IF (NOGO .NE. 0) GO TO 2850        
      K = NUMX1*2        
      DO 2840 I = 1,K,2        
      IF (KARD1.NE.ICARDS(I) .OR. KARD2.NE.ICARDS(I+1)) GO TO 2840      
      J = I/2        
      M = (J/31) + 1        
      N = MOD(J,31) + 2        
      IBITS(M) = ORF(IBITS(M),ITWO(N))        
      IF (DEBUG) WRITE (NOUT,2830) KARD1,KARD2        
 2830 FORMAT (5X,'BITS SET SUCCESSFULLY FOR ',2A4)        
      GO TO 2850        
 2840 CONTINUE        
 2850 GO TO CRDFLG, (200,810,880,2040)        
C        
C     ERRORS        
C        
 2900 TAPE = TAPE1        
      GO TO  2960        
 2910 TAPE = TAPE2        
      GO TO  2960        
 2920 TAPE = TAPE3        
      GO TO  2960        
 2930 TAPE = FILEA        
      GO TO  2960        
 2940 TAPE = FILEX        
      GO TO  2960        
 2950 TAPE = TAPECC        
      IF (TAPECC .LE. MAXSCR) GO TO 2960        
 2951 WRITE  (NOUT,2955) SFM        
 2955 FORMAT (A25,' 212, NUMBER OF AVAILABLE SCRATCH FILES EXEEDED.',5X,
     1        'RE-RUN JOB WITH MORE CORE')        
      GO TO  3140        
 2960 WRITE  (NOUT,2970) SFM,TAPE        
 2970 FORMAT (A25,' 210, COULD NOT OPEN SCRATCH FILE',I5)        
      GO TO  3140        
 2980 WRITE  (NOUT,2990) SFM        
 2990 FORMAT (A25,' 211, ILLEGAL EOR ON SCRATCH')        
      GO TO  3140        
 3000 WRITE  (NOUT,3010) SFM,TAPE        
 3010 FORMAT (A25,' 212, ILLEGAL EOF ON SCRATCH',I5)        
      GO TO  3140        
 3020 WRITE  (NOUT,3030)        
 3030 FORMAT (//26X,'212, TAPECC ERROR')        
      TAPE = TAPECC        
      GO TO  3000        
 3040 WRITE  (NOUT,3050) SFM        
 3050 FORMAT (A25,' 213, ILLEGAL EOF ON OPTP')        
      GO TO  3140        
 3060 WRITE  (NOUT,3070) SFM,IMHERE        
 3070 FORMAT (A25,' 213X, ILLEGAL DATA ON OPTP.  IMHERE =',I7)        
      NOGO = 1        
      GO TO  810        
 3080 WRITE  (NOUT,3090) SFM        
 3090 FORMAT (A25,' 214, OPTP COULD NOT BE OPENED')        
      GO TO  3140        
 3100 WRITE  (NOUT,3110) SFM        
 3110 FORMAT (A25,' 215, NPTP COULD NOT BE OPENED')        
      GO TO  3140        
 3120 WRITE  (NOUT,3130) SFM,IMHERE        
 3130 FORMAT (A25,' 219, MISSING ENDDATA CARD.  IMHERE =',I7)        
      NOGO = 1        
      GO TO  350        
 3140 WRITE  (NOUT,3150) IMHERE        
 3150 FORMAT (5X,'IMHERE =',I6)        
      CALL MESAGE (-37,0,NAME)        
C        
C     TURN OFF XSORT FLAG AND FREE-FIELD FLAG        
C        
 3200 IXSORT = 0        
      RETURN        
      END        