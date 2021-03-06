      SUBROUTINE EDIT (NAME,IOPT,ITEST)        
C        
C     REMOVES SELECTED ITEMS OF THE SUBSTRUCTURE NAME FROM THE SOF.     
C     THE VALUE OF IOPT IS THE SUM OF THE FOLLOWING INTEGERS REFLECTING 
C     WHICH ITEMS ARE TO BE REMOVED.        
C        
C              1 = STIFFNESS MATRIX        
C              2 = MASS MATRIX        
C              4 = LOAD DATA        
C              8 = SOLUTION DATA        
C             16 = TRANSFORMATION DATA        
C             32 = ALL ITEMS OF SUBSTRUCTURE        
C             64 = APPENDED LOADS DATA        
C            128 = DAMPING MATRICES        
C            256 = MODES DATA        
C        
C     THE OUTPUT VARIABLE ITEST TAKES ON ONE OF THE FOLLOWING VALUES    
C              1   NORMATL RETURN        
C              4   IF NAME DOES NOT EXIST        
C        
      EXTERNAL        ANDF        
      INTEGER         ANDF,NAME(2),NMSBR(2)        
      COMMON /ITEMDT/ NITEM,ITEM(7,1)        
      DATA    NMSBR / 4HEDIT,4H    /        
C        
      CALL CHKOPN (NMSBR(1))        
      ITEST = 1        
      IF (IOPT .LE. 0) GO TO 20        
      CALL FDSUB (NAME(1),INDEX)        
      IF (INDEX .EQ. -1) GO TO 30        
C        
C     REMOVE SELECTED ITEMS ACCORDING TO IOPT S VALUE.        
C        
      DO 10 I = 1,NITEM        
      MASK = ITEM(7,I)        
      IF (ANDF(IOPT,MASK) .NE. 0) CALL DELETE (NAME,ITEM(1,I),IT)       
   10 CONTINUE        
   20 RETURN        
C        
C     NAME DOES NOT EXIST.        
C        
   30 ITEST = 4        
      RETURN        
      END        
