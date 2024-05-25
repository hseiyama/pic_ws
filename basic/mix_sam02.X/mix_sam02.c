
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

#define TRUE			(1)
#define FALSE			(0)

#define SYS_MAIN_CYCLE	(5)							// 5ms
#define TIME_STOP		(0xFFFF)
#define TIME_START		(0x0000)
#define TIME_1S			(1000 / SYS_MAIN_CYCLE)		// 1s
#define TIME_200MS		(200 / SYS_MAIN_CYCLE)		// 200ms

#define TMR0H_VALUE		(0x0B)		// Clk=16MHz(Fosc/4),Freq=1Hz,PreScale=1:256
#define TMR0L_VALUE		(0xDC)		// TMR0H/L=65536-(16MHz/1Hz)/256=3036

#define U3BRG_VALUE		(416)		// 9600bps @ 64MHz
									// U3BRGH/L=64MHz/(9600bps*16)-1=416

#define RX_BUFFER_SIZE	(8)			// Rx buffer size should be 2^n
#define RX_BUFFER_MASK	(RX_BUFFER_SIZE - 1)
#define TX_BUFFER_SIZE	(8)			// Tx buffer size should be 2^n
#define TX_BUFFER_MASK	(TX_BUFFER_SIZE - 1)

volatile uint8_t	u8_sys_counter;
volatile uint8_t	au8_rx_buffer[RX_BUFFER_SIZE];
volatile uint8_t	u8_rx_head;
volatile uint8_t	u8_rx_tail;
volatile uint8_t	u8_rx_count;
volatile uint8_t	au8_tx_buffer[TX_BUFFER_SIZE];
volatile uint8_t	u8_tx_head;
volatile uint8_t	u8_tx_tail;
volatile uint8_t	u8_tx_count;
uint16_t			u16_timer_1s;
uint16_t			u16_timer_200m;
volatile uint8_t	count_out;
uint8_t				data_adch;
uint8_t				data_adcl;
__bit				bit_flag;
__bit				bit_state;

static void setup(void);
static void uart3_init(void);
static void timer2_init(void);
static void adcc_init(void);
static void pwm1_init(void);
static void loop(void);
static void request_in(void);
static void update_out(void);
static void adcc_read(void);
static void timer_start(uint16_t *p_timer);
static void timer_stop(uint16_t *p_timer);
static uint8_t timer_check(uint16_t *p_timer, uint16_t time);
static uint8_t uart_rx_ready(void);
static uint8_t uart_tx_ready(void);
static uint8_t uart_read(void);
static void uart_send(uint8_t data);
static void echo_hex(uint8_t hex_data);
static void echo_str(char *p_data);

void __interrupt(irq(default),base(8)) DEFAULT_ISR(void) {
}

void __interrupt(irq(INT0),base(8)) INT0_ISR(void) {
	// Clear interrupt flag
	INT0IF = 0;
	// Interrupt process
	count_out++;
}

void __interrupt(irq(TMR2),base(8)) TMR2_ISR(void) {
	// Clear interrupt flag
	TMR2IF = 0;
	// Interrupt process
	u8_sys_counter++;
}

void __interrupt(irq(U3RX),base(8)) U3RX_ISR(void) {
	uint8_t data;
	// Interrupt process
	data = U3RXB;
	if (u8_rx_count < RX_BUFFER_SIZE) {
		au8_rx_buffer[u8_rx_head] = data;
		u8_rx_head = (u8_rx_head + 1) & RX_BUFFER_MASK;
		u8_rx_count++;
	}
}

void __interrupt(irq(U3TX),base(8)) U3TX_ISR(void) {
	// Interrupt process
	if (u8_tx_count > 0) {
		U3TXB = au8_tx_buffer[u8_tx_tail];
		u8_tx_tail = (u8_tx_tail + 1) & TX_BUFFER_MASK;
		u8_tx_count--;
	}
	else {
		U3TXIE = 0;
	}
}

void main(void) {
	setup();

	while (TRUE) {
		if (u8_sys_counter >= SYS_MAIN_CYCLE) {
			u8_sys_counter = 0;
			loop();
		}
	}
}

static void setup(void) {
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

	// UART3 Initialize
	uart3_init();
	// TIMER2 Initialize
	timer2_init();
	// ADCC Initialize
	adcc_init();
	// PWM1 Initialize
	pwm1_init();

	// Initialize variant
	u8_sys_counter = 0;
	count_out = 0x00;
	data_adch = 0x00;
	data_adcl = 0x00;
	bit_flag = 0;
	bit_state = 1;

	// Global interrupt
	GIE = 1;						// Global interrupt enable

	// start timer_1s
	timer_start(&u16_timer_1s);
	// start timer_200ms
	timer_start(&u16_timer_200m);
}

static void uart3_init(void) {
	// UART3 Initialize
	U3BRG = U3BRG_VALUE;			// UART baud rate generator
	U3RXEN = 1;						// Receiver enable
	U3TXEN = 1;						// Transmitter enable
	// UART3 Receiver
	ANSELA7 = 0;					// Disable analog function
	TRISA7 = 1;						// RX set as input
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
	u8_rx_head = 0;
	u8_rx_tail = 0;
	u8_rx_count = 0;
	u8_tx_head = 0;
	u8_tx_tail = 0;
	u8_tx_count = 0;
}

static void timer2_init(void){
	// TCS FOSC/4;
	T2CLKCON = 0x1;
	// TMODE Software control; TCKSYNC Not Synchronized;
	// TCKPOL Rising Edge; TPSYNC Not Synchronized;
	T2HLT = 0x0;
	// TRSEL T2CKIPPS pin;
	T2RST = 0x0;
	// PR 124 (=(64Mz/4)/(1Kz*128)-1);
	T2PR = 0x7C;
	// TMR 0x0;
	T2TMR = 0x0;
	// Clearing IF flag before enabling the interrupt.
	PIR3bits.TMR2IF = 0;
	// Enabling TMR2 interrupt.
	PIE3bits.TMR2IE = 1;
	// TCKPS 1:128; TMRON on; TOUTPS 1:1;
	T2CON = 0xF0;
}

static void adcc_init(void) {
	// ADCC Initialize
	ADCON0bits.FM = 1;				// right justify
	ADCON0bits.CS = 1;				// ADCRC Clock
	ADPCH = 0x0C;					// RB4 is Analog channel
	TRISB4 = 1;						// Set RB4 to input
	ANSELB4 = 1;					// Set RB4 to analog
	ADCON0bits.ON = 1;				// Turn ADC On
}

static void pwm1_init(void) {
    // PPS registers
	TRISC0 = 0;						// PWM11 set as output
	TRISC1 = 0;						// PWM12 set as output
	RC0PPS = 0x18;					// RC0->PWM1_16BIT:PWM11;
	RC1PPS = 0x19;					// RC1->PWM1_16BIT:PWM12;

	// PWMERS External Reset Disabled;
	PWM1ERS = 0x0;
	// PWMCLK FOSC;
	PWM1CLK = 0x2;
	// PWMLDS Autoload disabled;
	PWM1LDS = 0x0;
	// PWMPRL 63;
	PWM1PRL = 0x3F;
	// PWMPRH 6;
	PWM1PRH = 0x6;
	// PWMCPRE Prescale by 4;
	PWM1CPRE = 0x3;
	// PWMPIPOS No postscale;
	PWM1PIPOS = 0x0;
	// PWMS1P1IF PWM1 output match did not occur; PWMS1P2IF PWM2 output match did not occur;
	PWM1GIR = 0x0;
	// PWMS1P1IE disabled; PWMS1P2IE disabled;
	PWM1GIE = 0x0;
	// PWMPOL1 disabled; PWMPOL2 disabled; PWMPPEN disabled; PWMMODE Left aligned mode;
	PWM1S1CFG = 0x0;
	// PWMS1P1L 96;
	PWM1S1P1L = 0x20;
	// PWMS1P1H 4;
	PWM1S1P1H = 0x3;
	// PWMS1P2L 224;
	PWM1S1P2L = 0x40;
	// PWMS1P2H 1;
	PWM1S1P2H = 0x0;
	// Clear PWM1_16BIT period interrupt flag
	PIR4bits.PWM1PIF = 0;
	// Clear PWM1_16BIT interrupt flag
	PIR4bits.PWM1IF = 0;
	// Clear PWM1_16BIT slice 1, output 1 interrupt flag
	PWM1GIRbits.S1P1IF = 0;
	// Clear PWM1_16BIT slice 1, output 2 interrupt flag
	PWM1GIRbits.S1P2IF = 0;
	// PWM1_16BIT interrupt enable bit
	PIE4bits.PWM1IE = 0;
	// PWM1_16BIT period interrupt enable bit
	PIE4bits.PWM1PIE = 0;
	// PWMEN enabled; PWMLD disabled; PWMERSPOL disabled; PWMERSNOW disabled;
	PWM1CON = 0x80;
}

static void loop(void) {
	uint8_t chk_val;
	// check timer_1s
	chk_val = timer_check(&u16_timer_1s, TIME_1S);
	if (chk_val) {
		count_out++;
		adcc_read();
		echo_hex(data_adch);
		echo_hex(data_adcl);
		echo_str("\r\n");
		// PWMS1P2
		PWM1S1P2L = data_adcl;
		PWM1S1P2H = data_adch;
		// Load the period and duty cycle registers on the next period event
		PWM1CONbits.LD = 1;
		// start timer_1s
		timer_start(&u16_timer_1s);
	}
	// check timer_200ms
	chk_val = timer_check(&u16_timer_200m, TIME_200MS);
	if (chk_val) {
		bit_flag = 1;
		// start timer_200ms
		timer_start(&u16_timer_200m);
	}
	request_in();
	update_out();
}

static void request_in(void) {
	uint8_t data_recv;
	data_recv = uart_read();
	switch (data_recv) {
	case 'r':						// Judge Reset
		// Reset
		Reset();
		break;
	case 's':						// Judge Sleep
		// Sleep
		Sleep();
		break;
	case 'z':						// Judge Zero
		count_out = 0x00;
		break;
	case 'u':						// Judge Uart
		bit_state = !bit_state;
		break;
	default:
		break;
	}
}

static void update_out(void) {
	// LED output
	LATA = count_out & 0x0F;
	// UART output
	if (bit_flag == 1) {
		if (bit_state == 1) {
			uart_send('+');
		}
		bit_flag = 0;
	}
}

static void adcc_read(void) {
	ADCON0bits.GO = 1;				// Start conversion
	while (ADCON0bits.GO == 1);		// Wait for conversion done (about 42us)
	data_adch = ADRESH;				// Read result
	data_adcl = ADRESL;				// Read result
}

static void timer_start(uint16_t *p_timer) {
	*p_timer = TIME_START;
}

static void timer_stop(uint16_t *p_timer) {
	*p_timer = TIME_STOP;
}

static uint8_t timer_check(uint16_t *p_timer, uint16_t time) {
	uint8_t ret_val = FALSE;
	if (*p_timer == TIME_STOP) {
		// Do nothing
	} else {
		(*p_timer)++;
		if (*p_timer >= time) {
			*p_timer = TIME_STOP;
			ret_val = TRUE;
		}
	}
	return ret_val;
}

static uint8_t uart_rx_ready(void) {
	return ((u8_rx_count > 0) ? TRUE : FALSE);
}

static uint8_t uart_tx_ready(void) {
	return ((u8_tx_count < TX_BUFFER_SIZE) ? TRUE : FALSE);
}

static uint8_t uart_read(void) {
	uint8_t data = 0x00;
	if (u8_rx_count > 0) {
		data = au8_rx_buffer[u8_rx_tail];
		u8_rx_tail = (u8_rx_tail + 1) & RX_BUFFER_MASK;
		U3RXIE = 0;					// Critical value decrement
		u8_rx_count--;
		U3RXIE = 1;
	}
	return data;
}

static void uart_send(uint8_t data) {
	if (u8_tx_count < TX_BUFFER_SIZE) {
		au8_tx_buffer[u8_tx_head] = data;
		u8_tx_head = (u8_tx_head + 1) & TX_BUFFER_MASK;
		U3TXIE = 0;					// Critical value increment
		u8_tx_count++;
	}
	U3TXIE = 1;
}

static void echo_hex(uint8_t hex_data) {
	static const uint8_t hex_table[] = {
		'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
	};
	uart_send(hex_table[(hex_data >> 4) & 0x0F]);
	uart_send(hex_table[hex_data & 0x0F]);
}

static void echo_str(char *p_data) {
	while (*p_data != 0x00) {
		uart_send(*p_data);
		p_data++;
	}
}
