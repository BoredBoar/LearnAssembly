# 05 — Absolute Value

A **level**. The student reads one signed value and writes its absolute value —
which means first understanding how a negative number is stored at all.

**Task:** put `|INPUT|` into `OUTPUT`, then `jmp done`.
**Student edits:** `answer.inc`, and nothing else.

| LED | Meaning |
| --- | --- |
| Steady on | all five correct |
| Blinking ~10 Hz | one came back wrong |
| Dark | never jumped to `done` |

```sh
./avr 5
```

## The new idea: two's complement

`answer.inc` carries the full explanation, because this is the first lesson
where the *interpretation* of the bits matters rather than the bits themselves.
The argument it makes, in short:

- Eight bits is 256 patterns and there is no room for a separate sign flag.
- Counting up from 255 wraps to 0, so counting down from 0 must wrap to 255 —
  which puts 255 exactly one below zero, where −1 belongs. So we call it −1.
- The same pattern `1111 1111` is 255 *or* −1 depending only on how you read
  it. The chip neither knows nor cares; `add` gives the right answer either way.
- Negating = flip every bit, add one. `com` does the flip, `inc` does the add,
  and `neg` does both in one instruction.

The worked check in the file is `-60 + 60`: `1100 0100 + 0011 1100` = `1 0000 0000`,
and the ninth bit falls off the end of the register, leaving zero. That is the
moment two's complement usually clicks.

It also warns about `-128`, which is its own negative, so students who trip
over it know it is the format's quirk and not their bug.

## Test cases

| Round | Bits | As signed | Expected |
| --- | --- | --- | --- |
| 1 | `0xC4` | −60 | 60 |
| 2 | `0x00` | 0 | 0 |
| 3 | `0x3C` | 60 | 60 |
| 4 | `0x78` | 120 | 120 |
| 5 | `0xB4` | −76 | 76 |

Chosen so both obvious wrong answers die quickly: **"just copy the input"
fails at round 1**, **"always negate" fails at round 3**. Round 2 checks that
zero is treated as positive — a real bug if the sign test is written as
"greater than zero". Round 5 exists because stepping 120 + 60 runs past 127 and
wraps into the negative half, which is worth seeing happen.

## Verified behaviour

Every one of these was executed against the assembled firmware:

| Answer | Result |
| --- | --- |
| skeleton, nothing written | dark (`no_signal`) |
| correct, `brpl` skip + `neg` | steady |
| correct, the long way with `com` + `inc` | steady |
| just copies the input | blink, fails round 1 |
| always negates | blink, fails round 3 |
| correct value but no `jmp done` | dark — right answer, no credit |

## Instructor notes

The tightest answer is five instructions:

```asm
    mov     OUTPUT, INPUT
    cpi     OUTPUT, 0
    brpl    already_positive    ; zero counts as positive
    neg     OUTPUT
already_positive:
    jmp     done
```

The checker deliberately computes its expected value with `com` + `inc` rather
than `neg`, so a student who reads it finds the mechanism spelled out rather
than a copy of the intended answer.

Failure modes worth watching for:

- **Branching the wrong way.** `brpl` skips the negate; `brmi` jumps *to* it.
  Getting these backwards produces the "always negate" failure at round 3.
- **Treating zero as negative.** Only shows up because round 2 exists.
- **Negating `INPUT` instead of `OUTPUT`**, then copying — works, but clobbers
  a register the student was told is the input. Worth a word about ownership.
- **Reaching for a `jump if greater` instruction.** AVR has `brge`/`brlt`, which
  are about signed comparison, not the sign of a single value. `brpl`/`brmi`
  read the top bit directly and are what you want here.

## Extending it

- Add `-128` to the sequence and let students discover that it negates to
  itself.
- Ask for `|a - b|` using the two-input handshake from lesson 04.
- Ask for the sign instead: −1, 0 or +1.
