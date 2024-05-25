
#ifndef _ADCC_H_
#define _ADCC_H_

extern void ADCC_Initialize(void);
extern uint16_t ADCC_GetSingleConversion(void);
extern void ADCC_StartConversion(void);
extern uint8_t ADCC_IsConversionDone(void);
extern uint16_t ADCC_GetConversionResult(void);
extern inline void ADCC_StopConversion(void);

#endif // _ADCC_H_
