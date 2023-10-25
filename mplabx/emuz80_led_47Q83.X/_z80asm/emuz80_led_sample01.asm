LED_HEX_TOP	EQU	0F000h		;0xF000-0xF003 HEX data

	ORG	0C000h			;ramìÆçÏóp

START:
	LD	IX, LED_HEX_TOP
	XOR	A
LOOP:
	LD	(IX + 0), A
	INC	A
	LD	(IX + 1), A
	INC	A
	LD	(IX + 2), A
	INC	A
	LD	(IX + 3), A

	LD	C, 04H
	RST	30H			;[UniMon] CONIN
	SUB	'0'
	JR	LOOP

	END
