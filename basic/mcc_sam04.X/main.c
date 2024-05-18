 /*
 * MAIN Generated Driver File
 * 
 * @file main.c
 * 
 * @defgroup main MAIN
 * 
 * @brief This is the generated driver implementation file for the MAIN driver.
 *
 * @version MAIN Driver Version 1.0.0
*/

/*
? [2024] Microchip Technology Inc. and its subsidiaries.

    Subject to your compliance with these terms, you may use Microchip 
    software and any derivatives exclusively with Microchip products. 
    You are responsible for complying with 3rd party license terms  
    applicable to your use of 3rd party software (including open source  
    software) that may accompany Microchip software. SOFTWARE IS ?AS IS.? 
    NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS 
    SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,  
    MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT 
    WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE, 
    INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY 
    KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF 
    MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE 
    FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP?S 
    TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT 
    EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR 
    THIS SOFTWARE.
*/
#include "mcc_generated_files/system/system.h"

#define TRUE	(1)
#define FALSE	(0)

#define SIZE_RESET		(sizeof(data_reset) - 1)
#define SIZE_WAKEUP		(sizeof(data_wakeup) - 1)

const uint8_t data_reset[] = "Status is RESET.\r\n";
const uint8_t data_wakeup[] = "Status is WAKEUP.\r\n";

asm("psect eeprom_data");
asm("_data_eep: DB 0,0");
extern const uint8_t data_eep[];

volatile uint8_t	count_out;
volatile uint8_t	data_recv;
volatile __bit		bit_flag;
__bit				bit_state;

static void dma1_init(void);
static void dma1_wakeup(void);
static void request_in(void);
static void update_out(void);
static uint8_t eep_read(uint8_t addr);
static void eep_write(uint8_t addr, uint8_t data);

/*
    Interrupt routine
*/

void int0Isr() {
	// interrupt process
	count_out++;
}

void tmr0Isr() {
	// interrupt process
	count_out++;
	bit_flag = 1;
}

void u3rxIsr() {
	// interrupt process
	data_recv = U3RXB;
}

/*
    Main application
*/

int main(void)
{
    SYSTEM_Initialize();

	// Setting InterruptHandler
	INT0_SetInterruptHandler(int0Isr);
	TMR0_OverflowCallbackRegister(tmr0Isr);
	UART3_RxCompleteCallbackRegister(u3rxIsr);

	// DMA1 Initialize
	dma1_init();

	// Read eeprom(count_out)
	count_out = eep_read(0);
	// Read eeprom(bit_state)
	bit_state = (__bit)eep_read(1);

	// Initialize variant
	data_recv = 0x00;
	bit_flag = 0;

    // Enable the Global High Interrupts 
	INTERRUPT_GlobalInterruptHighEnable(); 

	while (TRUE) {
		request_in();
		update_out();
	}
}

static void dma1_init(void) {
	// Source registers
	// Source start address, data_reset
	DMA1_SourceAddressSet((__uint24)&data_reset);
	// Source size
	DMA1_SourceSizeSet(SIZE_RESET);
	// Change arbiter priority
	// (注意)PFMアクセスはシステム調停が必要(DMA1>MAIN)
	DMA1_DMAPrioritySet(0x1);
	// Enable the DMA & the trigger to start DMA transfer
	DMA1_Enable();
	DMA1_TransferWithTriggerStart();
}

static void request_in(void) {
	// Judge Reset
	if (data_recv == 'r') {
		// Reset
		Reset();
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
		Sleep();
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
	// Disable the DMA
	// (注意)DMA設定の変更はDMA無効時に実施
	DMA1_Disable();
	// Source registers
	// Source start address, data_wakeup
	DMA1_SourceAddressSet((__uint24)&data_wakeup);
	// Source size
	DMA1_SourceSizeSet(SIZE_WAKEUP);
	// Enable the DMA & the trigger to start DMA transfer
	DMA1_Enable();
	DMA1_TransferWithTriggerStart();
}

static void update_out(void) {
	// LED output
	LATA = count_out & 0x0F;
	// UART output
	if (bit_flag == 1) {
		if (bit_state == 1) {
			UART3_Write('+');
		}
		bit_flag = 0;
	}
}

static uint8_t eep_read(uint8_t addr) {
	uint8_t data;
	data = EEPROM_Read((__uint24)(&data_eep[0] + addr));
	return data;
}

static void eep_write(uint8_t addr, uint8_t data) {
	NVM_UnlockKeySet(UNLOCK_KEY);
	EEPROM_Write((__uint24)(&data_eep[0] + addr), data);
	while (NVM_IsBusy());
	NVM_UnlockKeyClear();
}
