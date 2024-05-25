
#include <xc.h>
#include "types.h"
#include "adcc.h"

void ADCC_Initialize(void) {
	// ADCC Initialize
	ADCON0bits.FM = 1;				// right justify
	ADCON0bits.CS = 1;				// ADCRC Clock
	ADPCH = 0x0C;					// RB4 is Analog channel
	TRISB4 = 1;						// Set RB4 to input
	ANSELB4 = 1;					// Set RB4 to analog
	ADCON0bits.ON = 1;				// Turn ADC On
}

uint16_t ADCC_GetSingleConversion(void) {
	// Starts the conversion
	ADCON0bits.ADGO = 1;
	// Waits for the conversion to finish
	while (ADCON0bits.ADGO == 1);
	// Conversion finished, returns the result
	return ((uint16_t)((ADRESH << 8) + ADRESL));
}

void ADCC_StartConversion(void) {
	// Starts the conversion
	ADCON0bits.ADGO = 1;
}

uint8_t ADCC_IsConversionDone(void) {
	// Checks the conversion
	return ((ADCON0bits.ADGO == 0) ? TRUE : FALSE);
}

uint16_t ADCC_GetConversionResult(void) {
	// Returns the result
	return ((uint16_t)((ADRESH << 8) + ADRESL));
}

inline void ADCC_StopConversion(void) {
	// Resets the ADGO bit.
	ADCON0bits.ADGO = 0;
}
