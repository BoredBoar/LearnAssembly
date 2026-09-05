# 03 — Echo

A **level**. The student copies a value from one register to another and
signals when done; the board runs their code five times and grades every round.

**Task:** copy `INPUT` (r17) into `OUTPUT` (r16), then `jmp done`.
**Student edits:** `answer.inc`, and nothing else.

| LED | Meaning |
| --- | --- |
| Steady on | all five values echoed correctly |
| Blinking ~10 Hz | one round came back wrong |
| Dark | never jumped to `done` |

```sh
./avr 3
```

## The two ideas this level adds

**A stop condition.** The student must end with `jmp done`. This is not
decoration: the instruction immediately after the included answer is
`jmp no_signal`, so code that runs off the end lands in a distinct dark-LED
state. Signalling completion is a real requirement, and forgetting it produces
its own diagnosis rather than looking like a wrong answer.

**Repetition defeats hardcoding.** The checker runs the student's code five
times with the values **7, 44, 81, 118, 155** — deliberately unrelated. An
answer of `ldi OUTPUT, 7` clears round one and fails round two, so the level
cannot be passed without actually copying the register. This is the difference
between `ldi` (a constant known when you write the program) and `mov` (a value
you only see at run time), which is the point of the lesson.

## How it is put together

| File | Role |
| --- | --- |
| `answer.inc` | the only file the student opens |
| `echo.S` | the checker: delivers values, runs the answer, grades, loops |

The answer is `#include`d inline inside the checker's loop, so it re-runs each
round with no call and no stack. Two details that keep the level honest:

- `OUTPUT` is cleared to 0 at the top of every round, so last round's answer
  cannot be mistaken for this one's.
- The comparison is `cp OUTPUT, TESTVAL`, not against `INPUT`. `TESTVAL` is the
  checker's own copy, so an answer that overwrites `INPUT` cannot make itself
  look right.

Register budget: the student owns r16–r17 and may use r18–r20 as scratch. The
checker keeps its score in r21–r23, and `answer.inc` says so.

## Instructor notes

The answer is two lines:

```asm
    mov     OUTPUT, INPUT
    jmp     done
```

Failure modes worth watching for:

- **`ldi OUTPUT, INPUT`** — assembles?  No: `ldi` needs a constant, and the
  assembler rejects a register there. A clean demonstration of what "immediate"
  means.
- **`mov OUTPUT, 42`** — the mirror-image error. `mov` takes no constant.
- **`mov INPUT, OUTPUT`** — arguments the wrong way round. Copies the cleared
  OUTPUT over INPUT; every round fails. Worth pointing at the `mov dest, source`
  convention, which matches `ldi`.
- **Correct copy, no `jmp done`** — LED dark. The most instructive failure:
  the value was right and it still did not count.

## Extending it

- Change `ROUNDS`, `FIRST_VALUE` or `STEP_VALUE` in `echo.S` for a different
  test sequence.
- Make it a *transform* rather than an echo: compare against something derived
  from `TESTVAL` and have the student add, double, or negate the input.
