/*
 * File:   main.c
 * Author: hseiyama
 *
 * Created on 2023/07/25, 0:14
 */

// PIC18F26K22 Configuration Bit Settings

// 'C' source line config statements

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
#pragma config CCP2MX = PORTC1  // CCP2 MUX bit (CCP2 input/output is multiplexed with RC1)
#pragma config PBADEN = ON      // PORTB A/D Enable bit (PORTB<5:0> pins are configured as analog input channels on Reset)
#pragma config CCP3MX = PORTB5  // P3A/CCP3 Mux bit (P3A/CCP3 input/output is multiplexed with RB5)
#pragma config HFOFST = OFF     // HFINTOSC Fast Start-up (HFINTOSC output and ready status are delayed by the oscillator stable status)
#pragma config T3CMX = PORTC0   // Timer3 Clock input mux bit (T3CKI is on RC0)
#pragma config P2BMX = PORTB5   // ECCP2 B output mux bit (P2B is on RB5)
#pragma config MCLRE = INTMCLR  // MCLR Pin Enable bit (RE3 input pin enabled; MCLR disabled)

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

#define _XTAL_FREQ 64000000   // delay用に必要(クロック64MHzを指定)

// 指定した時間(num x 10ms)だけウエイトを行う処理関数
void Wait(unsigned int num)
{
    int i ;
    
    // numで指定した回数だけ繰り返す
    for (i=0 ; i < num ; i++) {
         __delay_ms(10) ;    // 10msプログラムの一時停止
    }
}

void main(void) {
    uint8_t data_uart;
    /* CLOCK初期化 */
    OSCCON = 0b01110000;    // 内部クロックとする(16MHz、プライマリ クロック)
    PLLEN  = 1;             // PLL(x4)を有効化
    /* PORT初期化 */
    ANSELA = 0b00000000;    // AN0-4 アナログは使用しない、デジタルI/Oに割当
    ANSELB = 0b00000000;    // AN8-13アナログは使用しない、デジタルI/Oに割当
    ANSELC = 0b00000000;    // AN14-19アナログは使用しない、デジタルI/Oに割当
    TRISA  = 0b11111000;    // RA0-2のみ出力に設定、1で入力 0で出力
    TRISB  = 0b11111111;    // RB0-RB7全て入力に設定
    TRISC  = 0b11111111;    // RC0-RC7全て入力に設定 
    PORTA  = 0b00000000;    // 出力ピンの初期化(全てLOWにする)
    PORTB  = 0b00000000;    // 出力ピンの初期化(全てLOWにする)
    PORTC  = 0b00000000;    // 出力ピンの初期化(全てLOWにする)
    RBPU   = 0;             // PORTBプルアップ有効
    WPUB   = 0xFF;          // RB0-RB7全てプルアップ有効
    /* ESUART1初期化 */
    TXSTA1 = 0b00100000;    // 送信情報設定：非同期モード、８ビット・ノンパリティ
    RCSTA1 = 0b10010000;    // 受信情報設定
    SPBRG1 = 103;           // ボーレートを9600(低速モード)に設定
    
    while(1) {
        if(PORTBbits.RB0 == 1) {    // RB0がHIGHの場合
            LATA1 = 0;
        }
        else{
            LATA1 = 1;
        }
        if(PORTBbits.RB1 == 1) {    // RB1がHIGHの場合
            LATA2 = 1;
        }
        else{
            LATA2 = 0;
        }
        LATA0 = 1 ;         // 2番ピン(RA0)にHIGH(5V)を出力する(LED ON)
//      LATAbits.LA0 = 1;   // ◆こちらの表現も可能
        if(RC1IF == 1) {            // UART受信があった場合
            data_uart = RCREG1;     // レジスタからデータを受信
            while(TX1IF == 0);      // 送信可能になるまで待つ
            TXREG1 = data_uart;     // 送信する
        }
        Wait(100) ;         // 1秒ウエイト
        LATA0 = 0 ;         // 2番ピン(RA0)にLOW(0V)を出力する(LED OFF)
        TXREG1 = 'Z';       // 送信する
        Wait(100) ;         // 1秒ウエイト
    }
}
