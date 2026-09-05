# 06 — Button and LED

**Concepts:** input pins, internal pull-up resistors, active-low logic, and
branching with the skip instructions.

**Hardware:** one pushbutton, wired from digital pin 2 (PE4 on the Mega, PD2 on
the Uno) to GND. No resistor needed.

```sh
./avr 6
```

## What to point at

- Three registers per port, not two: `DDRx` (direction), `PORTx` (output level
  *or*, for an input pin, the pull-up switch), `PINx` (the live input reading).
- The button is **active low**: pressed reads 0. That surprises students, so
  draw the circuit — the pull-up holds the pin at 5 V until the button shorts it
  to ground.
- `sbic` doesn't branch, it *skips the next instruction*. AVR has no
  "branch if pin low" — conditional control flow here is built out of a skip
  plus a jump.
- On the Mega the LED and the button are on **different ports** (B and E) while
  on the Uno they are on B and D. The program logic is untouched by that; only
  the register names change.

## Exercises

1. Invert it: LED on when the button is *not* pressed. (One instruction changes.)
2. Toggle on each press instead of following the button — this needs edge
   detection, and will visibly misbehave from contact bounce.
3. Fix the bounce with a delay loop borrowed from lesson 01.
4. Drive an external LED on pin 12 (Mega PB6, Uno PB4) through a 220 Ω resistor
   alongside the onboard one.
5. **Mega only:** try to drive an external LED on pin 8 instead. Pin 8 is PH5,
   and port H lives at address `0x102` — outside the `0x00`–`0x1F` window that
   `sbi` can reach, so the assembler refuses it with
   `Error: operand out of range`. Rewrite that one line with `lds`/`ori`/`sts`
   and compare the size and cycle count against `sbi`.
