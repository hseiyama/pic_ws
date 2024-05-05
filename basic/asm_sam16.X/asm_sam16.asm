
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

#define IPEN	BANKMASK(INTCON0),5,c

U3BRGH_VALUE	EQU		01h			; 9600bps @ 64MHz
U3BRGL_VALUE	EQU		0A0h		; U3BRGH/L=64MHz/(9600bps*16)-1=416

; ***** ram ************************
PSECT udata_acs
data_recv:
	DS		1

PSECT bitBss,bit,class=COMRAM,space=1
bit_flag:
	DS		1

; ***** vector *********************
PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto    main

PSECT ivecTbl,class=CODE,reloc=2,ovrld
ivecTbl:
	ORG		8h*2					; interrupt0 vector position
	DW		int0Isr shr 2
	ORG		30h*2					; interrupt1 vector position
	DW		int1Isr shr 2
	ORG		48h*2					; uart3rx vector position
	DW		u3rxIsr shr 2
	ORG		50h*2					; interrupt2 vector position
	DW		int2Isr shr 2

; ***** ISR ************************
PSECT textISR,class=CODE,reloc=4
int0Isr:
	bcf		INT0IF					; Clear interrupt flag
	; interrupt process
	; (疑問)シミュレータ動作ではWREGとWREG_SHADが連動して変更される
	;       ⇒変更された値で復帰する。
	;       ⇒(結果)ソース変更後は正常に動作。
	; (疑問)シミュレータ動作ではSHADLO=0(MainContext),1(LowContext)となる
	;       ⇒DataSheetの記載と差異がある。
	;       ⇒(結論)これはDataSheetの誤記。
	call	send_arrow
	call	send_shad
	movlw	'0'
	call	send_wreg
	bsf		bit_flag/8,bit_flag&7,c
	retfie	f

	ALIGN	4
int1Isr:
	bcf		INT1IF					; Clear interrupt flag
	; interrupt process
	call	send_arrow
	call	send_shad
	movlw	'1'
	call	send_wreg
	bsf		INT2IF					; Set interrupt flag
	nop
	nop
	call	send_wreg
	bsf		bit_flag/8,bit_flag&7,c
	retfie	f

	ALIGN	4
u3rxIsr:
	; interrupt process
	movff	U3RXB,data_recv
	retfie	f

	ALIGN	4
int2Isr:
	bcf		INT2IF					; Clear interrupt flag
	; interrupt process
	call	send_arrow
	call	send_shad
	movlw	'2'
	call	send_wreg
	bsf		bit_flag/8,bit_flag&7,c
	retfie	f

; ***** main ***********************
PSECT code
main:
	; System initialize
	BANKSEL	OSCFRQ
	movlw	08h
	movwf	OSCFRQ,b				; 64MHz internal OSC

	; RB0(INT0) input pin
	BANKSEL	ANSELB
	bcf		ANSELB0					; Disable analog function
	BANKSEL	WPUB
	bsf		WPUB0					; Week pull up
	bsf		TRISB0					; Set as intput
	BANKSEL	IPR1
	bcf		INT0IP					; Set Interrupt Priority as Low
	bcf		INT0EDG					; INT0 external interrupt falling edge
	bcf		INT0IF					; Clear INT0 external interrupt flag
	bsf		INT0IE					; INT0 external interrupt enable

	; RB1(INT1) input pin
	BANKSEL	ANSELB
	bcf		ANSELB1					; Disable analog function
	BANKSEL	WPUB
	bsf		WPUB1					; Week pull up
	bsf		TRISB1					; Set as intput
	BANKSEL	IPR6
	bcf		INT1IP					; Set Interrupt Priority as Low
	bcf		INT1EDG					; INT1 external interrupt falling edge
	bcf		INT1IF					; Clear INT1 external interrupt flag
	bsf		INT1IE					; INT1 external interrupt enable

	; RB2(INT2) input pin
	BANKSEL	ANSELB
	bcf		ANSELB2					; Disable analog function
	BANKSEL	WPUB
	bsf		WPUB2					; Week pull up
	bsf		TRISB2					; Set as intput
	BANKSEL	IPR10
	bsf		INT2IP					; Set Interrupt Priority as High
	bcf		INT2EDG					; INT2 external interrupt falling edge
	bcf		INT2IF					; Clear INT2 external interrupt flag
	bsf		INT2IE					; INT2 external interrupt enable

	; UART3 Initialize
	BANKSEL	U3BRG
	movlw	U3BRGH_VALUE
	movwf	U3BRGH,b
	movlw	U3BRGL_VALUE
	movwf	U3BRGL,b				; UART baud rate generator
	BANKSEL	U3CON0
	bsf		U3RXEN					; Receiver enable
	bsf		U3TXEN					; Transmitter enable
	; UART3 Receiver
	BANKSEL	ANSELA
	bcf		ANSELA7					; Disable analog function
	bsf		TRISA7					; RX set as input
	BANKSEL	U3RXPPS
	movlw	07h
	movwf	U3RXPPS,b				; RA7->UART3:RX3
	; UART3 Transmitter
	BANKSEL	ANSELA
	bcf		ANSELA6					; Disable analog function
	bsf		LATA6					; Default level
	bcf		TRISA6					; TX set as output
	BANKSEL	RA6PPS
	movlw	26h
	movwf	RA6PPS,b				; RA6->UART3:TX3
	; UART3 Enable
	BANKSEL	U3CON1
	bsf		U3ON					; Serial port enable
	bsf		U3RXIE					; Enable Receive interrupt

	; WREG_SHAD Initialize
	BANKSEL	SHADCON
	bcf		SHADLO
	movlw	'A'
	movwf	WREG_SHAD,b				; Main context
	bsf		SHADLO
	movlw	'B'
	movwf	WREG_SHAD,b				; Low context

	; Initialize variant
	clrf	data_recv,c
	bcf		bit_flag/8,bit_flag&7,c

	; Interrupt Priority(IPEN)
	bsf		IPEN					; Interrupt priority enable
	; Global interrupt(GIE)
	bsf		GIEH					; Global high-priority interrupt enable
	bsf		GIEL					; Global low-priority interrupt enable

	movlw	'm'
loop:
	bcf		GIE						; Global interrupt disable
	btfss	bit_flag/8,bit_flag&7,c
	goto	next_flag
	call	send_wreg
	bcf		bit_flag/8,bit_flag&7,c
next_flag:
	bsf		GIE						; Global interrupt enable
	goto	loop

; ***** send_wreg ******************
PSECT code
send_wreg:
	btfss	U3TXIF
	goto	send_wreg
	BANKSEL	U3TXB
	movwf	U3TXB,b
	return

; ***** send_shad ******************
PSECT code
send_shad:
	movlw	'('
	call	send_wreg
	BANKSEL	SHADCON
	bcf		SHADLO
	movf	WREG_SHAD,w,b			; Main context
	call	send_wreg
	movlw	','
	call	send_wreg
	BANKSEL	SHADCON
	bsf		SHADLO
	movf	WREG_SHAD,w,b			; Low context
	call	send_wreg
	movlw	')'
	call	send_wreg
	return

; ***** send_arrow *****************
PSECT code
send_arrow:
	movlw	'-'
	call	send_wreg
	movlw	'>'
	call	send_wreg
	return

	END		resetVec
