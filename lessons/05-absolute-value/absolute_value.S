; -----------------------------------------------------------------------------
; Lesson 05 - Absolute Value  (the checker)
;
; You do not need to edit this file. Each round it puts one signed value in
; INPUT, runs your code, and checks what you left in OUTPUT:
;
;   all five correct        ->  LED on, steady
;   one came back wrong     ->  LED blinks about ten times a second
;   never jumped to `done`  ->  LED stays dark
;
; Build & flash:  ./avr 5
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; New instructions in this lesson
;
;   neg  Rd           Replace Rd with its two's complement negative:          2 bytes, 1 cyc
;                       flip every bit, then add one.
;   com  Rd           One's complement: flip every bit and stop there.        2 bytes, 1 cyc
;   inc  Rd           Rd = Rd + 1. Any register.                              2 bytes, 1 cyc
;   brpl label        Branch if PLus: jump when the last result had its top   2 bytes, 2 cyc
;                       bit clear. Zero counts as plus.
;   brmi label        Branch if MInus: jump when the top bit was set.         2 bytes, 2 cyc
;
; The checker below deliberately negates the long way round, with `com` then
; `inc`, to show what `neg` is doing underneath. Either is correct; `neg` is
; one instruction instead of two.
; -----------------------------------------------------------------------------

#include "board.inc"

; --- the mock I/O ports the student sees -------------------------------------
#define OUTPUT      r16     /* the student writes the answer here */
#define INPUT       r17     /* one signed value appears here      */

; --- scratch, free for the student, reused by the checker after grading ------
#define CNT_LO      r18
#define CNT_MID     r19
#define CNT_HI      r20
#define EXPECTED    r18     /* only used at `done`, once the answer is in */

; --- the checker's own state; answer.inc is told not to touch these ----------
#define VAL         r21     /* this round's value, read as signed */
#define STEP        r22
#define REMAINING   r23

; Five values, stepping by 60 and wrapping the way a signed byte does:
;
;     round   bits    as signed   expected
;       1     0xC4       -60          60
;       2     0x00         0           0
;       3     0x3C        60          60
;       4     0x78       120         120
;       5     0xB4       -76          76     <- 120 + 60 ran past 127
;
; Both of the obvious wrong answers die early on this sequence: "just copy the
; input" fails at round 1, and "always negate" fails at round 3. Round 2 checks
; that zero is treated as positive, and round 5 exists because stepping past
; 127 wraps into the negative half - a two's complement fact worth seeing.
#define ROUNDS      5
#define FIRST_VALUE -60
#define STEP_BY     60

; 5 cycles per pass x 160,000 = 800,000 cycles = 50 ms, so a ~10 Hz blink.
#define BLINK_ITERATIONS 160000

    .section .text
    .global  main

main:
    sbi     LED_DDR, LED_BIT        ; make pin 13 an output
    ldi     REMAINING, ROUNDS
    ldi     VAL, FIRST_VALUE
    ldi     STEP, STEP_BY

next_round:
    mov     INPUT, VAL              ; deliver this round's value
    ldi     OUTPUT, 0               ; clear OUTPUT so last round's answer
                                    ;   cannot be mistaken for this one's

; --- run whatever the student wrote ------------------------------------------
#include "answer.inc"
; -----------------------------------------------------------------------------

    ; Reaching this point means the answer ran off the end without jumping to
    ; `done`, so the checker was never told to look.
    jmp     no_signal

done:
    ; Work out what the answer should have been. Done the long way on purpose:
    ; `com` flips every bit and `inc` adds one, which together are exactly what
    ; `neg` does in a single instruction.
    mov     EXPECTED, VAL
    cpi     EXPECTED, 0
    brpl    expected_ready          ; already positive (or zero) - leave it
    com     EXPECTED                ; flip every bit ...
    inc     EXPECTED                ; ... and add one

expected_ready:
    cp      OUTPUT, EXPECTED
    brne    wrong_answer

    add     VAL, STEP               ; next value; this deliberately wraps
    dec     REMAINING
    brne    next_round

all_correct:
    sbi     LED_PORT, LED_BIT       ; every round correct -> LED on, steady
    jmp     all_correct

no_signal:
    cbi     LED_PORT, LED_BIT       ; no stop condition -> leave the LED dark
    jmp     no_signal

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
