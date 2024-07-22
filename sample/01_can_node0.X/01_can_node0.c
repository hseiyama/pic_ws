
#include <xc.h>
#include "types.h"
#include "system.h"
#include "uart3.h"
#include "can1.h"

#define TIME_1S			(1000 / SYS_MAIN_CYCLE)		// 1s
#define TIME_200MS		(200 / SYS_MAIN_CYCLE)		// 200ms
#define TIME_40MS		(40 / SYS_MAIN_CYCLE)		// 40ms

const uint8_t acu8_msg_reset[] = "Status is RESET.\r\n";
const uint8_t acu8_msg_awake[] = "Status is AWAKE.\r\n";

struct CAN_MSG_OBJ	st_msgObj;
uint8_t				au8_msgData[8] = {0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18};
uint16_t			u16_timer_1s;
uint16_t			u16_timer_200m;
uint16_t			u16_timer_40m;
uint8_t				u8_count_out;
uint8_t				u8_data_can;
uint8_t				u8_data_can_prev;
__bit				bit_event_200ms;
__bit				bit_state_uart;
volatile __bit		bit_event_int0;
__bit				bit_state_mode;

static uint8_t CAN_SendMessage(void);
static uint8_t CAN_ReceiveMessage(void);
static void print_message(void);
static void request_in(void);
static void update_out(void);

void __interrupt(irq(INT0),base(8)) INT0_ISR() {
	// Clear interrupt flag
	INT0IF = 0;
	// Interrupt process
	bit_event_int0 = 1;
}

void setup(void) {
	// RB0(INT0) input pin
	ANSELB0 = 0;					// Disable analog function
	WPUB0 = 0;						// Disable week pull up
	TRISB0 = 1;						// Set as intput
    INT0PPS = 0x08;					// RB0->INT0
	INT0EDG = 1;					// INT0 external interrupt rising edge
	INT0IF = 0;						// Clear INT0 external interrupt flag
	INT0IE = 1;						// INT0 external interrupt enable
	// RC0-RC3 input pin
	// RC4-RC7 output pin
	ANSELC = 0x00;					// Disable analog function
	WPUC = 0x0F;					// Week pull up
	LATC = 0x00;					// Set low level
	TRISC = 0x0F;					// Set as output

	// UART3 Initialize
	UART3_Initialize();
	// CAN1 Initialize
	CAN1_Initialize();

	// Initialize variant
	u8_count_out = 0x00;
	u8_data_can = 0x00;
	u8_data_can_prev = 0x00;
	bit_event_200ms = 0;
	bit_state_uart = 1;
	bit_event_int0 = 0;
	bit_state_mode = 1;

	// Global interrupt
	GIE = 1;						// Global interrupt enable

	// Message
	EchoStr((char *)&acu8_msg_reset[0]);

	// start timer_1s
	TimerStart(&u16_timer_1s);
	// start timer_200ms
	TimerStart(&u16_timer_200m);
	// start timer_40ms
	TimerStart(&u16_timer_40m);
}

void loop(void) {
	uint8_t chk_val;

	CAN_ReceiveMessage();
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
		bit_event_200ms = 1;
		// start timer_200ms
		TimerStart(&u16_timer_200m);
	}
	// check timer_40ms
	chk_val = TimerCheck(&u16_timer_40m, TIME_40MS);
	if (chk_val) {
		CAN_SendMessage();
		// start timer_40ms
		TimerStart(&u16_timer_40m);
	}
	request_in();
	update_out();
}

static uint8_t CAN_SendMessage(void) {
	uint8_t txStatus;
	uint8_t retCode;

	retCode = FALSE;
	// CANオブジェクトを設定
	st_msgObj.field.formatType = CAN_2_0_FORMAT;	// CAN 2.0 フォーマット
	st_msgObj.field.brs = CAN_NON_BRS_MODE;			// CANビットレート切替え(CAN FD用)
	st_msgObj.field.frameType = CAN_FRAME_DATA;		// CANデータフレーム
	st_msgObj.field.idType = CAN_FRAME_STD;			// CAN標準ID
	st_msgObj.msgId = 0x123;						// メッセージID
	st_msgObj.field.dlc = DLC_8;					// データ長
	st_msgObj.data = &au8_msgData[0];				// 送信データ

	// 送信データを更新
	au8_msgData[0] = (LATC & 0xF0) | (~PORTC & 0x0F);
	au8_msgData[1] = u8_count_out;

	// メッセージ送信
	txStatus = CAN1_Transmit(CAN1_TXQ, &st_msgObj);
	if (txStatus == CAN_TX_MSG_REQUEST_FIFO_FULL) {
		// 送信バッファがいっぱいの場合の処理
		UART3_Write('f');
	}
	else {
		retCode = TRUE;
	}

	return retCode;
}

static uint8_t CAN_ReceiveMessage(void) {
	uint8_t rxStatus;
	uint8_t retCode;

	retCode = FALSE;
	// メッセージ受信を確認
	rxStatus = CAN1_Receive(&st_msgObj);
	if (rxStatus) {
		// メッセージ受信がある場合の処理
		if (st_msgObj.field.frameType == CAN_FRAME_DATA) {
			// 受信データを処理
			u8_data_can = st_msgObj.data[0];
			if (u8_data_can != u8_data_can_prev) {
				// 前回から変化があった場合
				print_message();
			}
			u8_data_can_prev = u8_data_can;
			retCode = TRUE;
		}
	}

	return retCode;
}

static void print_message(void) {
	uint8_t index;

	EchoStr("\r\n<node0 id:");
	EchoHex16(st_msgObj.msgId & 0xFFFF);
	EchoStr(" dlc:");
	EchoHex8(st_msgObj.field.dlc);
	EchoStr(">");
	for (index = 0; index < st_msgObj.field.dlc; index++) {
		UART3_Write(' ');
		EchoHex8(st_msgObj.data[index]);
	}
	EchoStr("\r\n");
}

static void request_in(void) {
	uint8_t data_recv;

	data_recv = UART3_Read();
	switch (data_recv) {
	case 'm':						// Mode Change
		bit_state_mode = !bit_state_mode;
		break;
	case 'r':						// Judge Reset
		// Reset
		Reset();
		break;
	case 's':						// Judge Sleep
		CAN1_Deinitialize();
		// Sleep
		Sleep();
		CAN1_Initialize();
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
		u8_count_out = 0x00;
		break;
	default:
		break;
	}
}

static void update_out(void) {
	// LED output
	if (bit_state_mode == 1) {
		LATC = (u8_count_out << 4) & 0xF0;
	}
	else {
		LATC = (u8_data_can << 4) & 0xF0;
	}
	// UART output
	if (bit_event_int0 == 1) {
		UART3_Write('e');
		bit_event_int0 = 0;
	}
	if (bit_event_200ms == 1) {
		if (bit_state_uart == 1) {
			UART3_Write('+');
		}
		bit_event_200ms = 0;
	}
}
