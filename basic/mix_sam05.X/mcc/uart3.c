
#include <xc.h>
#include "types.h"
#include "uart3.h"

#define U3BRG_VALUE		(416)		// 9600bps @ 64MHz
									// U3BRGH/L=64MHz/(9600bps*16)-1=416
#define RX_BUFFER_SIZE	(64)		// Rx buffer size should be 2^n
#define RX_BUFFER_MASK	(RX_BUFFER_SIZE - 1)
#define TX_BUFFER_SIZE	(64)		// Tx buffer size should be 2^n
#define TX_BUFFER_MASK	(TX_BUFFER_SIZE - 1)

volatile uint8_t	au8_rx_buffer[RX_BUFFER_SIZE];
volatile uint8_t	u8_rx_head;
volatile uint8_t	u8_rx_tail;
volatile uint8_t	u8_rx_count;
volatile uint8_t	au8_tx_buffer[TX_BUFFER_SIZE];
volatile uint8_t	u8_tx_head;
volatile uint8_t	u8_tx_tail;
volatile uint8_t	u8_tx_count;

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

void UART3_Initialize(void) {
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

uint8_t UART3_IsRxReady(void) {
	return ((u8_rx_count > 0) ? TRUE : FALSE);
}

uint8_t UART3_IsTxReady(void) {
	return ((u8_tx_count < TX_BUFFER_SIZE) ? TRUE : FALSE);
}

uint8_t UART3_Read(void) {
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

void UART3_Write(uint8_t data) {
	if (u8_tx_count < TX_BUFFER_SIZE) {
		au8_tx_buffer[u8_tx_head] = data;
		u8_tx_head = (u8_tx_head + 1) & TX_BUFFER_MASK;
		U3TXIE = 0;					// Critical value increment
		u8_tx_count++;
	}
	U3TXIE = 1;
}
