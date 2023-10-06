CR	EQU	0DH
LF	EQU	0AH
ESC	EQU	1BH

TIMER0_SCTL	equ	0F820H		;timer0 seconds counter LSB
TIMER0_SCTH	equ	0F821H		;timer0 seconds counter MSB

DISP_MODE	equ	0F004H		;Display mode
TRAC_MODE	equ	0F006H		;Trace mode

	ORG	0C000h			;for ram address

START:
	XOR	A
	LD	C, 19
	RST	30H			;[UniMon] stopwatch (start timer)
	LD	A, 04H			;[Display mode] Trace mode
	LD	(DISP_MODE), A
	LD	A, 00H			;[Trace mode] off
	LD	(TRAC_MODE), A
LOOP:
	LD	C, 5
	RST	30H			;[UniMon] CONST
	JR	Z, NEXT			;if key=null -> next
	LD	C, 4
	RST	30H			;[UniMon] CONIN
CHK_EXT:
	CP	ESC
	JR	Z, EXIT			;if key=ESC -> exit
CHK_LED:
	CP	'L'
	JR	NZ, CHK_URT
	CALL	LED_DP			;toggle LED Display
CHK_URT:
	CP	'U'
	JR	NZ, ECHO
	CALL	URT_DP			;toggle UART
ECHO:
	LD	C, 2
	RST	30H			;[UniMon] CONOUT (echo key)
NEXT:
	LD	A, (TIMER0_SCTL)
	LD	HL, TM_PRE
	CP	(HL)
	JR	Z, LOOP			;if timer0=timer_pre -> loop
	LD	(TM_PRE), A		;update timer_pre
	LD	A, '.'
	LD	C, 2
	RST	30H			;[UniMon] CONOUT
	JR	LOOP
EXIT:
	LD	HL, NEW_LN		;newline
	LD	C, 3
	RST	30H			;[UniMon] STROUT
	LD	C, 1
	RST	30H			;[UniMon] WSTART

LED_DP:					;toggle LED Display
	PUSH	AF
	LD	A,(TRAC_MODE)
	XOR	01H			;[Trace mode] LED Display
	LD	(TRAC_MODE), A
	POP	AF
	RET

URT_DP:					;toggle UART
	PUSH	AF
	LD	A,(TRAC_MODE)
	XOR	02H			;[Trace mode] UART
	LD	(TRAC_MODE), A
	POP	AF
	RET

NEW_LN	DEFB	CR, LF			;newline

TM_PRE	DEFS	1			;timer_pre

	END
