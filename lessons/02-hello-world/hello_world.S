; -----------------------------------------------------------------------------
; Lesson 02 - Hello, World  (the checker)
;
; You do not need to edit this file. It sets up the LED, runs whatever you
; wrote in answer.inc, and then checks the result:
;
;   OUTPUT holds 42   ->  LED on, steady
;   anything else     ->  LED blinks about ten times a second
;
; Build & flash:  ./avr 2
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; New instructions in this lesson
;
;   cpi  Rd, K        Compare with Immediate: work out Rd - K and set the      2 bytes, 1 cyc
;                       flags, but throw the answer away, leaving Rd alone.
;                       Rd must be r16-r31, like ldi.
;   brne label        Branch if Not Equal: jump to label if the last compare   2 bytes, 2 cyc
;                       found the two values different.
;
; Everything else (sbi, cbi, ldi, subi, sbci, brcc, jmp) is from lesson 01.
; -----------------------------------------------------------------------------

#include "board.inc"

; The register the student has to load, and the value it must end up holding.
; cpi can only compare r16-r31, which is another reason OUTPUT is r16.
#define OUTPUT      r16
#define EXPECTED    42

; Registers the "wrong answer" blink counts with. Deliberately NOT r16, so the
; checker cannot disturb the student's answer before it has been examined.
#define CNT_LO      r18
#define CNT_MID     r19
#define CNT_HI      r20

; 5 cycles per pass x 160,000 = 800,000 cycles = 50 ms at 16 MHz, so the
; failure blink runs at about 10 Hz - fast enough to look clearly different
; from lesson 01's steady 1 Hz.
#define BLINK_ITERATIONS 160000

    .section .text
    .global  main

main:
    sbi     LED_DDR, LED_BIT        ; make pin 13 an output

; --- run whatever the student wrote ------------------------------------------
#include "answer.inc"
; -----------------------------------------------------------------------------

; --- mark the answer ---------------------------------------------------------
    cpi     OUTPUT, EXPECTED        ; is OUTPUT holding 42?
    brne    wrong_answer            ; no -> go and blink

right_answer:
    sbi     LED_PORT, LED_BIT       ; yes -> LED on and leave it on
    jmp     right_answer

wrong_answer:
    sbi     LED_PORT, LED_BIT       ; LED on

    ldi     CNT_LO,  lo8(BLINK_ITERATIONS)
    ldi     CNT_MID, hi8(BLINK_ITERATIONS)
    ldi     CNT_HI,  hh8(BLINK_ITERATIONS)
on_delay:
    subi    CNT_LO,  1
    sbci    CNT_MID, 0
    sbci    CNT_HI,  0
    brcc    on_delay

    cbi     LED_PORT, LED_BIT       ; LED off

    ldi     CNT_LO,  lo8(BLINK_ITERATIONS)
    ldi     CNT_MID, hi8(BLINK_ITERATIONS)
    ldi     CNT_HI,  hh8(BLINK_ITERATIONS)
off_delay:
    subi    CNT_LO,  1
    sbci    CNT_MID, 0
    sbci    CNT_HI,  0
    brcc    off_delay

    jmp     wrong_answer
