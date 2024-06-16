
#include <xc.h>
#include "types.h"
#include "system.h"
#include "uart3.h"

#define TIME_1S			(1000 / SYS_MAIN_CYCLE)		// 1s
#define TIME_200MS		(200 / SYS_MAIN_CYCLE)		// 200ms

const uint8_t acu8_msg_reset[] = "Status is RESET.\r\n";
const uint8_t acu8_msg_awake[] = "Status is AWAKE.\r\n";

uint16_t			u16_timer_1s;
uint16_t			u16_timer_200m;
volatile uint8_t	u8_count_out;
__bit				bit_event_1s;
__bit				bit_event_200ms;
__bit				bit_state_uart;

static void request_in(void);
static void update_out(void);
static void print_vale(uint16_t data, char *p_msg);

void setup(void) {
	// RC0-RC3 input pin
	// RC4-RC7 output pin
	ANSELC = 0x00;					// Disable analog function
	WPUC = 0x0F;					// Week pull up
	LATC = 0x00;					// Set low level
	TRISC = 0x0F;					// Set as output

	// UART3 Initialize
	UART3_Initialize();

	// Initialize variant
	u8_count_out = 0x00;
	bit_event_1s = 0;
	bit_event_200ms = 0;
	bit_state_uart = 1;

	// Global interrupt
	GIE = 1;						// Global interrupt enable

	// Message
	EchoStr((char *)&acu8_msg_reset[0]);

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
		bit_event_1s = 1;
		// start timer_1s
		TimerStart(&u16_timer_1s);
	}
	// check timer_200ms
	chk_val = TimerCheck(&u16_timer_200m, TIME_200MS);
	if (chk_val) {
		bit_event_200ms = 1;
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
	case 'p':						// Judge Port
		LATC = (~PORTC << 4) & 0xF0;
		break;
	case 's':						// Judge Sleep
		// Sleep
		Sleep();
		// Message
		EchoStr((char *)&acu8_msg_awake[0]);
		break;
	case 'u':						// Judge Uart
		bit_state_uart = !bit_state_uart;
		break;
	case 'w':						// Judge aWake
		// Message
		EchoStr((char *)&acu8_msg_awake[0]);
		break;
	case 'z':						// Judge Zero
		u8_count_out = 0xFF;
		bit_event_1s = 1;
		break;
	default:
		break;
	}
}

static void update_out(void) {
	// LED output
	if (bit_event_1s == 1) {
		u8_count_out++;
		LATC = (u8_count_out << 4) & 0xF0;
		bit_event_1s = 0;
	}
	// UART output
	if (bit_event_200ms == 1) {
		if (bit_state_uart == 1) {
			UART3_Write('+');
		}
		bit_event_200ms = 0;
	}
}

static void print_vale(uint16_t data, char *p_msg) {
	EchoStr("\r\n");
	EchoHex((data >> 8) & 0xFF);
	EchoHex(data & 0xFF);
	EchoStr(p_msg);
}
