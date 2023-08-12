;;;
;;;	EMUZ80 Console Driver
;;;

INIT:
	;; Initialize UART
	RET

;;;
;;; PIC18F46K22 ESUART2 conin/const/conout w/o interrupt
;;;

CONIN:
	IN	A,(USARTC)
	AND	01H
	JR	Z,CONIN
	IN	A,(USARTD)
	RET

CONST:
	IN	A,(USARTC)
	AND	01H
	RET

CONOUT:
	PUSH	AF
CO0:
	IN	A,(USARTC)
	AND	02H
	JR	Z,CO0
	POP	AF
	OUT	(USARTD),A
	RET
