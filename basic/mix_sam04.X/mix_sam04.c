
#include <xc.h>
#include "types.h"
#include "system.h"
#include "uart3.h"
#include "i2c1.h"

#define TIME_1S			(1000 / SYS_MAIN_CYCLE)		// 1s
#define TIME_200MS		(200 / SYS_MAIN_CYCLE)		// 200ms
#define MCP23017_ADDR	(0x20)
#define SIZE_I2C_WRITE	(2)
#define SIZE_I2C_READ	(1)
// MCP23017 Register Address PORTA
#define IODIRA			(0x00)		// I/O方向レジスタ
#define IPOLA			(0x02)		// 入力極性ポートレジスタ
#define GPINTENA		(0x04)		// 状態変化割り込みピン
#define DEFVALA			(0x06)		// 既定値レジスタ
#define INTCONA			(0x08)		// 状態変化割り込み制御レジスタ
#define IOCON			(0x0A)		// I/Oエクスパンダコンフィグレーションレジスタ
#define GPPUA			(0x0C)		// GPIOプルアップ抵抗レジスタ
#define INTFA			(0x0E)		// 割り込みフラグレジスタ
#define INTCAPA			(0x10)		// 割り込み時にキャプチャしたポート値を示すレジスタ
#define GPIOA			(0x12)		// 汎用I/Oポ ートレジスタ
#define OLATA			(0x14)		// 出力ラッチレジスタ
// MCP23017 Register Address PORTB
#define IODIRB			(0x01)		// I/O方向レジスタ
#define IPOLB			(0x03)		// 入力極性ポートレジスタ
#define GPINTENB		(0x05)		// 状態変化割り込みピン
#define DEFVALB			(0x07)		// 既定値レジスタ
#define INTCONB			(0x09)		// 状態変化割り込み制御レジスタ
//#define IOCON			(0x0B)		// I/Oエクスパンダコンフィグレーションレジスタ
#define GPPUB			(0x0D)		// GPIOプルアップ抵抗レジスタ
#define INTFB			(0x0F)		// 割り込みフラグレジスタ
#define INTCAPB			(0x11)		// 割り込み時にキャプチャしたポート値を示すレジスタ
#define GPIOB			(0x13)		// 汎用I/Oポ ートレジスタ
#define OLATB			(0x15)		// 出力ラッチレジスタ

uint16_t			u16_timer_1s;
uint16_t			u16_timer_200m;
volatile uint8_t	u8_count_out;
__bit				bit_flag;
__bit				bit_state;

static void MCP23017_Initialize(void);
static void MCP23017_Write(uint8_t reg_addr, uint8_t data);
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
	TRISB0 = 1;						// Set as input
	INT0EDG = 0;					// INT0 external interrupt falling edge
	INT0IF = 0;						// Clear INT0 external interrupt flag
	INT0IE = 1;						// INT0 external interrupt enable

	// RA0-RA3 output pin
	ANSELA = 0xF0;					// Disable analog function
	LATA = 0x00;					// Set low level
	TRISA = 0xF0;					// Set as output

	// UART3 Initialize
	UART3_Initialize();
	// I2C1 Initialize
	I2C1_Host_Initialize();

	// Initialize variant
	u8_count_out = 0x00;
	bit_flag = 0;
	bit_state = 1;

	// Global interrupt
	GIE = 1;						// Global interrupt enable

	// MCP23017 Initialize
	MCP23017_Initialize();

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

static void MCP23017_Initialize(void) {
	// IOCON コンフィグレーションを初期化
	MCP23017_Write(IOCON, 0x00);	// I/Oエクスパンダコンフィグレーションレジスタ
	// PORTA 0-3ピンを入力として設定
	MCP23017_Write(IODIRA, 0xFF);	// I/O方向レジスタ
	MCP23017_Write(GPPUA, 0x0F);	// GPIOプルアップ抵抗レジスタ
	// PORTB 0-3ピンを出力として設定
	MCP23017_Write(IODIRB, 0xF0);	// I/O方向レジスタ
	MCP23017_Write(OLATB, 0x0A);	// 出力ラッチレジスタ
}

static void MCP23017_Write(uint8_t reg_addr, uint8_t data) {
	uint8_t data_write[SIZE_I2C_WRITE];
	data_write[0] = reg_addr;
	data_write[1] = data;
	I2C1_Host_Write(MCP23017_ADDR, &data_write[0], SIZE_I2C_WRITE);
	while (I2C1_IsBusy());
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
