; -----------------------------------------------------------------------------
; Lesson 01 - Blink
;
; Turns the onboard LED on digital pin 13 on and off about twice a second.
;
; Straight-line code: no subroutines, no stack, nothing hidden. Read it from
; top to bottom. The reasoning behind each choice is in README.md.
;
; Build & flash:  pio run -e mega-01-blink -t upload
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; The seven instructions used in this program
;
;   sbi  ioreg, bit   Set Bit in I/O register: drive one pin high    2 bytes, 2 cyc
;   cbi  ioreg, bit   Clear Bit in I/O register: drive one pin low   2 bytes, 2 cyc
;   ldi  Rd, K        Load Immediate: put constant K into register   2 bytes, 1 cyc
;                       Rd. Rd must be one of r16-r31.
;   subi Rd, K        Subtract Immediate: Rd = Rd - K. Sets the      2 bytes, 1 cyc
;                       carry flag if the subtraction borrowed.
;   sbci Rd, K        Subtract Immediate with Carry: Rd = Rd - K -   2 bytes, 1 cyc
;                       carry. Chains a borrow into the next byte up.
;   brcc label        Branch if Carry Cleared: jump to label if the  2 bytes, 2 cyc
;                       last subtraction did not borrow. The label
;                       is stored as a distance, max +63/-64 words.
;   jmp  label        Jump to an absolute address in flash.          4 bytes, 3 cyc
;
; That is the whole vocabulary. Everything else in the file is a name defined by
; the preprocessor (LED_PORT, CNT_LO, ...) or a label marking a spot to jump to.
; -----------------------------------------------------------------------------

; Which port and bit pin 13 is on, for whichever board we are building for.
#include "board.inc"

; The chip runs at 16 MHz and one pass of the delay loop below takes 5 clock
; cycles, so 1,600,000 passes = 8,000,000 cycles = half a second.
#define DELAY_ITERATIONS 1600000

; Names for the three registers that hold our countdown. It has to be three,
; because each register is 8 bits and 1,600,000 does not fit in one.
; These must be r16-r31: ldi cannot load a constant into r0-r15. See README.md.
#define CNT_LO      r18
#define CNT_MID     r19
#define CNT_HI      r20

    .section .text
    .global  main            ; the startup code jumps here after reset

main:
    sbi     LED_DDR, LED_BIT        ; make pin 13 an output

blink_loop:

    sbi     LED_PORT, LED_BIT       ; LED on

    ldi     CNT_LO,  lo8(DELAY_ITERATIONS)     ; load 1,600,000 into the
    ldi     CNT_MID, hi8(DELAY_ITERATIONS)     ;   three registers, lowest
    ldi     CNT_HI,  hh8(DELAY_ITERATIONS)     ;   8 bits in each
on_delay:
    subi    CNT_LO,  1              ; subtract 1 from the low byte
    sbci    CNT_MID, 0              ;   carrying the borrow into the middle
    sbci    CNT_HI,  0              ;   and then into the high byte
    brcc    on_delay                ; repeat until the count passes zero

    cbi     LED_PORT, LED_BIT       ; LED off

    ldi     CNT_LO,  lo8(DELAY_ITERATIONS)     ; wait the same amount again
    ldi     CNT_MID, hi8(DELAY_ITERATIONS)
    ldi     CNT_HI,  hh8(DELAY_ITERATIONS)
off_delay:
    subi    CNT_LO,  1
    sbci    CNT_MID, 0
    sbci    CNT_HI,  0
    brcc    off_delay

    jmp     blink_loop              ; start over
