; -----------------------------------------------------------------------------
; Lesson 03 - Echo  (the checker)
;
; You do not need to edit this file. It hands your code five different values
; one at a time, and after each one it checks what you put in OUTPUT:
;
;   all five echoed correctly  ->  LED on, steady
;   one came back wrong        ->  LED blinks about ten times a second
;   never jumped to `done`     ->  LED stays dark
;
; Build & flash:  ./avr 3
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; New instructions in this lesson
;
;   mov  Rd, Rr       Copy the contents of register Rr into register Rd.      2 bytes, 1 cyc
;                       Any registers, r0-r31 - it takes no constant, so the
;                       r16-r31 rule does not apply.
;   cp   Rd, Rr       Compare two registers: work out Rd - Rr and set the     2 bytes, 1 cyc
;                       flags, leaving both registers alone. Like cpi, but
;                       against a register instead of a constant.
;   add  Rd, Rr       Rd = Rd + Rr.                                          2 bytes, 1 cyc
;   dec  Rd           Rd = Rd - 1. Any register, r0-r31.                     2 bytes, 1 cyc
;
; Everything else (sbi, cbi, ldi, subi, sbci, brcc, brne, jmp) is from
; lessons 01 and 02.
; -----------------------------------------------------------------------------

#include "board.inc"

; --- the mock I/O ports the student sees -------------------------------------
#define OUTPUT      r16     /* the student writes their answer here */
#define INPUT       r17     /* the checker delivers a value here    */

; --- scratch, free for the student to use, reused later by the blink ---------
#define CNT_LO      r18
#define CNT_MID     r19
#define CNT_HI      r20

; --- the checker's own state; answer.inc is told not to touch these ----------
#define REMAINING   r21     /* rounds left to run   */
#define TESTVAL     r22     /* the value handed in this round */
#define STEP        r23     /* how much TESTVAL grows each round */

; Five values: 7, 44, 81, 118, 155. They are deliberately unrelated and all
; different, so an answer that hardcodes one constant clears round one and
; then fails round two.
#define ROUNDS      5
#define FIRST_VALUE 7
#define STEP_VALUE  37

; 5 cycles per pass x 160,000 = 800,000 cycles = 50 ms, so a ~10 Hz blink.
#define BLINK_ITERATIONS 160000

    .section .text
    .global  main

main:
    sbi     LED_DDR, LED_BIT        ; make pin 13 an output
    ldi     REMAINING, ROUNDS       ; five rounds to run
    ldi     TESTVAL, FIRST_VALUE    ; first value to hand over
    ldi     STEP, STEP_VALUE

next_round:
    mov     INPUT, TESTVAL          ; deliver this round's value
    ldi     OUTPUT, 0               ; clear OUTPUT so last round's answer
                                    ;   cannot be mistaken for this one's

; --- run whatever the student wrote ------------------------------------------
#include "answer.inc"
; -----------------------------------------------------------------------------

    ; Reaching this point means the answer ran off the end without jumping to
    ; `done`, so the checker was never told to look. Report that separately.
    jmp     no_signal

done:
    ; Compare against TESTVAL, not INPUT: TESTVAL belongs to the checker, so an
    ; answer that overwrites INPUT cannot make itself look correct.
    cp      OUTPUT, TESTVAL
    brne    wrong_answer

    add     TESTVAL, STEP           ; move on to the next value
    dec     REMAINING               ; one fewer round to go
    brne    next_round              ; more to do -> hand over the next value

all_correct:
    sbi     LED_PORT, LED_BIT       ; every round echoed -> LED on, steady
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
