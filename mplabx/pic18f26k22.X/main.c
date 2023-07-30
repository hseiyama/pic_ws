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

#define _XTAL_FREQ  64000000    // delay用に必要(クロック64MHzを指定)
#define TMR0H_INIT  0x0B        // タイマー0H,Lのカウント開始の初期値
#define TMR0L_INIT  0xDB        // ([0xFFFF-62,500]→1秒)

volatile uint8_t data_uart;
volatile uint16_t data_adc;

/* USART送信 (1文字) */
static void send_char(uint8_t data) {
    while(TX1IF == 0);          // 送信可能になるまで待つ
    TXREG1 = data;              // データを送信する
}

/* USART送信 (文字列) */
static void send_strg(uint8_t *data) {
    // 文字がNULLになるまで継続
    while(*data != 0x00) {
        send_char(*data);       // USART送信 (1文字)
        data++;
    }
}

/* HEX数字送信 */
static void echo_hex(uint8_t hex_data) {
    uint8_t hex_table[] = {
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
    };
    send_char(hex_table[(hex_data >> 4) & 0x0F]);
    send_char(hex_table[hex_data & 0x0F]);
}

/* 16進数データ送信 (2byte) */
static void echo_2byte(uint16_t data) {
    uint8_t msg[] = "0x";
    send_strg(msg);
    echo_hex((data >> 8) & 0xFF);   // HEX数字送信
    echo_hex(data & 0xFF);          // HEX数字送信
}

// 受信割込み処理
void __interrupt() isr(void) {
    if (RC1IF == 1) {           // 割込みはUSART通信の受信か？
        data_uart = RCREG1;     // レジスタからデータを受信
        send_char(data_uart);   // データ受信を送信する
    }
    if (TMR0IF == 1) {          // タイマー0の割込み発生か？
        TMR0H = TMR0H_INIT;     // タイマー0H,Lのカウント開始の初期値をセットする
        TMR0L = TMR0L_INIT;     // (1秒)
        /* 1msタイマ割り込み毎の処理 */
        {
            /* PORT操作処理 */
            LATA0 = !LATA0;         // 2番ピン(RA0)を反転出力する
            LATA1 = !PORTBbits.RB0; // RB0を反転し、RA1に出力する
            LATA2 = PORTBbits.RB1;  // RB1を入力し、RA1に出力する
        }
        TMR0IF = 0 ;            // タイマー0割込フラグをリセット
    }
}

// 指定した時間(num x 10ms)だけウエイトを行う処理関数
static void wait10ms(uint16_t num) {
    uint16_t index ;

    // numで指定した回数だけ繰り返す
    for (index=0; index < num; index++) {
        __delay_ms(10);         // 10msプログラムの一時停止
    }
}

void main(void) {
    /* CLOCK初期化 */
    OSCCON  = 0b01110000;       // 内部クロックとする(16MHz、プライマリ クロック)
    PLLEN   = 1;                // PLL(x4)を有効化(→64MHz)
    /* PORT初期化 */
    ANSELA  = 0b00000000;       // AN0-4 アナログは使用しない、デジタルI/Oに割当
    ANSELB  = 0b00000100;       // AN8ｱﾅﾛｸﾞのみ使用する、9-13ｱﾅﾛｸﾞは使用しない
    ANSELC  = 0b00000000;       // AN14-19アナログは使用しない、デジタルI/Oに割当
    TRISA   = 0b11111000;       // RA0-2のみ出力に設定、1で入力 0で出力
    TRISB   = 0b11111111;       // RB0-RB7全て入力に設定
    TRISC   = 0b11111111;       // RC0-RC7全て入力に設定 
    PORTA   = 0b00000001;       // 出力ピンの初期化(RA0のみHI、他はLOWにする)
    PORTB   = 0b00000000;       // 出力ピンの初期化(全てLOWにする)
    PORTC   = 0b00000000;       // 出力ピンの初期化(全てLOWにする)
    RBPU    = 0;                // PORTBプルアップ有効
    WPUB    = 0xFF;             // RB0-RB7全てプルアップ有効
    /* ESUART1初期化 */
    TXSTA1  = 0b00100000;       // 送信情報設定：非同期モード、８ビット・ノンパリティ
    RCSTA1  = 0b10010000;       // 受信情報設定
    SPBRG1  = 103;              // ボーレートを9600(低速モード)に設定
    RC1IE   = 1;                // USART割込み受信を有効にする
    /* TIMER0初期化 */
    T0CON   = 0b10000111;       // 内部ｸﾛｯｸ(64MHz/4)でTIMER0を16ビットにて使用、ﾌﾟﾘｽｹｰﾙ値 1:256
    TMR0H   = TMR0H_INIT;       // タイマー0H,Lのカウント開始の初期値をセットする
    TMR0L   = TMR0L_INIT;       // (この書込みﾀｲﾐﾝｸﾞで、TMR0H,Lが反映される)
    TMR0IF  = 0;                // タイマー0割込フラグ(T0IF)を0にする
    TMR0IE  = 1;                // タイマー0割込み(T0IE)を許可する
    /* ADC初期化*/
    ADCON0  = 0b00100001;       // ﾁｬﾈﾙ選択AN8、ADCを有効化
    ADCON1  = 0b00000000;       // 負電圧VSS、正電圧VDD
    ADCON2  = 0b10010110;       // ﾌｫｰﾏｯﾄ右詰め、ｱｸｲｼﾞｮﾝ時間4TAD、変換ｸﾛｯｸFOSC/64
    /* 全体初期化 */
    PEIE    = 1;                // 周辺装置割込みを有効にする
    ei();                       // 全割込み処理を許可する
    
    while(1) {
        wait10ms(100);          // 1秒ウエイト
        GO = 1;                 // A/D変換サイクルを開始する
        while(DONE == 0);       // A/D変換が完了するまで待つ
        data_adc = ((ADRESH << 8) | ADRESL) & 0x03FF;   // A/D結果を取得
        /* メッセージ出力 */
        uint8_t msg1[] = ">ADC0=";
        uint8_t msg2[] = "\r\n";
        send_strg(msg1);
        echo_2byte(data_adc);   // 16進数データ送信 (2byte)
        send_strg(msg2);
    }
}
