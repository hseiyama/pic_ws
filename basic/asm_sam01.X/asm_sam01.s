/*
 * File:   asm_sam01.s
 * Author: hseiyama
 *
 * Using for PSECT
 * Using for Access Bank
 */

PROCESSOR 18F47Q43

#include <xc.inc>

; ***** ram ************************
PSECT udata_acs						; common memory
count_a:
    DS      1

PSECT udata_bank5					; banked memory
count_b5:
    DS      1
count_bw:
    DS      1

; ***** vector *********************
PSECT resetVec,class=CODE,reloc=2
resetVec:
    org     0h
    goto    main

    org     8h
    goto    intp

; ***** main ***********************
PSECT code
main:
    nop
loop:
    incf    BANKMASK(count_a),w,c	; common memory
    movwf   BANKMASK(count_a),c

	BANKSEL(count_b5)
    incf    BANKMASK(count_b5),f,b	; banked memory

	BANKSEL(count_bw)
    incf    BANKMASK(count_bw),w,b	; banked memory
    movwf   BANKMASK(count_bw),b

    goto    loop

; ***** intp ***********************
intp:
    retfie

    END     resetVec
