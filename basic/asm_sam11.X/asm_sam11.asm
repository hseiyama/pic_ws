
; PIC18F47Q43 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FEXTOSC = OFF         ; External Oscillator Selection (Oscillator not enabled)
  CONFIG  RSTOSC = HFINTOSC_64MHZ; Reset Oscillator Selection (HFINTOSC with HFFRQ = 64 MHz and CDIV = 1:1)

; CONFIG2
  CONFIG  CLKOUTEN = OFF        ; Clock out Enable bit (CLKOUT function is disabled)
  CONFIG  PR1WAY = ON           ; PRLOCKED One-Way Set Enable bit (PRLOCKED bit can be cleared and set only once)
  CONFIG  CSWEN = ON            ; Clock Switch Enable bit (Writing to NOSC and NDIV is allowed)
  CONFIG  FCMEN = ON            ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor enabled)

; CONFIG3
  CONFIG  MCLRE = EXTMCLR       ; MCLR Enable bit (If LVP = 0, MCLR pin is MCLR; If LVP = 1, RE3 pin function is MCLR )
  CONFIG  PWRTS = PWRT_OFF      ; Power-up timer selection bits (PWRT is disabled)
  CONFIG  MVECEN = ON           ; Multi-vector enable bit (Multi-vector enabled, Vector table used for interrupts)
  CONFIG  IVT1WAY = ON          ; IVTLOCK bit One-way set enable bit (IVTLOCKED bit can be cleared and set only once)
  CONFIG  LPBOREN = OFF         ; Low Power BOR Enable bit (Low-Power BOR disabled)
  CONFIG  BOREN = SBORDIS       ; Brown-out Reset Enable bits (Brown-out Reset enabled , SBOREN bit is ignored)

; CONFIG4
  CONFIG  BORV = VBOR_1P9       ; Brown-out Reset Voltage Selection bits (Brown-out Reset Voltage (VBOR) set to 1.9V)
  CONFIG  ZCD = OFF             ; ZCD Disable bit (ZCD module is disabled. ZCD can be enabled by setting the ZCDSEN bit of ZCDCON)
  CONFIG  PPS1WAY = OFF         ; PPSLOCK bit One-Way Set Enable bit (PPSLOCKED bit can be set and cleared repeatedly (subject to the unlock sequence))
  CONFIG  STVREN = ON           ; Stack Full/Underflow Reset Enable bit (Stack full/underflow will cause Reset)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (Low voltage programming enabled. MCLR/VPP pin function is MCLR. MCLRE configuration bit is ignored)
  CONFIG  XINST = OFF           ; Extended Instruction Set Enable bit (Extended Instruction Set and Indexed Addressing Mode disabled)

; CONFIG5
  CONFIG  WDTCPS = WDTCPS_31    ; WDT Period selection bits (Divider ratio 1:65536; software control of WDTPS)
  CONFIG  WDTE = OFF            ; WDT operating mode (WDT Disabled; SWDTEN is ignored)

; CONFIG6
  CONFIG  WDTCWS = WDTCWS_7     ; WDT Window Select bits (window always open (100%); software control; keyed access not required)
  CONFIG  WDTCCS = SC           ; WDT input clock selector (Software Control)

; CONFIG7
  CONFIG  BBSIZE = BBSIZE_512   ; Boot Block Size selection bits (Boot Block size is 512 words)
  CONFIG  BBEN = OFF            ; Boot Block enable bit (Boot block disabled)
  CONFIG  SAFEN = OFF           ; Storage Area Flash enable bit (SAF disabled)
  CONFIG  DEBUG = OFF           ; Background Debugger (Background Debugger disabled)

; CONFIG8
  CONFIG  WRTB = OFF            ; Boot Block Write Protection bit (Boot Block not Write protected)
  CONFIG  WRTC = OFF            ; Configuration Register Write Protection bit (Configuration registers not Write protected)
  CONFIG  WRTD = OFF            ; Data EEPROM Write Protection bit (Data EEPROM not Write protected)
  CONFIG  WRTSAF = OFF          ; SAF Write protection bit (SAF not Write Protected)
  CONFIG  WRTAPP = OFF          ; Application Block write protection bit (Application Block not write protected)

; CONFIG10
  CONFIG  CP = OFF              ; PFM and Data EEPROM Code Protection bit (PFM and Data EEPROM code protection disabled)

// config statements should precede project file includes.
#include <xc.inc>

DATA_SIZE	EQU		10

; ***** ram ************************
PSECT udata_acs						; common ram
data_work:
	DS		1
index:
	DS		1

; ***** rom ************************
PSECT data							; const data
data_rom:
	DB		1,2,3,4,5,6,7,8,9,10

; ***** eep ************************
PSECT edata							; eeprom data
data_eep:
	DB		55h,55h,55h,55h,55h,55h,55h,55h,55h,55h

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
	; eep table write (high byte)
	BANKSEL	NVMADR
	movlw	highword data_eep
	movwf	NVMADRU,b
	movlw	high data_eep
	movwf	NVMADRH,b
	; eep table write (low byte)	; (2)
	movlw	low data_eep			; (2)
	movwf	NVMADRL,b				; (2)NVMADR = data_eep;
next:
	; rom table read (low byte)
	movlw	low data_rom
	addwf	index,w,c
	movwf	TBLPTRL,c
	tblrd	*
	movff	TABLAT,data_work
	; eep table write (low byte)	; (1)
;	BANKSEL	NVMADR					; (1)
;	movlw	low data_eep			; (1)
;	addwf	index,w,c				; (1)
;	movwf	NVMADRL,b				; (1)NVMADR = data_eep + index;
	BANKSEL	NVMDAT
	movff	data_work,NVMDATL		; NVMDATL = data_work;
	BANKSEL	NVMCON1
;	movlw	03h						; (1)write
;	movwf	NVMCON1,b				; (1)NVMCON1bits.CMD = 0x03;
	movlw	04h						; (2)write and post increment 
	movwf	NVMCON1,b				; (2)NVMCON1bits.CMD = 0x04;
	bcf		GIE						; INTCON0bits.GIE = 0;
	BANKSEL	NVMLOCK
	movlw	55h
	movwf	NVMLOCK,b				; NVMLOCK = 0x55;
	movlw	0AAh
	movwf	NVMLOCK,b				; NVMLOCK = 0xAA;
;	BANKSEL	NVMCON0					; (注意)ロック解除後の命令挿入は禁止
	bsf		NVMGO					; NVMCON0bits.GO = 1;
wait:
	btfsc	NVMGO					; while (NVMCON0bits.GO);
	goto	wait
	bsf		GIE						; INTCON0bits.GIE = 1;
	BANKSEL	NVMCON1
	clrf	NVMCON1,b				; NVMCON1bits.CMD = 0;
	; next index
	incf	index,f,c
	movlw	DATA_SIZE
	cpfseq	index,c					; if(index != 10) goto next
	goto	next
loop:
	goto	$

	END		resetVec
