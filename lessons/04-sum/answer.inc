; -----------------------------------------------------------------------------
; Lesson 04 - Sum                   >>> THIS IS THE ONLY FILE YOU EDIT <<<
;
; YOUR TASK
;   Read TWO values from INPUT, add them together, and put the total in OUTPUT.
;
;   INPUT  is r17 - one value at a time waits there for you.
;   OUTPUT is r16 - put the total there.
;
; ASKING FOR THE NEXT VALUE
;   Only the first value is waiting when your code starts. INPUT does not change
;   on its own - you have to ask for the next one:
;
;       jmp     next_input
;
;   The checker puts the second value into INPUT and then jumps straight back to
;   the label `resume` below. That is why `resume:` is already written out for
;   you: it is where your code carries on after the new value arrives.
;
;   Read the first value BEFORE you jump. INPUT is overwritten, not queued - if
;   you jump first, the first value is gone.
;
; THE STOP CONDITION
;   When the total is in OUTPUT, jump to `done` so the checker looks at it:
;
;       jmp     done
;
; THIS RUNS MORE THAN ONCE
;   The checker runs your code five times with five different pairs, so an
;   answer built around one particular number will not survive round two.
;
; HOW YOU KNOW IT WORKED
;   Build and flash with:   ./avr 4
;     LED on, steady  ->  all five totals correct
;     LED blinking    ->  one of them came back wrong
;     LED dark        ->  you never jumped to `done`
;
; WHICH REGISTERS YOU MAY USE
;   r16 (OUTPUT), r17 (INPUT), and r18-r20 as scratch space - you will need at
;   least one of them to hold the first value while you fetch the second.
;   Leave r21-r25 alone; that is where the checker keeps score.
;
; NO NEW INSTRUCTIONS
;   You already have everything you need: `mov` to copy a register, `add` to add
;   one register to another (`add Rd, Rr` leaves the total in Rd), and `jmp`.
; -----------------------------------------------------------------------------


    ; ================= write your answer below this line =================

    ; step 1 - save the first value somewhere before it is overwritten


    ; step 2 - ask for the second value:   jmp     next_input


resume:
    ; step 3 - add the second value to the first, and put the total in OUTPUT


    ; step 4 - signal that you are finished:   jmp     done


    ; ================= write your answer above this line =================
