# 01 — Blink

**Concepts:** the ATmega's I/O registers, output pins, single-bit instructions,
absolute vs. relative control flow, the split register file, and counting clock
cycles by hand.

**Hardware:** none beyond the board — digital pin 13 has an LED soldered to it.
That pin is **PB7** on the Mega and **PB5** on the Uno; see
[include/board.inc](../../include/board.inc).

```sh
pio run -e mega-01-blink -t upload
```

## What to point at

- `DDRB` decides *direction* (1 = output), `PORTB` decides the *level*. Two
  separate registers for one pin is a common first stumble.
- `sbi` / `cbi` set or clear one bit in a single 2-byte instruction — no
  read-modify-write, no mask constant.
- Nothing in the delay loop is a library call. 5 cycles × 1,600,000 = 8,000,000
  cycles = 0.5 s at 16 MHz. Change `DELAY_ITERATIONS` and time the result.
- **No stack.** There are no subroutines here, so nothing is pushed or popped —
  the whole program is straight-line code with two backward branches.
- The Mega build is 298 bytes of flash and the Uno build 170, from the *same
  source* — yet `main` through the final `jmp` is exactly **38 bytes on both**.
  The whole 128-byte difference is the interrupt vector table: the ATmega2560
  has far more interrupt sources, so `main` starts at `0x100` instead of `0x80`.
  Check it with `avr-size` and `avr-nm -n`.

## Why the code looks the way it does

Four questions students reliably ask about this file.

### Why r18, r19, r20 — why not r1, r2, r3?

Because the AVR register file is **not symmetric**. Instructions that carry an
immediate (a constant baked into the opcode) can only reach the top half:

```
ldi, subi, sbci, andi, ori, cpi, sbr, cbr   ->   r16–r31 ONLY
```

A 16-bit opcode has no room for both an 8-bit constant and a 5-bit register
number, so those instructions spend 4 bits on the register and hard-wire the top
bit. `ldi r1, 5` isn't slow — it isn't an instruction. The assembler says so:

```
Error: register number above 15 required
```

r0–r15 are perfectly usable, just only via `mov` (to fill them) and register
operand instructions like `dec`, `sub`, `sbc`, `inc`. Two more to leave alone:
**r0** is the ABI scratch register, used implicitly by `lpm`, and **r1** is the
ABI *zero register* — the startup code clears it and every compiler-generated
instruction assumes it still holds 0. Clobber r1 and any C you later link breaks
in ways that are very hard to find.

r18–r20 are the conventional choice: immediate-capable, and call-clobbered under
the avr-gcc ABI, so no one else expects them to survive.

### How do the `CNT_LO` names work?

Plain C preprocessor `#define`. Because the file is `.S` (capital), cpp runs
before the assembler, so it is pure text substitution — the assembler only ever
sees `r18`, and so does the disassembly.

It is also the *only* mechanism that works here. Worth demonstrating, because
students find the others in tutorials:

| Syntax | Result with avr-gcc |
| --- | --- |
| `#define CNT_LO r18` | **works** |
| `.set CNT_LO, r18` | `Error: constant value required` — GNU as symbols hold numbers, not registers |
| `.def CNT_LO = r18` | `Error: unknown pseudo-op` — that's Atmel AVRASM2, all over Microchip's docs, not GNU as |
| `CNT_LO .req r18` | `Error: unknown opcode` — that's ARM's directive |

Watch the comment rule: **no `;` comment on a `#define` line.** cpp doesn't know
`;` starts an assembler comment, so it pastes the whole thing into the macro
body. Use `/* ... */` there.

### Why `jmp` at the bottom but `brcc` in the loop?

`jmp` takes an absolute address — "go to this location in flash", 4 bytes and
3 cycles. `rjmp` encodes a *distance* from the current instruction in 2 bytes
and 2 cycles. Absolute is easier to read; relative is cheaper.

But `brcc` has no absolute counterpart. **AVR has no absolute conditional
branch at all** — every `br*` (`brcc`, `brne`, `breq`, `brlo`, …) encodes a
signed offset from the program counter and reaches only +63/−64 words. So:
absolute control flow on AVR means `jmp` and `call`; conditional control flow is
*always* relative. That asymmetry is worth a minute at the whiteboard.

### Where is `_SFR_IO_ADDR`?

Folded into `board.inc`, so lessons can write `sbi LED_PORT, LED_BIT`.

`avr/io.h` gives each register its address in **data space** — on both chips
`PORTB` is `0x25`. But `sbi`/`cbi`/`sbic`/`in`/`out` address the much smaller
**I/O space**, where that same register is `0x05`. `_SFR_IO_ADDR()` is nothing
but that subtraction of `0x20`. Doing it once in `board.inc` keeps it off every
instruction in every lesson.

The catch, and the reason it's worth knowing rather than hiding: those names are
now I/O addresses, valid only with `sbi`/`cbi`/`sbic`/`in`/`out`. Anything
needing `lds`/`sts` — any port at `0x100`+, such as the Mega's `PORTH` — has to
use the bare `avr/io.h` name instead.

## Exercises

1. Make the on-time and off-time different (fast flash, long pause).
2. Blink pin 11 instead of 13. Look up which port bit that is on your board
   (Mega: PB5, Uno: PB3) and add it to `board.inc` rather than hard-coding it.
3. Compute the iteration count for a 2-second period, flash it, and check it
   against a stopwatch — the loop is accurate to well under 1%.
4. Disassemble it and match every source line to its opcode:
   `avr-objdump -d .pio/build/mega-01-blink/firmware.elf`
5. Build `uno-01-blink` as well and diff the two disassemblies. One source file,
   two different `sbi` operands — why?
6. The delay block appears twice, byte for byte. Fold it back into a subroutine
   with `rcall`/`ret` and measure: how many bytes did you save, and what did you
   spend to get them? (Answer: a stack, and 3 cycles of call overhead each way.)
7. Swap the final `jmp` for `rjmp` and confirm from the disassembly that the
   program shrinks by 2 bytes. Then try to write the delay loop's `brcc` as an
   absolute branch — and work out why the instruction set won't let you.
8. Try `ldi r1, 5` and read the error. Then get the value 5 into r1 anyway, with
   two instructions.
9. Rename `CNT_LO` to something else, rebuild, and disassemble. Confirm the
   machine code is byte-for-byte unchanged — the name never reaches the chip.
