; -----------------------------------------------------------------------------
; Lesson 05 - Absolute Value        >>> THIS IS THE ONLY FILE YOU EDIT <<<
;
; YOUR TASK
;   Read a value from INPUT and put its ABSOLUTE VALUE into OUTPUT.
;   Positive stays as it is; negative becomes positive.
;
;   INPUT  is r17.   OUTPUT is r16.   Signal with `jmp done` when finished.
;   Only one value per round this time - no `next_input` needed.
;
; -----------------------------------------------------------------------------
; FIRST, A PROBLEM: WHERE DOES A MINUS SIGN LIVE?
;
; A register holds eight bits. Eight bits is 256 different patterns, and that
; is all you get - there is no room for a separate "sign" flag. So how does the
; chip store -1?
;
; The trick is called TWO'S COMPLEMENT, and the idea is to let the numbers wrap
; around like a clock. Counting up from 255 does not reach 256; it wraps to 0.
; So counting DOWN from 0 must wrap to 255. That means 255 sits one below zero
; - which is exactly what -1 should do. So we simply agree to call it -1:
;
;     bits        unsigned    signed
;     0000 0000       0          0
;     0000 0001       1          1
;     0111 1111     127        127     <- biggest positive
;     1000 0000     128       -128     <- most negative
;     1111 1110     254         -2
;     1111 1111     255         -1
;
; Nothing about the bits changed. The SAME pattern 1111 1111 is 255 or -1
; depending only on how you choose to read it. The chip does not know or care;
; `add` and `sub` give the right answer either way, which is the whole point of
; two's complement.
;
; The top bit tells you which half you are in: 0 means the number reads as
; positive, 1 means it reads as negative. That bit is copied into the N flag
; every time an instruction produces a result.
;
; TO NEGATE a number, flip every bit and add one:
;
;        60  =  0011 1100
;     flip    =  1100 0011      (this is `com`, the one's complement)
;     add 1   =  1100 0100      (= 0xC4, which reads as -60)
;
; Check it: -60 + 60 should be 0.   1100 0100 + 0011 1100 = 1 0000 0000.
; The ninth bit falls off the end of an 8-bit register, leaving 0000 0000. It
; works out exactly.
;
; The instruction `neg` does both steps for you in one go.
;
; ONE ODDITY WORTH KNOWING
;   -128 is its own negative. There is no +128 in a signed byte, so negating
;   1000 0000 gives 1000 0000 back. Every language has this bug; you are not
;   doing anything wrong. The test values avoid it.
; -----------------------------------------------------------------------------
;
; INSTRUCTIONS YOU MIGHT WANT
;   mov  Rd, Rr    copy a register
;   cpi  Rd, 0     compare with zero to set the flags (Rd must be r16-r31)
;   brpl label     branch if the last result was PLus - top bit clear, so zero
;                    counts as positive
;   brmi label     branch if the last result was MInus - top bit set
;   neg  Rd        replace Rd with its two's complement negative
;   jmp  label     jump
;
; THINK ABOUT
;   Which values need changing, and which are already correct? You only have to
;   act on one of the two cases.
;
; THIS RUNS MORE THAN ONCE
;   Five values, some negative, some positive, and one of them is zero. An
;   answer that always negates fails just as surely as one that never does.
;
; HOW YOU KNOW IT WORKED
;   Build and flash with:   ./avr 5
;     LED on, steady  ->  all five correct
;     LED blinking    ->  one came back wrong
;     LED dark        ->  you never jumped to `done`
;
; WHICH REGISTERS YOU MAY USE
;   r16 (OUTPUT), r17 (INPUT), r18-r20 scratch. Leave r21-r23 alone.
; -----------------------------------------------------------------------------


    ; ================= write your answer below this line =================



    ; ================= write your answer above this line =================
