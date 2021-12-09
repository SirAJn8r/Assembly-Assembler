*-----------------------------------------------------------
* Title      : Assembly Disassembler
* Written by : Jesse Oteba and Alex Lambert
* Date       : 11/30/2021
* Description: Decodes binary opcodes into assembly code
*-----------------------------------------------------------
        ORG     $1000     

*----------------------------------------------------------
*Initialization Section
*----------------------------------------------------------

START:
                            ;D0 (temp var) is used for trap/printing
        CLR.W   D2          ;D2 stores the current number of lines on the screen
                            ;D3 stores the current opcode being read
                            ;D4 (temp var) is used for the clr buffer index
                            ;D5 (temp var) is used for reading addresses from inputs
                            ;D6 (temp var) is used for the hex print (AToI) input parameter
                            ;A2 stores the start/current address
                            ;A3 stores the end address
                            ;A4 stores the print buffer
        MOVEA   #$9000,A6   ;A6 stores the MOVEM storage location
        
*----------------------------------------------------------
*Main Loop Section
*----------------------------------------------------------

STARTADDR:
        LEA     STARTMSG,A1
        MOVE.B  #13,D0
        TRAP    #15         ;Print out start address message
        MOVE.B  #2,D0
        TRAP    #15         ;Store input into A1
        CMPI.W  #4,D1       ;Make sure D1 = 4 bytes
        BNE     JERRINS
        CLR.L   D1
        JSR     HEXTOBIN    ;Convert input into an address in D5
        MOVEA.W D5,A2       ;Move address into A2

ENDADDR:
        LEA     ENDMSG,A1
        MOVE.B  #13,D0
        TRAP    #15         ;Print out end address message
        MOVE.B  #2,D0
        TRAP    #15         ;Store input into A1
        CMPI.W  #4,D1       ;Make sure D1 = 4 bytes
        BNE     JERRINS
        CLR.L   D1
        JSR     HEXTOBIN    ;Convert input into an address in D5
        MOVEA.W D5,A3       ;Move address into A3
        
        BRA     LOOP
JERRINS:
        JMP     ERRIN

LOOP:
        ADDI.W  #1,D2
        CMPI.W  #30,D2
        BEQ     WAITUSER

        MOVE.L  (A2)+,D3    ;Reads the next command
        CMPA.W  A2,A3       ;Continue loop until start = end (not inclusive)
        BEQ     REPORFIN
        JSR     CLRBUF      ;Clear printing buffer
        JSR     MEMPRINT    ;Add the memory address
        JSR     OPXXXX      ;Add the operation/operands
        JSR     PRNTBUF     ;Print the printing buffer
        BRA     LOOP

WAITUSER:
        CLR.W   D2
        MOVE.B  #2,D0
        TRAP    #15
        BRA     LOOP

REPORFIN:
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
*Main Loop Helper Funcions Section
*----------------------------------------------------------

CLRBUF:
        CLR.L   D4
        MOVE.W  #BUFSIZE,D4
        LEA     BUFFER,A4
CLRBUFLOOP:
        MOVE.B  #0,(A4)+
        SUBI.W  #1,D4
        BGT     CLRBUFLOOP

        LEA     BUFFER,A4
        RTS
        
MEMPRINT:
        MOVE.W  A2,D6
        JSR     HEX16B
        MOVE.B  #$9,(A4)+
        RTS

PRNTBUF:
        MOVE.B  #13,D0
        LEA     BUFFER,A1
        TRAP    #15
        RTS

*----------------------------------------------------------
*Hex to Binary Section (ITOA)
*----------------------------------------------------------

HEXTOBIN:
        CLR.W   D5          ;Clear the output
        MOVE.B  (A1)+,D1    ;Get next char
        JSR     H2BCHAR     ;Read the char into D5
        MOVE.B  (A1)+,D1
        ROL.L   #4,D5       ;Make room for the next output
        JSR     H2BCHAR
        MOVE.B  (A1)+,D1
        ROL.L   #4,D5
        JSR     H2BCHAR
        MOVE.B  (A1)+,D1
        ROL.L   #4,D5
        JSR     H2BCHAR
        RTS
H2BCHAR:
        MOVE.B  D1,D7
        ANDI.B  #$F0,D7
        CMPI.B  #$30,D7
        BEQ     NUM         ;Go to Number parser if it's 0-9
        CMPI.B  #$40,D7
        BEQ     LETTER      ;Go to Letter parser if it's A-F
        CMPI.B  #$60,D7
        BEQ     LETTER      ;Go to Letter parser if it's a-f
        BRA     JERRIN
NUM:                        ;Lowest ascii nibble is exactly the binary number
        MOVE.B  D1,D7
        ANDI.B  #$0F,D7
        OR.B    D7,D5
        RTS
LETTER:                     ;Lowest ascii nibble for caps and lowercase
        MOVE.B  D1,D7       ; after adding 9 is the binary number
        ADD.B   #9,D7
        ANDI.B  #$0F,D7
        CMPI.B  #$06,D7
        BLT     JERRIN
        CMPI.B  #$00,D7
        BEQ     JERRIN
        OR.B    D7,D5
        RTS

JERRIN  JSR     ERRIN
        JMP     STARTADDR

*----------------------------------------------------------
*Print in Hex Section (ATOI)
*----------------------------------------------------------

HEX16B: ;Uses Bits 16-0 of D6 to print out 4 Hex Chars
        ROL.W   #4,D6
        JSR     PRNTHEX
        ROL.W   #4,D6
        JSR     PRNTHEX
        ROL.W   #4,D6
        JSR     PRNTHEX
        ROL.W   #4,D6
        JMP     PRNTHEX
HEX8B:  ;Uses Bits 7-0 of D6 to print out 2 Hex Chars
        ROL.B   #4,D6
        JSR     PRNTHEX
        ROL.B   #4,D6
        JMP     PRNTHEX
HEX4B:  ;Uses Bits 3-0 of D6 to print out 1 Hex Char
        JMP     PRNTHEX
HEX3B:  ;Uses Bits 2-0 of D6 to print out 1 Hex Char
        MOVE.B  D6,D0
        BCLR    #3,D6
        JSR     PRNTHEX
        MOVE.B  D0,D6
        RTS
        
PRNTHEX:
        CLR.L   D7
        MOVE.B  D6,D7
        ANDI.B  #$0F,D7
        
        LEA     ITOA,A0
        ADDA.L  D7,A0
        MOVE.B  (A0),(A4)+
        RTS

*----------------------------------------------------------
*Get Opcode Section
*----------------------------------------------------------

OPXXXX:
        BTST    #31,D3
        BEQ     OP0XXX
        JMP     OP1XXX

OP0XXX: BTST    #30,D3
        BEQ     OP00XX
        JMP     OP01XX

OP1XXX: BTST    #30,D3
        BEQ     OP00XX
        JMP     OP01XX

*----------
OP00XX: BTST    #29,D3
        BEQ     OP000X
        JMP     OP001X

OP01XX: BTST    #29,D3
        BEQ     OP010X
        JMP     OP011X

OP10XX: BTST    #29,D3
        BEQ     OP100X
        JMP     OP101X

OP11XX: BTST    #29,D3
        BEQ     OP110X
        JMP     OP111X

*----------
OP000X: BTST    #28,D3
        BEQ     J0000
        JMP     OP0001
J0000:  JMP     OP0000
        
OP001X: BTST    #28,D3
        BEQ     J0010
        JMP     OP0011
J0010:  JMP     OP0010
        
OP010X: BTST    #28,D3
        BEQ     J0100
        JMP     OP0101
J0100:  JMP     OP0100
        
OP011X: BTST    #28,D3
        BEQ     J0110
        JMP     OP0111
J0110:  JMP     OP0110

OP100X: BTST    #28,D3
        BEQ     J1000
        JMP     OP1001
J1000:  JMP     OP1000

OP101X: BTST    #28,D3
        BEQ     J1010
        JMP     OP1011
J1010:  JMP     ERROP

OP110X: BTST    #28,D3
        BEQ     J1100
        JMP     OP1101
J1100:  JMP     OP1100

OP111X: BTST    #28,D3
        BEQ     J1110
        JMP     ERROP
J1110:  JMP     OP1110
  
*----------------------------------------------------------
*Opcode to Command Section
*----------------------------------------------------------
 
*------
OP0000:
        MOVE.W  D3,D4
        ROL.W   #7,D4
        ANDI.W  #$07,D4
        
        CMPI.W  #$00,D4
        BEQ     JORI
        CMPI.W  #$01,D4
        BEQ     JANDI
        CMPI.W  #$03,D4
        BEQ     JADDI
        CMPI.W  #$05,D4
        BEQ     JEORI
        CMPI.W  #$06,D4
        BEQ     JCMPI
        JMP     ERRCOM
        
        BTST    #11,D3
        BEQ     ORANAD
        JMP     EOCM
ORANAD:
        BTST    #10,D3
        BEQ     ORAN
        JMP     ADDI
ORAN:
        BTST    #9,D3
        BEQ     JORI
        JMP     ANDI
JORI:
        JMP     ORI
EOCM:
        BTST    #10,D3
        BEQ     JEORI
        JMP     CMPI
JEORI: 
        JMP     EORI

*----------
OP0001:
OP0010:
OP0011:        
        BTST    #7,D3
        BNE     JMOVE
        BTST    #6,D3
        BNE     JMOVE
        BTST    #5,D3
        BEQ     JMOVE
        JMP     MOVEA
JMOVE:
        JMP     MOVE

*----------
OP0100:        
        BTST    #8,D3
        BEQ     NOMO
        JMP     LEA
NOMO:
        BTST    #7,D3
        BEQ     JNOP
        JMP     MOVEM
JNOP:
        JMP     NOP

*----------
OP0101:
        BTST    #8,D3
        BEQ     JSUBQ
        JMP     ADDQ
JSUBQ:
        JMP     SUBQ

*----------
OP0110:
        BTST    #8,D3
        BEQ     JBRA
        JMP     BSR
JBRA:
        JMP     BRA

*----------
OP0111:
        JMP     MOVEQ

*----------
OP1000:
        BTST    #8,D3
        BEQ     JDIVU
        JMP     DIVS
JDIVU:
        JMP     DIVU

*----------
OP1001:
        JMP     SUB

*----------
OP1011:
        BTST    #8,D3
        BEQ     JCMP
        JMP     EOR
JCMP:
        JMP     CMP

*----------
OP1100:
        BTST    #8,D3
        BEQ     JMULU
        JMP     MULS
JMULU:
        JMP     MULU

*----------
OP1101:
        BTST    #7,D3
        BEQ     JADDA
        BTST    #6,D3
        BEQ     JADDA
        JMP     ADD
JADDA:
        JMP     ADDA

*----------
OP1110: 
        BTST    #3,D3
        BEQ     ASAS
        JMP     LSLS
ASAS:
        BTST    #8,D3
        BEQ     JASL
        JMP     ASR
JASL:
        JMP     ASL
LSLS:
        BTST    #8,D3
        BEQ     JLSL
        JMP     LSR
JLSL:
        JMP     LSL
        
*----------------------------------------------------------
*Command Section
*----------------------------------------------------------

*--------------
ORI:
        MOVE.B  #'O',(A4)+
        MOVE.B  #'R',(A4)+
        MOVE.B  #'I',(A4)+
        JSR     BWL7
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
ANDI:
        MOVE.B  #'A',(A4)+
        MOVE.B  #'N',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #'I',(A4)+
        JSR     BWL7
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
ADDI:
        MOVE.B  #'A',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #'I',(A4)+
        JSR     BWL7
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
EORI:
        MOVE.B  #'E',(A4)+
        MOVE.B  #'O',(A4)+
        MOVE.B  #'R',(A4)+
        MOVE.B  #'I',(A4)+
        JSR     BWL7
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
CMPI:
        MOVE.B  #'C',(A4)+
        MOVE.B  #'M',(A4)+
        MOVE.B  #'P',(A4)+
        MOVE.B  #'I',(A4)+
        JSR     BWL7
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
MOVE:
        MOVE.B  #'M',(A4)+
        MOVE.B  #'O',(A4)+
        MOVE.B  #'V',(A4)+
        MOVE.B  #'E',(A4)+
        JSR     BLW13
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     D11S5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
MOVEA:
        MOVE.B  #'M',(A4)+
        MOVE.B  #'O',(A4)+
        MOVE.B  #'V',(A4)+
        MOVE.B  #'E',(A4)+
        MOVE.B  #'A',(A4)+
        JSR     BLW13
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     D11S5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
NOP:
        MOVE.B  #'N',(A4)+
        MOVE.B  #'O',(A4)+
        MOVE.B  #'P',(A4)+
        RTS

*--------------
MOVEM:
        MOVE.B  #'M',(A4)+
        MOVE.B  #'O',(A4)+
        MOVE.B  #'V',(A4)+
        MOVE.B  #'E',(A4)+
        MOVE.B  #'M',(A4)+
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
LEA:
        MOVE.B  #'L',(A4)+
        MOVE.B  #'E',(A4)+
        MOVE.B  #'A',(A4)+
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     R11EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
SUBQ:
        MOVE.B  #'S',(A4)+
        MOVE.B  #'U',(A4)+
        MOVE.B  #'B',(A4)+
        MOVE.B  #'Q',(A4)+
        JSR     BWL7
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     D11EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
ADDQ:
        MOVE.B  #'A',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #'Q',(A4)+
        JSR     BWL7
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     D11EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
BRA:
        MOVE.B  #'B',(A4)+
        MOVE.B  #'R',(A4)+
        MOVE.B  #'A',(A4)+
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     DP7
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
BSR:
        MOVE.B  #'B',(A4)+
        MOVE.B  #'S',(A4)+
        MOVE.B  #'R',(A4)+
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     DP7
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
MOVEQ:
        MOVE.B  #'M',(A4)+
        MOVE.B  #'O',(A4)+
        MOVE.B  #'V',(A4)+
        MOVE.B  #'E',(A4)+
        MOVE.B  #'Q',(A4)+
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     R11D7
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
DIVU:
        MOVE.B  #'D',(A4)+
        MOVE.B  #'I',(A4)+
        MOVE.B  #'V',(A4)+
        MOVE.B  #'U',(A4)+
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     R11EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
DIVS:
        MOVE.B  #'D',(A4)+
        MOVE.B  #'I',(A4)+
        MOVE.B  #'V',(A4)+
        MOVE.B  #'S',(A4)+
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     R11EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
SUB:
        MOVE.B  #'S',(A4)+
        MOVE.B  #'U',(A4)+
        MOVE.B  #'B',(A4)+
        JSR     BWL7
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     R11EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
CMP:
        MOVE.B  #'C',(A4)+
        MOVE.B  #'M',(A4)+
        MOVE.B  #'P',(A4)+
        JSR     BWL7
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     R11EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
EOR:
        MOVE.B  #'E',(A4)+
        MOVE.B  #'O',(A4)+
        MOVE.B  #'R',(A4)+
        JSR     BWL7
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     R11EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
MULU:
        MOVE.B  #'M',(A4)+
        MOVE.B  #'U',(A4)+
        MOVE.B  #'L',(A4)+
        MOVE.B  #'U',(A4)+
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     R11EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
MULS:
        MOVE.B  #'M',(A4)+
        MOVE.B  #'U',(A4)+
        MOVE.B  #'L',(A4)+
        MOVE.B  #'S',(A4)+
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     R11EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
ADDA:
        MOVE.B  #'A',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #'A',(A4)+
        JSR     WL8
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     R11EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
ADD:
        MOVE.B  #'A',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #'D',(A4)+
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     R11EA5
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
ASL:
        MOVE.B  #'A',(A4)+
        MOVE.B  #'S',(A4)+
        MOVE.B  #'L',(A4)+
        JSR     BWL7
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     SHIFTS
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
ASR:
        MOVE.B  #'A',(A4)+
        MOVE.B  #'S',(A4)+
        MOVE.B  #'R',(A4)+
        JSR     BWL7
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     SHIFTS
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
LSL:
        MOVE.B  #'L',(A4)+
        MOVE.B  #'S',(A4)+
        MOVE.B  #'L',(A4)+
        JSR     BWL7
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     SHIFTS
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*--------------
LSR:
        MOVE.B  #'L',(A4)+
        MOVE.B  #'S',(A4)+
        MOVE.B  #'R',(A4)+
        JSR     BWL7
        MOVE.B  #$9,(A4)+
        MOVEM   D2-D3/A2-A4,-(A6)
        JSR     SHIFTS
        MOVEM   (A6)+,A2-A4/D2-D3
        RTS

*----------------------------------------------------------
*Size Section
*----------------------------------------------------------

BWL7:
        BTST    #7,D1
        BNE     TSTLONG
        BTST    #6,D1
        BEQ     BYTE
        BRA     WORD
TSTLONG:
        BTST    #6,D1
        BEQ     LONG
        JMP     ERRSIZE

BLW13:
        BTST    #13,D1
        BEQ     TSTBYTE
        BTST    #12,D1
        BEQ     LONG
        BRA     WORD
TSTBYTE:
        BTST    #12,D1
        BNE     BYTE
        JMP     ERRSIZE

WL8:
        BTST    #8,D1
        BEQ     WORD
        BRA     LONG
        
BYTE:
        MOVE.B  #'.',(A4)+
        MOVE.B  #'B',(A4)+
        RTS
WORD:
        MOVE.B  #'.',(A4)+
        MOVE.B  #'W',(A4)+
        RTS
LONG:
        MOVE.B  #'.',(A4)+
        MOVE.B  #'L',(A4)+
        RTS

*----------------------------------------------------------
*EA Section
*----------------------------------------------------------

EA5:
        RTS

D11S5:
        RTS

R11EA5:
        RTS

D11EA5:
        RTS

DP7:
        RTS

R11D7:
        RTS

SHIFTS:
        RTS

*----------------------------------------------------------
*Error Catching Section
*----------------------------------------------------------

ERRIN:
        LEA     ERRINMSG,A1
        MOVE.B  #13,D0
        TRAP    #15
        RTS
ERROP:
        LEA     ERROPMSG,A1
        MOVE.B  #13,D0
        TRAP    #15
        JMP     LOOP
ERRCOM:
        LEA     ERRCOMMSG,A1
        MOVE.B  #13,D0
        TRAP    #15
        JMP     LOOP
ERRSIZE:
        LEA     ERRSIZEMSG,A1
        MOVE.B  #13,D0
        TRAP    #15
        RTS
ERREA:
        LEA     ERREAMSG,A1
        MOVE.B  #13,D0
        TRAP    #15
        JMP     LOOP

*----------------------------------------------------------
*Variable Section (And End Simulation)
*----------------------------------------------------------

END:    SIMHALT

BUFSIZE DC.B    64
BUFFER: DS.B    BUFSIZE

CR:     EQU     $0D
LF:     EQU     $0A

ITOA:   DC.B    '0123456789ABCDEF'

STARTMSG:
        DC.B    'Input the starting address for the decoder: ',0
ENDMSG:
        DC.B    'Input the ending address for the decoder: ',0
REPORFINMSG:
        DC.B    'Would you like to run the program again? (Y/N): ',0
ERRINMSG:
        DC.B    'Please enter 4 digit hexadecimal inputs only',CR,LF,0
ERROPMSG:
        DC.B    'Found Invalid Opcode',CR,LF,0
ERRCOMMSG:
        DC.B    'Found Not Implemented Command',CR,LF,0
ERRSIZEMSG:
        DC.B    'Found Invalid Size',0
ERREAMSG:
        DC.B    'Found Invalid EA Mode',CR,LF,0

        END     START


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
