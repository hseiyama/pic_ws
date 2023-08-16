
PORTDR	EQU	0D0H			; PORT DATA REGISTOR

;=======================================
; MAIN ROUTINE
;=======================================

	ORG	3400H

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
