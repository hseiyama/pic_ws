
#include <xc.h>
#include "types.h"
#include "system.h"
#include "uart3.h"
#include "can1.h"

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

static void CAN_SendMessage(void);
static void CAN_ReceiveMessage(void);
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
	// CAN1 Initialize
	CAN1_Initialize();

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
	CAN_ReceiveMessage();
	// check timer_1s
	chk_val = TimerCheck(&u16_timer_1s, TIME_1S);
	if (chk_val) {
		CAN_SendMessage();
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

static void CAN_SendMessage(void) {
	struct CAN_MSG_OBJ txObj;
	uint8_t txData[8] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08};
	uint8_t txStatus;

	txObj.field.formatType = CAN_2_0_FORMAT;	// CAN 2.0 フォーマット
	txObj.field.brs = CAN_NON_BRS_MODE;			// CANビットレート切替え(CAN FD用)
	txObj.field.frameType = CAN_FRAME_DATA;		// CANデータフレーム
	txObj.field.idType = CAN_FRAME_STD;			// CAN標準ID
	txObj.msgId = 0x123;						// メッセージID
	txObj.field.dlc = DLC_8;					// データ長
	txObj.data = &txData[0];					// 送信データ

	// メッセージ送信
	txStatus = CAN1_Transmit(CAN1_TXQ, &txObj);
	if (txStatus == CAN_TX_MSG_REQUEST_FIFO_FULL) {
		// 送信バッファがいっぱいの場合の処理
		EchoStr("Can Transmit FIFO is Full.\r\n");
	}
	else {
		UART3_Write('c');
	}
}

static void CAN_ReceiveMessage(void) {
	struct CAN_MSG_OBJ rxObj;
	uint8_t rxStatus;
	uint8_t index;

	// メッセージ受信を確認
	rxStatus = CAN1_Receive(&rxObj);
	if (rxStatus) {
		// メッセージ受信がある場合の処理
		if (rxObj.field.frameType == CAN_FRAME_DATA) {
			// 受信データを処理
			EchoStr("\r\n[id=");
			EchoHex((rxObj.msgId >> 8) & 0xFF);
			EchoHex(rxObj.msgId & 0xFF);
			EchoStr(",dlc=");
			EchoHex(rxObj.field.dlc);
			EchoStr("] ");
			for (index = 0; index < rxObj.field.dlc; index++) {
				EchoHex(rxObj.data[index]);
				UART3_Write(' ');
			}
			EchoStr("\r\n");
		}
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
