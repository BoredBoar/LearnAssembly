# Project: Teaching Assembly Programming with AVR

## Goal
Teach assembly programming to students using low-cost, widely available development boards.

## Board decisions
- **Primary teaching board: Arduino Mega 2560-compatible (ATmega2560, AVR architecture)** — this is the board on hand (**ELEGOO MEGA 2560 Project Starter Kit**)
- **Also supported: Arduino Uno-compatible (ATmega328P)** — **ELEGOO UNO Project Super Starter Kit** (~$32-45)
  - The repo builds every lesson for both chips from one set of sources; see "Repo state" below. Switching the class to Unos is a `platformio.ini` env-prefix change, not a rewrite
- AVR chosen over MSP430/Xtensa/ARM for a first course because the ISA is simple: fixed-width instructions, flat register file, minimal addressing modes. The 2560 and the 328P share that same AVR core and instruction set, so lesson content is unaffected by the choice between them
- **Considered and set aside for the intro course:**
  - MSP430 LaunchPad — also simple/good for teaching, but going with AVR instead so the class stays on one consistent ecosystem
  - Raspberry Pi Pico (RP2040, ARM Cortex-M0+ / Thumb) — cheap ($4) but bigger jump for beginners; better as a later unit
  - ESP32 (Xtensa LX6/LX7) — harder to teach as a first ISA due to windowed registers; ESP32-C3 (RISC-V variant) would be a better "second architecture" pick than original Xtensa ESP32
  - Arduino Uno R4 WiFi (Renesas RA4M1, ARM Cortex-M4 + ESP32-S3 co-processor) — good bridge toward STM32/ARM work later, but Thumb-2, NVIC, and interrupt vectors make it a step up in complexity vs AVR; not for lesson one

## Mega-specific teaching consequences
Two differences from the Uno that matter in assembly (they do not exist in Arduino C, which hides both):

1. **Pin numbers are labels, not addresses.** The same silkscreen number sits on a different port per chip. Verified against Arduino's `pins_arduino.h` variant tables:

   | Silkscreen pin | Uno (ATmega328P) | Mega 2560 (ATmega2560) |
   | --- | --- | --- |
   | 13 (onboard LED) | PB5 | PB7 |
   | 2 | PD2 | PE4 |
   | 8 | PB0 | PH5 |
   | 11 / 12 | PB3 / PB4 | PB5 / PB6 |

   Uno-written code assembles cleanly for a Mega and silently drives the wrong pin. All board-specific names are therefore isolated in `include/board.inc`.

2. **`sbi`/`cbi`/`in`/`out` only reach I/O addresses `0x00`-`0x1F`.** On the ATmega2560, ports **H, J, K, L** are memory-mapped at `0x100`+ (e.g. `PORTH` = `0x102`) and are unreachable by those instructions — the assembler errors with `operand out of range`. That covers Mega digital pins 6, 7, 8, 9 and 14-17, which need `lds`/`ori`/`sts` instead of a one-word `sbi`.
   - Ports B, D, E, F, G are in low I/O space and behave exactly like the Uno's. **Lessons deliberately stay on those ports**, with the port-H limitation introduced on purpose as an exercise rather than hit by accident.
   - This is the one real argument for the Uno as the teaching board: on a 328P every GPIO is `sbi`-able, so there is only one idiom to teach. Worth revisiting if students trip over it.

Also worth knowing: the Mega's larger interrupt vector table pushes `main` to `0x100` (vs `0x80` on the Uno), so identical source yields 298 vs 170 bytes of flash while the actual code is 38 bytes on both. Good material for a "what is actually in my binary" discussion.

## I/O for hands-on exercises
- Need onboard/breadboard I/O for labs: buttons, LEDs, pots, LCD, etc.
- Two viable approaches:
  1. **Arduino Education Shield** — purpose-built teaching shield: reset button, protoshield area, direct digital I/O breakout, I2C connector, speaker jack on pin 11
     - **Caveat now that the Mega is primary:** it is an Uno-form-factor shield. It fits the Mega's header physically, but Uno shields that reach for SPI on pins 11-13 or I2C on A4/A5 do not work on a Mega, where those buses live on pins 50-53 and 20/21. Needs checking against this shield specifically before buying
  2. **ELEGOO kit's bundled parts** (LCD1602, joystick, buttons, LEDs, potentiometer, buzzers, servo/stepper motor, sensors) — already covers exercise needs without a separate shield purchase, and has no shield-compatibility question

## Toolchain
**Decided: VS Code + PlatformIO.** Installed and working.

- **Assembler/compiler driver:** `avr-gcc` 7.3.0 (from PlatformIO's `toolchain-atmelavr` package), which also supplies `avr-as`, `avr-ld`, `avr-objdump`, `avr-size`, `avr-nm`
- **Flashing:** `avrdude` over USB-serial (same connection Arduino IDE uses), invoked by `pio run -t upload`
- **PlatformIO Core** 6.1.19 at `~/.platformio/penv/bin/pio`; **platform** `atmelavr` 5.3.0. PlatformIO downloads its own toolchain, so there is no separate Homebrew/AVR install to maintain per machine — a real win for classroom setup
- Native AVR support, visible build flags, supports standalone `.S` assembly files directly; cross-platform and free; mirrors real embedded toolchains (useful bridge to STM32 work)
- **Alternatives considered:**
  - Arduino IDE — supports inline `asm()` in `.ino` files but hides the build process; not ideal for teaching what's happening under the hood
  - VS Code + raw Makefile — most transparent (every assemble/link/flash step visible), but more setup work for the instructor
  - Microchip Studio (formerly Atmel Studio) — Windows-only, has a proper source-level debugger with register view; good if classroom is Windows-based

### Toolchain gotchas found in practice
- **Bare-metal, no `framework` line.** avr-gcc still links its C runtime (`crt*.o`), which builds the vector table, zeroes RAM, sets the stack pointer, and jumps to `main` — hence every lesson exports `.global main`
- Use a capital `.S` extension so the C preprocessor runs first (`#include <avr/io.h>`, `#define`)
- Inside a `.S` file `;` starts an assembler comment — but **not** on a `#define` line, where cpp pastes it into the macro body and silently truncates the expression. Use `/* ... */` in macro definitions
- PlatformIO's `build_flags` are parsed by SCons, which strips the `-Wa,` prefix; passing `-Wa,-adhlns=...` for listings fails. Use `avr-objdump -d` on the linked `.elf` instead — it also shows the real addresses

### ISA constraints that shape lesson code
- **Immediate instructions reach r16-r31 only.** `ldi`, `subi`, `sbci`, `andi`, `ori`, `cpi` reject r0-r15 with `Error: register number above 15 required` — a 16-bit opcode cannot hold both an 8-bit constant and a 5-bit register number. Low registers must be filled with `mov` and changed with `dec`/`sub`/`sbc`. Additionally r0 is the ABI scratch (implicit in `lpm`) and r1 is the ABI zero register the C runtime clears at reset. Lessons use **r18-r20**: immediate-capable and call-clobbered
- **Register aliases must be `#define`.** cpp runs first on `.S` files, so `#define CNT_LO r18` is pure text substitution and the machine code is unchanged. GNU as symbol directives hold numbers, not registers, so `.set CNT_LO, r18` fails with `constant value required`; Atmel AVRASM2's `.def CNT_LO = r18` (ubiquitous in Microchip docs) is an `unknown pseudo-op` here; `.req` is ARM's. All four verified by assembling
- **There is no absolute conditional branch.** `jmp`/`call` are absolute (4 bytes); every `br*` (`brcc`, `brne`, `breq`, `brlo`) encodes a signed PC-relative offset reaching only +63/-64 words. So conditional control flow is *always* relative, even in code that otherwise avoids `rjmp`. Both `jmp` and `call` are available on the ATmega2560 and the ATmega328P (verified by assembling for both)

## Repo state (as of 2026-09-05)
```
avr                    helper script: ./avr 1 = build+flash, ./avr help for the rest
INSTRUCTIONS.md        every instruction the lessons use and nothing else (~30),
                       with the four gotcha rules and a "beyond this list" plan
tools/avrsim.py        ~25-instruction AVR interpreter. Executes a built lesson
                       from `main` to the checker's end label and reports
                       PASS/WRONG/DARK. No memory, stack, I/O or timing; it
                       raises loudly on an instruction it does not know
lessons/*/tests/*.inc  one fixture per plausible student answer, each with an
                       `; expect: PASS|WRONG|DARK` header
platformio.ini         12 envs, named <board>-<lesson>; default mega-01-blink
include/board.inc      per-chip pin-to-port map (the only board-specific file);
                       also applies _SFR_IO_ADDR so lessons write `sbi LED_PORT, LED_BIT`
lessons/01-blink/      DDR/PORT, sbi/cbi, hand-counted 5-cycle delay loop; no
                       subroutine or stack, absolute jmp (see note below)
lessons/02-hello-world/ a LEVEL, not a demo: student edits answer.inc to load 42
                       into r16; hello_world.S #includes it inline and grades it
                       (steady LED = right, ~10 Hz blink = wrong). No call/stack
lessons/03-echo/       a LEVEL: mock I/O in registers (INPUT r17 -> OUTPUT r16),
                       student must `jmp done` as a stop condition; checker runs
                       the answer 5x with 7/44/81/118/155 so hardcoding fails.
                       Steady LED = pass, ~10 Hz blink = wrong, dark = no signal
lessons/04-sum/        a LEVEL: read two values from INPUT and add them. Adds a
                       `jmp next_input` handshake - the checker loads the next
                       value then jmps back to a `resume:` label that ships in
                       answer.inc (so the checker's jmp always resolves). A
                       hand-built call from two jumps: no rcall/ret, no stack,
                       fixed return point. 5 pairs, sums all <256 so `add`
                       never carries
lessons/05-absolute-value/ a LEVEL: two's complement. answer.inc carries the full
                       explanation (wrap-around, sign bit, com+inc = neg, the
                       -128 quirk). Values -60/0/60/120/-76 kill both naive
                       answers fast: "copy" dies round 1, "always negate" round 3
lessons/06-button-led/ inputs, internal pull-ups, sbic skip-based branching
docs/SETUP.md          install, flashing, CH340/CP2102 driver troubleshooting
```
`pio run -e mega-01-blink -t upload`. All four envs build clean; disassembly verified to hit PB7/PE4 on the Mega and PB5/PD2 on the Uno.

**Hardware verified 2026-09-04:** a genuine **Arduino Mega 2560 R3** (USB `2341:0042`, signature `1E 98 01` = ATmega2560) on `/dev/cu.usbmodem21101`. `pio run -e mega-01-blink -t upload` wrote and verified 288 bytes; the pin-13 LED blinks at 1 Hz. This board enumerates as `usbmodem` via its ATmega16U2, so **no CH340 driver was needed** — but student-supplied ELEGOO clones usually do use a CH340 and will need it before a port appears.

## Level design (the format to follow when adding exercises)

The lesson set has two kinds of content, and new work should almost always be
the second kind.

- **Demos** (`01-blink`, `06-button-led`) are complete programs to read, run and
  modify. Useful for introducing hardware, poor at telling a student whether
  they have understood anything.
- **Levels** (`02` onward) are puzzles the board grades. The format is lifted
  from **The Assembly Game** by Chilling Moose (App Store, $2.99) — see the
  attribution section in `README.md`, which should stay there.

### Anatomy of a level

Two files in `lessons/NN-name/`:

| File | Role |
| --- | --- |
| `answer.inc` | the **only** file the student opens: task, rules, hint, and an empty marked region |
| `<name>.S` | the checker: owns `main`, `#include`s the answer inline, grades it |

The student's code is **textually included** into the middle of the checker's
loop. This is deliberate and load-bearing:

- no `rcall`, no `ret`, nothing on the stack — consistent with lesson 01, which
  established that the stack has not been introduced yet;
- the answer re-runs each round with no machinery;
- `.inc` (not `.S`) keeps PlatformIO from assembling it as a second program.

### The contract every level keeps

- **Mock I/O in registers.** `OUTPUT` = r16, `INPUT` = r17. Both must be
  immediate-capable (r16-r31) so `ldi`/`cpi` work on them.
- **Register budget, stated in `answer.inc`.** Student owns r16-r17 plus r18-r20
  scratch; the checker keeps its state in r21 upward and says so.
- **`OUTPUT` is cleared at the top of every round**, so a previous round's
  answer cannot be mistaken for this one's.
- **Grade against the checker's own copy**, never against `INPUT`. An answer
  that overwrites `INPUT` must not be able to make itself look correct.
- **A stop condition.** The student ends with `jmp done`. The instruction
  immediately after the include is `jmp no_signal`, so an answer that runs off
  the end lands in its own diagnosable state instead of looking wrong.
- **Three LED states**, identical across every level:

  | LED | Meaning |
  | --- | --- |
  | steady on | every round correct |
  | ~10 Hz blink | a round came back wrong |
  | dark | never signalled |

  Blink rather than dark for "wrong" is deliberate: an unlit LED is
  indistinguishable from a board that is not running, and 10 Hz is visibly
  different from lesson 01's 1 Hz.

### Designing the test cases

- **Several rounds, always.** One round can be passed by hardcoding. Levels run
  five, generated arithmetically rather than tabulated (no `lpm` needed yet).
- **Pick values that kill the plausible wrong answers early**, and write down
  which wrong answer each round catches. Lesson 04's pairs rule out "return the
  input", "double the first value" and "hardcode round one". Lesson 05's values
  kill "just copy" at round 1 and "always negate" at round 3.
- **Include the edge case that exposes a bad condition** — lesson 05 has a zero
  round precisely because "greater than zero" is a tempting, wrong sign test.
- **Stay inside 8 bits** unless the level is *about* overflow. Lesson 04's sums
  are all < 256 so `add` never carries.
- **Do not put the answer in the checker.** Where the grading logic would
  duplicate the intended solution, write it a different way: lesson 05 computes
  its expected value with `com`+`inc` so a student reading the checker learns
  what `neg` does rather than finding the answer.

### Handshakes when one value is not enough

Lesson 04 needs two inputs, so the student asks for the next one with
`jmp next_input`; the checker loads it and jumps back to a `resume:` label. That
is a subroutine call built by hand from two plain jumps. Two consequences:

- the return point is fixed, which is fine for two values and does not scale —
  a three-input level is the natural argument for finally introducing
  `rcall`/`ret` and the stack;
- `resume:` must **ship inside `answer.inc`**, or the checker's `jmp resume`
  fails to link against an empty answer.

### Verifying a level without hardware

Assembling proves nothing about whether a level grades correctly, so every level
is verified by execution:

    ./avr check <lesson>     simulate the answer.inc that is there now
    ./avr verify [<lesson>]  run a level's fixtures, or every level's

`tools/avrsim.py` disassembles the built firmware and interprets it from `main`
until it reaches a checker end label (`all_correct`/`right_answer`,
`wrong_answer`, `no_signal`), which is enough to answer "does this answer
pass?". It models no memory, stack, I/O or timing, and raises rather than
guessing when it meets an unknown instruction — so adding an instruction to a
lesson means adding it to `avrsim.py` and `INSTRUCTIONS.md` too.

**A new level is not finished until it has a `tests/` directory.** One fixture
per plausible student answer, each a complete replacement for `answer.inc` with
an `; expect: PASS|WRONG|DARK` header. At minimum: the empty skeleton, a correct
answer, every wrong approach the test values were designed to catch, and a
correct-but-unsignalled answer. `./avr verify` also lints that the `answer.inc`
which ships contains no instructions, so a solution cannot be committed by
accident. The "Verified behaviour" table in each lesson README is just that
fixture list written out.

## Open items / not yet decided
- Whether to introduce a second architecture unit (ARM Cortex-M via Uno R4 WiFi, or RISC-V via ESP32-C3) after the AVR fundamentals unit
- Final choice between Arduino Education Shield vs. relying solely on ELEGOO kit's bundled components for lab exercises — now leaning toward the kit's parts, since the shield's Uno form factor raises SPI/I2C questions on a Mega
- Whether the Mega's split between `sbi`-able and memory-mapped ports is a teaching liability worth switching the class to Unos over
- Lesson sequence beyond 06 (timers/interrupts, USART, and memory/pointers are the obvious next candidates)
- **Flat vocabulary vs. tiers.** `INSTRUCTIONS.md` currently lists only what the lessons use (~30 instructions). Either keep it flat and add each instruction when a level needs it, or group levels into tiers that each unlock a block (logic -> shifts -> memory -> subroutines -> interrupts) so students always know the size of their vocabulary. Undecided
- **Debugging is researched but not set up** — see "Debugging and single-stepping" in `docs/SETUP.md`. Three findings worth carrying: (1) PlatformIO's bundled `avr-gdb` is broken on this Mac (linked against the removed Python 2.7 framework), so any GDB-based debugging needs `brew install avr-gdb` from the `osx-cross/avr` tap first; (2) this board's high fuse is `0xD8`, so **JTAG and OCD are disabled** and enabling them needs an ISP programmer, not the bootloader; (3) JTAG would occupy PF4-PF7 = pins A4-A7. The ATmega2560 having real JTAG where the 328P has only debugWIRE is a genuine point in the Mega's favour for the board question above. Recommended first step when wanted: `debug_tool = simavr` (simulator, no hardware, shows r0-r31 live)
