MON_SEG	EQU	0D000H			;monitor segment
CR_SIZE EQU	MON_SEG - CTOP -1	;clear target ram size

	ORG	0040h			;for ram address

START:
	LD	HL, CTOP
	LD	DE, CTOP + 1
	LD	BC, CR_SIZE
	LDIR				;load increment repeat
	RST	38H			;beak
CTOP:
	DEFB	00H			;clear target ram

	END
