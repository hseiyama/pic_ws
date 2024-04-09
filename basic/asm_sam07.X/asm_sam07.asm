/*
 * File:   asm_sam07.asm
 * Author: hseiyama
 *
 * Using for Compiled stack
 */

PROCESSOR 18F47Q43

#include <xc.inc>

; ***** call graph *****************
FNCONF udata_acs,?auto_,?param_				; auto=?auto_***,param=?param_***
FNROOT main
FNCALL main,func1
FNCALL main,func2

; ***** ram ************************
PSECT udata_acs								; common memory
count_static:
    DS      1

; ***** vector *********************
PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto    main

; ***** func1 **********************
PSECT udata_acs								; common memory
FNSIZE func1,1,2							; auto=1,param=2
GLOBAL ?auto_func1
GLOBAL ?param_func1

PSECT code
func1:
;	movff	?param_func1+0,?auto_func1		; param0 -> auto
	movf	?param_func1+0,w,c
	movwf	?auto_func1,c
	movlw	12h								; 12h -> w
	addwf	?auto_func1,f,c					; w + auto -> auto
;	movff	?auto_func1,?param_func1+1		; auto -> param1
	movf	?auto_func1,w,c
	movwf	?param_func1+1,c
	return

; ***** func2 **********************
FNSIZE func2,0,3							; param=3
GLOBAL ?param_func2

PSECT code
func2:
	movf	?param_func2+0,w,c				; param0 -> w
	addwf	?param_func2+1,w,c				; w + param1 -> w
	movwf	?param_func2+2,c				; w -> param2
	return

; ***** main ***********************
FNSIZE main,2,0								; auto=2
GLOBAL ?auto_main

PSECT code
main:
    clrf	count_static,c					; 0 -> count_static
	movlw	2
    movwf	?auto_main+0,c					; 2 -> auto0
	movlw	3
    movwf	?auto_main+1,c					; 3 -> auto1
loop:
	; Call func1
;	movff	?auto_main+0,?param_func1+0		; auto0 -> func1.param0
	movf	?auto_main+0,w,c
	movwf	?param_func1+0,c
	call	func1
;	movff	?param_func1+1,?auto_main+0		; func1.param1 -> auto0
	movf	?param_func1+1,w,c
	movwf	?auto_main+0,c
	; Call func2
;	movff	?auto_main+0,?param_func2+0		; auto0 -> func2.param0
	movf	?auto_main+0,w,c
	movwf	?param_func2+0,c
;	movff	?auto_main+1,?param_func2+1		; auto1 -> func2.param1
	movf	?auto_main+1,w,c
	movwf	?param_func2+1,c
	call	func2
;	movff	?param_func2+2,?auto_main+1		; func2.param2 -> auto1
	movf	?param_func2+2,w,c
	movwf	?auto_main+1,c
	; Update count_static
	movf	?auto_main+0,w,c				; auto0 -> w
	addwf	?auto_main+1,w,c				; w + auto1 -> w
	addwf	count_static,w,c				; w + count_static -> w
	movwf	count_static,c					; w -> count_static
    goto    loop

    END     resetVec
