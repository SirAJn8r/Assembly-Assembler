*-----------------------------------------------------------
* Title      : Assembly Disassembler
* Written by : Jesse Oteba and Alex Lambert
* Date       : 12/15/2021
* Description: Decodes binary opcodes into assembly code
*-----------------------------------------------------------
        ORG     $1000
START:

*---Permanent Variables---
    ;D2 stores the current number of lines on the screen
    ;D3 stores the current opcode being read
    ;D7 stores the current opcode's size
    ;A2 stores the start/current address
    ;A3 stores the end address
    ;A4 stores the print buffer
    
*---Purposes of other Variables---
    ;D0,D1,A0,A1 only used for I/O
    ;D4,D5 used for temp internal variables
    ;D6 is used to output from ATOI (HEXTOBIN) and input to ITOA (HEXnB)
    ;A5,A6 used for temp internal varaibles

*----------------------------------------------------------
*Input/Initialization Section
*----------------------------------------------------------

STARTADDR:
        LEA     STARTMSG,A1
        MOVE.B  #13,D0
        TRAP    #15         ;Print out start address message
        LEA     INPADDR,A1
        JSR     HEXTOBIN    ;Read input into Hex into D5
        MOVEA.L D6,A2       ;Move address into A2

ENDADDR:
        LEA     ENDMSG,A1
        MOVE.B  #13,D0
        TRAP    #15         ;Print out end address message
        LEA     INPADDR,A1
        JSR     HEXTOBIN    ;Read input into Hex into D5
        MOVEA.L D6,A3       ;Move address into A3
        
        CLR.W   D2
        BRA     LOOP

WAITUSER:                   ;Wait for user enter key
        CLR.W   D2
        MOVE.B  #5,D0
        TRAP    #15
        BRA     LOOP

REPORFIN:                   ;Repeat Or Finish Program
        LEA     REPORFINMSG,A1
        MOVE.B  #13,D0
        TRAP    #15         ;Print out repeat or finish message
        MOVE.B  #5,D0
        TRAP    #15         ;Store input into D1
        CMPI.B  #'Y',D1     ;Repeat program if Y
        BEQ     STARTADDR
        CMPI.B  #'N',D1     ;End if N
        BNE     REPORFIN    ;Re-ask if anything else
        JMP     END

*----------------------------------------------------------
*Main Loop Section
*----------------------------------------------------------

LOOP:
        JSR     CLRBUF      ;Clear printing buffer
        JSR     MEMPRINT    ;Add the memory address
        MOVE.W  (A2)+,D3    ;Reads the next command

        CMPA.W  A2,A3       ;Continue loop until start = end (not inclusive)
        BLE     REPORFIN    ;Then ask if the user is done
        
        ADDI.W  #1,D2
        CMPI.W  #30,D2
        BGE     WAITUSER    ;If 30 lines are on the screen, pause

        MOVE.B  #$FF,D7     ;Set the size tracker to invalid
        JSR     OPCODE      ;Parse and print the command
        JSR     PRNTBUF     ;Print the printing buffer
        
        BRA     LOOP

*----------------------------------------------------------
*Main Loop Helper Funcions Section
*----------------------------------------------------------
* CLRBUFFER temp uses D4 as an index
*----------------------------------------------------------

CLRBUF:
        MOVE.W  #BUFSIZE,D4
        LEA     BUFFER,A4
CLRBUFLOOP:
        MOVE.B  #0,(A4)+
        SUBI.W  #1,D4
        BGT     CLRBUFLOOP

        LEA     BUFFER,A4
        RTS
        
MEMPRINT:
        MOVE.L  A2,D6
        JSR     HEX32B        
        MOVE.B  #$9,(A4)+
        RTS

PRNTBUF:
        MOVE.B  #13,D0
        LEA     BUFFER,A1
        TRAP    #15
        RTS

*----------------------------------------------------------
*Hex to Binary Section (ATOI)
*----------------------------------------------------------
* Stores output in D6
* Temp uses D4 as an index
*----------------------------------------------------------

HEXTOBIN:
        CLR.L   D6          ;Clear output
        MOVE.B  #2,D0
        TRAP    #15         ;Read input into A1
        MOVE.B  D1,D4       ;Start i at length, which must be 4 or 8
        CMPI.W  #4,D4
        BEQ     H2BLOOP
        CMPI.W  #8,D4
        BEQ     H2BLOOP
        BRA     JERRIN

H2BLOOP:
        MOVE.B  (A1)+,D1    ;Get next char
        ROL.L   #4,D6       ;Make room for the next output
        BRA     H2BCHAR     ;Read the char into D5        
CONTH2BLOOP:
        SUBI.B  #1,D4
        BNE     H2BLOOP
        RTS

H2BCHAR:
        MOVE.B  D1,D0
        ANDI.B  #$F0,D0
        CMPI.B  #$30,D0
        BEQ     NUM         ;Go to Number parser if it's 0-9
        CMPI.B  #$40,D0
        BEQ     LETTER      ;Go to Letter parser if it's A-F
        CMPI.B  #$60,D0
        BEQ     LETTER      ;Go to Letter parser if it's a-f
        BRA     JERRIN

NUM:    MOVE.B  D1,D0       ;Lowest ascii nibble is exactly the binary number
        ANDI.B  #$0F,D0
        OR.B    D0,D6
        BRA     CONTH2BLOOP

LETTER: MOVE.B  D1,D0       ;Lowest ascii nibble for both caps and lowercase
        ADD.B   #9,D0       ; after adding 9 is the binary number
        ANDI.B  #$0F,D0
        CMPI.B  #$06,D0
        BLT     JERRIN
        CMPI.B  #$00,D0
        BEQ     JERRIN
        OR.B    D0,D6
        BRA     CONTH2BLOOP

JERRIN  JMP     ERRIN

*----------------------------------------------------------
*Print in Hex Section (ITOA)
*----------------------------------------------------------
* Takes input into as D6
* Temp uses D4
* NOTE: Hex3B destroys some data
*----------------------------------------------------------


HEX32B: ;Uses Bits 32-0 of D6 to print out 8 Hex Chars
        SWAP    D6
        JSR     HEX16B
        SWAP    D6
        JMP     HEX16B
HEX16B: ;Uses Bits 16-0 of D6 to print out 4 Hex Chars
        ROL.W   #8,D6
        JSR     HEX8B
        ROL.W   #8,D6
        JMP     HEX8B
HEX8B:  ;Uses Bits 7-0 of D6 to print out 2 Hex Chars
        ROL.B   #4,D6
        JSR     PRNTHEX
        ROL.B   #4,D6
        JMP     PRNTHEX
HEX4B:  ;Uses Bits 3-0 of D6 to print out 1 Hex Char
        JMP     PRNTHEX
HEX3B:  ;Uses Bits 2-0 of D6 to print out 1 Hex Char
        ANDI.B  #$7,D6
        JMP     PRNTHEX
        
PRNTHEX:
        MOVE.B  D6,D4
        ANDI.L  #$0F,D4
        
        LEA     ITOA,A0
        ADDA.L  D4,A0
        MOVE.B  (A0),(A4)+
        RTS

*----------------------------------------------------------
*Get Opcode Section
*----------------------------------------------------------
* Temp uses D4
*----------------------------------------------------------

OPCODE: MOVE.W  D3,D4
        ROL.W   #4,D4
        ANDI.B  #$0F,D4
        CMPI.B  #%0000,D4
        BEQ     JOP0000
        CMPI.B  #%0001,D4
        BEQ     JOP0001
        CMPI.B  #%0010,D4
        BEQ     JOP0010
        CMPI.B  #%0011,D4
        BEQ     JOP0011
        CMPI.B  #%0100,D4
        BEQ     JOP0100
        CMPI.B  #%0101,D4
        BEQ     JOP0101
        CMPI.B  #%0110,D4
        BEQ     JOP0110
        CMPI.B  #%0111,D4
        BEQ     JOP0111
        CMPI.B  #%1000,D4
        BEQ     JOP1000
        CMPI.B  #%1001,D4
        BEQ     JOP1001
        CMPI.B  #%1010,D4
        BEQ     JOP1010
        CMPI.B  #%1011,D4
        BEQ     JOP1011
        CMPI.B  #%1100,D4
        BEQ     JOP1100
        CMPI.B  #%1101,D4
        BEQ     JOP1101
        CMPI.B  #%1110,D4
        BEQ     JOP1110
        CMPI.B  #%1111,D4
        BEQ     JOP1111
        JMP     ERROP

JOP0000 JMP     OP0000
JOP0001:
JOP0010:
JOP0011 JMP     OP00XX
JOP0100 JMP     OP0100
JOP0101 JMP     OP0101
JOP0110 JMP     OP0110
JOP0111 JMP     OP0111
JOP1000 JMP     OP1000
JOP1001 JMP     OP1001
JOP1010 JMP     ERROP
JOP1011 JMP     OP1011
JOP1100 JMP     OP1100
JOP1101 JMP     OP1101
JOP1110 JMP     OP1110
JOP1111 JMP     ERROP

*----------------------------------------------------------
*Opcode to Command Section
*----------------------------------------------------------
* Temp uses D4
*----------------------------------------------------------

OP0000: MOVE.W  D3,D4
        ROL.W   #7,D4
        ANDI.B  #$07,D4
        
        CMPI.B  #$00,D4
        BEQ     JORI
        CMPI.B  #$01,D4
        BEQ     JANDI
        CMPI.B  #$03,D4
        BEQ     JADDI
        CMPI.B  #$05,D4
        BEQ     JEORI
        CMPI.B  #$06,D4
        BEQ     JCMPI
        JMP     ERRCOM
        
JADDI:  JMP     ADDI
JANDI:  JMP     ANDI
JORI:   JMP     ORI
JCMPI:  JMP     CMPI
JEORI:  JMP     EORI

*----------
OP00XX: MOVE.W  D3,D4
        ROR.W   #6,D4
        ANDI.B  #$07,D4
        
        CMPI.B  #$01,D4
        BNE     JMOVE
        JMP     MOVEA
JMOVE:  JMP     MOVE

*----------
OP0100: MOVE.W  D3,D4
        ROR.W   #7,D4
        ANDI.B  #$07,D4
        CMPI.B  #$01,D4
        BEQ     JMOVEM
        
        MOVE.W  D3,D4
        ROR.W   #6,D4
        ANDI.B  #$07,D4
        CMPI.B  #$07,D4
        BEQ     JLEA
        
        CMPI.W  #$4E71,D3
        BEQ     JNOP
        JMP     ERRCOM

JLEA:   JMP     LEA
JMOVEM: JMP     MOVEM
JNOP:   JMP     NOP

*----------
OP0101: BTST    #8,D3
        BNE     JSUBQ
        JMP     ADDQ
JSUBQ:  JMP     SUBQ

*----------
OP0110: MOVE.W  D3,D4
        ROR.W   #8,D4
        ANDI.B  #$0F,D4
        
        CMPI.B  #$00,D4
        BEQ     JBRA
        CMPI.B  #$01,D4
        BEQ     JBSR
        JMP     ERRCOM

JBRA:   JMP     BRA
JBSR:   JMP     BSR

*----------
OP0111: JMP     MOVEQ

*----------
OP1000: MOVE.W  D3,D4
        ROR.W   #6,D4
        ANDI.B  #$07,D4
        
        CMPI.B  #$03,D4
        BEQ     JDIVU
        CMPI.B  #$07,D4
        BEQ     JDIVS
        JMP     ERRCOM

JDIVU:  JMP     DIVU
JDIVS:  JMP     DIVS

*----------
OP1001: JMP     SUB

*----------
OP1011:
        BTST    #8,D3
        BEQ     JCMP
        JMP     EOR
JCMP:   JMP     CMP

*----------
OP1100: MOVE.W  D3,D4
        ROR.W   #6,D4
        ANDI.B  #$07,D4
        
        CMPI.B  #$03,D4
        BEQ     JMULU
        CMPI.B  #$07,D4
        BEQ     JMULS
        JMP     ERRCOM

JMULU:  JMP     MULU
JMULS:  JMP     MULS

*----------
OP1101: BTST    #7,D3
        BEQ     JADD
        BTST    #6,D3
        BEQ     JADD
        JMP     ADDA
JADD:   JMP     ADD

*----------
OP1110: BTST    #4,D3
        BNE     JROX
        BTST    #3,D3
        BEQ     ASX
        JMP     LSX

ASX:    BTST    #8,D3
        BNE     JASL
        JMP     ASR
LSX:    BTST    #8,D3
        BNE     JLSL
        JMP     LSR

JASL:   JMP     ASL
JLSL:   JMP     LSL
JROX:   JMP     ERRCOM
        
*----------------------------------------------------------
*Command Section
*----------------------------------------------------------

ORI:    MOVE.B  #'O',(A4)+
        MOVE.B  #'R',(A4)+
        MOVE.B  #'I',(A4)+
        JSR     BWL7
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JSR     READIMM
        MOVE.B  #',',(A4)+
        MOVE.B  #' ',(A4)+
        JMP     EA5

ANDI:   MOVE.B  #'A',(A4)+
        MOVE.B  #'N',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #'I',(A4)+
        JSR     BWL7
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JSR     READIMM
        MOVE.B  #',',(A4)+
        MOVE.B  #' ',(A4)+
        JMP     EA5

ADDI:   MOVE.B  #'A',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #'I',(A4)+
        JSR     BWL7
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+ 
        JSR     READIMM
        MOVE.B  #',',(A4)+
        MOVE.B  #' ',(A4)+
        JMP     EA5

EORI:   MOVE.B  #'E',(A4)+
        MOVE.B  #'O',(A4)+
        MOVE.B  #'R',(A4)+
        MOVE.B  #'I',(A4)+
        JSR     BWL7
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JSR     READIMM
        MOVE.B  #',',(A4)+
        MOVE.B  #' ',(A4)+
        JMP     EA5

CMPI:   MOVE.B  #'C',(A4)+
        MOVE.B  #'M',(A4)+
        MOVE.B  #'P',(A4)+
        MOVE.B  #'I',(A4)+
        JSR     BWL7
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JSR     READIMM
        MOVE.B  #',',(A4)+
        MOVE.B  #' ',(A4)+
        JMP     EA5

MOVE:   MOVE.B  #'M',(A4)+
        MOVE.B  #'O',(A4)+
        MOVE.B  #'V',(A4)+
        MOVE.B  #'E',(A4)+
        JSR     BLW13
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     D11S5

MOVEA:  MOVE.B  #'M',(A4)+
        MOVE.B  #'O',(A4)+
        MOVE.B  #'V',(A4)+
        MOVE.B  #'E',(A4)+
        MOVE.B  #'A',(A4)+
        JSR     LW13
        MOVE.B  #$9,(A4)+
        JMP     D11S5

NOP:    MOVE.B  #'N',(A4)+
        MOVE.B  #'O',(A4)+
        MOVE.B  #'P',(A4)+
        RTS

MOVEM:  MOVE.B  #'M',(A4)+
        MOVE.B  #'O',(A4)+
        MOVE.B  #'V',(A4)+
        MOVE.B  #'E',(A4)+
        MOVE.B  #'M',(A4)+
        JSR     WL6
        MOVE.B  #$9,(A4)+
        JMP     MOVEMEA

LEA:    MOVE.B  #'L',(A4)+
        MOVE.B  #'E',(A4)+
        MOVE.B  #'A',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     AR11EA5M2ORABS

SUBQ:   MOVE.B  #'S',(A4)+
        MOVE.B  #'U',(A4)+
        MOVE.B  #'B',(A4)+
        MOVE.B  #'Q',(A4)+
        JSR     BWL7
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     DT11EA5

ADDQ:   MOVE.B  #'A',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #'Q',(A4)+
        JSR     BWL7
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     DT11EA5

BRA:    MOVE.B  #'B',(A4)+
        MOVE.B  #'R',(A4)+
        MOVE.B  #'A',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     DP7

BSR:    MOVE.B  #'B',(A4)+
        MOVE.B  #'S',(A4)+
        MOVE.B  #'R',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     DP7

MOVEQ:  MOVE.B  #'M',(A4)+
        MOVE.B  #'O',(A4)+
        MOVE.B  #'V',(A4)+
        MOVE.B  #'E',(A4)+
        MOVE.B  #'Q',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     R11DT7

DIVU:   MOVE.B  #'D',(A4)+
        MOVE.B  #'I',(A4)+
        MOVE.B  #'V',(A4)+
        MOVE.B  #'U',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     R11EA5NOTM1

DIVS:   MOVE.B  #'D',(A4)+
        MOVE.B  #'I',(A4)+
        MOVE.B  #'V',(A4)+
        MOVE.B  #'S',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     R11EA5NOTM1

SUB:    MOVE.B  #'S',(A4)+
        MOVE.B  #'U',(A4)+
        MOVE.B  #'B',(A4)+
        JSR     BWL7
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     R11DEA5

CMP:    MOVE.B  #'C',(A4)+
        MOVE.B  #'M',(A4)+
        MOVE.B  #'P',(A4)+
        JSR     BWL7
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     R11EA5

EOR:    MOVE.B  #'E',(A4)+
        MOVE.B  #'O',(A4)+
        MOVE.B  #'R',(A4)+
        JSR     BWL7
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     R11EA5NOTM1

MULU:   MOVE.B  #'M',(A4)+
        MOVE.B  #'U',(A4)+
        MOVE.B  #'L',(A4)+
        MOVE.B  #'U',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     R11EA5NOTM1

MULS:   MOVE.B  #'M',(A4)+
        MOVE.B  #'U',(A4)+
        MOVE.B  #'L',(A4)+
        MOVE.B  #'S',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     R11EA5NOTM1

ADDA:   MOVE.B  #'A',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #'A',(A4)+
        JSR     WL8
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     AR11EA5

ADD:    MOVE.B  #'A',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #'D',(A4)+
        JSR     BWL7
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     R11DEA5

ASL:    MOVE.B  #'A',(A4)+
        MOVE.B  #'S',(A4)+
        MOVE.B  #'L',(A4)+
        JSR     BWL7
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     SHIFTS

ASR:    MOVE.B  #'A',(A4)+
        MOVE.B  #'S',(A4)+
        MOVE.B  #'R',(A4)+
        JSR     BWL7
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     SHIFTS

LSL:    MOVE.B  #'L',(A4)+
        MOVE.B  #'S',(A4)+
        MOVE.B  #'L',(A4)+
        JSR     BWL7
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     SHIFTS

LSR:    MOVE.B  #'L',(A4)+
        MOVE.B  #'S',(A4)+
        MOVE.B  #'R',(A4)+
        JSR     BWL7
        MOVE.B  #' ',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #$9,(A4)+
        JMP     SHIFTS

*----------------------------------------------------------
*Size Section
*----------------------------------------------------------

BWL7:   BTST    #7,D3
        BNE     TSTL6
        BTST    #6,D3
        BEQ     BYTE
        BRA     WORD
TSTL6:  BTST    #6,D3
        BEQ     LONG
        JMP     ERRSIZE

LW13:   BTST    #13,D3
        BNE     BLW13
        JMP     ERRSIZE

BLW13:  BTST    #13,D3
        BEQ     TSTB12
        BTST    #12,D3
        BEQ     LONG
        BRA     WORD
TSTB12: BTST    #12,D3
        BNE     BYTE
        JMP     ERRSIZE

WL6:    BTST    #6,D3
        BEQ     WORD
        BRA     LONG
        
WL8:    BTST    #8,D3
        BEQ     WORD
        BRA     LONG
        
BYTE:   MOVE.B  #'.',(A4)+
        MOVE.B  #'B',(A4)+
        MOVE.B  #0,D7
        RTS
WORD:   MOVE.B  #'.',(A4)+
        MOVE.B  #'W',(A4)+
        MOVE.B  #1,D7
        RTS
LONG:   MOVE.B  #'.',(A4)+
        MOVE.B  #'L',(A4)+
        MOVE.B  #2,D7
        RTS

*----------------------------------------------------------
*EA Section
*----------------------------------------------------------
* Temp uses D6 to use GETEA
* Temp uses D5 for parsing input
*----------------------------------------------------------

PRNTDT11:
        MOVE.W  D3,D6
        ROL.W   #7,D6
        JMP     HEX3B

EA5:    
        JSR     EA5CHECKM1LIT
        MOVE.W  D3,D6
        JMP     GETEA5

EA5CHECKM1LIT:
        MOVE.B  D3,D5
        ANDI.B  #$38,D5
        CMPI.B  #$8,D5      ;Not Mode 1
        BEQ     JERREA
EA5CHECKLIT:
        MOVE.B  D3,D5
        ANDI.B  #$3F,D5
        CMPI.B  #$3C,D5     ;Not Literal
        BEQ     JERREA
        RTS

D11S5:  
        MOVE.B  D3,D6
        JSR     GETEA5
        
        MOVE.W  D3,D5
        ROL.W   #7,D5
        ANDI.W  #$7,D5      ;Isolate dest reg
        MOVE.W  D3,D6
        ROR.W   #3,D6
        ANDI.W  #$38,D6     ;Isolate dest mode
        OR.W    D5,D6       ;Combine in EA5-format

        MOVE.B  D3,D5
        ANDI.B  #$38,D5
        CMPI.B  #$8,D5      ;If MOVEA, skip the literal check
        BEQ     SKIPLITCHECK
        MOVE.B  D3,D5
        ANDI.B  #$3F,D5
        CMPI.B  #$3C,D6
        BEQ     JERREA      ;Not Literal
SKIPLITCHECK:
        MOVE.B  #',',(A4)+
        MOVE.B  #' ',(A4)+
        JMP     GETEA5

R11DEA5:
        BTST    #8,D3       ;If B8 is on, reverse the order
        BEQ     R11EA5
        
        MOVE.B  #'D',(A4)+
        JMP     PRNTDT11
        MOVE.B  #',',(A4)+
        MOVE.B  #' ',(A4)+
        ;If destination is EA, EA can't be Mode 1 or Literal
        JMP     EA5

R11EA5NOTM1:
        MOVE.B  D3,D6
        ANDI.B  #$38,D6
        CMPI.B  #$8,D6      ;Not Mode 1
        BEQ     JERREA
R11EA5: 
        MOVE.B  D3,D6
        JSR     GETEA5
        MOVE.B  #',',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #'D',(A4)+
        JMP     PRNTDT11

AR11EA5M2ORABS:
        MOVE.B  D3,D5
        ANDI.B  #$38,D5
        CMPI.B  #$10,D5
        BEQ     AR11EA5     ;Continue if Mode 2
        MOVE.B  D3,D5
        ANDI.B  #$3E,D5
        CMPI.B  #$38,D5
        BNE     JERREA      ;If not Mode 2 or Abs, error
AR11EA5:
        MOVE.B  D3,D6
        JMP     GETEA5
        MOVE.B  #',',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #'A',(A4)+
        JMP     PRNTDT11

DT11EA5:
        JSR     EA5CHECKLIT
        MOVE.B  #'#',(A4)+
        MOVE.B  #'$',(A4)+
        JSR     PRNTDT11
        MOVE.B  #',',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  D3,D6
        JMP     GETEA5
        
DP7:
        MOVE.L  A2,D5
        CLR.L   D6
        MOVE.B  D3,D6
        TST.B   D6
        BEQ     DP2WORD
        EXT.W   D6
        ADD.L   D5,D6
        JMP     HEX16B
DP2WORD:
        MOVE.W  (A2)+,D6
        ADD.L   D5,D6
        JMP     HEX16B

R11DT7:
        MOVE.B  #'#',(A4)+
        MOVE.B  #'$',(A4)+
        MOVE.B  D3,D6
        JSR     HEX8B
        MOVE.B  #',',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #'D',(A4)+
        JMP     PRNTDT11

SHIFTS:
        BTST    #5,D3
        BNE     SHIFTREG    ;Print either Dn or #$n
        MOVE.B  #'#',(A4)+
        MOVE.B  #'$',(A4)+
        BRA     FINSHIFT
SHIFTREG:
        MOVE.B  #'D',(A4)+
FINSHIFT:
        JSR     PRNTDT11
        MOVE.B  #',',(A4)+
        MOVE.B  #' ',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.W  D3,D6
        JMP     HEX3B

JERREA: JMP     ERREA

*----------------------------------------------------------
*GETEA5 Section
*----------------------------------------------------------
* Take input as EA5-formatting within D6
* Temp uses D5 to parse input
* D6 likely will be modified as it calls HEX3B
*----------------------------------------------------------

GETEA5: MOVE.B  D6,D5
        LSR.B   #3,D5
        ANDI.B  #$7,D5
        CMPI.B  #$00,D5
        BEQ     MODE0
        CMPI.B  #$01,D5
        BEQ     MODE1
        CMPI.B  #$02,D5
        BEQ     MODE2
        CMPI.B  #$03,D5
        BEQ     MODE3
        CMPI.B  #$04,D5
        BEQ     MODE4
        CMPI.B  #$07,D5
        BEQ     MODE7
        BRA    ERREA

MODE0:  MOVE.B  #'D',(A4)+
        JMP     HEX3B

MODE1:  MOVE.B  #'A',(A4)+
        JMP     HEX3B

MODE2:  MOVE.B  #'(',(A4)+
        MOVE.B  #'A',(A4)+
        JSR     HEX3B
        MOVE.B  #')',(A4)+
        RTS

MODE3:  MOVE.B  #'(',(A4)+
        MOVE.B  #'A',(A4)+
        JSR     HEX3B
        MOVE.B  #')',(A4)+
        MOVE.B  #'+',(A4)+
        RTS

MODE4:  MOVE.B  #'-',(A4)+
        MOVE.B  #'(',(A4)+
        MOVE.B  #'A',(A4)+
        JSR     HEX3B
        MOVE.B  #')',(A4)+
        RTS

MODE7:  MOVE.B  D6,D5
        ANDI.B  #$7,D5
        CMPI.B  #$00,D5
        BEQ     READWORD
        CMPI.B  #$01,D5
        BEQ     READLONG
        CMPI.B  #$04,D5
        BEQ     READIMM
        BRA     ERREA
        
*-------Read Words After Opcode-------
READIMM:
        MOVE.B  #'#',(A4)+
        CMPI.B  #0,D7
        BEQ     READBYTE
        CMPI.B  #1,D7
        BEQ     READWORD
        CMPI.B  #2,D7
        BEQ     READLONG
        BRA     ERREA
READBYTE:
        MOVE.B  #'$',(A4)+
        MOVE.W  (A2)+,D6
        JMP     HEX8B
READWORD:
        MOVE.B  #'$',(A4)+
        MOVE.W  (A2)+,D6
        JMP     HEX16B
READLONG:        
        MOVE.B  #'$',(A4)+
        MOVE.L  (A2)+,D6
        JMP     HEX32B
        
*----------------------------------------------------------
*MOVEM EA Section
*----------------------------------------------------------
* Temp uses D4 to track info
* Temp uses D5 to count the loop
* Temp uses D6 to store the register list
* Temp uses A5 to point to the printing values
* Temp uses A6 to read buffer to check if / is necessary
*----------------------------------------------------------
        ;Never Mode 0,1, or Imm. Can't be An+ or -An depending on mode

MOVEMEA:
        MOVE.B  D3,D6
        ANDI.B  #$38,D6
        CMPI.B  #$8,D6      ;Not Mode 1
        BEQ     JERREA
        CMPI.B  #$0,D6      ;Not Mode 0
        BEQ     JERREA

        BTST    #10,D3
        BNE     REVORDER

FORORDER:
        ANDI.B  #$38,D6
        CMPI.B  #$18,D6      ;Not Mode 3
        BEQ     JERREA
        
        JSR     MOVEMLIST
        MOVE.B  #',',(A4)+
        MOVE.B  #' ',(A4)+
        JMP     EA5
REVORDER:
        ANDI.B  #$38,D6
        CMPI.B  #$20,D6      ;Not Mode 4
        BEQ     JERREA
        
        JSR     EA5
        MOVE.B  #',',(A4)+
        MOVE.B  #' ',(A4)+
        JMP     MOVEMLIST
*---------
MOVEMLIST:
        MOVE.W  (A2)+,D6    ;Regs to move
        
        MOVEQ   #7,D5       ;Start counter from 7 to 0
        CLR.B   D4          ;B2 = exactly second in series (so add -)
                            ;B1 = has there been a reg already (so add comma)
                            ;B0 = was one immediately before (so remove previous to add new reg)    
        LEA     MOVMA07,A5  ;Load printing values
        JSR     MOVEMLOOP
        
        JSR     CHECKADDSLASH
        ROL.W   #8,D6       ;Swap halves
        
        MOVEQ   #7,D5       ;Set up again
        CLR.B   D1
        LEA     MOVMD07,A5
        JSR     MOVEMLOOP
        
        JSR     CHECKREMSLASH
        RTS

*---------
CHECKADDSLASH:
        MOVE.L  A4,A6
        SUBA.L  #1,A6
        CMP.B   #' ',(A6)
        BNE     ADDSLASH
        RTS
ADDSLASH:
        MOVE.B  #'/',(A4)+
        RTS
        
CHECKREMSLASH:
        MOVE.L  A4,A6
        SUBA.L  #1,A6
        CMP.B   #'/',(A6)
        BEQ     REMSLASH
        RTS
REMSLASH:
        MOVE.B  #0,-(A4)
        MOVE.B  #0,(A4)
        RTS

*---------
MOVEMLOOP:
        BTST    D5,D6       ;Test i-th bit of regs
        BEQ     NOREG       ;Update D1 and continue
        BTST    #0,D4
        BNE     SERIES      ;Start/Continue range
        
        BSET    #2,D4
        BSET    #1,D4       ;Test if there has been at least 1 reg, and set that
        BEQ     ADDREG      ;After at least 1 reg, start adding '/'
        BRA     ADDSLASHREG

SERIES:
        BTST    #2,D4
        BNE     STARTRANGE

        MOVE.B  #0,-(A4)    ;Continue range
        MOVE.B  #0,-(A4)
STARTRANGE:
        BCLR    #2,D4
        MOVE.B  #'-',(A4)+
        BRA     ADDREG

*---------
ADDSLASHREG:
        MOVE.B  #'/',(A4)+
ADDREG:
        MOVEA.L A5,A6
        ADDA.L  D5,A6
        ADDA.L  D5,A6       ;A6 = A5 + 2*i
        MOVE.B  (A6)+,(A4)+
        MOVE.B  (A6)+,(A4)+
        BRA     CONTMOVEMLOOP

*---------
NOREG:
        BCLR    #0,D4
        BCLR    #2,D4
CONTMOVEMLOOP:
        SUBI.B  #1,D5
        CMPI.B  #-1,D5
        BNE     MOVEMLOOP
        RTS
        
*----------------------------------------------------------
*Error Catching Section
*----------------------------------------------------------

ERRIN   LEA     ERRINMSG,A1
        MOVE.B  #13,D0
        TRAP    #15
        JMP     STARTADDR

ERROP   LEA     ERROPMSG,A1
        BRA     PRINTERR
ERRCOM  LEA     ERRCOMMSG,A1
        BRA     PRINTERR
ERRSIZE LEA     ERRSIZEMSG,A1
        BRA     PRINTERR
ERREA   LEA     ERREAMSG,A1
        
PRINTERR:
        MOVE.B  #13,D0
        TRAP    #15
        JMP     LOOP

*----------------------------------------------------------
*Variable Section (And End Simulation)
*----------------------------------------------------------

END:    SIMHALT

BUFSIZE DC.B    $40
BUFFER: DS.B    BUFSIZE

INPADDR     DS.B    9      

CR:     EQU     $0D
LF:     EQU     $0A

ITOA:   DC.B    '0123456789ABCDEF'
MOVMD07 DC.B    'A0','A1','A2','A3','A4','A5','A6','A7'
MOVMA07 DC.B    'D0','D1','D2','D3','D4','D5','D6','D7'

STARTMSG:
        DC.B    CR,LF,'Input the starting address for the decoder:',0
ENDMSG:
        DC.B    CR,LF,'Input the ending address for the decoder:',0
REPORFINMSG:
        DC.B    CR,LF,'Would you like to run the program again? (Y/N):',0
ERRINMSG:
        DC.B    CR,LF,'Please enter 4 digit hexadecimal inputs only',0
ERROPMSG:
        DC.B    'Found Invalid Opcode',0
ERRCOMMSG:
        DC.B    'Found Not Implemented Command',0
ERRSIZEMSG:
        DC.B    'Found Invalid Size',0
ERREAMSG:
        DC.B    'Found Invalid EA Mode',0

        END     START

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
