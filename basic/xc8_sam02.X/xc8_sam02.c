
// PIC18F47Q43 Configuration Bit Settings

// 'C' source line config statements

// CONFIG1
#pragma config FEXTOSC = OFF    // External Oscillator Selection (Oscillator not enabled)
#pragma config RSTOSC = HFINTOSC_64MHZ// Reset Oscillator Selection (HFINTOSC with HFFRQ = 64 MHz and CDIV = 1:1)

// CONFIG2
#pragma config CLKOUTEN = OFF   // Clock out Enable bit (CLKOUT function is disabled)
#pragma config PR1WAY = ON      // PRLOCKED One-Way Set Enable bit (PRLOCKED bit can be cleared and set only once)
#pragma config CSWEN = ON       // Clock Switch Enable bit (Writing to NOSC and NDIV is allowed)
#pragma config FCMEN = ON       // Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor enabled)

// CONFIG3
#pragma config MCLRE = EXTMCLR  // MCLR Enable bit (If LVP = 0, MCLR pin is MCLR; If LVP = 1, RE3 pin function is MCLR )
#pragma config PWRTS = PWRT_OFF // Power-up timer selection bits (PWRT is disabled)
#pragma config MVECEN = ON      // Multi-vector enable bit (Multi-vector enabled, Vector table used for interrupts)
#pragma config IVT1WAY = ON     // IVTLOCK bit One-way set enable bit (IVTLOCKED bit can be cleared and set only once)
#pragma config LPBOREN = OFF    // Low Power BOR Enable bit (Low-Power BOR disabled)
#pragma config BOREN = SBORDIS  // Brown-out Reset Enable bits (Brown-out Reset enabled , SBOREN bit is ignored)

// CONFIG4
#pragma config BORV = VBOR_1P9  // Brown-out Reset Voltage Selection bits (Brown-out Reset Voltage (VBOR) set to 1.9V)
#pragma config ZCD = OFF        // ZCD Disable bit (ZCD module is disabled. ZCD can be enabled by setting the ZCDSEN bit of ZCDCON)
#pragma config PPS1WAY = OFF    // PPSLOCK bit One-Way Set Enable bit (PPSLOCKED bit can be set and cleared repeatedly (subject to the unlock sequence))
#pragma config STVREN = ON      // Stack Full/Underflow Reset Enable bit (Stack full/underflow will cause Reset)
#pragma config LVP = ON         // Low Voltage Programming Enable bit (Low voltage programming enabled. MCLR/VPP pin function is MCLR. MCLRE configuration bit is ignored)
#pragma config XINST = OFF      // Extended Instruction Set Enable bit (Extended Instruction Set and Indexed Addressing Mode disabled)

// CONFIG5
#pragma config WDTCPS = WDTCPS_31// WDT Period selection bits (Divider ratio 1:65536; software control of WDTPS)
#pragma config WDTE = OFF       // WDT operating mode (WDT Disabled; SWDTEN is ignored)

// CONFIG6
#pragma config WDTCWS = WDTCWS_7// WDT Window Select bits (window always open (100%); software control; keyed access not required)
#pragma config WDTCCS = SC      // WDT input clock selector (Software Control)

// CONFIG7
#pragma config BBSIZE = BBSIZE_512// Boot Block Size selection bits (Boot Block size is 512 words)
#pragma config BBEN = OFF       // Boot Block enable bit (Boot block disabled)
#pragma config SAFEN = OFF      // Storage Area Flash enable bit (SAF disabled)
#pragma config DEBUG = OFF      // Background Debugger (Background Debugger disabled)

// CONFIG8
#pragma config WRTB = OFF       // Boot Block Write Protection bit (Boot Block not Write protected)
#pragma config WRTC = OFF       // Configuration Register Write Protection bit (Configuration registers not Write protected)
#pragma config WRTD = OFF       // Data EEPROM Write Protection bit (Data EEPROM not Write protected)
#pragma config WRTSAF = OFF     // SAF Write protection bit (SAF not Write Protected)
#pragma config WRTAPP = OFF     // Application Block write protection bit (Application Block not write protected)

// CONFIG10
#pragma config CP = OFF         // PFM and Data EEPROM Code Protection bit (PFM and Data EEPROM code protection disabled)

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

#include <xc.h>

#define TRUE	(1)
#define FALSE	(0)

#define TMR0H_VALUE		(0x0B)		// Clk=16MHz(Fosc/4),Freq=1Hz,PreScale=1:256
#define TMR0L_VALUE		(0xDC)		// TMR0H/L=65536-(16MHz/1Hz)/256=3036

#define U3BRG_VALUE		(416)		// 9600bps @ 64MHz
									// U3BRGH/L=64MHz/(9600bps*16)-1=416

volatile __bit		led_state;
volatile uint8_t	count_a;
volatile uint8_t	data_uart;

static void update(void);


void __interrupt(irq(default),base(8)) defaultIsr() {
}

void __interrupt(irq(INT0),base(8)) int0Isr() {
	INT0IF = 0;						// Clear interrupt flag
	// interrupt process
	count_a++;
	led_state = !led_state;
}

void __interrupt(irq(TMR0),base(8)) tmr0Isr() {
	TMR0IF = 0;						// Clear interrupt flag
	// interrupt process
	count_a++;
	led_state = !led_state;
	// set timer0
	TMR0H = TMR0H_VALUE;
	TMR0L = TMR0L_VALUE;
}

void __interrupt(irq(U3RX),base(8)) u3rxIsr() {
	data_uart = U3RXB;
	if (U3TXIF == 1) {
		U3TXB = data_uart;
	}
}

void main(void) {
	// System initialize
	OSCFRQ = 0x08;					// 64MHz internal OSC

	// RB0(INT0) input pin
	ANSELB0 = 0;					// Disable analog function
	WPUB0 = 1;						// Week pull up
	TRISB0 = 1;						// Set as intput
	INT0EDG = 0;					// INT0 external interrupt falling edge
	INT0IF = 0;						// Clear INT0 external interrupt flag
	INT0IE = 1;						// INT0 external interrupt enable

	// RA0-RA03 output pin
	ANSELA = 0xF0;					// Disable analog function
	LATA = 0x00;					// Set low level
	TRISA = 0xF0;					// Set as output

	// Timer0(interval 1s) setup
	T0CON0 = 0x90;					// timer enable, 16bit timer, 1:1 Postscaler
	T0CON1 = 0x48;					// sorce clk:FOSC/4, 1:256 Prescaler
	TMR0H = TMR0H_VALUE;
	TMR0L = TMR0L_VALUE;			// timer0 count register
	TMR0IF = 0;						// Clear TMR0 timer interrupt flag
	TMR0IE = 1;						// TMR0 timer interrupt enable

	// UART3 Initialize
	U3BRG = U3BRG_VALUE;			// UART baud rate generator
	U3RXEN = 1;						// Receiver enable
	U3TXEN = 1;						// Transmitter enable
	// UART3 Receiver
	ANSELA7 = 0;					// Disable analog function
	TRISA7	= 1;					// RX set as input
	U3RXPPS = 0x07;					// RA7->UART3:RX3
	// UART3 Transmitter
	ANSELA6 = 0;					// Disable analog function
	LATA6 = 1;						// Default level
	TRISA6 = 0;						// TX set as output
	RA6PPS = 0x26;					// RA6->UART3:TX3
	// UART3 Enable
	U3ON = 1;						// Serial port enable
	U3RXIE = 1;						// Enable Receive interrupt

	// Initialize variant
	count_a = 0x00;
	led_state = 0;

	// Global interrupt
	GIE = 1;						// Global interrupt enable

	while (TRUE) {
		update();
	}
}

static void update(void) {
	GIE = 0;						// Global interrupt disable
	LATA = count_a & 0x0F;
	GIE = 1;						// Global interrupt enable
}
