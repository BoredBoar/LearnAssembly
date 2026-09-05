# 04 — Sum

A **level**. The student reads two values from `INPUT`, adds them, and puts the
total in `OUTPUT` — which means asking for the second value, not just waiting
for it.

**Task:** read two values from `INPUT` (r17), add them, leave the total in
`OUTPUT` (r16).
**Student edits:** `answer.inc`, and nothing else.

| LED | Meaning |
| --- | --- |
| Steady on | all five totals correct |
| Blinking ~10 Hz | one round came back wrong |
| Dark | never jumped to `done` |

```sh
./avr 4
```

## The new idea: asking for input

Only the *first* value is waiting when the student's code starts. `INPUT` does
not refill on its own — the student has to ask:

```asm
    jmp     next_input      ; checker loads the next value, then jmps to `resume`
```

The checker's `next_input` puts the second value into `INPUT` and jumps straight
back to the label `resume`, which is why `resume:` ships already written in
`answer.inc`. **This is a subroutine call built by hand out of two plain jumps**
— no `rcall`, no `ret`, nothing on the stack, consistent with every lesson so
far. The cost of doing it that way is that the return point is fixed:
`next_input` always comes back to `resume`, which is exactly enough for two
values and no more.

It also creates a genuine ordering trap. `INPUT` is overwritten, not queued, so
a student who jumps *before* saving the first value loses it. That is the whole
reason step 1 in the skeleton says "save the first value somewhere".

## Test cases

Five pairs, generated rather than tabulated (`VAL_A += 37`, `VAL_B += 11`):

| Round | INPUT 1 | INPUT 2 | Expected |
| --- | --- | --- | --- |
| 1 | 7 | 5 | 12 |
| 2 | 44 | 16 | 60 |
| 3 | 81 | 27 | 108 |
| 4 | 118 | 38 | 156 |
| 5 | 155 | 49 | 204 |

Chosen so that no total exceeds 255 (`add` never overflows — carry is a later
lesson), no total coincides with either input, and the two inputs are never
equal. That closes off "return the input", "double the first value" and
"hardcode the first answer" as accidental passes.

## Verified behaviour

Reproduce with `./avr verify 4`; the fixtures live in `tests/`.

| Answer | Result |
| --- | --- |
| skeleton, nothing written | dark (`no_signal`) |
| correct | steady, OUTPUT 204 after round 5 |
| correct sum but no `jmp done` | dark — right answer, no credit |
| forgot to fetch the 2nd value (7+7) | blink, fails round 1 |
| jumped before reading the 1st | blink, OUTPUT 5 |
| hardcoded `ldi OUTPUT, 12` | blink, passes round 1 then meets 44 |
| lesson 03's answer (`mov OUTPUT, INPUT`) | blink |

## Instructor notes

The answer is five instructions:

```asm
    mov     r18, INPUT      ; save the first value
    jmp     next_input      ; ask for the second
resume:
    add     r18, INPUT      ; add it on
    mov     OUTPUT, r18     ; publish the total
    jmp     done
```

Failure modes worth watching for:

- **Jumping before saving.** The most common one, and the point of the level.
  The first value is simply gone; the total ends up being the second value
  alone or garbage.
- **`add OUTPUT, INPUT` without clearing.** The checker zeroes `OUTPUT` each
  round, so this accidentally works — worth pointing out as luck, not design,
  and a reason to be explicit.
- **Using r21–r25 as scratch.** Clobbers the checker's score and produces
  baffling results. `answer.inc` says which registers are theirs.
- **Expecting a queue.** Students assume `INPUT` holds both values, or that
  reading it twice yields two different values. It is a single register.

## Extending it

- Raise `ROUNDS`, or change `STEP_A_BY` / `STEP_B_BY` for a different sequence.
- Let a total exceed 255 and let students discover the carry flag.
- Ask for three values — which needs a second return label, and makes the case
  for `rcall`/`ret` and a stack all by itself.
