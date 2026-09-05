# LearnAssembly

Teaching materials and a working build setup for a first course in assembly
programming on AVR. Course/hardware rationale lives in [claude.md](claude.md).

Supports two boards from one set of lesson sources:

| Board | Chip | Build env prefix |
| --- | --- | --- |
| Arduino Mega 2560 / ELEGOO MEGA | ATmega2560 | `mega-` |
| Arduino Uno / ELEGOO UNO | ATmega328P | `uno-` |

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
platformio.ini         one build env per board x lesson
include/board.inc      the pin-to-port map that differs between the two chips
lessons/
  01-blink/            onboard LED, DDR/PORT, sbi/cbi, a hand-written delay loop
  02-button-led/       input pins, internal pull-ups, sbic/skip-based branching
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
- Lesson 02 needs one pushbutton wired between digital pin 2 and GND
