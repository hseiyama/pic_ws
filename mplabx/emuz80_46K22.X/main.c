/*
  PIC18F46K22 ROM RAM and UART emulation firmware
  This single source file contains all code

  Target: EMUZ80 - The computer with only Z80 and PIC18F46K22
  Compiler: MPLAB XC8 v2.41
  Update by Hirofumi Seiyama
--------------------------------------------------------------------------------
  [Z80]             [PIC18F46K22]     [User input/output]
  Address Lines:
   A8..A13    <----> RD0..RD5
   A0..A7     <----> RA0..RA7
  Data Lines:
   D0..D7     <----> RC0..RC7
  Control lines:
   RD         <----> RB0
   WR         <----> RB1
   M1         <----> RB2
   CLK        <----> RB3(CCP2)
   MREQ       <----> RB4
   IOREQ      <----> RB5
                     RB6        <----> IN port (button)
                     RB7        <----> OUT port (led)
   WAIT       <----> RE0
   RESET      <----> RE1
   INT        <----> RE2
                     RE3        <----> RESET button
                     RD6(TX2)   <----> UART TX
                     RD7(RX2)   <----> UART RX
   NMI        <----------------------> NMI button
   BUSRQ      <----------------------> BUSRQ button
   HALT       <----------------------> HALT led
   BUSACK     <----------------------> BUSACK led
                                       POWER led
--------------------------------------------------------------------------------
  Memory map:
   0x0000-0x37FF  ROM  14Kbyte
   0x3800-0x3FFF  RAM  2Kbyte
--------------------------------------------------------------------------------
*/

// CONFIG1H
#pragma config FOSC = INTIO67   // Oscillator Selection bits (Internal oscillator block)
#pragma config PLLCFG = OFF     // 4X PLL Enable (Oscillator used directly)
#pragma config PRICLKEN = OFF   // Primary clock enable bit (Primary clock can be disabled by software)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled)
#pragma config IESO = OFF       // Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled)

// CONFIG2L
#pragma config PWRTEN = ON      // Power-up Timer Enable bit (Power up timer enabled)
#pragma config BOREN = NOSLP    // Brown-out Reset Enable bits (Brown-out Reset enabled in hardware only and disabled in Sleep mode (SBOREN is disabled))
#pragma config BORV = 285       // Brown Out Reset Voltage bits (VBOR set to 2.85 V nominal)

// CONFIG2H
#pragma config WDTEN = OFF      // Watchdog Timer Enable bits (Watch dog timer is always disabled. SWDTEN has no effect.)
#pragma config WDTPS = 32768    // Watchdog Timer Postscale Select bits (1:32768)

// CONFIG3H
#pragma config CCP2MX = PORTB3  // CCP2 MUX bit (CCP2 input/output is multiplexed with RB3)
#pragma config PBADEN = ON      // PORTB A/D Enable bit (PORTB<5:0> pins are configured as analog input channels on Reset)
#pragma config CCP3MX = PORTB5  // P3A/CCP3 Mux bit (P3A/CCP3 input/output is multiplexed with RB5)
#pragma config HFOFST = OFF     // HFINTOSC Fast Start-up (HFINTOSC output and ready status are delayed by the oscillator stable status)
#pragma config T3CMX = PORTC0   // Timer3 Clock input mux bit (T3CKI is on RC0)
#pragma config P2BMX = PORTD2   // ECCP2 B output mux bit (P2B is on RD2)
#pragma config MCLRE = EXTMCLR  // MCLR Pin Enable bit (MCLR pin enabled, RE3 input pin disabled)

// CONFIG4L
#pragma config STVREN = ON      // Stack Full/Underflow Reset Enable bit (Stack full/underflow will cause Reset)
#pragma config LVP = OFF        // Single-Supply ICSP Enable bit (Single-Supply ICSP disabled)
#pragma config XINST = OFF      // Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled (Legacy mode))

// CONFIG5L
#pragma config CP0 = OFF        // Code Protection Block 0 (Block 0 (000800-003FFFh) not code-protected)
#pragma config CP1 = OFF        // Code Protection Block 1 (Block 1 (004000-007FFFh) not code-protected)
#pragma config CP2 = OFF        // Code Protection Block 2 (Block 2 (008000-00BFFFh) not code-protected)
#pragma config CP3 = OFF        // Code Protection Block 3 (Block 3 (00C000-00FFFFh) not code-protected)

// CONFIG5H
#pragma config CPB = OFF        // Boot Block Code Protection bit (Boot block (000000-0007FFh) not code-protected)
#pragma config CPD = OFF        // Data EEPROM Code Protection bit (Data EEPROM not code-protected)

// CONFIG6L
#pragma config WRT0 = OFF       // Write Protection Block 0 (Block 0 (000800-003FFFh) not write-protected)
#pragma config WRT1 = OFF       // Write Protection Block 1 (Block 1 (004000-007FFFh) not write-protected)
#pragma config WRT2 = OFF       // Write Protection Block 2 (Block 2 (008000-00BFFFh) not write-protected)
#pragma config WRT3 = OFF       // Write Protection Block 3 (Block 3 (00C000-00FFFFh) not write-protected)

// CONFIG6H
#pragma config WRTC = OFF       // Configuration Register Write Protection bit (Configuration registers (300000-3000FFh) not write-protected)
#pragma config WRTB = OFF       // Boot Block Write Protection bit (Boot Block (000000-0007FFh) not write-protected)
#pragma config WRTD = OFF       // Data EEPROM Write Protection bit (Data EEPROM not write-protected)

// CONFIG7L
#pragma config EBTR0 = OFF      // Table Read Protection Block 0 (Block 0 (000800-003FFFh) not protected from table reads executed in other blocks)
#pragma config EBTR1 = OFF      // Table Read Protection Block 1 (Block 1 (004000-007FFFh) not protected from table reads executed in other blocks)
#pragma config EBTR2 = OFF      // Table Read Protection Block 2 (Block 2 (008000-00BFFFh) not protected from table reads executed in other blocks)
#pragma config EBTR3 = OFF      // Table Read Protection Block 3 (Block 3 (00C000-00FFFFh) not protected from table reads executed in other blocks)

// CONFIG7H
#pragma config EBTRB = OFF      // Boot Block Table Read Protection bit (Boot Block (000000-0007FFh) not protected from table reads executed in other blocks)

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

#include <xc.h>

#define _XTAL_FREQ 64000000UL // PIC clock frequency(64MHz)
#define Z80_CLK 1000000UL // Z80 clock frequency(Max 16MHz)
#define PWM_PERIOD (_XTAL_FREQ / (4 * Z80_CLK))

#define ROM_SIZE 0x3800 // 14K bytes
#define RAM_SIZE 0x0800 // 2K bytes
#define RAM_TOP 0x3800 // RAM top address
#define RAM_END RAM_TOP+RAM_SIZE
#define UART_DREG 0xE0 // UART_Data REG
#define UART_CREG 0xE1 // UART_Control REG
#define PORT_DREG 0xD0 // PORT_Data REG

//Z80 ROM equivalent, see end of this file
extern const unsigned char rom[];

//Z80 RAM equivalent
unsigned char ram[RAM_SIZE];

//Address Bus
union {
    unsigned int w; // 16 bits Address
    struct {
        unsigned char l; // Address low
        unsigned char h; // Address high
    };
} ab;

/*
// UART2 Transmit
void putch(char c) {
    while(!TX2IF); // Wait or Tx interrupt flag set
    TXREG2 = c; // Write data
}

// UART2 Recive
char getch(void) {
    while(!RC2IF); // Wait for Rx interrupt flag set
    return RCREG2; // Read data
}
*/

// Called falling edge(Immediately after Z80 RD or WR falling)
void __interrupt() EXT_ISR(){
    LATE0 = 0; // Set wait
    INT0IF = 0; // Clear interrupt flag
    INT1IF = 0; // Clear interrupt flag

    ab.h = PORTD & 0x3f; // Read address high
    ab.l = PORTA; // Read address low
    
    // Z80 WR falling
    if(PORTBbits.RB0) { // RD==1 ?
        // Z80 memory write cycle
        if(!PORTBbits.RB4) { // MREQ==0 ?
            if((ab.w >= RAM_TOP) && (ab.w < RAM_END)) // RAM area
                ram[ab.w - RAM_TOP] = PORTC; // Write into RAM
        }
        // Z80 io write cycle
        else {
            if(ab.l == UART_DREG) // TXREG2
                TXREG2 = PORTC; // Write into TXREG2
            else if(ab.l == PORT_DREG) // LATB7
                LATB7 = PORTC & 0x01; // Out LATB7
        }
        LATE0 = 1; // Release wait
        return;
    }

    // Z80 RD falling
    TRISC = 0x00; // Set data bus as output
    // Z80 memory read cycle
    if(!PORTBbits.RB4) { // MREQ==0 ?
        if(ab.w < ROM_SIZE) // ROM area
            LATC = rom[ab.w]; // Out ROM data
        else if((ab.w >= RAM_TOP) && (ab.w < RAM_END)) // RAM area
            LATC = ram[ab.w - RAM_TOP]; // Out RAM data
        else // Empty
            LATC = 0xff; // Invalid data
    }
    // Z80 io read cycle
    else {
        if(ab.l == UART_CREG) // RC2IF
            LATC = RC2IF; // Out RC2IF
        else if(ab.l == UART_DREG) //RCREG2
            LATC = RCREG2; // Out RCREG2
        else if(ab.l == PORT_DREG) //RB6
            LATC = PORTBbits.RB6; // Out RB6
        else // Empty
            LATC = 0xff; // Invalid data
    }
    LATE0 = 1; // Release wait

    //Post processing
    while(!PORTBbits.RB0); // RD==0 ?
    TRISC = 0xff; // Set as input
}

// main routine
void main(void) {
    // System initialize
    OSCCONbits.IRCF = 0b111; // 16MHz Internal OSC
    OSCCONbits.SCS = 0b00; // Primary clock
    PLLEN = 1; // 4xPLL enabled (64MHz)
    RBPU = 0; // PORTB pull-ups are enabled

    // Address bus A13-A8 pin
    ANSELD = 0x00; // Disable analog function
    TRISD = 0xff; // Set as input

    // Address bus A7-A0 pin
    ANSELA = 0x00; // Disable analog function
    TRISA = 0xff; // Set as input

    // Data bus D7-D0 pin
    ANSELC = 0x00; // Disable analog function
    TRISC = 0xff; // Set as input(default)

    // WAIT(RE0) output pin
    ANSE0 = 0; // Disable analog function
    LATE0 = 1; // No wait request
    TRISE0 = 0; // Set as output

    // RESET(RE1) output pin
    ANSE1 = 0; // Disable analog function
    LATE1 = 0; // Reset
    TRISE1 = 0; // Set as output

    // INT(RE2) output pin
    ANSE2 = 0; // Disable analog function
    LATE2 = 1; // No interrupt request
    TRISE2 = 0; // Set as output

    // RD(RB0)  input pin
    ANSB0 = 0; // Disable analog function
    WPUB0 = 1; // Week pull up
    TRISB0 = 1; // Set as intput
    INTEDG0 = 0; // INT0 external interrupt falling edge
    INT0IF  = 0; // Clear INT0 external interrupt flag
    INT0IE  = 1; // INT0 external interrupt enable

    // WR(RB1)  input pin
    ANSB1 = 0; // Disable analog function
    WPUB1 = 1; // Week pull up
    TRISB1 = 1; // Set as intput
    INTEDG1 = 0; // INT1 external interrupt falling edge
    INT1IF  = 0; // Clear INT1 external interrupt flag
    INT1IE  = 1; // INT1 external interrupt enable

    // M1(RB2)  input pin
    ANSB2 = 0; // Disable analog function
    WPUB2 = 1; // Week pull up
    TRISB2 = 1; // Set as intput

    // Z80 clock(RB3) by CCP2 PWM mode
    ANSB3 = 0; // Disable analog function
    LATB3 = 0; // Clock low side
    TRISB3 = 0; // Set as output
    CCP2CONbits.CCP2M = 0b1100; // ECCP2 mode select PWM mode (P2A active-high, P2B active-high)
    CCP2CONbits.P2M = 0b00; // Enhanced PWM Single Output (P2A modulated, P2B assigned as port pin)
    PSTR2CONbits.STR2A = 1; // P2A pin has the PWM waveform
    PSTR2CONbits.STR2B = 0; // P2B pin is assigned to port pin
    CCPTMRS0bits.C2TSEL = 0b00; // CCP2 timer select PWM modes use Timer2
    CCPR2L = PWM_PERIOD / 2; // PWM duty cycle (9-2bits)
    CCP2CONbits.DC2B = 0b00; // PWM duty cycle (1-0bits)
    T2CONbits.T2CKPS = 0b00; // Timer2 clock prescaler 1:1
    PR2 = PWM_PERIOD - 1; // PWM period
    TMR2ON = 1; // Timer2 is on

    // MREQ(RB4) input pin
    ANSB4 = 0; // Disable analog function
    WPUB4 = 1; // Week pull up
    TRISB4 = 1; // Set as input

    // IOREQ(RB5) input pin
    ANSB5 = 0; // Disable analog function
    WPUB5 = 1; // Week pull up
    TRISB5 = 1; // Set as input

    // IN port(RB6) input pin
    WPUB6 = 1; // Week pull up
    TRISB6 = 1; // Set as input

    // OUT port(RB7) output pin
    LATB7 = 0; // Low output
    TRISB7 = 0; // Set as output

    // UART2 initialize
    SPBRG2 = 103;// 9600bps @ 64MHz
    CREN2 =1; // Receiver enable
    TXEN2 =1; // Transmitter enable

    // UART2 Receiver(RD7)
    ANSD7 = 0; // Disable analog function
    TRISD7 = 1; // RX set as input

    // UART2 Transmitter(RD6)
    ANSD6 = 0; // Disable analog function
    LATD6 = 1; // Default level
    TRISD6 = 0; // TX set as output

    SPEN2 =1; // Serial port enable

    // Wait for clock stabilization
    __delay_ms(2);

    // Z80 start
    GIE = 1; // Global interrupt enable
    LATE1 = 1; // Release reset

    while(1); // All things come to those who wait
}

const unsigned char rom[ROM_SIZE] = {
    // HELLO
    0x31, 0x00, 0x40, 0x21, 0x2d, 0x00, 0x7e, 0xfe,
    0x00, 0x28, 0x06, 0xcd, 0x19, 0x00, 0x23, 0x18,
    0xf5, 0xcd, 0x24, 0x00, 0xcd, 0x19, 0x00, 0x18,
    0xf8, 0xf5, 0xdb, 0xe1, 0xcb, 0x4f, 0x28, 0xfa,
    0xf1, 0xd3, 0xe0, 0xc9, 0xdb, 0xe1, 0xcb, 0x47,
    0x28, 0xfa, 0xdb, 0xe0, 0xc9, 0x48, 0x45, 0x4c,
    0x4c, 0x4f, 0x2c, 0x20, 0x57, 0x4f, 0x52, 0x4c,
    0x44, 0x0d, 0x0a, 0x00
};
