/*
 * Blink the LED on a PIC18F47K42 Curiosity Nano Board
 * using the timer and interrupts to control the flash period.
 */
    
#include <xc.inc>

CONFIG "FEXTOSC = OFF"          // External Oscillator  not enabled
CONFIG "RSTOSC = HFINTOSC_1MHZ" // Reset Oscillator->HFINTOSC, HFFRQ=4MHz, CDIV=4:1
CONFIG "CLKOUTEN = OFF"         // Clock out Enable->CLKOUT function is disabled
CONFIG "PR1WAY = ON"            // PRLOCK cleared/set only once
CONFIG "CSWEN = ON"             // Writing to NOSC and NDIV is allowed
CONFIG "FCMEN = ON"             // Clock Monitor enabled

CONFIG "MCLRE = EXTMCLR"        // LVP=0=>MCLR pin is MCLR; LVP=1=>MCLR on RE3
CONFIG "PWRTS = PWRT_OFF"       // Power-up timer selection bits->PWRT is disabled
CONFIG "MVECEN = ON"            // Multi-vector enable->Multi-vector table enabled
CONFIG "IVT1WAY = ON"           // IVTLOCK cleared/set only once
CONFIG "LPBOREN = OFF"          // Low Power BOR Enable bit->ULPBOR disabled
CONFIG "BOREN = SBORDIS"        // BOR enabled, SBOREN ignored
CONFIG "BORV = VBOR_2P45"       // Brown-out Reset Voltage->VBOR set to 2.45V
CONFIG "ZCD = OFF"              // ZCD disabled; enable by setting ZCDSEN
CONFIG "PPS1WAY = ON"           // PPSLOCK cleared/set only once
CONFIG "STVREN = ON"            // Stack Full/underflow => Reset
CONFIG "DEBUG = OFF"            // Debugger Enable->Background debugger disabled
CONFIG "XINST = OFF"            // Extended Instruction Set Enable->Disabled

CONFIG "WDTCPS = WDTCPS_31"     // WDT Period->Divider 1:65536; software control
CONFIG "WDTE = OFF"             // WDT Disabled; SWDTEN is ignored
CONFIG "WDTCWS = WDTCWS_7"      // WDT window open (100%); software control
CONFIG "WDTCCS = SC"            // WDT input clock selector->Software Control

CONFIG "BBSIZE = BBSIZE_512"    // Boot Block Size->Boot Block size is 512 words
CONFIG "BBEN = OFF"             // Boot Block enable bit->Boot block disabled
CONFIG "SAFEN = OFF"            // Storage Area Flash enable bit->SAF disabled
CONFIG "WRTAPP = OFF"           // Application Block  not protected
CONFIG "WRTB = OFF"             // Configuration Register not protected
CONFIG "WRTC = OFF"             // Boot Block not write-protected
CONFIG "WRTD = OFF"             // Data EEPROM not write-protected
CONFIG "WRTSAF = OFF"           // SAF not Write Protected
CONFIG "LVP = ON"               // Low Voltage Programming Enable->LVP enabled

CONFIG "CP = OFF"               // PFM and Data EEPROM Code Protection->Disabled

GLOBAL resetVec
GLOBAL LEDState               ;make this global so it is watchable when debugging
GLOBAL __Livt                 ;defined by the linker but used in this code

PSECT bitbssCOMMON,bit,class=COMRAM,space=1
LEDState:
    DS          1             ;a single bit used to hold the required LED state

PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto        start

;vector table
PSECT ivt,class=CODE,reloc=2,ovrld
ivtbase:
    ORG         31*2           ;timer 0 vector position
    DW          tmr0Isr shr 2  ;timer 0 ISR address shifted right

PSECT textISR,class=CODE,reloc=4
tmr0Isr:
    bcf         TMR0IF      ;clear the timer interrupt flag
    ;toggle the desired LED state
    movlw       1 shl (LEDState&7)
    xorwf       LEDState/(0+8),c

    retfie      f

PSECT code
start:
    bsf         BANKMASK(INTCON0),INTCON0_IPEN_POSN,c        ;set IPEN bit
    ;use the unlock sequence to set the vector table position
    ;based on where the ivt psect is linked
    bcf         GIE
    movlw       0x55
    movwf       BANKMASK(IVTLOCK),c
    movlw       0xAA
    movwf       BANKMASK(IVTLOCK),c
    bcf         IVTLOCKED
    movlw       low highword __Livt
    movwf       BANKMASK(IVTBASEU),c
    movlw       high __Livt
    movwf       BANKMASK(IVTBASEH),c
    movlw       low __Livt
    movwf       BANKMASK(IVTBASEL),c
    movlw       0x55
    movwf       BANKMASK(IVTLOCK),c
    movlw       0xAA
    movwf       BANKMASK(IVTLOCK),c
    bsf         IVTLOCKED
    ;set up the state of the oscillator and peripherals with RE0 as a digital
    ;output driving the LED, assuming that other registers have not changed
    ;from their reset state
    movlw       6
    movwf       BANKMASK(TRISE),c
    movlw       0x62
    movlb       57
    movwf       BANKMASK(OSCCON1),b  
    clrf        BANKMASK(OSCCON3),b
    clrf        BANKMASK(OSCEN),b
    movlw       2
    movwf       BANKMASK(OSCFRQ),b
    clrf        BANKMASK(OSCTUNE),b
    ;configure and start timer interrupts
    movlb       57
    bsf         TMR0IP
    movlw       0x6D
    movwf       BANKMASK(T0CON1),c
    movlw       0xF3
    movwf       BANKMASK(TMR0H),c
    clrf        BANKMASK(TMR0L),c
    movlb       57
    bcf         TMR0IF
    bsf         TMR0IE
    movlw       0x80
    movwf       BANKMASK(T0CON0),c
    bsf         GIEH
loop:
    ;set LED state to be that requested by the interrupt code
    btfss       LEDState/8,LEDState&7,c    
    goto        lightLED
    bsf         RE0          ;turn LED off
    goto        loop
lightLED:
    bcf         RE0          ;turn LED on
    goto        loop

    END         resetVec
