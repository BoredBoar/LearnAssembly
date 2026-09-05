# AVR instruction reference

Every instruction used anywhere in these lessons, and nothing else. This is
deliberately small — around thirty instructions out of the ATmega's ~130. A
student who knows these can read every file in the repo.

Sizes are as emitted for the ATmega2560/ATmega328P (verified against
`avr-objdump` output from the built lessons). Cycle counts are from the AVR
instruction set for these parts.

`Rd` = destination register. `Rr` = source register. `K` = a constant baked
into the instruction ("immediate"). `k` = a label.

---

## Moving values around

| Instruction | Does | Size | Cycles | Restriction |
| --- | --- | --- | --- | --- |
| `ldi Rd, K` | Load Immediate — put constant `K` into `Rd` | 2 | 1 | **`Rd` must be r16–r31** |
| `mov Rd, Rr` | Copy `Rr` into `Rd` | 2 | 1 | any register |

## Single bits in I/O registers

| Instruction | Does | Size | Cycles | Restriction |
| --- | --- | --- | --- | --- |
| `sbi A, b` | Set Bit — drive one pin high | 2 | 2 | **I/O address 0x00–0x1F only** |
| `cbi A, b` | Clear Bit — drive one pin low | 2 | 2 | same |
| `sbic A, b` | Skip next instruction if bit is Clear | 2 | 1 / 2 / 3 | same |
| `sbis A, b` | Skip next instruction if bit is Set | 2 | 1 / 2 / 3 | same |

The skip instructions cost 1 cycle when they do not skip, 2 or 3 when they do
(depending on the size of the instruction skipped).

## Arithmetic

| Instruction | Does | Size | Cycles | Restriction |
| --- | --- | --- | --- | --- |
| `add Rd, Rr` | `Rd = Rd + Rr` | 2 | 1 | any register |
| `adc Rd, Rr` | Add with Carry — `Rd = Rd + Rr + C` | 2 | 1 | any register |
| `sub Rd, Rr` | `Rd = Rd - Rr` | 2 | 1 | any register |
| `subi Rd, K` | Subtract Immediate | 2 | 1 | **r16–r31** |
| `sbc Rd, Rr` | Subtract with Carry | 2 | 1 | any register |
| `sbci Rd, K` | Subtract Immediate with Carry | 2 | 1 | **r16–r31** |
| `inc Rd` | `Rd = Rd + 1` | 2 | 1 | any register |
| `dec Rd` | `Rd = Rd - 1` | 2 | 1 | any register |
| `neg Rd` | Two's complement negate — flip all bits, add 1 | 2 | 1 | any register |
| `com Rd` | One's complement — flip all bits | 2 | 1 | any register |
| `sbiw Rd, K` | Subtract `K` from the 16-bit pair `Rd+1:Rd` | 2 | 2 | **r24, r26, r28 or r30 only; K ≤ 63** |
| `adiw Rd, K` | Add `K` to the 16-bit pair | 2 | 2 | same |

`subi`/`sbci` are how you build wider subtraction out of 8-bit pieces: `subi`
sets the carry flag on borrow and `sbci` subtracts that borrow out of the next
byte up. Lesson 01 chains three of them into a 24-bit countdown.

## Comparing

| Instruction | Does | Size | Cycles | Restriction |
| --- | --- | --- | --- | --- |
| `cp Rd, Rr` | Compare two registers — set flags, change nothing | 2 | 1 | any register |
| `cpi Rd, K` | Compare register with a constant | 2 | 1 | **r16–r31** |
| `tst Rd` | Test for zero or minus — sets flags from `Rd` | 2 | 1 | any register |

Compares work by *subtracting and throwing the answer away*, keeping only the
flags. That is why `cpi Rd, 0` is a good way to ask "is this value negative?" —
the result's top bit lands in the N flag.

## Branching (always relative, ±64 words)

| Instruction | Jumps when | Size | Cycles |
| --- | --- | --- | --- |
| `breq k` | equal (Z set) | 2 | 1 not taken / 2 taken |
| `brne k` | not equal (Z clear) | 2 | 1 / 2 |
| `brcs k` | carry set — also `brlo`, "unsigned lower" | 2 | 1 / 2 |
| `brcc k` | carry clear — also `brsh`, "unsigned same or higher" | 2 | 1 / 2 |
| `brmi k` | minus — top bit of the last result was 1 | 2 | 1 / 2 |
| `brpl k` | plus — top bit was 0, so **zero counts as plus** | 2 | 1 / 2 |

## Jumping

| Instruction | Does | Size | Cycles |
| --- | --- | --- | --- |
| `rjmp k` | Relative jump — stores a *distance*, ±2 K words | 2 | 2 |
| `jmp k` | Absolute jump — stores an address | 4 | 3 |

## Doing nothing

| Instruction | Does | Size | Cycles |
| --- | --- | --- | --- |
| `nop` | burns one cycle | 2 | 1 |

---

## Four rules that catch everyone out

1. **Immediates only reach r16–r31.** `ldi`, `subi`, `sbci`, `andi`, `ori`,
   `cpi` — all of them. A 16-bit opcode has no room for both an 8-bit constant
   and a 5-bit register number, so the top bit of the register field is
   hard-wired. `ldi r1, 5` is not slow, it is not an instruction:
   `Error: register number above 15 required`. Fill r0–r15 with `mov` instead.

2. **`sbiw`/`adiw` reach only four register pairs**: r24, r26 (X), r28 (Y),
   r30 (Z). `Error: register r24, r26, r28 or r30 required`.

3. **`sbi`/`cbi`/`sbic`/`in`/`out` only reach I/O addresses 0x00–0x1F.** On the
   ATmega2560 that excludes ports H, J, K and L, which live at 0x100+ and need
   `lds`/`sts` instead. Ports B, D, E, F and G are fine. On the ATmega328P
   every port is in range.

4. **There is no absolute conditional branch.** `jmp` and `call` take absolute
   addresses; every `br*` stores a signed distance and reaches only +63/−64
   words. Conditional control flow on AVR is *always* relative.

## Two registers that are not yours

| Register | Reserved for |
| --- | --- |
| `r0` | the ABI's scratch register, used implicitly by `lpm` |
| `r1` | the ABI's **zero register** — the C runtime clears it at reset and all compiler-generated code assumes it still holds 0 |

Clobber `r1` and any C you later link breaks in ways that are very hard to
find. The lessons use r18–r20 for scratch: immediate-capable, and
call-clobbered under the avr-gcc ABI.

---

## Beyond this list

This list covers the current lessons. As exercises grow, the natural next
additions — roughly in order of when they become necessary — are:

- **Logic:** `and`, `andi`, `or`, `ori`, `eor`
- **Shifting:** `lsl`, `lsr`, `asr`, `ror`, `rol`, `swap`
- **Memory:** `lds`, `sts`, `ld`, `st` and the X/Y/Z pointers
- **Program memory:** `lpm` for lookup tables
- **Subroutines:** `rcall`, `call`, `ret`, `push`, `pop` and the stack
- **Signed comparison:** `brge`, `brlt`
- **Interrupts:** `sei`, `cli`, `reti`

One option for the curriculum is to keep the whole set flat and introduce each
instruction when a level needs it. Another is to group levels into **tiers**,
each tier unlocking a block of instructions — arithmetic, then memory, then
subroutines, then interrupts — so a student always knows the size of the
vocabulary they are working with. That decision is still open; see `CLAUDE.md`.
