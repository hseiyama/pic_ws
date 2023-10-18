;;;
;;;	MC68901 (MFP) Console Driver
;;;

SCR:	EQU	MFBASE+13*2
UCR:	EQU	MFBASE+14*2
RSR:	EQU	MFBASE+15*2
TSR:	EQU	MFBASE+16*2
UDR:	EQU	MFBASE+17*2
	
INIT:
	MOVE.B	#UCR_V,UCR
	MOVE.B	#$01,RSR	; Enable receiver
	MOVE.B	#$05,TSR	; Enable transmitter
	
	RTS

CONIN:
	MOVE.B	RSR,D0
	AND.B	#$80,D0
	BEQ	CONIN
	MOVE.B	UDR,D0

	RTS

CONST:
	MOVE.B	RSR,D0
	AND.B	#$80,D0

	RTS

CONOUT:
	SWAP	D0
CO0:
	MOVE.B	TSR,D0
	AND.B	#$80,D0
	BEQ	CO0
	SWAP	D0
	MOVE.B	D0,UDR

	RTS