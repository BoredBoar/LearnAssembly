# Setup

Everything below is free and cross-platform (macOS, Linux, Windows). PlatformIO
downloads its own copy of `avr-gcc` and `avrdude`, so there is no separate
toolchain install to babysit in a classroom.

## 1. Install VS Code

<https://code.visualstudio.com/> — then open this folder in it.

## 2. Install the VS Code extensions

Opening this folder prompts you to install both recommended extensions
(see `.vscode/extensions.json`); accept, or install them by hand:

| Extension | ID | Why |
| --- | --- | --- |
| PlatformIO IDE | `platformio.platformio-ide` | Build/upload buttons, serial monitor, installs PlatformIO Core |
| AVR Support | `rockcat.avr-support` | Syntax highlighting for AVR assembly |

VS Code ships **no** built-in assembly grammar, so without the second extension
the lesson sources render as undifferentiated plain text.

### Why `.S` files need a file association

AVR Support registers its grammar for `.asm` and `.inc` only, but our lessons
use a capital `.S` so that avr-gcc runs the C preprocessor over them first.
`.vscode/settings.json` bridges that gap:

```json
"files.associations": { "*.S": "avr", "*.inc": "avr" }
```

That is already committed, so highlighting works as soon as the extension is
installed - no per-student setup. If a file still looks plain, click the
language indicator in the status bar (bottom right) and confirm it says
**avr**.

## 3. (Optional) Command line

PlatformIO Core is already installed on this machine at
`~/.platformio/penv/bin/pio`. To type `pio` instead of the full path, add it to
your `PATH`:

```sh
echo 'export PATH="$HOME/.platformio/penv/bin:$PATH"' >> ~/.zshrc
exec zsh
```

## 4. Verify without hardware

```sh
pio run -e mega-01-blink   # assemble + link only; no board needed
```

## 5. Flash a board

Plug the Mega / ELEGOO MEGA in over USB, then:

```sh
pio run -e mega-01-blink -t upload
```

Swap the `mega-` prefix for `uno-` when building for an ATmega328P board. The
lesson sources are the same either way; only `include/board.inc` differs.

PlatformIO auto-detects the serial port. If it picks the wrong one, list ports
with `pio device list` and pin it down in `platformio.ini`:

```ini
upload_port = /dev/cu.usbserial-XXXX
```

### macOS driver note

Official Arduino Unos use an ATmega16U2 USB chip and need no driver. Many clones
(including some ELEGOO boards) use a **CH340** chip and show up only after
installing the CH340 driver, after which the port appears as
`/dev/cu.wchusbserialXXXX`. Boards using a **CP2102** need Silicon Labs' VCP
driver. Check which chip is on the board before class — it is the single most
common first-day blocker.

## Useful commands

The `./avr` script in the repo root wraps all of these — `./avr 1` builds and
flashes lesson 1, `./avr help` lists the rest. It finds `pio` and the serial
port on its own, so it works without adding anything to `PATH`.

| Command | What it does |
| --- | --- |
| `pio run -e mega-01-blink` | Assemble and link lesson 1 |
| `pio run -e mega-01-blink -t upload` | Flash lesson 1 to the board |
| `pio run -e mega-01-blink -t size` | Report flash/SRAM used |
| `pio run -t clean -e mega-01-blink` | Clean one env |
| `pio run -t clean` | Delete build output |
| `pio device list` | List serial ports |
| `pio device monitor` | Open a serial terminal (9600 baud) |

## Seeing the machine code

Disassemble the linked program to show students exactly which opcodes their
source became, and where each one landed in flash:

```sh
export PATH="$HOME/.platformio/packages/toolchain-atmelavr/bin:$PATH"
avr-objdump -d .pio/build/mega-01-blink/firmware.elf   # disassembly
avr-objdump -h .pio/build/mega-01-blink/firmware.elf   # section sizes
avr-nm -n .pio/build/mega-01-blink/firmware.elf        # symbols by address
```

The same `bin` directory holds `avr-as`, `avr-ld`, and `avr-size` if you want to
run an assemble/link by hand to show every step.

Building the same lesson for both boards and diffing the disassembly is a quick
way to show that `sbi 0x04, 7` (Mega) and `sbi 0x04, 5` (Uno) come from one
identical source file.

## Debugging and single-stepping (not set up yet)

Nothing below is installed — this is the research, done 2026-09-04, so it does
not have to be repeated. Everything here was checked against this board and this
machine rather than taken from documentation.

### Fix this first: the bundled `avr-gdb` is broken on macOS

PlatformIO's `toolchain-atmelavr` ships an `avr-gdb` linked against the Python
2.7 framework, which Apple no longer ships:

```
dyld: Library not loaded: /System/Library/Frameworks/Python.framework/Versions/2.7/Python
```

Every GDB-based option needs a working one. Build it from Homebrew:

```sh
brew tap osx-cross/avr
brew install avr-gdb
```

### What PlatformIO supports for this board

The `megaatmega2560` manifest declares two debug tools, both installable on demand:

```json
"debug": { "simavr_target": "atmega2560", "avr-stub": { "speed": 115200 } }
```

### Option 1 — simavr (recommended: simulator, no hardware)

Add `debug_tool = simavr` to a lesson env and press F5 in VS Code. Gives
breakpoints, single-step, and a live view of r0–r31. Works on bare `.S` files
with no framework, and needs no hardware — so every student can step through
their own code. Watching the borrow chain move through `CNT_LO`/`CNT_MID`/
`CNT_HI` one instruction at a time is exactly what lesson 01 teaches.

### Option 2 — Atmel-ICE over JTAG (real stepping on real silicon)

**This is where the Mega beats an Uno.** The ATmega2560 has full JTAG; the
ATmega328P only has debugWIRE, a single-wire protocol over the RESET pin that is
fragile and easy to lock yourself out of. Relevant to the open Mega-vs-Uno
question in CLAUDE.md.

Two things to know before buying hardware (both verified on this board):

- **JTAG is disabled from the factory.** The high fuse reads `0xD8`:
  `JTAGEN = 1` (off) and `OCDEN = 1` (off). Turning it on needs an **ISP
  programmer** — the Arduino bootloader can read fuses (`-U hfuse:r:-:h`) but
  cannot write them.
- **JTAG occupies PF4–PF7, which are pins A4–A7** on the Mega header. Enabling
  it costs those four analog inputs.

Hardware: Atmel-ICE ~$60, MPLAB Snap ~$35.

### Option 3 — avr-stub (GDB stub on the chip, over the USB cable)

No extra hardware, but it is a C library linked into the program, consuming
RAM, flash, a UART and an interrupt vector. A poor fit here: the debugger would
be many times larger than a 38-byte lesson.

### Option 4 — Microchip Studio simulator (Windows only)

The nicest *assembly* debugging UI of the lot: source-level stepping with a full
register and I/O view. Worth it if the classroom is Windows.

### Option 5 — no debugger

At 15 instructions, `avr-objdump -d` plus an LED used as a probe covers most
of it, and hand-tracing against the cycle counts in each lesson's instruction
legend is a worthwhile exercise in itself.
