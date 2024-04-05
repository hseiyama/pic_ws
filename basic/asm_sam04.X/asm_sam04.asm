/*
 * File:   asm_sam04.asm
 * Author: hseiyama
 *
 * Using for Multi files
 * Using for Global symbol
 */

PROCESSOR 18F47Q43

#include <xc.inc>

; ***** extern *********************
EXTRN count_global
EXTRN func_global

; ***** ram ************************
PSECT udata_acs						; common memory
count_local:
    DS      1

; ***** vector *********************
PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto    main

; ***** main ***********************
PSECT code
main:
    clrf	count_global,c
    clrf	count_local,c
loop:
	incf    count_local,f,c
	movf	count_local,w,c
	addwf	count_global,f,c
	call	func_global				; call subroutine
    goto    loop

    END     resetVec
