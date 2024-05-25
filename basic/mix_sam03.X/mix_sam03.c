
#include <xc.h>
#include "types.h"
#include "system.h"
#include "uart3.h"
#include "adcc.h"
#include "pwm1.h"

#define TIME_1S			(1000 / SYS_MAIN_CYCLE)		// 1s
#define TIME_200MS		(200 / SYS_MAIN_CYCLE)		// 200ms

uint16_t			u16_timer_1s;
uint16_t			u16_timer_200m;
volatile uint8_t	u8_count_out;
uint16_t			u16_data_adcc;
__bit				bit_flag;
__bit				bit_state;

static void request_in(void);
static void update_out(void);

void __interrupt(irq(INT0),base(8)) INT0_ISR(void) {
	// Clear interrupt flag
	INT0IF = 0;
	// Interrupt process
	u8_count_out++;
}

void setup(void) {
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
	UART3_Initialize();
	// ADCC Initialize
	ADCC_Initialize();
	// PWM1 Initialize
	PWM1_Initialize();

	// Initialize variant
	u8_count_out = 0x00;
	u16_data_adcc = 0x0000;
	bit_flag = 0;
	bit_state = 1;

	// Global interrupt
	GIE = 1;						// Global interrupt enable

	// start timer_1s
	TimerStart(&u16_timer_1s);
	// start timer_200ms
	TimerStart(&u16_timer_200m);
}

void loop(void) {
	uint8_t chk_val;
	// check timer_1s
	chk_val = TimerCheck(&u16_timer_1s, TIME_1S);
	if (chk_val) {
		u8_count_out++;
		u16_data_adcc = ADCC_GetSingleConversion();
		EchoHex(u16_data_adcc >> 8);
		EchoHex(u16_data_adcc & 0xFF);
		EchoStr("\r\n");
		PWM1_SetSlice1Output2DutyCycleRegister(u16_data_adcc);
		PWM1_LoadBufferRegisters();
		// start timer_1s
		TimerStart(&u16_timer_1s);
	}
	// check timer_200ms
	chk_val = TimerCheck(&u16_timer_200m, TIME_200MS);
	if (chk_val) {
		bit_flag = 1;
		// start timer_200ms
		TimerStart(&u16_timer_200m);
	}
	request_in();
	update_out();
}

static void request_in(void) {
	uint8_t data_recv;
	data_recv = UART3_Read();
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
		u8_count_out = 0x00;
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
	LATA = u8_count_out & 0x0F;
	// UART output
	if (bit_flag == 1) {
		if (bit_state == 1) {
			UART3_Write('+');
		}
		bit_flag = 0;
	}
}
