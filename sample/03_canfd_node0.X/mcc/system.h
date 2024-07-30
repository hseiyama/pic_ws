
#ifndef _SYSTEM_H_
#define _SYSTEM_H_

extern void TMR2_Start(void);
extern void TMR2_Stop(void);
extern void TimerStart(uint16_t *p_timer);
extern void TimerStop(uint16_t *p_timer);
extern uint8_t TimerCheck(uint16_t *p_timer, uint16_t time);
extern void EchoHex8(uint8_t data);
extern void EchoHex16(uint16_t data);
extern void EchoHex32(uint32_t data);
extern void EchoStr(char *p_data);

#endif // _SYSTEM_H_
