;;;
;;; Universal Monitor 68000
;;;   Copyright (C) 2021 Haruo Asano
;;;

	CPU	68030
	SUPMODE	ON

;;;
;;; Memory
;;;

ROM_B:	EQU	$00000000

WORK_B:	EQU	$0001FE00	; Work area 1FE00-1FFFF
STACK:	EQU	$0001FE00	; Monitor stack area 1F800-1FDFF
USTACK:	EQU	$0001F800	; User stack area xxxxx-1F7FF

RAM_B	EQU	ENTRY		; RAM base address
MON_SEG	EQU	$0001D000	; Monitor segment addiress
SV_ROM	EQU	$00000100	; SAVE addiress for monitor code at POWER ON

BUFLEN:	EQU	24		; Input buffer size
VECSIZ:	EQU	256		; Number of vectors to be initialized

F_bitSize	equ	16

;;;
;;; Options
;;;

USE_IDENT = 1			; MPU Identification
MPU_SPEC = 0			; MPU Spec. (Effective when USE_IDENT=0) 0:MC68000/8 1:MC68010

USE_REGCMD = 1			; R(egister) command and related functions

;;;
;;; Motorola MC6850
;;;

USE_DEV_6850 = 1
	IF USE_DEV_6850
ACIAC:	EQU	$40000001
ACIAD:	EQU	$40000000
;CR_V:	EQU	$15		; x16, 8bit, N, 1
	ENDIF

	IFNDEF USE_SFDECODE
USE_SFDECODE = 1
	ENDIF

;;;
;;; Common header file
;;;

	RELAXED	ON

;;; Constants
CR:	EQU	0x0D
LF:	EQU	0x0A
BS:	EQU	0x08
DEL:	EQU	0x7F

;;; Functions
low	function	x,(x & 255)
high	function	x,(x >> 8)

	RELAXED	OFF

;;;
;;; ROM area
;;;

	ORG	ROM_B

INIVEC:
	;; 0-7
	DC.L	STACK		; Reset: Initial SSP
	DC.L	ENTRY		; Reset: Initial PC

	DC.L	BUSERR_H	; Bus Error
	DC.L	ADDERR_H	; Address Error

	DC.L	ILLINS_H	; Illegal Instruction
	DC.L	ZERDIV_H	; Zero Divide
	DC.L	CHK_H		; CHK Instruction
	DC.L	TRAPV_H		; TRAPV Instruction

	;; 8-15
	DC.L	PRIV_H		; Privilege Violation
	DC.L	TRACE_H		; Trace
	DC.L	L1010_H		; Line 1010 Emulator
	DC.L	L1111_H		; Line 1111 Emulator

	DC.L	DUMMY_H		; (Unassigned, reserved)
	DC.L	DUMMY_H		; (Unassigned, reserved)
	DC.L	FORMAT_H	; Format Error (MC68010)
	DC.L	DUMMY_H		; (Unassigned, reserved)

	;; 16-23
	DC.L	DUMMY_H		; (Unassigned, reserved)
	DC.L	DUMMY_H		; (Unassigned, reserved)
	DC.L	DUMMY_H		; (Unassigned, reserved)
	DC.L	DUMMY_H		; (Unassigned, reserved)

	DC.L	DUMMY_H		; (Unassigned, reserved)
	DC.L	DUMMY_H		; (Unassigned, reserved)
	DC.L	DUMMY_H		; (Unassigned, reserved)
	DC.L	DUMMY_H		; (Unassigned, reserved)

	;; 24-31
	DC.L	DUMMY_H		; Spurious Interrupt
	DC.L	DUMMY_H		; Level 1 Interrupt Autovector
	DC.L	DUMMY_H		; Level 2 Interrupt Autovector
	DC.L	DUMMY_H		; Level 3 Interrupt Autovector

	DC.L	DUMMY_H		; Level 4 Interrupt Autovector
	DC.L	DUMMY_H		; Level 5 Interrupt Autovector
	DC.L	DUMMY_H		; Level 6 Interrupt Autovector
	DC.L	DUMMY_H		; Level 7 Interrupt Autovector

	;; 32-39
	DC.L	TRAP0_H		; TRAP Instruction Vector #0
	DC.L	TRAP1_H		; TRAP Instruction Vector #1
	DC.L	TRAP2_H		; TRAP Instruction Vector #2
	DC.L	TRAP3_H		; TRAP Instruction Vector #3

	DC.L	TRAP4_H		; TRAP Instruction Vector #4
	DC.L	TRAP5_H		; TRAP Instruction Vector #5
	DC.L	TRAP6_H		; TRAP Instruction Vector #6
	DC.L	TRAP7_H		; TRAP Instruction Vector #7

	;; 40-47
	DC.L	TRAP8_H		; TRAP Instruction Vector #8
	DC.L	TRAP9_H		; TRAP Instruction Vector #9
	DC.L	TRAP10_H	; TRAP Instruction Vector #10
	DC.L	TRAP11_H	; TRAP Instruction Vector #11

	DC.L	TRAP12_H	; TRAP Instruction Vector #12
	DC.L	TRAP13_H	; TRAP Instruction Vector #13
	DC.L	TRAP14_H	; TRAP Instruction Vector #14
	DC.L	TRAP15_H	; TRAP Instruction Vector #15

INIVECE:

ENTRY:
	MOVE.L	#CSTART,$00000004; Set new Initial PC

	LEA	SV_ROM,A0	; Copy monitor code to monitor segment
	LEA	MON_SEG,A1
CPY_MON:
	MOVE.L	(A0)+,(A1)+
	CMPA.L	#(ROM_E-CSTART+SV_ROM),A0
	BCS	CPY_MON
	JMP	CSTART

	DC.B	[SV_ROM-*]$FF

	ORG	MON_SEG

CSTART:
	MOVE.L	#$00000001,D0	; [add] Set instruction cache enable
	MOVEC	D0,CACR		; [add] at cache control register

	BSR	INIT

	IF INIVEC <> $00000000
	MOVE.L	#VECSIZ*4,D0
	ELSE
	MOVE.L	#RAM_B,D0
	ENDIF
	MOVE.L	D0,DSADDR
	MOVE.L	D0,GADDR
	MOVE.L	D0,SADDR
	MOVE.B	#'S',HEXMOD
	MOVE.B	#MPU_SPEC,PSPEC

	IF INIVEC <> $00000000
	;; Initialize vector area
	MOVE.L	#INIVEC,A0
	MOVE.L	#$00000000,A1
	MOVE	#VECSIZ,D1
INI0:
	MOVE.L	(A0)+,(A1)+
	SUBQ	#1,D1
	BEQ	INI2
	CMP.L	INIVECE,A0
	BNE	INI0
	MOVE.L	#DUMMY_H,D0
INI1:
	MOVE.L	D0,(A1)+
	SUBQ.L	#1,D1
	BNE	INI1
INI2:
	ENDIF

	IF USE_REGCMD

	;; Initialize register save area
	LEA	REG_B,A0
	MOVE	#(REG_E-REG_B)-1,D0
INIR0:
	CLR.B	(A0)+
	DBF	D0,INIR0
	MOVE.L	#STACK,REGSSP
	MOVE.L	GADDR,REGPC
	MOVE.L	#USTACK,REGA7

	;; Initialize mode area
	MOVE.B	#F_bitSize,D0
	LEA	F_bit,A0
INIM0:
	MOVE.B	#'.',(A0)+
	SUB.B	#1,D0
	TST.B	D0
	BNE	INIM0
	MOVE.B	#$00,(A0)

	ENDIF

	;; Initialize debug work area
	MOVE.W	#$0000,D0
	LEA	dbg_wtop,A0
INIB0:
	MOVE.W	D0,(A0)+
	CMPA.L	#dbg_wend,A0
	BCS	INIB0
	;; init address & opcode
	MOVE.L	#RAM_B,D0
	MOVE.L	D0,bpt1_adr
	MOVE.L	D0,bpt2_adr
	MOVE.L	D0,tmpb_adr
	MOVE.W	RAM_B,D0
	MOVE.W	D0,bpt1_op
	MOVE.W	D0,bpt2_op
	MOVE.W	D0,tmpb_op

	;; Opening message
	LEA	OPNMSG,A0
	BSR	STROUT

	IF USE_IDENT

	LEA	IM000,A0
	SAVE
	CPU	68010
ID0:	MOVEC	VBR,D0		; Try MC68010 instruction
	RESTORE

	SAVE
	CPU	68020
ID1:	CALLM	#0,MDESC	; Try MC68020 instruction
	RESTORE
	LEA	IM020,A0
	MOVE.B	#2,PSPEC
	BRA	ID9

ID2:
	SAVE
	CPU	68030
ID3:	MOVEC	CACR,D0		; Try MC68020 instruction (since MC68020 already eliminated, this checks MC68030)
	RESTORE
	LEA	IM030,A0
	MOVE.B	#3,PSPEC

ID9:
	BSR	STROUT

	ENDIF

WSTART:
	LEA	PROMPT,A0
	BSR	STROUT
	BSR	GETLIN
	LEA	INBUF,A0
	BSR	SKIPSP
	MOVE.B	(A0),D0
	BSR	UPPER
	TST.B	D0
	BEQ	WSTART

	CMP.B	#'D',D0
	BEQ	DUMP
	CMP.B	#'G',D0
	BEQ	GO
	CMP.B	#'S',D0
	BEQ	SETM

	CMP.B	#'L',D0
	BEQ	LOADH
	CMP.B	#'P',D0
	BEQ	SAVEH

	IF USE_REGCMD
	CMP.B	#'R',D0
	BEQ	REG
	CMP.B	#'M',D0
	BEQ	MODE
	ENDIF

	CMP.B	#'B',D0
	BEQ	BRKPT

	CMP.B	#'?',D0
	BEQ	CMDHLP

ERR:
	LEA	ERRMSG,A0
	BSR	STROUT
	BRA	WSTART

;;;
;;; Dump memory
;;;

DUMP:
	ADDQ	#1,A0
	BSR	SKIPSP
	BSR	RDHEX		; 1st arg.
	TST	D2
	BNE	DP0
	;; No arg.
	BSR	SKIPSP
	TST.B	(A0)
	BNE	ERR
	MOVE.L	DSADDR,D0
	ADD.L	#128,D0
	MOVE.L	D0,DEADDR
	BRA	DPM

	;; 1st arg. found
DP0:
	MOVE.L	D1,DSADDR
	BSR	SKIPSP
	CMP.B	#',',(A0)
	BEQ	DP1
	TST.B	(A0)
	BNE	ERR
	;; No 2nd arg.
	ADD.L	#128,D1
	MOVE.L	D1,DEADDR
	BRA	DPM

DP1:
	ADDQ	#1,A0
	BSR	SKIPSP
	BSR	RDHEX
	BSR	SKIPSP
	TST	D2
	BEQ	ERR
	TST.B	(A0)
	BNE	ERR
	ADDQ.L	#1,D1
	MOVE.L	D1,DEADDR

	;; DUMP main
DPM:
	MOVE.L	DSADDR,D0
	AND.B	#$F0,D0
	MOVE.L	D0,A1
	CLR	D2		; DSTATE
DPM0:
	BSR	DPL
	BSR	CONST
	TST.B	D0
	BNE	DPM1
	CMP	#2,D2		; DSTATE
	BCS	DPM0
	MOVE.L	DEADDR,DSADDR
	BRA	WSTART
DPM1:
	MOVE.L	A1,DSADDR
	BSR	CONIN
	BRA	WSTART

	;; DUMP line
DPL:
	MOVE.L	A1,D0
	BSR	HEXOUT8
	LEA	DSEP0,A0
	BSR	STROUT
	LEA	INBUF,A2
	MOVE	#15,D3
DPL0:
	BSR	DPB
	DBF	D3,DPL0

	LEA	DSEP1,A0
	BSR	STROUT

	LEA	INBUF,A2
	MOVE	#15,D3
DPL1:
	MOVE.B	(A2)+,D0
	CMP.B	#' ',D0
	BCS	DPL2
	CMP.B	#$7F,D0
	BCC	DPL2
	BSR	CONOUT
	BRA	DPL3
DPL2:
	MOVE.B	#'.',D0
	BSR	CONOUT
DPL3:
	DBF	D3,DPL1
	BRA	CRLF

	;; DUMP byte
DPB:
	MOVE.B	#' ',D0
	BSR	CONOUT
	TST	D2		; DSTATE
	BNE	DPB2
	;; Dump state 0
	CMP.L	DSADDR,A1
	BEQ	DPB1
	;; Still 0 or 2
DPB0:
	MOVE.B	#' ',D0
	BSR	CONOUT
	BSR	CONOUT
	MOVE.B	D0,(A2)+
	ADDQ	#1,A1
	RTS
	;; Found start address
DPB1:
	MOVE	#1,D2		; DSTATE
DPB2:
	CMP	#1,D2		; DSTATE
	BNE	DPB0
	;; Dump state 1
	MOVE.B	(A1)+,D0
	MOVE.B	D0,(A2)+
	BSR	HEXOUT2
	CMP.L	DEADDR,A1
	BEQ	DPB3
	RTS
	;; Found end address
DPB3:
	MOVE	#2,D2		; DSTATE
	RTS

;;;
;;; GO address
;;;

GO:
	ADDQ	#1,A0
	BSR	SKIPSP
	BSR	RDHEX
	MOVE.L	D1,D3		; Value(start address)
	MOVE.L	D2,D4		; Count(start address)
	MOVE.B	#0,tmpb_f	; Clear go break point
	MOVE.B	(A0),D0
	TST.B	D0
	BEQ	go_bpt
	CMP.B	#',',D0
	BNE	ERR
	ADDQ	#1,A0
	BSR	SKIPSP
	BSR	RDHEX
	TST	D2
	BEQ	ERR
	;; Set go break point
	MOVE.L	D1,tmpb_adr
	MOVE.L	D1,A0
	MOVE.W	(A0),tmpb_op
	MOVE.B	#1,tmpb_f

go_bpt:
	BSR	start_bpt	; Sart break point

	TST	D4		; Count(start address)
	BEQ	G0

	IF USE_REGCMD

	MOVE.L	D3,REGPC	; Value(start address)
G0:
	MOVE.L	REGSSP,D0
	AND.L	#$FFFFFFFE,D0
	MOVE.L	D0,A7

	TST.B	PSPEC
	BEQ	G1

	;; MC68010 only
	SAVE
	CPU	68010

	MOVE	#$0000,-(A7)	; Format / Dummy (Vector Offset)

	MOVE.L	REGVBR,D0
	AND.L	#$FFFFFFFE,D0
	MOVEC	D0,VBR		; Be careful!
	MOVE.B	REGSFC,D0
	MOVEC	D0,SFC
	MOVE.B	REGDFC,D0
	MOVEC	D0,DFC

	RESTORE
G1:
	MOVE.L	REGPC,-(A7)
	MOVE	REGSR,-(A7)

	MOVE.L	REGA7,A0
	MOVE	A0,USP

	MOVEM.L	REGD0,D0-D7/A0-A6

	RTE

	ELSE

	MOVE.L	D3,GADDR	; Value(start address)
G0:
	MOVE.L	GADDR,A0
	JMP	(A0)

	ENDIF

;;;
;;; SET memory
;;;

SETM:
	ADDQ	#1,A0
	BSR	SKIPSP
	BSR	RDHEX
	BSR	SKIPSP
	TST.B	(A0)
	BNE	ERR
	MOVE.L	D1,A1
	TST	D2
	BNE	SM0
	MOVE.L	SADDR,A1
SM0:
SM1:
	MOVE.L	A1,D0
	BSR	HEXOUT8
	LEA	DSEP1,A0
	BSR	STROUT
	MOVE.B	(A1),D0
	BSR	HEXOUT2
	MOVE.B	#' ',D0
	BSR	CONOUT
	BSR	GETLIN
	LEA	INBUF,A0
	BSR	SKIPSP
	MOVE.B	(A0),D0
	BNE	SM2
	;; Empty (Increment address)
	ADDQ	#1,A1
	MOVE.L	A1,SADDR
	BRA	SM1
SM2:
	CMP.B	#'-',D0
	BNE	SM3
	;; '-' (Decrement address)
	SUBQ	#1,A1
	MOVE.L	A1,SADDR
	BRA	SM1
SM3:
	CMP.B	#'.',D0
	BNE	SM4
	;; '.' (Quit)
	MOVE.L	A1,SADDR

	BSR	save_bpt	; Save break point
	BRA	WSTART
SM4:
	BSR	RDHEX
	TST	D2
	BEQ	ERR
	MOVE.B	D1,(A1)+
	MOVE.L	A1,SADDR
	BRA	SM1

;;;
;;; LOAD HEX file
;;;

LOADH:
	ADDQ	#1,A0
	BSR	SKIPSP
	BSR	RDHEX
	BSR	SKIPSP
	TST.B	(A0)
	BNE	ERR
	BSR	clear_bpt	; Clear break point

	TST	D2
	BNE	LH0

	CLR.L	D1		; Offset
LH0:
	BSR	CONIN
	BSR	UPPER
	CMP.B	#'S',D0
	BEQ	LHS0
LH1:
	CMP.B	#':',D0
	BEQ	LHI0
	;; Skip to EOL
LH2:
	CMP.B	#CR,D0
	BEQ	LH0
	CMP.B	#LF,D0
	BEQ	LH0
LH3:
	BSR	CONIN
	BRA	LH2

	;; Intel HEX
LHI0:
	BSR	HEXIN
	CLR	D2
	MOVE.B	D0,D2		; Length
	MOVE.B	D0,D3		; Checksum

	BSR	HEXIN
	CLR.L	D4
	MOVE.B	D0,D4		; Address H
	ADD.B	D0,D3		; Checksum

	BSR	HEXIN
	LSL	#8,D4
	MOVE.B	D0,D4		; Address L
	ADD.B	D0,D3		; Checksum

	;; Add offset
	ADD.L	D1,D4
	MOVE.L	D4,A1

	BSR	HEXIN
	MOVE.B	D0,RECTYP
	ADD.B	D0,D3		; Checksum

	TST	D2
	BEQ	LHI3
	SUBQ	#1,D2
LHI1:
	BSR	HEXIN
	ADD.B	D0,D3		; Checksum

	TST.B	RECTYP
	BNE	LHI2

	MOVE.B	D0,(A1)+
LHI2:
	DBF	D2,LHI1
LHI3:
	BSR	HEXIN
	ADD.B	D0,D3		; Checksum
	BNE	LHIE		; Checksum error
	TST.B	RECTYP
	BEQ	LH3
	BRA	WSTART
LHIE:
	LEA	IHEMSG,A0
	BSR	STROUT
	BRA	WSTART

	;; Motorola S record
LHS0:
	BSR	CONIN
	MOVE.B	D0,RECTYP

	BSR	HEXIN
	CLR	D2
	MOVE.B	D0,D2		; Length+3
	MOVE.B	D0,D3		; Checksum

	BSR	HEXIN
	CLR.L	D4
	MOVE.B	D0,D4		; Address H
	ADD.B	D0,D3		; Checksum

	BSR	HEXIN
	LSL.L	#8,D4
	MOVE.B	D0,D4		; Address L
	ADD.B	D0,D3		; Checksum

	;; Add offset
	ADD.L	D1,D4
	MOVE.L	D4,A1

	SUBQ	#3,D2
	BEQ	LHS3
	SUBQ	#1,D2
LHS1:
	BSR	HEXIN
	ADD.B	D0,D3		; Checksum

	CMP.B	#'1',RECTYP
	BNE	LHS2

	MOVE.B	D0,(A1)+
LHS2:
	DBF	D2,LHS1
LHS3:
	BSR	HEXIN
	ADD.B	D0,D3		; Checksum
	CMP.B	#$FF,D3
	BNE	LHSE		; Checksum error

	CMP.B	#'9',RECTYP
	BEQ	LHSR
	BRA	LH3
LHSE:
	LEA	SHEMSG,A0
	BSR	STROUT
LHSR:
	BRA	WSTART

;;;
;;;  SAVE HEX file
;;;

SAVEH:
	ADDQ	#1,A0
	MOVE.B	(A0),D0
	BSR	UPPER
	CMP.B	#'I',D0
	BEQ	SH0
	CMP.B	#'S',D0
	BNE	SH1
SH0:
	ADDQ	#1,A0
	MOVE.B	D0,HEXMOD
SH1:
	BSR	SKIPSP
	BSR	RDHEX
	TST	D2
	BEQ	ERR
	MOVE.L	D1,A1		; Start address
	BSR	SKIPSP
	CMP.B	#',',(A0)+
	BNE	ERR
	BSR	SKIPSP
	BSR	RDHEX		; D1 = End address
	TST	D2
	BEQ	ERR
	BSR	SKIPSP
	TST.B	(A0)
	BNE	ERR

SH2:
	SUB.L	A1,D1
	ADDQ	#1,D1		; D1 = Length
SH3:
	BSR	SHL
	TST.L	D1
	BNE	SH3

	CMP.B	#'I',HEXMOD
	BNE	SH4
	;; End record for Intel HEX
	LEA	IHEXER,A0
	BSR	STROUT
	BRA	WSTART
	;; End record for Motorola S record
SH4:
	LEA	SRECER,A0
	BSR	STROUT
	BRA	WSTART

SHL:
	MOVEQ.L	#16,D2
	CMP.L	D2,D1
	BCC	SHL0
	MOVE.L	D1,D2
SHL0:
	SUB.L	D2,D1		; D1 = remain

	CMP.B	#'I',HEXMOD
	BNE	SHLS

	;; Intel HEX
	MOVE.B	#':',D0
	BSR	CONOUT

	MOVE.B	D2,D0
	MOVE.B	D2,D3		; Checksum
	BSR	HEXOUT2		; Length

	MOVE.L	A1,D0
	LSR	#8,D0
	ADD.B	D0,D3		; Checksum
	BSR	HEXOUT2		; Address H

	MOVE.L	A1,D0
	ADD.B	D0,D3		; Checksum
	BSR	HEXOUT2		; Address L

	CLR.B	D0
	BSR	HEXOUT2		; Record type

	SUBQ	#1,D2
SHLI0:
	MOVE.B	(A1)+,D0
	ADD.B	D0,D3		; Checksum
	BSR	HEXOUT2

	DBF	D2,SHLI0

	MOVE.B	D3,D0
	NEG.B	D0
	BSR	HEXOUT2		; Checksum
	BRA	CRLF

	;; Motorola S record
SHLS:
	MOVE.B	#'S',D0
	BSR	CONOUT
	MOVE.B	#'1',D0
	BSR	CONOUT

	MOVE.B	D2,D0
	ADDQ.B	#2+1,D0		; DataLength + 2(Addr) + 1(Sum)
	MOVE.B	D0,D3		; Checksum
	BSR	HEXOUT2		; Length

	MOVE.L	A1,D0
	LSR.L	#8,D0
	ADD.B	D0,D3		; Checksum
	BSR	HEXOUT2		; Address H

	MOVE.L	A1,D0
	ADD.B	D0,D3		; Checksum
	BSR	HEXOUT2		; Address L

	SUBQ	#1,D2
SHLS0:
	MOVE.B	(A1)+,D0
	ADD.B	D0,D3		; Checksum
	BSR	HEXOUT2		; Data

	DBF	D2,SHLS0

	MOVE.B	D3,D0
	NOT.B	D0
	BSR	HEXOUT2
	BRA	CRLF

;;;
;;; Register
;;;
	IF USE_REGCMD

REG:
	ADDQ	#1,A0
	BSR	SKIPSP
	MOVE.B	(A0),D0
	BSR	UPPER
	TST.B	D0
	BNE	RG0
	BSR	RDUMP
	BRA	WSTART
RG0:
	LEA	RNTAB,A1
RG1:
	CMP.B	(A1),D0
	BEQ	RG2		; Character match
	TST.B	1(A1)
	BEQ	RGE
	ADD.L	#10,A1
	BRA	RG1
RG2:
	CMP.B	#$0F,1(A1)
	BNE	RG3
	;; Next table
	MOVE.L	2(A1),A1
	ADDQ	#1,A0
	MOVE.B	(A0),D0
	BSR	UPPER
	BRA	RG1
RG3:
	MOVE.B	1(A1),D3
	BEQ	RGE		; Found end mark
	BPL	RG30
	;; Check MC68010
	TST.B	PSPEC
	BEQ	RGE
RG30:
	MOVE.L	6(A1),A0
	BSR	STROUT
	MOVE.B	#'=',D0
	BSR	CONOUT
	MOVE.L	2(A1),A2
	AND.B	#$07,D3
	CMP.B	#1,D3
	BNE	RG4
	;; 8 bit register
	MOVE.B	(A2),D0
	BSR	HEXOUT2
	BRA	RG6
RG4:
	CMP.B	#2,D3
	BNE	RG5
	;; 16 bit register
	MOVE	(A2),D0
	BSR	HEXOUT4
	BRA	RG6
RG5:
	;; 32 bit register
	MOVE.L	(A2),D0
	BSR	HEXOUT8
RG6:
	MOVE.B	#' ',D0
	BSR	CONOUT
	BSR	GETLIN
	LEA	INBUF,A0
	BSR	SKIPSP
	BSR	RDHEX
	TST	D2
	BEQ	RGR
	CMP.B	#1,D3
	BNE	RG7
	;; 8 bit register
	MOVE.B	D1,(A2)
	BRA	RG9
RG7:
	CMP.B	#2,D3
	BNE	RG8
	;; 16 bit register
	MOVE	D1,(A2)
	BRA	RG9
RG8:
	;; 32 bit register
	MOVE.L	D1,(A2)
RG9:
RGR:
	BRA	WSTART
RGE:
	BRA	ERR

RDUMP:
	LEA	RDTAB,A1
RD0:
	MOVE	(A1)+,D1	; Flag
	BEQ	CRLF		; Found END mark => CR,LF and return
	BPL	RD00
	TST.B	PSPEC
	BEQ	CRLF
RD00:
	MOVE.L	(A1)+,A0	; String address
	BSR	STROUT
	MOVE.L	(A1)+,A0	; Register save area
	AND	#$0003,D1
	CMP	#1,D1
	BNE	RD1
	;; BYTE size
	MOVE.B	(A0),D0
	BSR	HEXOUT2
	BRA	RD0
RD1:
	CMP	#2,D1
	BNE	RD2
	;; WORD size
	MOVE	(A0),D0
	BSR	HEXOUT4
	BRA	RD0
RD2:
	;; LONG size
	MOVE.L	(A0),D0
	BSR	HEXOUT8
	BRA	RD0

	ENDIF

;;;
;;; Mode(SR System Byte)
;;;
	IF USE_REGCMD

MODE:
	;; Parse M command
	ADDQ	#1,A0
	MOVE.B	(A0),D0
	BSR	UPPER
	TST.B	D0
	BEQ	MD10
	CMP.B	#'T',D0		; Trace
	BNE	MD01
	ADDQ	#1,A0
	BSR	RDHEX
	TST	D2
	BEQ	ERR
	CMP.L	#3,D1
	BCC	ERR
	LSL.W	#8,D1
	LSL.W	#6,D1
	ANDI.W	#$3FFF,REGSR
	OR.W	D1,REGSR
	BRA	MD10
MD01:
	CMP.B	#'S',D0		; Supervisor
	BNE	MD02
	EORI.W	#$2000,REGSR
	BRA	MD10
MD02:
	CMP.B	#'M',D0		; Master
	BNE	MD03
	EORI.W	#$1000,REGSR
	BRA	MD10
MD03:
	CMP.B	#'I',D0		; Interrupt
	BNE	ERR
	ADDQ	#1,A0
	BSR	RDHEX
	TST	D2
	BEQ	ERR
	CMP.L	#8,D1
	BCC	ERR
	LSL.W	#8,D1
	ANDI.W	#$F8FF,REGSR
	OR.W	D1,REGSR
MD10:
	;; Show SR register
	MOVE.W	REGSR,D0
	MOVE.B	#F_bitSize,D1
	LEA	F_bit,A0
	LEA	F_bit_on,A1
	LEA	F_bit_off,A2
MD11:
	LSL.W	#1,D0
	BCS	MD12
	MOVE.B	(A2)+,(A0)+	; bit_off
	ADD.L	#1,A1
	BRA	MD13
MD12:
	MOVE.B	(A1)+,(A0)+	; bit_on
	ADD.L	#1,A2
MD13:
	SUB.B	#1,D1
	TST.B	D1
	BNE	MD11
	LEA	RDSSR,A0
	BSR	STROUT
	LEA	F_bit,A0
	BSR	STROUT
	BSR	CRLF
	BRA	WSTART

F_bit_on:	DC.B	"TTSM.III...XNZVC"
F_bit_off:	DC.B	"................"

	ENDIF

;;;
;;; Break point command
;;;

BRKPT:
	ADDQ	#1,A0
	MOVE.B	(A0),D0
	BSR	UPPER
	TST.B	D0
	BEQ	lst_bpt
	CMP.B	#'T',D0
	BEQ	BOOT		; Reset Boot
	CMP.B	#'1',D0
	BEQ	set_bpt1
	CMP.B	#'2',D0
	BEQ	set_bpt2
	CMP.B	#'C',D0
	BEQ	clr_bpt
	BRA	ERR

set_bpt1:
	;; Set break point1
	LEA	bpt1_adr,A1
	LEA	bpt1_op,A2
	LEA	bpt1_f,A3
	BRA	set_bpt
set_bpt2:
	;; Set break point2
	LEA	bpt2_adr,A1
	LEA	bpt2_op,A2
	LEA	bpt2_f,A3
set_bpt:
	ADDQ	#1,A0
	BSR	SKIPSP
	MOVE.B	(A0),D0
	CMP.B	#',',D0
	BNE	ERR
	ADDQ	#1,A0
	BSR	SKIPSP
	BSR	RDHEX
	TST	D2
	BEQ	ERR
	MOVE.L	D1,(A1)		; bpt(x)_adr
	MOVE.L	D1,A0
	MOVE.W	(A0),(A2)	; bpt(x)_op
	MOVE.B	#1,(A3)		; bpt(x)_f
	BRA	lst_bpt

clr_bpt:
	;; Clear break point
	ADDQ	#1,A0
	MOVE.B	(A0),D0
	TST.B	D0
	BEQ	clr_bpt_all
	LEA	bpt1_f,A1	; Break point1
	CMP.B	#'1',D0
	BEQ	clr_bpt_0
	LEA	bpt2_f,A1	; Break point2
	CMP.B	#'2',D0
	BNE	ERR
clr_bpt_0:
	MOVE.B	#0,(A1)
	BRA	lst_bpt
clr_bpt_all:
	MOVE.B	#0,D0
	MOVE.B	D0,bpt1_f
	MOVE.B	D0,bpt2_f
	BRA	lst_bpt

lst_bpt:
	;; List break point
	TST.B	bpt1_f		; Break point1
	BEQ	lst_bpt_0
	LEA	bp_msg1,A0
	BSR	STROUT
	MOVE.L	bpt1_adr,D0
	BSR	HEXOUT8
	BSR	CRLF
lst_bpt_0:
	TST.B	bpt2_f		; Break point2
	BEQ	lst_bpt_1
	LEA	bp_msg2,A0
	BSR	STROUT
	MOVE.L	bpt2_adr,D0
	BSR	HEXOUT8
	BSR	CRLF
lst_bpt_1:
	BRA	WSTART

start_bpt:
	;; Sart break point(subroutine)
	MOVE.L	A0,-(A7)	; Push
	TST.B	bpt1_f		; Break point1
	BEQ	start_bpt_0
	MOVE.L	bpt1_adr,A0
	MOVE.W	#$4AFC,(A0)
start_bpt_0:
	TST.B	bpt2_f		; Break point2
	BEQ	start_bpt_1
	MOVE.L	bpt2_adr,A0
	MOVE.W	#$4AFC,(A0)
start_bpt_1:
	TST.B	tmpb_f		; Go break point
	BEQ	start_bpt_2
	MOVE.L	tmpb_adr,A0
	MOVE.W	#$4AFC,(A0)
start_bpt_2:
	MOVE.L	(A7)+,A0	; Pop
	RTS

stop_bpt:
	;; Stop break point(subroutine)
	MOVE.L	A0,-(A7)	; Push
	TST.B	bpt1_f		; Break point1
	BEQ	stop_bpt_0
	MOVE.L	bpt1_adr,A0
	MOVE.W	bpt1_op,(A0)
stop_bpt_0:
	TST.B	bpt2_f		; Break point2
	BEQ	stop_bpt_1
	MOVE.L	bpt2_adr,A0
	MOVE.W	bpt2_op,(A0)
stop_bpt_1:
	TST.B	tmpb_f		; Go break point
	BEQ	stop_bpt_2
	MOVE.L	tmpb_adr,A0
	MOVE.W	tmpb_op,(A0)
stop_bpt_2:
	MOVE.L	(A7)+,A0	; Pop
	RTS

save_bpt:
	;; Save break point(subroutine)
	MOVE.L	A0,-(A7)	; Push
	TST.B	bpt1_f		; Break point1
	BEQ	save_bpt_0
	MOVE.L	bpt1_adr,A0
	MOVE.W	(A0),bpt1_op
save_bpt_0:
	TST.B	bpt2_f		; Break point2
	BEQ	save_bpt_1
	MOVE.L	bpt2_adr,A0
	MOVE.W	(A0),bpt2_op
save_bpt_1:
	MOVE.L	(A7)+,A0	; Pop
	RTS

clear_bpt:
	;; Clear break point(subroutine)
	MOVE.B	#0,bpt1_f
	MOVE.B	#0,bpt2_f
	RTS

bp_msg1:	DC.B	"BP(1):",$00
bp_msg2:	DC.B	"BP(2):",$00

;;;
;;; Reset Boot
;;;

BOOT:
	MOVE.L	$00000000,A7	; Reset: Initial SSP
	MOVE.L	$00000004,A0	; Reset: Initial PC
	JMP	(A0)

;;;
;;; Command help
;;;

CMDHLP:
	LEA	HLPMSG,A0
	BSR	STROUT
	BRA	WSTART

;;;
;;; Other support routines
;;;

STROUT:
	MOVE.B	(A0)+,D0
	TST.B	D0
	BEQ	STROE
	BSR	CONOUT
	BRA	STROUT
STROE:
	RTS

HEXOUT8:
	MOVE.L	D0,-(A7)
	SWAP	D0
	BSR	HEXOUT4
	MOVE.L	(A7)+,D0
HEXOUT4:
	MOVE.L	D0,-(A7)
	ROR	#8,D0
	BSR	HEXOUT2
	MOVE.L	(A7)+,D0
HEXOUT2:
	MOVE.L	D0,-(A7)
	ROR.B	#4,D0
	BSR	HEXOUT1
	MOVE.L	(A7)+,D0
HEXOUT1:
	AND.B	#$0F,D0
	ADD.B	#'0',D0
	CMP.B	#'9'+1,D0
	BCS	CONOUT
	ADD	#'A'-'9'-1,D0
	BRA	CONOUT

HEXIN:
	CLR.B	D0
	BSR	HI0
	LSL.B	#4,D0
HI0:
	MOVE	D0,-(A7)
	BSR	CONIN
	BSR	UPPER
	CMP.B	#'0',D0
	BCS	HIR
	CMP.B	#'9'+1,D0
	BCS	HI1
	CMP.B	#'A',D0
	BCS	HIR
	CMP.B	#'F'+1,D0
	BCC	HIR
	SUB.B	#'A'-'9'-1,D0
HI1:
	SUB.B	#'0',D0
	OR	(A7),D0
HIR:
	ADDQ	#2,A7
	RTS

CRLF:
	MOVE.B	#CR,D0
	BSR	CONOUT
	MOVE.B	#LF,D0
	BRA	CONOUT

GETLIN:
	LEA	INBUF,A0
	CLR.B	D1
GL0:
	BSR	CONIN
	CMP.B	#CR,D0
	BEQ	GLE
	CMP.B	#LF,D0
	BEQ	GLE
	CMP.B	#BS,D0
	BEQ	GLB
	CMP.B	#DEL,D0
	BEQ	GLB
	CMP.B	#' ',D0
	BCS	GL0
	CMP.B	#$80,D0
	BCC	GL0
	CMP.B	#BUFLEN-1,D1
	BCC	GL0		; Too long
	ADDQ.B	#1,D1
	MOVE.B	D0,(A0)+
	BSR	CONOUT
	BRA	GL0
GLB:
	TST.B	D1
	BEQ	GL0
	SUBQ.L	#1,A0
	SUBQ.B	#1,D1
	MOVE.B	#BS,D0
	BSR	CONOUT
	MOVE.B	#' ',D0
	BSR	CONOUT
	MOVE.B	#BS,D0
	BSR	CONOUT
	BRA	GL0
GLE:
	BSR	CRLF
	MOVE.B	#$00,(A0)
	RTS

SKIPSP:
	CMP.B	#' ',(A0)+
	BEQ	SKIPSP
	SUBQ.L	#1,A0
	RTS

UPPER:
	CMP.B	#'a',D0
	BCS	UPR
	CMP.B	#'z'+1,D0
	BCC	UPR
	ADD.B	#'A'-'a',D0
UPR:
	RTS

RDHEX:
	CLR	D2		; Count
	CLR.L	D1		; Value
RH0:
	MOVE.B	(A0),D0
	BSR	UPPER
	CMP.B	#'0',D0
	BCS	RHE
	CMP.B	#'9'+1,D0
	BCS	RH1
	CMP.B	#'A',D0
	BCS	RHE
	CMP.B	#'F'+1,D0
	BCC	RHE
	SUB.B	#'A'-'9'-1,D0
RH1:
	SUB.B	#'0',D0
	LSL.L	#4,D1
	OR.B	D0,D1
	ADDQ	#1,A0
	ADDQ	#1,D2
	BRA	RH0
RHE:
	RTS

;;;
;;; Exception Handler
;;;

	;; Dummy
DUMMY_H:
	RTE

	;; 02 Bus Error
BUSERR_H:
	MOVE.L	#BUSERR_M,EXMSG
	CLR	EXGRP		; Exception Group 0

	BRA	COMM_H

	;; 03 Address Error
ADDERR_H:
	MOVE.L	#ADDERR_M,EXMSG
	CLR	EXGRP		; Exception Group 0

	BRA	COMM_H

	;; 04 Illegal Instruction
ILLINS_H:
	;; Check IDENT
	IF USE_IDENT

	CMP.L	#ID0,2(A7)	; Check PC on system stack
	BNE	ILLINS0		; PC is not IDENT routine

	;; MOVEC VBR,D0 caused error ==> MC68000 or MC68008
	ADDQ	#6,A7		; Drop stack frame (MC68000 format)
	CLR.B	PSPEC
	BRA	ID9

ILLINS0:
	CMP.L	#ID1,2(A7)
	BNE	ILLINS1

	;; CALLM caused error ==> MC68010 or MC68030
	ADDQ	#8,A7		; Drop stack frame (MC68010- format)
	BRA	ID2

ILLINS1:
	CMP.L	#ID3,2(A7)
	BNE	ILLINS2

	;; MOVEC CACR,D0 caused error ==> MC68010
	ADDQ	#8,A7		; Drop stack frame (MC68010- format)
	LEA	IM010,A0
	MOVE.B	#1,PSPEC
	BRA	ID9

ILLINS2:
ILLINS9:
	ENDIF

	IF USE_REGCMD
	MOVEM.L	D0-D7/A0-A6,REGD0
	ELSE
	MOVEM.L	D0-D3,REGD0
	MOVEM.L	A0-A3,REGA0
	ENDIF

	MOVE.L	#ILLINS_M,EXMSG
	MOVE	#1,EXGRP	; Exception Group 1

	;; Check BREAK
	MOVE.L	2(A7),A0	; Get PC
	MOVE	(A0),D0		; Read OP-code
	CMP	#$4AFC,D0
	BEQ	BREAK
	AND	#$FFF8,D0
	CMP	#$4848,D0
	BNE	COMM_H0
BREAK:
	MOVE.L	#BREAK_M,EXMSG
	MOVE	#$0101,EXGRP	; BREAK
	BRA	COMM_H0

	;; 05 Zero Divide
ZERDIV_H:
	MOVE.L	#ZERDIV_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 06 CHK Instruction
CHK_H:
	MOVE.L	#CHK_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 07 TRAPV Instruction
TRAPV_H:
	MOVE.L	#TRAPV_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 08 Privilege Violation
PRIV_H:
	MOVE.L	#PRIV_M,EXMSG
	MOVE	#1,EXGRP	; Exception Group 1

	BRA	COMM_H

	;; 09 Trace
TRACE_H:
	MOVE.L	#TRACE_M,EXMSG
	MOVE	#1,EXGRP	; Exception Group 1

	BRA	COMM_H

	;; 10 Line 1010 Emulator
L1010_H:
	MOVE.L	#L1010_M,EXMSG
	MOVE	#1,EXGRP	; Exception Group 1

	BRA	COMM_H

	;; 11 Line 1111 Emulator
L1111_H:
	MOVE.L	#L1111_M,EXMSG
	MOVE	#1,EXGRP	; Exception Group 1

	BRA	COMM_H

	;; 14 Format Error
FORMAT_H:
	MOVE.L	#FORMAT_M,EXMSG
	MOVE	#1,EXGRP	; Exception Group 1

	BRA	COMM_H

	;; 32 TRAP #0
TRAP0_H:
	MOVE.L	#TRAP0_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 33 TRAP #1
TRAP1_H:
	MOVE.L	#TRAP1_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 34 TRAP #2
TRAP2_H:
	MOVE.L	#TRAP2_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 35 TRAP #3
TRAP3_H:
	MOVE.L	#TRAP3_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 36 TRAP #4
TRAP4_H:
	MOVE.L	#TRAP4_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 37 TRAP #5
TRAP5_H:
	MOVE.L	#TRAP5_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 38 TRAP #6
TRAP6_H:
	MOVE.L	#TRAP6_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 39 TRAP #7
TRAP7_H:
	MOVE.L	#TRAP7_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 40 TRAP #8
TRAP8_H:
	MOVE.L	#TRAP8_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 41 TRAP #9
TRAP9_H:
	MOVE.L	#TRAP9_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 42 TRAP #10
TRAP10_H:
	MOVE.L	#TRAP10_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 43 TRAP #11
TRAP11_H:
	MOVE.L	#TRAP11_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 44 TRAP #12
TRAP12_H:
	MOVE.L	#TRAP12_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 45 TRAP #13
TRAP13_H:
	MOVE.L	#TRAP13_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 46 TRAP #14
TRAP14_H:
	MOVE.L	#TRAP14_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;; 47 TRAP #15
TRAP15_H:
	MOVE.L	#TRAP15_M,EXMSG
	MOVE	#2,EXGRP	; Exception Group 2

	BRA	COMM_H

	;;
	;; Common handler
	;;
COMM_H:
	;; Save registers
	IF USE_REGCMD
	MOVEM.L	D0-D7/A0-A6,REGD0
	ELSE
	MOVEM.L	D0-D3,REGD0
	MOVEM.L	A0-A3,REGA0
	ENDIF

COMM_H0:

	IF USE_REGCMD

	TST	EXGRP
	BNE	CH0		; not Group 0
	TST.B	PSPEC
	BNE	CH0		; not MC68000/8

	;; MC68000/8 : Group 0 (Bus/address error)
	LEA	GR0BUF,A0
	MOVE	(A7)+,(A0)+
	MOVE.L	(A7)+,(A0)+	; Access address
	MOVE	(A7)+,(A0)+	; Instruction register
CH0:
	;; Common
	MOVE	(A7)+,REGSR
	MOVE.L	(A7)+,REGPC

	MOVE	USP,A0
	MOVE.L	A0,REGA7

	TST.B	PSPEC
	BEQ	CH2

	;; MC68010
	SAVE
	CPU	68010
	MOVEC	VBR,D0
	MOVE.L	D0,REGVBR
	MOVEC	SFC,D0
	MOVE.B	D0,REGSFC
	MOVEC	SFC,D0
	MOVE.B	D0,REGDFC
	RESTORE

	MOVE	(A7)+,D2	; Format / Vector offset
	MOVE	D2,REGFV
	ROL.W	#4,D2
	AND	#$000F,D2
	LEA	GR0BUF,A0
	LEA	FMTLEN,A1
	CLR	D3
	MOVE.B	0(A1,D2.W),D3
	SUBQ	#4,D3		; 4 words already POPed
	BLS	CH2		; No more to POP, or unknown format
	SUBQ	#1,D3
CH1:
	MOVE	(A7)+,(A0)+
	DBF	D3,CH1

CH2:
	MOVE.L	A7,REGSSP

	ELSE
	;; USE_REGCMD == 0

	TST.B	PSPEC
	BNE	CH1

	;; MC68000/8
	TST	D2
	BNE	CH0

	;; Group 0
	ADD.L	#7*2,A7
	BRA	CH3

CH0:
	;; Group 1-3
	ADD.L	#3*2,A7
	BRA	CH3

CH1:
	;; MC68010 and above
	MOVE	6(A7),D2	; Get format word
	ROL	#4,D2
	AND	#$000F,D2
	LEA	FMTLEN,A1
	CLR	D3
	MOVE.B	0(A1,D2.W),D3
	ASL	#1,D3
	ADD	D3,A7

CH3:
	ENDIF

	BSR	stop_bpt	; Stop break point

	MOVE.L	EXMSG,A0
	BSR	STROUT
	BSR	CRLF
	IF USE_REGCMD
	TST	EXGRP
	BNE	CH4
	BSR	G0DUMP
CH4:
	BSR	RDUMP
	ELSE
	IFDEF DEBUG
	MOVE.L	A7,D0
	BSR	HEXOUT8
	ENDIF
	BSR	CRLF
	ENDIF

	BRA	WSTART

	IF USE_REGCMD
;;; DUMP group 0 (Address/Bus Error)
G0DUMP:
	TST.B	PSPEC
	BNE	G0D1

	;; MC68000/MC68008
	IFDEF DEBUG
	MOVE	GR0BUF,D0
	BSR	HEXOUT4
	MOVE.B	#' ',D0
	BSR	CONOUT
	MOVE.L	GR0BUF+2,D0
	BSR	HEXOUT8		; Access address
	MOVE.B	#' ',D0
	BSR	CONOUT
	MOVE	GR0BUF+6,D0
	BSR	HEXOUT4		; Instruction register
	BSR	CRLF
	ENDIF

	;; Function Code
	MOVE	GR0BUF,D0
	AND	#$0007,D0
	LSL	#2,D0
	LEA	FCTAB,A0
	MOVE.L	0(A0,D3.W),A0
	BSR	STROUT

	;; Read / Write
	MOVE	GR0BUF,D0
	AND	#$0010,D0
	BNE	G0D00
	LEA	G0WR,A0
	BRA	G0D01
G0D00:
	LEA	G0RD,A0
G0D01:
	BSR	STROUT

	;; Address
	MOVE.L	GR0BUF+2,D0
	BSR	HEXOUT8		; Access address

	;; Instruction Register
	LEA	G0INS0,A0
	BSR	STROUT
	MOVE	GR0BUF+6,D0
	BSR	HEXOUT4		; Instruction register
	MOVE.B	#')',D0
	BSR	CONOUT

	BRA	CRLF

G0D1:
	IF USE_SFDECODE
	MOVE	REGFV,D3
	ROL	#4,D3
	AND	#$000F,D3
	CMP	#$08,D3
	BNE	G0D2		; Not MC68010

	;; MC68010
	IFDEF DEBUG
	MOVE	GR0BUF,D0	; Special Status Word
	BSR	HEXOUT4
	MOVE	#' ',D0
	BSR	CONOUT
	MOVE.L	GR0BUF+2,D0	; Fault Address
	BSR	HEXOUT8
	MOVE	#' ',D0
	BSR	CONOUT
	MOVE	GR0BUF+8,D0
	BSR	HEXOUT4
	BSR	CRLF
	ENDIF

	;; Function Code
	MOVE	GR0BUF,D0
	AND	#$0007,D0
	LSL	#2,D0
	LEA	FCTAB2,A0
	MOVE.L	0(A0,D0),A0
	BSR	STROUT
	LEA	G0SPC,A0
	BSR	STROUT

	;; Read / Write
	MOVE	GR0BUF,D0
	BTST	#8,D0
	BNE	G0D10
	LEA	G0WR,A0
	BRA	G0D11
G0D10:
	LEA	G0RD,A0
G0D11:
	BSR	STROUT

	;; BYTE / WORD
	MOVE	GR0BUF,D0
	BTST	#9,D0
	BEQ	G0D12
	LEA	G0BYTE,A0
	BRA	G0D13
G0D12:
	LEA	G0WORD,A0
G0D13:
	BSR	STROUT

	;; Write Data
	LEA	G0FROM,A0
	MOVE	GR0BUF,D0
	BTST	#8,D0
	BNE	G0D17		; if READ
	BTST	#9,D0
	BEQ	G0D15		; if WORD
	MOVE	GR0BUF+8,D1
	BTST	#10,D0
	BEQ	G0D14		; if not HB
	LSR	#8,D1
G0D14:
	MOVE.B	D1,D0
	BSR	HEXOUT2
	BRA	G0D16
G0D15:
	MOVE	GR0BUF+8,D0
	BSR	HEXOUT4
G0D16:
	LEA	G0TO,A0
G0D17:
	BSR	STROUT

	;; Address
	MOVE.L	GR0BUF+2,D0
	BSR	HEXOUT8		; Access address

	;; Instruction Fetch
	MOVE	GR0BUF,D0
	BTST	#13,D0
	BEQ	G0D18
	LEA	G0IF,A0
	BSR	STROUT
G0D18:
	;; Read-Modify-Write
	MOVE	GR0BUF,D0
	BTST	#11,D0
	BEQ	G0D19
	LEA	G0RMW,A0
	BSR	STROUT
G0D19:
	BRA	CRLF

G0D2:
	CMP	#$0A,D3		; MC68020/MC68030 Short Bus Fault Stack Frame
	BEQ	G0D20
	CMP	#$0B,D3		; MC68020/MC68030 Long Bus Fault Stack Frame
	BNE	G0D3
G0D20:
	;; MC68020 / MC68030


G0D3:
	ENDIF			; USE_SFDECODE

G0D9:
	;; Unsupported Stack Frame
	MOVE	REGSR,D0
	BSR	HEXOUT4
	MOVE.B	#' ',D0
	BSR	CONOUT

	MOVE	REGPC,D0
	BSR	HEXOUT4
	MOVE.B	#' ',D0
	BSR	CONOUT

	MOVE	REGPC+2,D0
	BSR	HEXOUT4
	MOVE.B	#' ',D0
	BSR	CONOUT

	MOVE	REGFV,D0
	BSR	HEXOUT4
	MOVE.B	#' ',D0
	BSR	CONOUT

	CLR	D2
	LEA	FMTLEN,A0
	MOVE	REGFV,D3
	ROL	#4,D3
	AND	#$000F,D3
	MOVE.B	0(A0,D3),D2
	MOVEQ	#4,D3		; Counter.  4 words already printed
	LEA	GR0BUF,A0

G0D90:
	MOVE	(A0)+,D0
	BSR	HEXOUT4
	ADDQ	#1,D3
	CMP	D3,D2
	BLS	G0D92
	MOVE	#$000F,D0
	AND	D3,D0
	BNE	G0D91
	BSR	CRLF
	BRA	G0D90
G0D91:
	MOVE.B	#' ',D0
	BSR	CONOUT
	BRA	G0D90
G0D92:
	BRA	CRLF

	ENDIF

	IF USE_IDENT

	SAVE
	CPU	68020
DMYRTM:
	DC.W	$F000		; A7
	RTM	A7
	RESTORE

	ENDIF

;;;
;;; Data area
;;;

HLPMSG:
	DC.B	"? :Command Help",CR,LF
	DC.B	"B[(1|2),<adr>] :Set or List Break Point",CR,LF
	DC.B	"BC[1|2] :Clear Break Point",CR,LF
	DC.B	"BT :Reset Boot",CR,LF
	DC.B	"D[<adr>] :Dump Memory",CR,LF
	DC.B	"G[<adr>][,<stop adr>] :Go and Stop",CR,LF
	DC.B	"L[<offset>] :Load HexFile",CR,LF
	DC.B	"M[T(0-2)|S|M|I(0-7)] :Mode(SR System Byte)",CR,LF
	DC.B	"P(I|S)<adr,adr> :Save HexFile(I:Intel,S:Motorola)",CR,LF
	DC.B	"R[<reg>] :Set or Dump Register",CR,LF
	DC.B	"S[<adr>] :Set Memory",CR,LF,$00

OPNMSG:	DC.B	CR,LF,"Universal Monitor 68000",CR,LF,$00

PROMPT:	DC.B	"] ",$00

IHEMSG:	DC.B	"Error ihex",CR,LF,$00
SHEMSG:	DC.B	"Error srec",CR,LF,$00
ERRMSG:	DC.B	"Error",CR,LF,$00

DSEP0:	DC.B	" :",$00
DSEP1:	DC.B	" : ",$00
IHEXER:	DC.B	":00000001FF",CR,LF,$00
SRECER: DC.B	"S9030000FC",CR,LF,$00

	IF USE_IDENT

IM000:	DC.B	"MC68000",CR,LF,$00
IM010:	DC.B	"MC68010",CR,LF,$00
IM020:	DC.B	"MC68020",CR,LF,$00
IM030:	DC.B	"MC68030",CR,LF,$00

	;; Module Descriptor for CALLM
	ALIGN	4
MDESC:
	DC.L	$00000000	; Opt=000, Type=$00, AL=$00
	DC.L	DMYRTM		; Module Entry Word Pointer
	DC.L	$00000000	; Module Data Area Pointer
	DC.L	$00000000

	ENDIF

BUSERR_M:
	DC.B	"Bus Error",$00
ADDERR_M:
	DC.B	"Address Error",$00
ILLINS_M:
	DC.B	"Illegal Instruction",$00
ZERDIV_M:
	DC.B	"Zero Divide",$00
CHK_M:
	DC.B	"CHK Instruction",$00
TRAPV_M:
	DC.B	"TRAPV Instruction",$00
PRIV_M:
	DC.B	"Privilege Violation",$00
TRACE_M:
	DC.B	"Trace",$00
L1010_M:
	DC.B	"Line 1010 Emulator",$00
L1111_M:
	DC.B	"Line 1111 Emulator",$00
FORMAT_M:
	DC.B	"Format Error",$00
TRAP0_M:
	DC.B	"TRAP #0",$00
TRAP1_M:
	DC.B	"TRAP #1",$00
TRAP2_M:
	DC.B	"TRAP #2",$00
TRAP3_M:
	DC.B	"TRAP #3",$00
TRAP4_M:
	DC.B	"TRAP #4",$00
TRAP5_M:
	DC.B	"TRAP #5",$00
TRAP6_M:
	DC.B	"TRAP #6",$00
TRAP7_M:
	DC.B	"TRAP #7",$00
TRAP8_M:
	DC.B	"TRAP #8",$00
TRAP9_M:
	DC.B	"TRAP #9",$00
TRAP10_M:
	DC.B	"TRAP #10",$00
TRAP11_M:
	DC.B	"TRAP #11",$00
TRAP12_M:
	DC.B	"TRAP #12",$00
TRAP13_M:
	DC.B	"TRAP #13",$00
TRAP14_M:
	DC.B	"TRAP #14",$00
TRAP15_M:
	DC.B	"TRAP #15",$00

BREAK_M:
	DC.B	"BREAK",$00

	IF USE_REGCMD

	ALIGN	2
RDTAB:	DC.W	$0003		; LONG
	DC.L	RDSD07, REGD0
	DC.W	$0003
	DC.L	RDSC,   REGD1
	DC.W	$0003
	DC.L	RDSC,   REGD2
	DC.W	$0003
	DC.L	RDSC,   REGD3
	DC.W	$0003
	DC.L	RDSCS,  REGD4
	DC.W	$0003
	DC.L	RDSC,   REGD5
	DC.W	$0003
	DC.L	RDSC,   REGD6
	DC.W	$0003
	DC.L	RDSC,   REGD7

	DC.W	$0003
	DC.L	RDSA07, REGA0
	DC.W	$0003
	DC.L	RDSC,   REGA1
	DC.W	$0003
	DC.L	RDSC,   REGA2
	DC.W	$0003
	DC.L	RDSC,   REGA3
	DC.W	$0003
	DC.L	RDSCS,  REGA4
	DC.W	$0003
	DC.L	RDSC,   REGA5
	DC.W	$0003
	DC.L	RDSC,   REGA6
	DC.W	$0003
	DC.L	RDSC,   REGA7

	DC.W	$0003
	DC.L	RDSPC,  REGPC
	DC.W	$0003
	DC.L	RDSSSP, REGSSP
	DC.W	$0002		; WORD
	DC.L	RDSSR,  REGSR

	DC.W	$8003		; LONG + (END flag for MC68000/8)
	DC.L	RDSVBR, REGVBR
	DC.W	$8001		; BYTE
	DC.L	RDSSFC, REGSFC
	DC.W	$8001		; BYTE
	DC.L	RDSDFC, REGDFC

	DC.W	$0000		; END

RDSD07:	DC.B	"D0-D7=",$00
RDSA07:	DC.B	CR,LF,"A0-A7=",$00
RDSPC:	DC.B	CR,LF,"PC=",$00
RDSSSP:	DC.B	" SSP=",$00
RDSSR:	DC.B	" SR=",$00
RDSVBR:	DC.B	"  VBR=",$00
RDSSFC:	DC.B	" SFC=",$00
RDSDFC:	DC.B	" DFC=",$00
RDSC:	DC.B	",",$00
RDSCS:	DC.B	", ",$00

	ALIGN	2
RNTAB:
	DC.B	'A',$0F		; "A?"
	DC.L	RNTABA,0
	DC.B	'C',$0F		; "C?"
	DC.L	RNTABC,0
	DC.B	'D',$0F		; "D?"
	DC.L	RNTABD,0
	DC.B	'P',$0F		; "P?"
	DC.L	RNTABP,0
	DC.B	'S',$0F		; "S?"
	DC.L	RNTABS,0
	DC.B	'V',$0F		; "V?"
	DC.L	RNTABV,0

	DC.B	$00,$00		; End mark
	DC.L	0,0

RNTABA:
	DC.B	'0',3		; "A0"
	DC.L	REGA0, RNA0
	DC.B	'1',3		; "A1"
	DC.L	REGA1, RNA1
	DC.B	'2',3		; "A2"
	DC.L	REGA2, RNA2
	DC.B	'3',3		; "A3"
	DC.L	REGA3, RNA3
	DC.B	'4',3		; "A4"
	DC.L	REGA4, RNA4
	DC.B	'5',3		; "A5"
	DC.L	REGA5, RNA5
	DC.B	'6',3		; "A6"
	DC.L	REGA6, RNA6
	DC.B	'7',3		; "A7"
	DC.L	REGA7, RNA7

	DC.B	$00,$00		; End mark
	DC.L	0,0

RNTABC:
	DC.B	'C', $0F	; "CC"
	DC.L	RNTABCC, 0

	DC.B	$00,$00		; End mark
	DC.L	0,0

RNTABD:
	DC.B	'0',3		; "D0"
	DC.L	REGD0, RND0
	DC.B	'1',3		; "D1"
	DC.L	REGD1, RND1
	DC.B	'2',3		; "D2"
	DC.L	REGD2, RND2
	DC.B	'3',3		; "D3"
	DC.L	REGD3, RND3
	DC.B	'4',3		; "D4"
	DC.L	REGD4, RND4
	DC.B	'5',3		; "D5"
	DC.L	REGD5, RND5
	DC.B	'6',3		; "D6"
	DC.L	REGD6, RND6
	DC.B	'7',3		; "D7"
	DC.L	REGD7, RND7
	DC.B	'F', $0F	; "DF?"
	DC.L	RNTABDF, 0

	DC.B	$00,$00		; End mark
	DC.L	0,0

RNTABP:
	DC.B	'C',3		; "PC"
	DC.L	REGPC, RNPC

	DC.B	$00,$00		; End mark
	DC.L	0,0

RNTABS:
	DC.B	'F', $0F	; "SF?"
	DC.L	RNTABSF, 0
	DC.B	'R', 2		; "SR"
	DC.L	REGSR, RNSR
	DC.B	'S', $0F	; "SS?"
	DC.L	RNTABSS, 0

	DC.B	$00,$00		; End mark
	DC.L	0,0

RNTABV:
	DC.B	'B', $0F	; "VB?"
	DC.L	RNTABVB, 0

	DC.B	$00,$00		; End mark
	DC.L	0,0

RNTABCC:
	DC.B	'R', 1		; "CCR"
	DC.L	REGSR+1, RNCCR

	DC.B	$00,$00		; End mark
	DC.L	0,0

RNTABDF:
	DC.B	'C', $81	; "DFC"
	DC.L	REGDFC, RNDFC

	DC.B	$00,$00		; End mark
	DC.L	0,0

RNTABSF:
	DC.B	'C', $81	; "SFC"
	DC.L	REGSFC, RNSFC

	DC.B	$00,$00		; End mark
	DC.L	0,0

RNTABSS:
	DC.B	'P', 3		; "SSP"
	DC.L	REGSSP, RNSSP

	DC.B	$00,$00		; End mark
	DC.L	0,0

RNTABVB:
	DC.B	'R', $83	; "VBR"
	DC.L	REGVBR, RNVBR

	DC.B	$00,$00		; End mark
	DC.L	0,0

RNA0:	DC.B	"A0",$00
RNA1:	DC.B	"A1",$00
RNA2:	DC.B	"A2",$00
RNA3:	DC.B	"A3",$00
RNA4:	DC.B	"A4",$00
RNA5:	DC.B	"A5",$00
RNA6:	DC.B	"A6",$00
RNA7:	DC.B	"A7",$00
RNCCR:	DC.B	"CCR",$00
RND0:	DC.B	"D0",$00
RND1:	DC.B	"D1",$00
RND2:	DC.B	"D2",$00
RND3:	DC.B	"D3",$00
RND4:	DC.B	"D4",$00
RND5:	DC.B	"D5",$00
RND6:	DC.B	"D6",$00
RND7:	DC.B	"D7",$00
RNDFC:	DC.B	"DFC",$00
RNPC:	DC.B	"PC",$00
RNSFC:	DC.B	"SFC",$00
RNSR:	DC.B	"SR",$00
RNSSP:	DC.B	"SSP",$00
RNVBR:	DC.B	"VBR",$00

FCTAB:	DC.L	FCN0,FCN1,FCN2,FCN3
	DC.L	FCN4,FCN5,FCN6,FCN7
FCTAB2:	DC.L	FCN0,FCN1,FCN2,FCN3
	DC.L	FCN4,FCN5,FCN6,FCN7A
FCN0:	DC.B	"FC=0 ",$00
FCN1:	DC.B	"User Data ",$00
FCN2:	DC.B	"User Program ",$00
FCN3:	DC.B	"FC=3 ",$00
FCN4:	DC.B	"FC=4 ",$00
FCN5:	DC.B	"Supervisor Data ",$00
FCN6:	DC.B	"Supervisor Program ",$00
FCN7:	DC.B	"Interrupt Acknowledge ",$00
FCN7A:	DC.B	"CPU ",$00
G0WR:	DC.B	"Write ",$00
G0RD:	DC.B	"Read ",$00
G0INS0:	DC.B	"  (Inst=",$00
G0BYTE:	DC.B	"Byte ",$00
G0WORD:	DC.B	"Word ",$00
G0TO:	DC.B	" to ",$00
G0FROM:	DC.B	"from ",$00
G0SPC:	DC.B	"Space ",$00
G0IF:	DC.B	" (Instruction Fetch)",$00
G0RMW:	DC.B	" (Read Modify Write)",$00
	ENDIF

	;; Stack frame size (WORD) for each format
FMTLEN:
	DC.B	4		; 0000 (68010,68020,SCC68070)
	DC.B	4		; 0001 Throw Away (68020)
	DC.B	6		; 0010 (68020)
	DC.B	6		; 0011
	DC.B	8		; 0100
	DC.B	0		; 0101
	DC.B	0		; 0110
	DC.B	30		; 0111
	DC.B	29		; 1000 Bus Error, Address Error (68010)
	DC.B	10		; 1001 Coprocessor Midinstruction (68020)
	DC.B	16		; 1010 Short Bus Fault (68020,68030)
	DC.B	46		; 1011 Long Bus Fault (68020,68030)
	DC.B	12		; 1100 Bus Error (CPU32)
	DC.B	0		; 1101
	DC.B	0		; 1110
	DC.B	17		; 1111 (SCC68070)


	ALIGN	2

;;;
;;;	MC6850 (ACIA) Console Driver
;;;

INIT:
;	MOVE.B	#$03,ACIAC	; Master reset
;	NOP
;	NOP
;	MOVE.B	#CR_V,ACIAC	; x16 8bit N 1

	RTS

CONIN:
	MOVE.B	ACIAC,D0
	AND.B	#$01,D0
	BEQ	CONIN
	MOVE.B	ACIAD,D0

	RTS

CONST:
	MOVE.B	ACIAC,D0
	AND.B	#$01,D0

	RTS

CONOUT:
	SWAP	D0
CO0:
	MOVE.B	ACIAC,D0
	AND.B	#$02,D0
	BEQ	CO0
	SWAP	D0
	MOVE.B	D0,ACIAD

	RTS

ROM_E:

	DC.B	[(*+$100)&$FFFFFF00-*]$FF

;;;
;;; RAM area
;;;

	ORG	WORK_B

INBUF:	DS.B	BUFLEN		; Line input buffer
DSADDR:	DS.L	1		; DUMP start address
DEADDR:	DS.L	1
DSTATE:	DS.B	1
	ALIGN	2
GADDR:	DS.L	1
SADDR:	DS.L	1		; SET address
HEXMOD:	DS.B	1		; HEX file mode
RECTYP:	DS.B	1		; Record type
PSPEC:	DS.B	1		; Processor spec.

	ALIGN	2

EXMSG:	DS.L	1		; Exception message
EXGRP:	DS.W	1		; Exception Group

REG_B:
REGPC:	DS.L	1

REGD0:	DS.L	1
REGD1:	DS.L	1
REGD2:	DS.L	1
REGD3:	DS.L	1
	IF USE_REGCMD
REGD4:	DS.L	1
REGD5:	DS.L	1
REGD6:	DS.L	1
REGD7:	DS.L	1
	ENDIF

REGA0:	DS.L	1
REGA1:	DS.L	1
REGA2:	DS.L	1
REGA3:	DS.L	1
	IF USE_REGCMD
REGA4:	DS.L	1
REGA5:	DS.L	1
REGA6:	DS.L	1
REGA7:	DS.L	1		; USP

REGSSP:	DS.L	1
REGSR:	DS.W	1
REGVBR:	DS.L	1
REGSFC:	DS.B	1
REGDFC:	DS.B	1

GR0BUF:	DS.W	46-4		; Group 0 exception
REGFV:	DS.W	1		; Format / Vector offset
REG_E:

F_bit:	DS.B	F_bitSize+1

	ENDIF

	ALIGN	2

;; Break point work area
dbg_wtop	EQU	*
bpt1_f:		DS.B	1
bpt1_op:	DS.W	1
bpt1_adr:	DS.L	1
bpt2_f:		DS.B	1
bpt2_op:	DS.W	1
bpt2_adr:	DS.L	1

tmpb_f:		DS.B	1
tmpb_op:	DS.W	1
tmpb_adr:	DS.L	2

	ALIGN	2

dbg_wend	EQU	*

	END
