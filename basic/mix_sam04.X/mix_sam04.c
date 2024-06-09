
#include <xc.h>
#include "types.h"
#include "system.h"
#include "uart3.h"
#include "i2c1.h"
#include "spi1.h"
#include "clc1.h"
#include "nco1.h"
#include "ccp1.h"
#include "tmr1.h"

#define TIME_1S			(1000 / SYS_MAIN_CYCLE)		// 1s
#define TIME_200MS		(200 / SYS_MAIN_CYCLE)		// 200ms
#define MCP23017_ADDR	(0x20)
#define SIZE_I2C_WRITE	(2)
#define SIZE_I2C_READ	(1)
#define MCP23S17_ADDR	(0x40)
#define SIZE_SPI_BUFFER	(3)
// MCP23017/MCP23S17 Register Address
#define REG_IODIRA		(0x00)		// I/O方向レジスタ
#define REG_IODIRB		(0x01)
#define REG_IPOLA		(0x02)		// 入力極性ポートレジスタ
#define REG_IPOLB		(0x03)
#define REG_GPINTENA	(0x04)		// 状態変化割り込みピン
#define REG_GPINTENB	(0x05)
#define REG_DEFVALA		(0x06)		// 既定値レジスタ
#define REG_DEFVALB		(0x07)
#define REG_INTCONA		(0x08)		// 状態変化割り込み制御レジスタ
#define REG_INTCONB		(0x09)
#define REG_IOCON		(0x0A)		// I/Oエクスパンダコンフィグレーションレジスタ
//#define REG_IOCON		(0x0B)
#define REG_GPPUA		(0x0C)		// GPIOプルアップ抵抗レジスタ
#define REG_GPPUB		(0x0D)
#define REG_INTFA		(0x0E)		// 割り込みフラグレジスタ
#define REG_INTFB		(0x0F)
#define REG_INTCAPA		(0x10)		// 割り込み時にキャプチャしたポート値を示すレジスタ
#define REG_INTCAPB		(0x11)
#define REG_GPIOA		(0x12)		// 汎用I/Oポ ートレジスタ
#define REG_GPIOB		(0x13)
#define REG_OLATA		(0x14)		// 出力ラッチレジスタ
#define REG_OLATB		(0x15)

enum {
	STATE_WAIT_READ = 0,
	STATE_WAIT_WRITE
};

const uint8_t acu8_msg_reset[] = "Status is RESET.\r\n";
const uint8_t acu8_msg_awake[] = "Status is AWAKE.\r\n";

uint16_t			u16_timer_1s;
uint16_t			u16_timer_200m;
volatile uint8_t	u8_count_out;
__bit				bit_flag;
__bit				bit_state;
uint8_t				u8_state_i2c;
uint8_t				au8_data_i2c_write[SIZE_I2C_WRITE];
uint8_t				u8_data_i2c_read;
uint8_t				u8_state_spi;
uint8_t				au8_data_spi_buffer[SIZE_SPI_BUFFER];
uint8_t				u8_data_spi_read;
volatile uint16_t	u16_data_ccp;
volatile __bit		bit_capture;

static void MCP23017_Initialize(void);
static void MCP23017_Write(uint8_t reg_addr, uint8_t data);
static void MCP23017_UpdateState(void);
static void MCP23S17_Initialize(void);
static void MCP23S17_Write(uint8_t reg_addr, uint8_t data);
static uint8_t MCP23S17_Read(uint8_t reg_addr);
static void MCP23S17_UpdateState(void);
static void request_in(void);
static void update_out(void);

void __interrupt(irq(INT0),base(8)) INT0_ISR(void) {
	// Clear interrupt flag
	INT0IF = 0;
	// Interrupt process
	u8_count_out++;
}

void CCP1_CBK(uint16_t data) {
	u16_data_ccp = data;
	bit_capture = 1;
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
	// SPI1 Initialize
	SPI1_Host_Initialize();
	// CLC1 Initialize
	CLC1_Initialize();
	// NCO1 Initialize
	NCO1_Initialize();
	// CCP1 Initialize
	CCP1_Initialize();
	// Timer1 Initialize
	Timer1_Initialize();

	// Initialize variant
	u8_count_out = 0x00;
	bit_flag = 0;
	bit_state = 1;
	u8_state_i2c = STATE_WAIT_READ;
	u8_state_spi = STATE_WAIT_READ;
	u16_data_ccp = 0x0000;
	bit_capture = 0;

	// Global interrupt
	GIE = 1;						// Global interrupt enable

	// Message
	EchoStr((char *)&acu8_msg_reset[0]);
	// MCP23017 Initialize
	MCP23017_Initialize();
	// MCP23S17 Initialize
	MCP23S17_Initialize();
	// CLC1 Enable
	CLC1_Enable();
	// CCP1 Setting
	CCP1_SetCallBack(CCP1_CBK);
	// Timer1 Start
	Timer1_Start();

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
	// MCP23017 UpdateState
	MCP23017_UpdateState();
	// MCP23S17 UpdateState
	MCP23S17_UpdateState();
}

static void MCP23017_Initialize(void) {
	// IOCON コンフィグレーションを初期化
	MCP23017_Write(REG_IOCON, 0x00);	// I/Oエクスパンダコンフィグレーションレジスタ
	// PORTA 0-3ピンを入力として設定
	MCP23017_Write(REG_IODIRA, 0xFF);	// I/O方向レジスタ
	MCP23017_Write(REG_GPPUA, 0x0F);	// GPIOプルアップ抵抗レジスタ
	// PORTB 0-3ピンを出力として設定
	MCP23017_Write(REG_IODIRB, 0xF0);	// I/O方向レジスタ
	MCP23017_Write(REG_OLATB, 0x00);	// 出力ラッチレジスタ
}

static void MCP23017_Write(uint8_t reg_addr, uint8_t data) {
	au8_data_i2c_write[0] = reg_addr;
	au8_data_i2c_write[1] = data;
	I2C1_Host_Write(MCP23017_ADDR, &au8_data_i2c_write[0], SIZE_I2C_WRITE);
	while (I2C1_Host_IsBusy());
}

static void MCP23017_UpdateState(void) {
	switch (u8_state_i2c) {
	case STATE_WAIT_READ:
		if (!I2C1_Host_IsBusy()) {
			au8_data_i2c_write[0] = REG_GPIOA;
			I2C1_Host_WriteRead(MCP23017_ADDR, &au8_data_i2c_write[0], 1, &u8_data_i2c_read, SIZE_I2C_READ);
			u8_state_i2c = STATE_WAIT_WRITE;
		}
		break;
	case STATE_WAIT_WRITE:
		if (!I2C1_Host_IsBusy()) {
			au8_data_i2c_write[0] = REG_OLATB;
			au8_data_i2c_write[1] = u8_data_i2c_read;
			I2C1_Host_Write(MCP23017_ADDR, &au8_data_i2c_write[0], SIZE_I2C_WRITE);
			u8_state_i2c = STATE_WAIT_READ;
		}
		break;
	default:
		u8_state_i2c = STATE_WAIT_READ;
		break;
	}
}

static void MCP23S17_Initialize(void) {
	LATC7 = 1;						// CS deactive
	SPI1_Host_Open(HOST_CONFIG);
	// IOCON コンフィグレーションを初期化
	MCP23S17_Write(REG_IOCON, 0x00);	// I/Oエクスパンダコンフィグレーションレジスタ
	// PORTA 0-3ピンを入力として設定
	MCP23S17_Write(REG_IODIRA, 0xFF);	// I/O方向レジスタ
	MCP23S17_Write(REG_GPPUA, 0x0F);	// GPIOプルアップ抵抗レジスタ
	// PORTB 0-3ピンを出力として設定
	MCP23S17_Write(REG_IODIRB, 0xF0);	// I/O方向レジスタ
	MCP23S17_Write(REG_OLATB, 0x00);	// 出力ラッチレジスタ
}

static void MCP23S17_Write(uint8_t reg_addr, uint8_t data) {
	au8_data_spi_buffer[0] = MCP23S17_ADDR;
	au8_data_spi_buffer[1] = reg_addr;
	au8_data_spi_buffer[2] = data;
	LATC7 = 0;						// CS active
	SPI1_Host_BufferExchange(&au8_data_spi_buffer[0], SIZE_SPI_BUFFER);
	LATC7 = 1;						// CS deactive
}

static uint8_t MCP23S17_Read(uint8_t reg_addr) {
	au8_data_spi_buffer[0] = MCP23S17_ADDR | 1;
	au8_data_spi_buffer[1] = REG_GPIOA;
	au8_data_spi_buffer[2] = 0x00;
	LATC7 = 0;						// CS active
	SPI1_Host_BufferExchange(&au8_data_spi_buffer[0], SIZE_SPI_BUFFER);
	LATC7 = 1;						// CS deactive
	return au8_data_spi_buffer[2];
}

static void MCP23S17_UpdateState(void) {
	switch (u8_state_spi) {
	case STATE_WAIT_READ:
		u8_data_spi_read = MCP23S17_Read(REG_GPIOA);
		u8_state_spi = STATE_WAIT_WRITE;
		break;
	case STATE_WAIT_WRITE:
		MCP23S17_Write(REG_OLATB, u8_data_spi_read);
		u8_state_spi = STATE_WAIT_READ;
		break;
	default:
		u8_state_spi = STATE_WAIT_READ;
		break;
	}
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
		// Message
		EchoStr((char *)&acu8_msg_awake[0]);
		break;
	case 'u':						// Judge Uart
		bit_state = !bit_state;
		break;
	case 'w':						// Judge aWake
		// Message
		EchoStr((char *)&acu8_msg_awake[0]);
		break;
	case 'z':						// Judge Zero
		u8_count_out = 0x00;
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
	// CCP1 output
	if (bit_capture == 1) {
		GIE = 0;					// Global interrupt disable
		EchoStr("\r\n");
		EchoHex((u16_data_ccp >> 8) & 0xFF);
		EchoHex(u16_data_ccp & 0xFF);
		EchoStr("(ccp) ");
		GIE = 1;					// Global interrupt enable
		bit_capture = 0;
	}
}
