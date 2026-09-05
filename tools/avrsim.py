#!/usr/bin/env python3
"""
avrsim - a very small AVR interpreter, just big enough to grade a level.

It disassembles a built lesson with avr-objdump and executes it from `main`
until the program reaches one of the checker's end labels. That answers the
only question that matters when authoring or attempting a level:

    does this answer.inc actually pass?

It is not a general AVR emulator. It knows the ~25 instructions the lessons
use and nothing else, has no memory, no stack, no I/O and no timing. If a
lesson starts using an instruction it does not know, it says so loudly rather
than quietly producing a wrong answer.

Usage:  python3 tools/avrsim.py <firmware.elf>
        ./avr check <lesson>          (the friendlier front end)
"""
import os, re, subprocess, sys

# The checker labels that end a run, and what the board does when you get there.
END_STATES = {
    'all_correct':  ('PASS',  'LED steady on'),
    'right_answer': ('PASS',  'LED steady on'),   # lesson 02 names it this way
    'wrong_answer': ('WRONG', 'LED blinking'),
    'no_signal':    ('DARK',  'LED dark - never jumped to `done`'),
}

def objdump():
    tc = os.path.expanduser('~/.platformio/packages/toolchain-atmelavr/bin/avr-objdump')
    return tc if os.path.exists(tc) else 'avr-objdump'

def disassemble(elf):
    """Return {addr: (mnemonic, operands, branch_target)} and {addr: label}."""
    out = subprocess.run([objdump(), '-d', elf], capture_output=True, text=True)
    if out.returncode != 0:
        raise SystemExit(f'avr-objdump failed on {elf}:\n{out.stderr.strip()}')
    prog, labels = {}, {}
    for line in out.stdout.splitlines():
        m = re.match(r'^([0-9a-fA-F]+) <([\w.]+)>:', line)
        if m:
            labels[int(m.group(1), 16)] = m.group(2)
            continue
        m = re.match(r'^\s+([0-9a-fA-F]+):\s+(?:[0-9a-fA-F]{2} )+\s*\t(\w+)\s*(.*)', line)
        if m:
            addr, mn, ops = int(m.group(1), 16), m.group(2), m.group(3)
            # objdump appends the resolved target as "; 0x1234 <label>"
            tgt = re.search(r';\s*0x([0-9a-fA-F]+)', ops)
            prog[addr] = (mn, ops.split(';')[0].strip(), int(tgt.group(1), 16) if tgt else None)
    return prog, labels

def run(elf, cap=200_000):
    prog, labels = disassemble(elf)
    by_name = {v: k for k, v in labels.items()}
    if 'main' not in by_name:
        raise SystemExit(f'no `main` in {elf}')
    if not any(n in by_name for n in END_STATES):
        return None, None, 0   # not a graded level (a demo lesson)

    order = sorted(prog)
    after = {a: b for a, b in zip(order, order[1:])}   # address -> next address
    r, Z, C, N, steps = [0] * 32, 0, 0, 0, 0
    pc = by_name['main']

    while steps < cap:
        steps += 1
        if pc not in prog:
            raise SystemExit(f'ran off the end of the program at 0x{pc:x}')
        mn, ops, tgt = prog[pc]
        # Stop as soon as we arrive at an end label; which LED that means is a
        # fixed property of the label, so there is nothing left to simulate.
        if pc in labels and labels[pc] in END_STATES:
            return labels[pc], r, steps

        d = [int(x[1:]) for x in re.findall(r'\br\d+\b', ops)]
        k = re.search(r'0x([0-9a-fA-F]+)', ops)
        k = int(k.group(1), 16) if k else None
        nxt = after.get(pc)

        def flags(v):
            return int(v == 0), (v >> 7) & 1

        if   mn == 'ldi':  r[d[0]] = k
        elif mn == 'mov':  r[d[0]] = r[d[1]]
        elif mn == 'nop':  pass
        elif mn in ('sbi', 'cbi'):  pass          # no I/O model; label says it all
        elif mn == 'add':
            v = r[d[0]] + r[d[1]]; C = int(v > 255); r[d[0]] = v & 0xFF; Z, N = flags(r[d[0]])
        elif mn == 'adc':
            v = r[d[0]] + r[d[1]] + C; C = int(v > 255); r[d[0]] = v & 0xFF; Z, N = flags(r[d[0]])
        elif mn == 'sub':
            v = r[d[0]] - r[d[1]]; C = int(v < 0); r[d[0]] = v & 0xFF; Z, N = flags(r[d[0]])
        elif mn == 'subi':
            v = r[d[0]] - k; C = int(v < 0); r[d[0]] = v & 0xFF; Z, N = flags(r[d[0]])
        elif mn == 'sbc':
            v = r[d[0]] - r[d[1]] - C; C = int(v < 0); r[d[0]] = v & 0xFF; _, N = flags(r[d[0]])
        elif mn == 'sbci':
            v = r[d[0]] - k - C; C = int(v < 0); r[d[0]] = v & 0xFF; _, N = flags(r[d[0]])
        elif mn == 'sbiw':
            w = (r[d[0] + 1] << 8 | r[d[0]]) - k
            C = int(w < 0); w &= 0xFFFF
            r[d[0]], r[d[0] + 1] = w & 0xFF, w >> 8
            Z, N = int(w == 0), (w >> 15) & 1
        elif mn == 'inc':  r[d[0]] = (r[d[0]] + 1) & 0xFF; Z, N = flags(r[d[0]])
        elif mn == 'dec':  r[d[0]] = (r[d[0]] - 1) & 0xFF; Z, N = flags(r[d[0]])
        elif mn == 'neg':  r[d[0]] = (-r[d[0]]) & 0xFF;    Z, N = flags(r[d[0]])
        elif mn == 'com':  r[d[0]] = (~r[d[0]]) & 0xFF;    Z, N = flags(r[d[0]])
        elif mn == 'cp':
            v = r[d[0]] - r[d[1]]; C = int(v < 0); Z, N = int(v == 0), (v >> 7) & 1
        elif mn == 'cpi':
            v = r[d[0]] - k;       C = int(v < 0); Z, N = int(v == 0), (v >> 7) & 1
        elif mn == 'tst':          Z, N = flags(r[d[0]])
        elif mn == 'brne': nxt = tgt if not Z else nxt
        elif mn == 'breq': nxt = tgt if Z else nxt
        elif mn == 'brcc': nxt = tgt if not C else nxt
        elif mn == 'brcs': nxt = tgt if C else nxt
        elif mn == 'brpl': nxt = tgt if not N else nxt
        elif mn == 'brmi': nxt = tgt if N else nxt
        elif mn in ('jmp', 'rjmp'): nxt = tgt
        elif mn in ('cli', 'sei'):  pass
        else:
            raise SystemExit(
                f'avrsim does not know the instruction `{mn}` (at 0x{pc:x}).\n'
                f'Add it to tools/avrsim.py and to INSTRUCTIONS.md.')
        pc = nxt
        if pc is None:
            raise SystemExit('fell off the end of the program')

    raise SystemExit(f'gave up after {cap} instructions - the answer probably loops forever')

def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__.strip())
    state, r, steps = run(sys.argv[1])
    if state is None:
        print('  not a graded level (no checker end labels) - nothing to simulate')
        return 0
    verdict, led = END_STATES[state]
    print(f'  {verdict:<6} {led}')
    print(f'         OUTPUT(r16)={r[16]}  INPUT(r17)={r[17]}  after {steps} instructions')
    return 0 if verdict == 'PASS' else 1

if __name__ == '__main__':
    sys.exit(main())
