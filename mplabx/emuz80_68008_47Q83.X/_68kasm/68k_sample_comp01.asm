	CPU	68000
	SUPMODE	OFF

ROM_B	EQU	$00008000
RAM_B	EQU	$00008060
STACK	EQU	$00008080

	ORG	ROM_B

START:
LOOP:
	MOVEQ	#5,D0
	CMPI.L	#4,D0
	CMPI.L	#5,D0
	CMPI.L	#6,D0
	MOVE.L	#$7FFFFFFF,D1
	ADDI.L	#$00000002,D1
	MOVE.L	#$7FFFFFFF,D1
	ADDI.L	#$80000002,D1
	BRA	LOOP
	ILLEGAL

	ORG	RAM_B
	DC.B	[STACK-*]$FF

	ORG	RAM_B

DUMMY:	DS.L	1

END
