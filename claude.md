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

## Repo state (as of 2026-09-04)
```
avr                    helper script: ./avr 1 = build+flash, ./avr help for the rest
platformio.ini         4 envs, named <board>-<lesson>; default mega-01-blink
include/board.inc      per-chip pin-to-port map (the only board-specific file);
                       also applies _SFR_IO_ADDR so lessons write `sbi LED_PORT, LED_BIT`
lessons/01-blink/      DDR/PORT, sbi/cbi, hand-counted 5-cycle delay loop; no
                       subroutine or stack, absolute jmp (see note below)
lessons/02-button-led/ inputs, internal pull-ups, sbic skip-based branching
docs/SETUP.md          install, flashing, CH340/CP2102 driver troubleshooting
```
`pio run -e mega-01-blink -t upload`. All four envs build clean; disassembly verified to hit PB7/PE4 on the Mega and PB5/PD2 on the Uno.

**Hardware verified 2026-09-04:** a genuine **Arduino Mega 2560 R3** (USB `2341:0042`, signature `1E 98 01` = ATmega2560) on `/dev/cu.usbmodem21101`. `pio run -e mega-01-blink -t upload` wrote and verified 288 bytes; the pin-13 LED blinks at 1 Hz. This board enumerates as `usbmodem` via its ATmega16U2, so **no CH340 driver was needed** — but student-supplied ELEGOO clones usually do use a CH340 and will need it before a port appears.

## Open items / not yet decided
- Whether to introduce a second architecture unit (ARM Cortex-M via Uno R4 WiFi, or RISC-V via ESP32-C3) after the AVR fundamentals unit
- Final choice between Arduino Education Shield vs. relying solely on ELEGOO kit's bundled components for lab exercises — now leaning toward the kit's parts, since the shield's Uno form factor raises SPI/I2C questions on a Mega
- Whether the Mega's split between `sbi`-able and memory-mapped ports is a teaching liability worth switching the class to Unos over
- Lesson sequence beyond 02 (timers/interrupts, USART, arithmetic and the SREG flags are the obvious next candidates)
- **Debugging is researched but not set up** — see "Debugging and single-stepping" in `docs/SETUP.md`. Three findings worth carrying: (1) PlatformIO's bundled `avr-gdb` is broken on this Mac (linked against the removed Python 2.7 framework), so any GDB-based debugging needs `brew install avr-gdb` from the `osx-cross/avr` tap first; (2) this board's high fuse is `0xD8`, so **JTAG and OCD are disabled** and enabling them needs an ISP programmer, not the bootloader; (3) JTAG would occupy PF4-PF7 = pins A4-A7. The ATmega2560 having real JTAG where the 328P has only debugWIRE is a genuine point in the Mega's favour for the board question above. Recommended first step when wanted: `debug_tool = simavr` (simulator, no hardware, shows r0-r31 live)
