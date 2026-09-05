# LearnAssembly

Teaching materials and a working build setup for a first course in assembly
programming on AVR. Course/hardware rationale lives in [claude.md](claude.md).

Supports two boards from one set of lesson sources:

| Board | Chip | Build env prefix |
| --- | --- | --- |
| Arduino Mega 2560 / ELEGOO MEGA | ATmega2560 | `mega-` |
| Arduino Uno / ELEGOO UNO | ATmega328P | `uno-` |

## Credit where it's due: The Assembly Game

The level format in this repo — a puzzle, a fixed set of instructions, a
machine that tells you whether you got it right — is lifted wholesale from
**[The Assembly Game](https://apps.apple.com/us/app/the-assembly-game/id6752651042)**
by Chilling Moose. If that idea appeals to you, **buy the game**. It is $2.99,
which is less than the resistor kit you will need for lesson 06.

It bills itself as *Algorithm Puzzles in Assembly*, and it is exactly that: a
progression of algorithm problems — GCD through binary search and beyond — that
you solve by writing assembly, with its own built-in assembly language, real-time
feedback on what your code does, and a sandbox for writing whatever you like
once the puzzles have stopped scaring you. It runs on iPhone, iPad, Mac (Apple
silicon) and Apple Vision.

What it gets right, and what this repo is trying to borrow:

- **One idea per puzzle.** You are never fighting two unfamiliar things at once.
- **The machine is small enough to hold in your head.** A short instruction list
  is a feature, not a limitation — see [INSTRUCTIONS.md](INSTRUCTIONS.md).
- **The feedback loop is immediate and unambiguous.** You do not wonder whether
  you solved it.

This project asks what happens if you move that loop onto **real silicon**. The
puzzles here run on a $30 board on your desk, the "output" is a physical LED,
and when your answer is wrong the failure is a light blinking at you rather than
a red mark on a screen. The trade is honest: the game is a far better place to
learn the *thinking*, because it iterates in seconds and has none of the
toolchain and wiring in the way. This repo is a better place to learn what a
microcontroller actually is.

Play the game first. Then come and make an LED do it.

*This project is not affiliated with or endorsed by Chilling Moose. Details
above are from the App Store listing as of September 2026.*

## Quick start

```sh
./avr 1              # build lesson 01 and flash it to the board
./avr build 1        # build only, no board needed
./avr list           # lessons, envs, and the detected serial port
./avr help           # everything else
```

`./avr` wraps PlatformIO so nobody has to remember env names or where `pio` is
installed. Lesson names match loosely — `1`, `01`, `blink` and `01-blink` all
work — and `--uno` targets an ATmega328P board instead of the Mega. The
underlying commands still work if you prefer them:

```sh
pio run -e mega-01-blink            # assemble + link (no board required)
pio run -e mega-01-blink -t upload  # flash a connected Mega
```

Full install instructions: [docs/SETUP.md](docs/SETUP.md).

## Layout

```
avr                    build/flash/inspect helper (./avr help)
INSTRUCTIONS.md        every instruction the lessons use, and nothing else
platformio.ini         one build env per board x lesson
include/board.inc      the pin-to-port map that differs between the two chips
lessons/
  01-blink/            onboard LED, DDR/PORT, sbi/cbi, a hand-written delay loop
  02-hello-world/      a LEVEL: student loads 42 into a register, board grades it
  03-echo/             a LEVEL: copy input->output, signal done, graded 5 rounds
  04-sum/              a LEVEL: read two inputs and add them; must request the
                       second value, so the answer has to sequence its reads
  05-absolute-value/   a LEVEL: two's complement, sign testing, neg
  06-button-led/       input pins, internal pull-ups, sbic/skip-based branching
docs/SETUP.md          toolchain install, flashing, serial-port troubleshooting
```

## Why board.inc exists

The number printed on the header is a *label*, not an address — assembly talks
to ports and bits, and the same silkscreen number sits on a different port
depending on the chip:

| Silkscreen pin | Uno (ATmega328P) | Mega 2560 (ATmega2560) |
| --- | --- | --- |
| 13 (onboard LED) | PB5 | PB7 |
| 2 (button) | PD2 | PE4 |

Wiring instructions are identical on both boards; the source is not. Building
the Uno version of a lesson against a Mega produces no error — it just drives
the wrong pin — so all board-specific names live in
[include/board.inc](include/board.inc) and the lessons stay about the ISA.

## Mega gotcha worth teaching

`sbi`, `cbi`, `in`, and `out` can only reach I/O addresses `0x00`–`0x1F`. On the
ATmega2560, ports **H, J, K, L** are at `0x100`+ in memory space and are
unreachable by those instructions — the assembler rejects it outright:

```
Error: operand out of range: 226
```

That covers Mega digital pins 6, 7, 8, 9 and 14–17, which need `lds`/`sts`
(2 words, 2 cycles) instead of a one-word `sbi`. Ports B, D, E, F and G are in
low I/O space and behave exactly like the Uno's. Both lessons stay on those
ports on purpose.

## Lesson vs. level

`01` and `06` are **demos**: complete programs to read, run and modify.

`02` through `05` are **levels**: the student edits one small file
(`answer.inc`) and the board grades the result. The checker lives in a separate
`.S` file that `#include`s the student's answer inline, so there is no call and
no stack involved. Levels 03 and 04 run the answer five times with different
inputs, which is what stops a hardcoded constant from passing. Level 04 adds a
`jmp next_input` handshake — a hand-built subroutine call made of two plain
jumps, returning to a label the answer provides.

Adding more levels follows that shape: a `*.S` checker holding `main`, and an
`answer.inc` the student edits.

## Adding a lesson

1. `mkdir lessons/03-something` and add a `.S` file that defines `.global main`.
2. Append to `platformio.ini`:

   ```ini
   [env:mega-03-something]
   extends = mega
   build_src_filter = +<03-something/>
   ```

Use a capital `.S` extension: it runs the C preprocessor first, which is what
makes `#include` and `#define` work. Inside a `.S` file `;` starts an assembler
comment — but **not** on a `#define` line, where the preprocessor pastes it
into the macro body. Use `/* ... */` there.

## Hardware

- Arduino Mega 2560-compatible board (ELEGOO MEGA Project Starter Kit works)
- Lesson 06 needs one pushbutton wired between digital pin 2 and GND
