;
; File:   asm_sam01.asm
; Author: hseiyama
;
; Created on 2024/03/30, 21:35
;


#include <xc.inc>

    psect	code
; ***** vector *********************
    org		000000H
    goto	MAIN

    org		000008H
    goto	INTP

; ***** main ***********************
    org		000100H
MAIN:
    nop
LOOP:
    goto	LOOP

; ***** intp ***********************
INTP:
    retfie
    end
