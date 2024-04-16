
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

TMR0H_VALUE		EQU		0Bh			; Clk=16MHz(Fosc/4),Freq=1Hz,PreScale=1:256
TMR0L_VALUE		EQU		0DCh		; TMR0H/L=65536-(16MHz/1Hz)/256=3036

U3BRGH_VALUE	EQU		01h			; 9600bps @ 64MHz
U3BRGL_VALUE	EQU		0A0h		; U3BRGH/L=416

; ***** ram ************************
PSECT bitBss,bit,class=COMRAM,space=1
led_state:
	DS		1

PSECT udata_acs
count_a:
	DS		1
data_uart:
	DS		1

; ***** vector *********************
PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto    main

PSECT ivecTbl,class=CODE,reloc=2,ovrld
ivecTbl:
	ORG		8h*2					;interrupt0 vector position
	DW		int0Isr shr 2			;interrupt0 ISR address shifted right
	ORG		1Fh*2					;timer0 vector position
	DW		tmr0Isr shr 2			;timer0 ISR address shifted right
	ORG		48h*2					;uart3rx vector position
	DW		u3rxIsr shr 2			;uart3rx ISR address shifted right

; ***** ISR ************************
PSECT textISR,class=CODE,reloc=4
int0Isr:
	bcf		INT0IF					; Clear interrupt flag
	; interrupt process
	incf	count_a,f,c
	btg		led_state/8,led_state&7,c
	retfie

	ALIGN	4
tmr0Isr:
	bcf		TMR0IF					; Clear interrupt flag
	; interrupt process
	incf	count_a,f,c
	btg		led_state/8,led_state&7,c
	; set timer0
	BANKSEL	TMR0H
	movlw	TMR0H_VALUE
	movwf	TMR0H,b
	BANKSEL	TMR0L
	movlw	220
	movwf	TMR0L,b
	retfie

	ALIGN	4
u3rxIsr:
	movff	U3RXB,data_uart
	btfsc	U3TXIF
	movff	data_uart,U3TXB
	retfie

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
	bcf		INT0EDG					; INT0 external interrupt falling edge
	bcf		INT0IF					; Clear INT0 external interrupt flag
	bsf		INT0IE					; INT0 external interrupt enable

	; RA0-RA03 output pin
	BANKSEL	ANSELA
	movlw	0F0h
	movwf	ANSELA,b				; Disable analog function
	clrf	LATA,c					; Set low level
	movlw	0F0h
	movwf	TRISA,c					; Set as output

	; Timer0(interval 1s) setup
	BANKSEL	T0CON0
	movlw	90h
	movwf	T0CON0,b				; timer enable, 16bit timer, 1:1 Postscaler
	BANKSEL	T0CON1
	movlw	48h
	movwf	T0CON1,b				; sorce clk:FOSC/4, 1:256 Prescaler
	BANKSEL	TMR0H
	movlw	TMR0H_VALUE
	movwf	TMR0H,b
	BANKSEL	TMR0L
	movlw	TMR0L_VALUE				; timer0 count register
	movwf	TMR0L,b
	bcf		TMR0IF					; Clear TMR0 timer interrupt flag
	bsf		TMR0IE					; TMR0 timer interrupt enable

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

	; Initialize variant
	clrf	count_a,c
	bcf		led_state/8,led_state&7,c

	; Global interrupt
	bsf		GIE						; Global interrupt enable
loop:
	call	update
	goto	loop

update:
	bcf		GIE						; Global interrupt disable
	movlw	0Fh
	andwf	count_a,w,c
	movwf	LATA,c
	bsf		GIE						; Global interrupt enable
	return

	END		resetVec
