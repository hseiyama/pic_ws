/*
 * File:   asm_sam02.s
 * Author: hseiyama
 *
 * Using for Subroutine
 * Using for Branch
 */

PROCESSOR 18F47Q43

#include <xc.inc>

; ***** ram ************************
PSECT udata_acs						; common memory
count_a:
    DS      1
count_b:
    DS      1

; ***** vector *********************
PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto    main

; ***** main ***********************
PSECT code
main:
    clrf	BANKMASK(count_a),c
    clrf	BANKMASK(count_b),c
loop:
	incf    BANKMASK(count_a),f,c
	movlw	5
	cpfsgt	BANKMASK(count_a),c
	goto	loop
    clrf	BANKMASK(count_a),c
	call	func					; call subroutine
    goto    loop

; ***** func ***********************
func:
	incf    BANKMASK(count_b),f,c
    return

    END     resetVec
