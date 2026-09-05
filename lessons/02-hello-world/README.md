# 02 — Hello, World

A **level**, not a demo: the student writes the code, and the board says whether
it is right.

**Task:** put the value `42` into the register `OUTPUT` (r16).
**Student edits:** `answer.inc`, and nothing else.
**Feedback:** LED steady = correct. LED blinking at ~10 Hz = wrong.

```sh
./avr 2
```

## How it is put together

| File | Role |
| --- | --- |
| `answer.inc` | the only file the student opens; contains the task and an empty marked region |
| `hello_world.S` | the checker — sets up the LED, `#include`s `answer.inc`, then compares and reports |

The student's code is **textually included** into the middle of `main`, so there
is no call, no `ret` and no stack — the answer simply runs in place. `answer.inc`
uses the `.inc` extension so PlatformIO does not also try to assemble it as a
separate program.

The checker counts with r18–r20 and never touches r16, so it cannot disturb the
answer before examining it.

## What it teaches

- `ldi` in isolation — one instruction, one observable result. Lesson 01 used
  it three times inside a bigger program; here it *is* the program.
- Reinforces the r16–r31 rule the hard way. `OUTPUT` is r16 for a reason, and
  the hint in `answer.inc` points at it without giving the instruction away.
- Introduces `cpi` and `brne` by having them visible in the checker — the
  student can read how their answer is being judged.

## Instructor notes

The answer is one line:

```asm
    ldi     OUTPUT, 42
```

Things students actually do, all of which are worth catching:

- Write `ldi r1, 42` after skim-reading — the assembler rejects it outright
  (`register number above 15 required`), which is the lesson from 01 landing.
- Write `mov OUTPUT, 42` — `mov` copies register to register; there is no
  immediate form. The error names the problem.
- Write `ldi OUTPUT, 0x42` — builds fine, LED blinks. 0x42 is 66. A good
  first encounter with "it assembled, therefore it is correct" being false.
- Leave it blank and flash it anyway, to see the failure state first. Worth
  encouraging: it proves the checker works before they trust it.

## Extending it

Change `EXPECTED` in `hello_world.S` to set a different target, or change
`OUTPUT` to a register outside r16–r31 to turn the level into a lesson about
why that fails.
