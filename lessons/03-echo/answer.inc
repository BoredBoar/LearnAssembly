; -----------------------------------------------------------------------------
; Lesson 03 - Echo                  >>> THIS IS THE ONLY FILE YOU EDIT <<<
;
; YOUR TASK
;   Whatever value arrives in INPUT, put that same value into OUTPUT.
;   Then signal that you are finished with this value.
;
;   INPUT  is r17 - the checker puts a new value there for you each round.
;   OUTPUT is r16 - put your answer there.
;
; THE STOP CONDITION
;   When your answer is ready, jump to the label `done`:
;
;       jmp     done
;
;   That is how you tell the checker to look at OUTPUT. If you never jump to
;   `done`, the checker never grades you and the LED stays dark.
;
; THIS RUNS MORE THAN ONCE
;   The checker hands you five different values, one after another, and your
;   code runs again for each one. A single value that happens to be right will
;   not get you through round two - your code has to actually copy INPUT.
;
; HOW YOU KNOW IT WORKED
;   Build and flash with:   ./avr 3
;     LED on, steady  ->  all five values echoed correctly
;     LED blinking    ->  one of them came back wrong
;     LED dark        ->  you never jumped to `done`
;
; WHICH REGISTERS YOU MAY USE
;   r16 (OUTPUT), r17 (INPUT), and r18-r20 if you need scratch space.
;   Leave r21-r23 alone - that is where the checker keeps score.
;
; A HINT, IF YOU NEED ONE
;   `ldi` puts a *constant* into a register, which is not what you want here:
;   you do not know the value in advance. The instruction that copies one
;   register into another is `mov`, and it is written the same way round as
;   `ldi` - destination first:
;
;       mov     destination, source
; -----------------------------------------------------------------------------


    ; ================= write your answer below this line =================



    ; ================= write your answer above this line =================
