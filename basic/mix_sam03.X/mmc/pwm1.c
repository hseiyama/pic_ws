
#include <xc.h>
#include "types.h"
#include "pwm1.h"

void PWM1_Initialize(void) {
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

void PWM1_Enable(void) {
	PWM1CONbits.EN = 1;
}

void PWM1_Disable(void) {
	PWM1CONbits.EN = 0;
}

void PWM1_WritePeriodRegister(uint16_t count) {
	PWM1PRL = (uint8_t)count;
	PWM1PRH = (uint8_t)(count >> 8);
}

void PWM1_SetSlice1Output1DutyCycleRegister(uint16_t value) {
	PWM1S1P1L = (uint8_t)value;
	PWM1S1P1H = (uint8_t)(value >> 8);
}

void PWM1_SetSlice1Output2DutyCycleRegister(uint16_t value) {
	PWM1S1P2L = (uint8_t)value;
	PWM1S1P2H = (uint8_t)(value >> 8);
}

void PWM1_LoadBufferRegisters(void) {
	// Load the period and duty cycle registers on the next period event
	PWM1CONbits.LD = 1;
}
