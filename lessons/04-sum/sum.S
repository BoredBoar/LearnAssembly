; -----------------------------------------------------------------------------
; Lesson 04 - Sum  (the checker)
;
; You do not need to edit this file. Each round it puts one value in INPUT,
; runs your code, hands over a second value when you ask for it, and then
; checks the total you left in OUTPUT:
;
;   all five totals correct  ->  LED on, steady
;   one came back wrong      ->  LED blinks about ten times a second
;   never jumped to `done`   ->  LED stays dark
;
; Build & flash:  ./avr 4
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; No new instructions this time. The new idea is the handshake:
;
;   jmp next_input    the student asks for the next value. The checker loads it
;                     into INPUT and jumps back to the student's `resume` label.
;                     This is a subroutine call built by hand out of two plain
;                     jumps - no rcall, no ret, and nothing on the stack. The
;                     price of doing it this way is that the return point is
;                     fixed: `next_input` always comes back to `resume`.
;
;   jmp done          the student says the answer is ready to be graded.
; -----------------------------------------------------------------------------

#include "board.inc"

; --- the mock I/O ports the student sees -------------------------------------
#define OUTPUT      r16     /* the student writes the total here */
#define INPUT       r17     /* one value at a time appears here  */

; --- scratch, free for the student, reused by the checker after grading ------
#define CNT_LO      r18
#define CNT_MID     r19
#define CNT_HI      r20
#define EXPECTED    r18     /* only used at `done`, once the answer is in */

; --- the checker's own state; answer.inc is told not to touch these ----------
#define VAL_A       r21     /* this round's first value  */
#define VAL_B       r22     /* this round's second value */
#define REMAINING   r23     /* rounds left to run        */
#define STEP_A      r24
#define STEP_B      r25

; Five pairs, generated rather than tabulated:
;     7+5=12   44+16=60   81+27=108   118+38=156   155+49=204
; Chosen so that no total exceeds 255 (add never overflows - carry is a later
; lesson), no total coincides with either input, and the two inputs are never
; equal, so answers like "return the input" or "double the first value" fail.
#define ROUNDS      5
#define FIRST_A     7
#define FIRST_B     5
#define STEP_A_BY   37
#define STEP_B_BY   11

; 5 cycles per pass x 160,000 = 800,000 cycles = 50 ms, so a ~10 Hz blink.
#define BLINK_ITERATIONS 160000

    .section .text
    .global  main

main:
    sbi     LED_DDR, LED_BIT        ; make pin 13 an output
    ldi     REMAINING, ROUNDS
    ldi     VAL_A, FIRST_A
    ldi     VAL_B, FIRST_B
    ldi     STEP_A, STEP_A_BY
    ldi     STEP_B, STEP_B_BY

next_round:
    mov     INPUT, VAL_A            ; only the FIRST value is waiting
    ldi     OUTPUT, 0               ; clear OUTPUT so last round's total
                                    ;   cannot be mistaken for this one's

; --- run whatever the student wrote ------------------------------------------
#include "answer.inc"
; -----------------------------------------------------------------------------

    ; Reaching this point means the answer ran off the end without jumping to
    ; `done`, so the checker was never told to look.
    jmp     no_signal

next_input:
    mov     INPUT, VAL_B            ; hand over the second value ...
    jmp     resume                  ; ... and give control back to the student

done:
    mov     EXPECTED, VAL_A         ; the total we were expecting
    add     EXPECTED, VAL_B
    cp      OUTPUT, EXPECTED        ; compare against the checker's own copies,
    brne    wrong_answer            ;   never against INPUT

    add     VAL_A, STEP_A           ; move on to the next pair
    add     VAL_B, STEP_B
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
