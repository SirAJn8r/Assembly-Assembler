*-----------------------------------------------------------
* Title      : Disassmbler Test Program
* Written by : Munehiro Fukuda
* Date       : 2/11/2021
*-----------------------------------------------------------
    ORG     $400
START:

*-----------------------------------------------------------
* Op Code: 24pts
*
* CPU Instructions..........................................
* Total: 18pts
* 1pt each * 18 instructions = 18pts
* 1pt each * 10 extra instructions = 10 extra pts
*
* 0000: ORI, (ANDI, SUBI, ADDI, EORI, CMPI)
* 0001: MOVEA
* 0011: MOVE
* 0010:
* 0100: (CLR, NOP, EXT, TRAP,) NOT, (STOP, RTE, RTS, JSR, JMP), MOVEM, LEA
* 0101: ADDQ, (SUBQ)
* 0110: BRA, BSR, (BEQ)
* 0111: MOVEQ
* 1000: DIVU, (DIVS, OR)
* 1001: SUB
* 1011: (EOR), CMP
* 1100: MULU, (MULS, AND)
* 1101: ADD, ADDA
* 1110: ASL, ASR, (LSL, LSR, ROL, ROR)
*

* Remove optional CPU instructions your disassembler haven't handled

      ORI.W     #$ABCD, D0  ; 1
      ANDI.W    #$ABCD, D1  ; optional
      SUBI.W	#$ABCD, D2  ; optional
      ADDI.W	#$ABCD, D3  ; optional
      EORI.W    #$ABCD, D4  ; optional
      CMPI.W    #$ABCD, D5  ; optional
      
      MOVEA.W	D6, A7      ; 2
      MOVE.W	D0, D1      ; 3
      
      CLR.W     D2          ; optional
      NOT.W     D3          ; optional
      EXT.W     D4          ; optional       
      TRAP      #15         ; optional
      NOP                   ; 4
      STOP      #$2700      ; optional
      RTE                   ; optional
      RTS                   ; optional
      JSR	    (A5)        ; optional
      JMP       (A6)		; optional
      MOVEM.W	D7, (A0)    ; 5
      LEA	    (A1), A2    ; 6
      
      ADDQ.W	#$7, D3     ; 7
      SUBQ.W    #$7, D4     ; optional
      
      BRA   	$1234		; 16bit (word) displacement  8
      BSR   	$1234		; 16bit (word) displacement  9
      BEQ   	$1234		; optional
      
      MOVEQ	    #$AB, D5    ; 10
      
      DIVU	    D6, D7      ; 11
      DIVS      D0, D1      ; optional
      OR.W	    D2, D3      ; optional
      
      SUB.W	    D2, D3      ; 12
      
      EOR.W     D4, D5      ; optional
      CMP.W	    D6, D7      ; 13
      
      MULU	    D0, D1	    ; 14
      MULS	    D2, D3      ; optional
      AND.W	    D3, D4      ; optional
      
      ADD.W	    D5, D6      ; 15
      ADDA.W	D6, A7      ; 16
      
      ASL.W	    #1, D0      ; 17
      ASR.W	    D2, D1      ; 18
      
      LSL.W	    #3, D2      ; optional
      LSR.W	    D4, D3      ; optional
      ROL.W	    #5, D4      ; optional
      ROR.W	    D6, D5      ; optional

* Data size distinction.....................................
* Total: 6pts
* .B: 2pts
* .W: 2pt (Note this size was tested in the above OP code analysis)
* .L: 2pt
LOOP:
      ORI.B	    #$AB, D0    ; 1
      MOVE.B	D1, D2      ; 3
      ADDQ.B	#$6, D3     ; 7
      BRA    	LOOP		; 8bit (byte) displacement  9
      SUB.B     D4, D5      ; 12
      CMP.B     D6, D7      ; 13
      ADD.B     D0, D1      ; 15
      ASL.B     #2, D3      ; 17
      ASR.B     D4, D5      ; 18

      ORI.L	    #$ABCDEF12, D0   ; 1
      MOVEA.L	D1, A2           ; 2
      MOVE.L	D3, D4           ; 3
      MOVEM.L	(A0), D5         ; 5
      ADDQ.L	#$6, D7          ; 7
      SUB.L     D0, D1           ; 12 
      CMP.L     D2, D3           ; 13
      ADD.L     D4, D5           ; 15
      ADDA.L	D6, A7           ; 16
      ASL.L     #6, D5           ; 17
      ASR.L     D4, D3           ; 18

*-----------------------------------------------------------
* Effective Address: 38pts
* Data Register Direct (mode 0).......................... 4
* Address Register Direct (mode 1)....................... 4
* Address Register Indirect (mode 2)..................... 5
* Address Register Indirect with Post Increment (mode 3). 5
* Address Register Indirect with Pre Decrement (mode 4).. 5
* Absolute Word Address (mode 7 subclass 0).............. 5
* Absolute Long Address (moe 7 subclass 1)............... 5
* Immediate Data (mode 7 subclass 4)..................... 5

      MOVE.L	A0, D1 	 	  ; mode 0 and mode 1                    4pts
      MOVEA.L	D2, A3		  ; mode 0 and mode 1                    4pts
      MOVE.L	(A4), D5	  ; mode 2                               2.5pts
      MOVE.L	D6, (A6)	  ; mode 2                               2.5pts
      MOVEM.L	(A7)+, D0/A7  ; mode 3                               5pts
      MOVEM.L	D1/A6, -(A2)  ; mode 4                               5pts
      MOVE.L	$ABCD, D3	  ; mode 7 subclass 0                    2.5pts
      ASL	    $ABCD         ; mode 7 subclass 0                    2.5pts
      MOVE.L	D4, ($ABCDEF12).L ; mode 7 subclass 1                2.5pts
      ASR	    ($ABCDEF12).L	  ; mode 7 subclass 1                2.5pts
      MOVE.L	#$12345678, D5	  ; mode 7 subclass 4                2.5pts
      MOVE.L    #$12345678, ($ABCDEF12).L ; mode 7 subclass 1 and 4  2.5pts

      END   START







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
