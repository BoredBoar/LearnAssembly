; -----------------------------------------------------------------------------
; board.inc - which port and bit each lesson's pin actually lives on
;
; The number silkscreened on an Arduino header is a *label*, not an address.
; Assembly talks to ports and bits, and the same silkscreen number sits on a
; different port depending on the chip:
;
;     silkscreen    Uno (ATmega328P)      Mega 2560 (ATmega2560)
;     ----------    ----------------      ----------------------
;     13 (LED)      PB5                   PB7
;      2 (button)   PD2                   PE4
;
; Wiring instructions are therefore identical on both boards, but the source is
; not. Everything board-specific lives here so the lessons themselves stay
; about the instruction set.
;
; avr-gcc defines __AVR_ATmega2560__ / __AVR_ATmega328P__ from the -mmcu flag
; that PlatformIO derives from `board` in platformio.ini.
;
; Each name below is wrapped in _SFR_IO_ADDR() so the lessons can write a plain
;     sbi LED_PORT, LED_BIT
; avr/io.h gives every register its address in DATA space (PORTB = 0x25), but
; sbi/cbi/sbic/in/out address the smaller I/O space, where the same register is
; 0x05. _SFR_IO_ADDR() is just that subtraction of 0x20. Doing it once here
; keeps it out of every instruction in every lesson.
;
; Consequence: these names are I/O addresses, so they work with sbi/cbi/sbic/
; in/out only. Code that needs lds/sts (any port at 0x100+, such as the Mega's
; PORTH) must use the bare avr/io.h name instead.
; -----------------------------------------------------------------------------

#ifndef BOARD_INC
#define BOARD_INC

#include <avr/io.h>

#if defined(__AVR_ATmega2560__)

    /* --- Arduino Mega 2560 / ELEGOO MEGA ---------------------------------- */
    #define LED_DDR     _SFR_IO_ADDR(DDRB)            /* digital pin 13 -> PB7 */
    #define LED_PORT    _SFR_IO_ADDR(PORTB)
    #define LED_BIT     PB7

    #define BTN_DDR     _SFR_IO_ADDR(DDRE)            /* digital pin 2  -> PE4 */
    #define BTN_PORT    _SFR_IO_ADDR(PORTE)
    #define BTN_PIN     _SFR_IO_ADDR(PINE)
    #define BTN_BIT     PE4

#elif defined(__AVR_ATmega328P__)

    /* --- Arduino Uno / ELEGOO UNO ----------------------------------------- */
    #define LED_DDR     _SFR_IO_ADDR(DDRB)            /* digital pin 13 -> PB5 */
    #define LED_PORT    _SFR_IO_ADDR(PORTB)
    #define LED_BIT     PB5

    #define BTN_DDR     _SFR_IO_ADDR(DDRD)            /* digital pin 2  -> PD2 */
    #define BTN_PORT    _SFR_IO_ADDR(PORTD)
    #define BTN_PIN     _SFR_IO_ADDR(PIND)
    #define BTN_BIT     PD2

#else
    #error "Unknown board - add its pin map to include/board.inc"
#endif

#endif /* BOARD_INC */
