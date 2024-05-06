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
	; rom table read (low byte)		; (2)
	movlw	low data_rom			; (2)
	movwf	TBLPTRL,c				; (2)
	; ram table write (high byte)
	movlw	high data_ram
	movwf	FSR0H,c
	; ram table write (low byte)	; (2)
	movlw	low data_ram			; (2)
	movwf	FSR0L,c					; (2)
next:
	; rom table read (low byte)		; (1)
;	movlw	low data_rom			; (1)
;	addwf	index,w,c				; (1)
;	movwf	TBLPTRL,c				; (1)
;	tblrd	*						; (1)Table Read
	tblrd	*+						; (2)Table Read with post-increment
	movff	TABLAT,data_work
	; ram table write (low byte)	; (1)
;	movlw	low data_ram			; (1)
;	addwf	index,w,c				; (1)
;	movwf	FSR0L,c					; (1)
;	movff	data_work,INDF0			; (1)Indirect Data Register
;	movff	data_work,POSTINC0		; (2)Indirect Data Register with post increment
	movf	index,w,c				; (3)
	movff	data_work,PLUSW0		; (3)Indirect Data Register with WREG offset
	; next index
	incf	index,f,c
	movlw	DATA_SIZE
	cpfseq	index,c					; if(index != 10) goto next
	goto	next
loop:
	goto	$

	END		resetVec
