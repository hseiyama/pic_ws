	CPU	68000
	SUPMODE	OFF

ROM_B	EQU	$00008000
RAM_B	EQU	$00008050
STACK	EQU	$00008080

	ORG	ROM_B

START:
	LEA.L	STACK,A7
	MOVE.L	#$12345678,A6
	CLR.L	SUMVAL
LOOP:
	MOVE.L	SUMVAL,D1
	MOVE.L	D1,-(A7)	; Push
	BSR	SUMFNC
	ADDQ.L	#4,A7		; Move stack(pop)
	MOVE.L	D0,SUMVAL
	MOVE.L	A6,D2
	ROL.L	#4,D2
	MOVEA.L	D2,A6
	BRA	LOOP
	ILLEGAL

SUMFNC:
	LINK	A6,#-8
	MOVE.L	8(A6),-8(A6)	; Get parameter
	ADDQ.L	#1,-8(A6)
	MOVE.L	-8(A6),D0
	UNLK	A6
	RTS

	ORG	RAM_B
	DC.B	[STACK-*]$FF

	ORG	RAM_B

SUMVAL:	DS.L	1

END
