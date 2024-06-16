
#ifndef _UART3_H_
#define _UART3_H_

extern void UART3_Initialize(void);
extern uint8_t UART3_IsRxReady(void);
extern uint8_t UART3_IsTxReady(void);
extern uint8_t UART3_Read(void);
extern void UART3_Write(uint8_t data);

#endif // _UART3_H_
