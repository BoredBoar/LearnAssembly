; -----------------------------------------------------------------------------
; Lesson 02 - Reading an input pin
;
; Lights the onboard LED (digital pin 13) while a pushbutton wired between
; digital pin 2 and GND is held down.
;
; Wiring: one leg of the button to pin 2, the other leg to GND.
;         No external resistor - we switch on the ATmega's internal pull-up,
;         so the pin reads 1 when the button is up and 0 when it is pressed.
;         The wiring is the same on an Uno and a Mega; the ports behind those
;         two pins are not. See include/board.inc.
;
; Build & flash:  pio run -e mega-02-button-led -t upload
; -----------------------------------------------------------------------------

#include "board.inc"

    .section .text
    .global  main

main:
    ; --- LED pin as an output ------------------------------------------------
    sbi     LED_DDR, LED_BIT

    ; --- Button pin as an input with its pull-up enabled ---------------------
    cbi     BTN_DDR, BTN_BIT    ; 0 in DDR = input
    sbi     BTN_PORT, BTN_BIT   ; 1 in PORT of an input = pull-up

read_loop:
    ; BTN_PIN is the *input* register: it reports the live voltage on the port.
    ; sbic = Skip next instruction if Bit in I/O register is Clear.
    ; Button pressed -> the pin is pulled to GND -> bit is 0 -> rjmp is skipped.
    sbic    BTN_PIN, BTN_BIT
    rjmp    led_off                           ; bit was 1: not pressed

led_on:
    sbi     LED_PORT, LED_BIT
    rjmp    read_loop

led_off:
    cbi     LED_PORT, LED_BIT
    rjmp    read_loop
