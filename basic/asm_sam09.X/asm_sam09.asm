/*
 * File:   asm_sam09.asm
 * Author: hseiyama
 *
 * Using for Table accesss
 */

PROCESSOR 18F47Q43

#include <xc.inc>

DATA_SIZE	EQU		10

; ***** ram ************************
PSECT udata_acs						; common ram
data_ram:
	DS		DATA_SIZE
data_work:
	DS		1
index:
	DS		1

; ***** rom ************************
PSECT data							; const data
data_rom:
	DB		1,2,3,4,5,6,7,8,9,10

; ***** vector *********************
PSECT resetVec,class=CODE,reloc=2
resetVec:
	goto	main

; ***** main ***********************
PSECT code
main:
	; initialize
	clrf	index,c
	; rom table read (high byte)
	movlw	highword data_rom
	movwf	TBLPTRU,c
	movlw	high data_rom
	movwf	TBLPTRH,c
	; ram table write (high byte)
	movlw	high data_ram
	movwf	FSR0H,c
next:
	; rom table read (low byte)
	movlw	low data_rom
	addwf	index,w,c
	movwf	TBLPTRL,c
	tblrd	*
	movff	TABLAT,data_work
	; ram table write (low byte)
	movlw	low data_ram
	addwf	index,w,c
	movwf	FSR0L,c
	movff	data_work,INDF0
	; next index
	incf	index,f,c
	movlw	DATA_SIZE
	cpfseq	index,c					; if(index != 10) goto next
	goto	next
loop:
	goto	$

	END		resetVec
