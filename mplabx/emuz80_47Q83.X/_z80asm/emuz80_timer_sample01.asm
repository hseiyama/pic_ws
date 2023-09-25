CR	EQU	0DH
LF	EQU	0AH
ESC	EQU	1BH

TIMER0_SCTL	equ	0F820H		;timer0 seconds counter LSB
TIMER0_SCTH	equ	0F821H		;timer0 seconds counter MSB

	ORG	0C000h			;for ram address

START:
	XOR	A
	LD	C, 19
	RST	30H			;[UniMon] stopwatch (start timer)
LOOP:
	LD	C, 5
	RST	30H			;[UniMon] CONST
	JR	Z, NEXT			;if key=null -> next
	LD	C, 4
	RST	30H			;[UniMon] CONIN
	CP	ESC
	JR	Z, EXIT			;if key=ESC -> exit
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

NEW_LN	DEFB	CR, LF			;newline

TM_PRE	DEFS	1			;timer_pre

	END
