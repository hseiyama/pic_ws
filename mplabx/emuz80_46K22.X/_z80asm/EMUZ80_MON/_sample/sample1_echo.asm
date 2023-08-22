
STACK	EQU	3EC0H			; user stack
RAM_B	EQU	3400H			;EMUZ80_K22 RAM base address
NMI_OFS	EQU	0010H			; NMI offset
ENT_OFS	EQU	0020H			; ENTRY offset
PORTDR	EQU	0D0H			; PORT DATA REGISTOR

;=======================================
; MAIN ROUTINE
;=======================================

	ORG	RAM_B
BOOT:
	LD	SP, STACK
	JR	START

	ORG	RAM_B + NMI_OFS
NMI:
	RST	38H
	RETN

	ORG	RAM_B + ENT_OFS
START:
LOOP:
	IN	A, (PORTDR)
	OUT	(PORTDR), A
	LD	C, 05H
	RST	30H			;CONST
	JR	Z, LOOP
	LD	C, 04H
	RST	30H			;CONIN
	LD	C, 02H
	RST	30H			;CONOUT
	JR	LOOP

	END
