
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

#define SIZE_RESET		(sizeof(data_reset) - 1)
#define SIZE_WAKEUP		(sizeof(data_wakeup) - 1)

const uint8_t data_reset[] = "Status is RESET.\r\n";
const uint8_t data_wakeup[] = "Status is WAKEUP.\r\n";

asm("psect eeprom_data");
asm("_data_eep: DB 0,0");
extern const uint8_t data_eep[];

volatile uint8_t	count_out;
volatile uint8_t	data_recv;
volatile uint8_t	data_send;
volatile __bit		bit_flag;
__bit				bit_state;

static void timer0_init(void);
static void uart3_init(void);
static void dma1_init(void);
static void dma1_wakeup(void);
static void request_in(void);
static void update_out(void);
static uint8_t eep_read(uint8_t addr);
static void eep_write(uint8_t addr, uint8_t data);

void __interrupt(irq(default),base(8)) defaultIsr() {
}

void __interrupt(irq(INT0),base(8)) int0Isr() {
	INT0IF = 0;						// Clear interrupt flag
	// interrupt process
	count_out++;
}

void __interrupt(irq(TMR0),base(8)) tmr0Isr() {
	TMR0IF = 0;						// Clear interrupt flag
	// interrupt process
	count_out++;
	bit_flag = 1;
	// set timer0
	TMR0H = TMR0H_VALUE;
	TMR0L = TMR0L_VALUE;
}

void __interrupt(irq(U3RX),base(8)) u3rxIsr() {
	// interrupt process
	data_recv = U3RXB;
}

void __interrupt(irq(U3TX),base(8)) u3txIsr() {
	// interrupt process
	data_send++;
	U3TXB = data_send;				// Not used Instruction
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

	// Timer0 Initialize
	timer0_init();
	// UART3 Initialize
	uart3_init();
	// DMA1 Initialize
	dma1_init();

	// Read eeprom(count_out)
	count_out = eep_read(0);
	// Read eeprom(bit_state)
	bit_state = (__bit)eep_read(1);

	// Initialize variant
	data_recv = 0x00;
	data_send = 0x00;
	bit_flag = 0;

	// Global interrupt
	GIE = 1;						// Global interrupt enable

	while (TRUE) {
		request_in();
		update_out();
	}
}

static void timer0_init(void) {
	// Timer0(interval 1s) setup
	T0CON0 = 0x90;					// timer enable, 16bit timer, 1:1 Postscaler
	T0CON1 = 0x48;					// sorce clk:FOSC/4, 1:256 Prescaler
	TMR0H = TMR0H_VALUE;
	TMR0L = TMR0L_VALUE;			// timer0 count register
	TMR0IF = 0;						// Clear TMR0 timer interrupt flag
	TMR0IE = 1;						// TMR0 timer interrupt enable
}

static void uart3_init(void) {
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
	// (情報)DMA転送のトリガに割込み許可は不要
//	U3TXIE = 1;						// Enable Transmit interrupt
}

static void dma1_init(void) {
	// Select DMA1 by setting DMASELECT register to 0x00
	DMASELECT = 0x00;
	// DMAnCON1 - DPTR remains, DSTP=0, Source Memory Region PFM,
	//            SPTR increments, SSTP=1,
	DMAnCON1 = 0x0B;
	// Source registers
	// Source size
	DMAnSSZ = SIZE_RESET;
	// Source start address, data_reset
	DMAnSSA = (volatile __uint24)&data_reset;
	// Destination registers
	// Destination size
	DMAnDSZ = 1;
	// Destination start address, U3TXB
	DMAnDSA = (volatile uint16_t)&U3TXB;
	// Start trigger source U3TX
	DMAnSIRQ = 0x49;
	// Change arbiter priority
	// (注意)PFMアクセスはシステム調停が必要(DMA1>MAIN)
	DMA1PR = 0x01;
	PRLOCK = 0x55;
	PRLOCK = 0xAA;
	PRLOCKbits.PRLOCKED = 1;
	// Enable the DMA & the trigger to start DMA transfer
	DMAnCON0 = 0xC0;
}

static void request_in(void) {
	// Judge Reset
	if (data_recv == 'r') {
		// Reset
		asm("reset");
	}
	// Judge Sleep
	if (data_recv == 's') {
		TMR0IE = 0;					// TMR0 timer interrupt disable
		TMR0IF = 0;					// Clear TMR0 timer interrupt flag
		// Write eeprom(count_out)
		eep_write(0, count_out);
		// Write eeprom(bit_state)
		eep_write(1, bit_state);
		// Sleep
		asm("sleep");
		TMR0IE = 1;					// TMR0 timer interrupt enable
		dma1_wakeup();
		data_recv = 0x00;
	}
	// Judge Wakeup
	if (data_recv == 'w') {
		dma1_wakeup();
		data_recv = 0x00;
	}
	// Judge Zero
	if (data_recv == 'z') {
		count_out = 0x00;
		data_recv = 0x00;
	}
	// Judge Uart
	if (data_recv == 'u') {
		bit_state = !bit_state;
		data_recv = 0x00;
	}
}

static void dma1_wakeup(void) {
	// Select DMA1 by setting DMASELECT register to 0x00
	DMASELECT = 0x00;
	// Disable the DMA
	// (注意)DMA設定の変更はDMA無効時に実施
	DMAnCON0 = 0x00;
	// Source registers
	// Source size
	DMAnSSZ = SIZE_WAKEUP;
	// Source start address, data_wakeup
	DMAnSSA = (volatile __uint24)&data_wakeup;
	// Enable the DMA & the trigger to start DMA transfer
	DMAnCON0 = 0xC0;
}

static void update_out(void) {
	// LED output
	LATA = count_out & 0x0F;
	// UART output
	if (bit_flag == 1) {
		if ((bit_state == 1) && (U3TXIF == 1)) {
			U3TXB = '+';
		}
		bit_flag = 0;
	}
}

static uint8_t eep_read(uint8_t addr) {
	NVMADR = (__uint24)(&data_eep[0] + addr);
	NVMCON1bits.CMD = 0x00;			// Read
	NVMCON0bits.GO = 1;
	while (NVMCON0bits.GO);
	return NVMDATL;
}

static void eep_write(uint8_t addr, uint8_t data) {
	NVMADR = (__uint24)(&data_eep[0] + addr);
	NVMDATL = data;
	NVMCON1bits.CMD = 0x03;			// Write
	GIE = 0;						// Global interrupt disable
	NVMLOCK = 0x55;
	NVMLOCK = 0xAA;
	NVMCON0bits.GO = 1;
	while (NVMCON0bits.GO);
	GIE = 1;						// Global interrupt enable
	NVMCON1bits.CMD = 0;
}
