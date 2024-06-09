/**
 * Generated Driver File
 * 
 * @file pins.c
 * 
 * @ingroup  pinsdriver
 * 
 * @brief This is generated driver implementation for pins. 
 *        This file provides implementations for pin APIs for all pins selected in the GUI.
 *
 * @version Driver Version 3.1.0
*/

/*
? [2024] Microchip Technology Inc. and its subsidiaries.

    Subject to your compliance with these terms, you may use Microchip 
    software and any derivatives exclusively with Microchip products. 
    You are responsible for complying with 3rd party license terms  
    applicable to your use of 3rd party software (including open source  
    software) that may accompany Microchip software. SOFTWARE IS ?AS IS.? 
    NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS 
    SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,  
    MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT 
    WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE, 
    INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY 
    KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF 
    MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE 
    FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP?S 
    TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT 
    EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR 
    THIS SOFTWARE.
*/

#include "../pins.h"


void PIN_MANAGER_Initialize(void)
{
   /**
    LATx registers
    */
    LATA = 0x4F;
    LATB = 0x0;
    LATC = 0x8C;
    LATD = 0x0;
    LATE = 0x0;

    /**
    TRISx registers
    */
    TRISA = 0x80;
    TRISB = 0xFF;
    TRISC = 0x30;
    TRISD = 0xFF;
    TRISE = 0xF;

    /**
    ANSELx registers
    */
    ANSELA = 0x20;
    ANSELB = 0xD8;
    ANSELC = 0x3;
    ANSELD = 0xFF;
    ANSELE = 0x7;

    /**
    WPUx registers
    */
    WPUA = 0x0;
    WPUB = 0x7;
    WPUC = 0x0;
    WPUD = 0x0;
    WPUE = 0x0;

    /**
    ODx registers
    */
    ODCONA = 0x0;
    ODCONB = 0x0;
    ODCONC = 0xC;
    ODCOND = 0x0;
    ODCONE = 0x0;

    /**
    SLRCONx registers
    */
    SLRCONA = 0xFF;
    SLRCONB = 0xFF;
    SLRCONC = 0xFF;
    SLRCOND = 0xFF;
    SLRCONE = 0x7;

    /**
    INLVLx registers
    */
    INLVLA = 0xFF;
    INLVLB = 0xFF;
    INLVLC = 0xFF;
    INLVLD = 0xFF;
    INLVLE = 0xF;

   /**
    RxyI2C | RxyFEAT registers   
    */
    RB1I2C = 0x0;
    RB2I2C = 0x0;
    RC3I2C = 0x1;
    RC4I2C = 0x0;
    /**
    PPS registers
    */
    U3RXPPS = 0x7; //RA7->UART3:RX3;
    CLCIN2PPS = 0x9; //RB1->CLC1:CLCIN2;
    CLCIN3PPS = 0xA; //RB2->CLC1:CLCIN3;
    SPI1SDIPPS = 0x15; //RC5->SPI1:SDI1;
    INT0PPS = 0x8; //RB0->INTERRUPT MANAGER:INT0;
    RA6PPS = 0x26;  //RA6->UART3:TX3;
    RA4PPS = 0x01;  //RA4->CLC1:CLC1;
    RC6PPS = 0x32;  //RC6->SPI1:SDO1;
    RC0PPS = 0x18;  //RC0->PWM1_16BIT:PWM11;
    RC1PPS = 0x19;  //RC1->PWM1_16BIT:PWM12;
    RA5PPS = 0x3F;  //RA5->NCO1:NCO1;
    I2C1SCLPPS = 0x12;  //RC2->I2C1:SCL1;
    RC2PPS = 0x37;  //RC2->I2C1:SCL1;
    I2C1SDAPPS = 0x13;  //RC3->I2C1:SDA1;
    RC3PPS = 0x38;  //RC3->I2C1:SDA1;
    CCP1PPS = 0xD;  //RB5->CCP1:CCP1;
    RB5PPS = 0x15;  //RB5->CCP1:CCP1;
    SPI1SCKPPS = 0x14;  //RC4->SPI1:SCK1;
    RC4PPS = 0x31;  //RC4->SPI1:SCK1;

   /**
    IOCx registers 
    */
    IOCAP = 0x0;
    IOCAN = 0x0;
    IOCAF = 0x0;
    IOCBP = 0x0;
    IOCBN = 0x0;
    IOCBF = 0x0;
    IOCCP = 0x0;
    IOCCN = 0x0;
    IOCCF = 0x0;
    IOCEP = 0x0;
    IOCEN = 0x0;
    IOCEF = 0x0;


}
  
void PIN_MANAGER_IOC(void)
{
}
/**
 End of File
*/