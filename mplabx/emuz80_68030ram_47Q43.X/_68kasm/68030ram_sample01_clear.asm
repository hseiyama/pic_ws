	CPU	68030
	SUPMODE	ON

ENTRY	EQU	$000000C0	; Entry address
RAM_B	EQU	$00000100	; RAM base address
RAM_E	EQU	$0001D000	; RAM end address(+1)

	ORG	ENTRY

	MOVE.L	#$00000000,D0
	MOVE.L	#RAM_B,A0
CLEAR:
	MOVE.L	D0,(A0)+
	CMPA.L	#RAM_E,A0
	BCS	CLEAR
BREAK:	DC.W	$4AFC

	DC.B	[RAM_B-*]$FF

	END