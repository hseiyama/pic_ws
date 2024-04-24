/*
 * File:   asm_sam13.asm
 * Author: hseiyama
 *
 * Using for Reset
 * Using for Sleep
 */

PROCESSOR 18F47Q43

#include <xc.inc>

; ***** vector *********************
PSECT resetVec,class=CODE,reloc=2
resetVec:
	goto	main

PSECT ivecTbl,class=CODE,reloc=2,ovrld
ivecTbl:
	ORG		8h*2					;interrupt0 vector position
	DW		int0Isr shr 2			;interrupt0 ISR address shifted right

; ***** ISR ************************
PSECT textISR,class=CODE,reloc=4
int0Isr:
	bcf		INT0IF					; Clear interrupt flag
	retfie

; ***** main ***********************
PSECT code
main:
	; RB0(INT0) input pin
	BANKSEL	ANSELB
	bcf		ANSELB0					; Disable analog function
	BANKSEL	WPUB
	bsf		WPUB0					; Week pull up
	bsf		TRISB0					; Set as intput
	bcf		INT0EDG					; INT0 external interrupt falling edge
	bcf		INT0IF					; Clear INT0 external interrupt flag
	bsf		INT0IE					; INT0 external interrupt enable
	; Global interrupt
	bsf		GIE						; Global interrupt enable
	nop
	nop
	sleep
	nop
	nop
	reset
	goto	$

	END		resetVec
