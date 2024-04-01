/*
 * File:   asm_sam01.s
 * Author: hseiyama
 *
 * Created on 2024/03/30, 21:35
 *
 * Using for PSECT
 * Using for Access Bank
 */

PROCESSOR 18F47Q43

#include <xc.inc>

; ***** ram ************************
PSECT udata_acs						; force Access Bank
count_a:
    DS      1

PSECT udata_bank5					; BSR to select bank
count_b5:
    DS      1
count_bw:
    DS      1

; ***** vector *********************
PSECT resetVec,class=CODE,reloc=2
resetVec:
    org     0x0
    goto    main

    org     0x8
    goto    intp

; ***** main ***********************
PSECT code
main:
    nop
loop:
    incf    count_a,w,a				; force Access Bank
    movwf   count_a,a

    movlb   5
    incf    count_b5,f,b			; BSR to select bank

    incf    count_bw,w,b			; BSR to select bank
    movwf   count_bw,b

    goto    loop

; ***** intp ***********************
intp:
    retfie

    END     resetVec
