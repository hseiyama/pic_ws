
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
#include "types.h"
#include "system.h"
#include "uart3.h"

#define TIME_STOP		(0xFFFF)
#define TIME_START		(0x0000)

volatile uint8_t	u8_sys_counter;

extern void setup(void);
extern void loop(void);
static void TMR2_Initialize(void);

void __interrupt(irq(default),base(8)) DEFAULT_ISR(void) {
}

void __interrupt(irq(TMR2),base(8)) TMR2_ISR(void) {
	// Clear interrupt flag
	TMR2IF = 0;
	// Interrupt process
	u8_sys_counter++;
}

void main(void) {
	// System initialize
	OSCFRQ = 0x08;					// 64MHz internal OSC
	// TIMER2 Initialize
	TMR2_Initialize();
	// Initialize variant
	u8_sys_counter = 0;
	// User initialize
	setup();

	while (TRUE) {
		if (u8_sys_counter >= SYS_MAIN_CYCLE) {
			u8_sys_counter = 0;
			// User process
			loop();
		}
	}
}

static void TMR2_Initialize(void){
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

void TMR2_Start(void) {
	// Start the Timer by writing to TMRxON bit
	T2CONbits.TMR2ON = 1;
}

void TMR2_Stop(void) {
	// Stop the Timer by writing to TMRxON bit
	T2CONbits.TMR2ON = 0;
}

void TimerStart(uint16_t *p_timer) {
	*p_timer = TIME_START;
}

void TimerStop(uint16_t *p_timer) {
	*p_timer = TIME_STOP;
}

uint8_t TimerCheck(uint16_t *p_timer, uint16_t time) {
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

void EchoHex(uint8_t data) {
	static const uint8_t hex_table[] = {
		'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
	};
	UART3_Write(hex_table[(data >> 4) & 0x0F]);
	UART3_Write(hex_table[data & 0x0F]);
}

void EchoStr(char *p_data) {
	while (*p_data != 0x00) {
		UART3_Write(*p_data);
		p_data++;
	}
}
