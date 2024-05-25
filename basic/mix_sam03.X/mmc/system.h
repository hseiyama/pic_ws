
#ifndef _SYSTEM_H_
#define _SYSTEM_H_

#define SYS_MAIN_CYCLE	(5)			// 5ms

extern void TMR2_Start(void);
extern void TMR2_Stop(void);
extern void TimerStart(uint16_t *p_timer);
extern void TimerStop(uint16_t *p_timer);
extern uint8_t TimerCheck(uint16_t *p_timer, uint16_t time);
extern void EchoHex(uint8_t data);
extern void EchoStr(char *p_data);

#endif // _SYSTEM_H_
