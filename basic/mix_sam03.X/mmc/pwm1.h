
#ifndef _PWM1_H_
#define _PWM1_H_

extern void PWM1_Initialize(void);
extern void PWM1_Enable(void);
extern void PWM1_Disable(void);
extern void PWM1_WritePeriodRegister(uint16_t count);
extern void PWM1_SetSlice1Output1DutyCycleRegister(uint16_t value);
extern void PWM1_SetSlice1Output2DutyCycleRegister(uint16_t value);
extern void PWM1_LoadBufferRegisters(void);

#endif // _PWM1_H_
