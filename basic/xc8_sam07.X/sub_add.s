#include <xc.inc>
GLOBAL _add            ; make _add globally accessible
SIGNAT _add,4217       ; tell the linker how it should be called
; everything following will be placed into the code psect
PSECT code
; our routine to add to ints and return the result
_add:
    ; W is loaded by the calling function;
    BANKSEL (PORTB)               ; select the bank of this object
    addwf BANKMASK(PORTB),w,b     ; add parameter to port
    ; the result is already in the required location (W) so we can
    ; just return immediately
    return

; ***** extern *********************
EXTRN _add2$0
EXTRN _add2$1
;EXTRN ?_add2

; ***** ram ************************
PSECT udata_acs
add2@temp:
	DS		2

; ***** add2 ***********************
GLOBAL _add2
PSECT code
_add2:
	; temp = b + c;
	movf	BANKMASK(_add2$1),w,c
	addwf	BANKMASK(_add2$0),w,c
	movwf	BANKMASK(add2@temp),c
	movf	BANKMASK(_add2$1+1),w,c
	addwfc	BANKMASK(_add2$0+1),w,c
	movwf	BANKMASK(add2@temp+1),c
	; return temp;
;	movff	add2@temp,?_add2			; (疑問)?_add2を使用すると
;	movff	add2@temp+1,?_add2+1		; アドレスが「0」となる
	movff	add2@temp,_add2$0
	movff	add2@temp+1,_add2$0+1
	return
