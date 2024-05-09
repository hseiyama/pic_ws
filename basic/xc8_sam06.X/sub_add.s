#include <xc.inc>
psect        text1,class=CODE,space=0,reloc=2
GLOBAL _add
_add:
    stack_auto tmp,2      ;an auto called 'tmp'; 2 bytes wide
    stack_auto result,2   ;an auto called 'result'; 2 bytes wide
    stack_param base,2    ;a parameter called 'base'; 2 bytes wide
    stack_param index,2   ;a parameter called 'index'; 2 bytes wide
    alloc_stack
    ;tmp = base + index;
    movlw   base_offset
    movff   PLUSW1,btemp+0
    movlw   base_offset+1
    movff   PLUSW1,btemp+1
    movlw   index_offset
    movf    PLUSW1,w,c
    addwf   BANKMASK(btemp+0),f,c
    movlw   index_offset+1
    movf    PLUSW1,w,c
    addwfc  BANKMASK(btemp+1),f,c
    movlw   tmp_offset
    movff   btemp+0,PLUSW1
    movlw   tmp_offset+1
    movff   btemp+1,PLUSW1
    ;result = tmp + 1;
    movlw   tmp_offset
    movf    PLUSW1,w,c
    addlw   1
    movwf   BANKMASK(btemp+0),c
    movlw   tmp_offset+1
    movff   PLUSW1,btemp+1
    movlw   0
    addwfc  BANKMASK(btemp+1),f,c
    movlw   result_offset
    movff   btemp+0,PLUSW1
    movlw   result_offset+1
    movff   btemp+1,PLUSW1
    ;return result;
    movlw   result_offset
    movff   PLUSW1,btemp+0
    movlw   result_offset+1
    movff   PLUSW1,btemp+1
    restore_stack
    return
