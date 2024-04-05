
PROCESSOR 18F47Q43

#include <xc.inc>

; ***** ram ************************
GLOBAL count_global
PSECT udata_acs						; common memory
count_global:
    DS      1

; ***** func ***********************
GLOBAL func_global
PSECT code
func_global:
	incf    count_global,f,c
	return

    END
