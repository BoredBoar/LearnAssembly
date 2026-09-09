# Project review and improvement plan

Reviewed 2026-09-09. Scope: all six lessons, answer fixtures, build configuration,
`avr`, `tools/avrsim.py`, student documentation, and `CLAUDE.md`.
This is a proposed plan; implementation files have not been changed.

## Recommendation

Keep lesson-specific grading beside the lesson. Centralize only genuinely shared
machinery: board definitions, level register conventions, and LED result routines.
Separate student-facing explanations from instructor solutions. Directory placement
organizes material; it does not make material private.

Confirmed instructor preferences: grading is practice feedback and readable checkers
are welcome; support macOS, Windows, and Linux; preserve lesson 04's sequential
input-request handshake. No private assessment infrastructure is needed.

Preserve the strongest existing choices: real hardware feedback, small editable
answers, shared board mapping, and fixtures representing plausible mistakes.
Do not build a general lesson engine or expand to another architecture yet.

## Findings, ordered by priority

### 1. Simulator results are not yet a reliable correctness oracle

In `tools/avrsim.py:95–107`, `sbc` and `sbci` leave Z unchanged instead of updating
it to previous-Z AND result-is-zero. `com` does not set C, and `neg` does not set
C according to whether its result is nonzero. Later carry/zero branches can
therefore disagree with hardware.

Four synthetic instruction sequences, injected through the existing disassembly
interface, reproduced these errors: COM followed by BRCS; nonzero NEG followed by
BRCS; and SBC/SBCI producing nonzero after a zero compare, followed by BRNE.
Each should reach the success label and instead reaches the failure label.
This demonstrates interpreter bugs, not that the current lesson fixtures fail.

The interpreter also initializes every register to zero, starts at `main`, ignores
I/O, and stops before executing the LED result routine. Its checks cannot verify
reset behavior, wiring, LED timing, or the correctness of the result routine itself.
Lesson 02 does not initialize OUTPUT, so its empty-answer hardware result depends
on a register value the lesson never establishes; the simulator hides that issue.

Fix the supported instruction semantics and add focused tests independent of lesson
fixtures. Reject unsupported instructions explicitly, including any aliases emitted
by objdump. Before adding memory, calls, or interrupts, evaluate replacing the
interpreter with a maintained AVR simulator through one thin verdict adapter.
Validate actual board support and installation before committing to a replacement.

### 2. Verification mutates student work and can report misleading success

`avr:124–170` replaces real `answer.inc` files with fixtures. EXIT restoration is
helpful, but cannot protect against forced termination or concurrent editing and
verification. The restored source also differs from the last fixture's build output.

The blank-answer regex misses unindented instructions and many mnemonics. Lessons
without tests are silently skipped, so a new graded lesson can be omitted while
verification reports success. Missing fixture headers can terminate the script at
the assignment under `set -e`/`pipefail`, before the intended diagnostic executes.

Build fixtures in an isolated temporary project/output directory, or use an explicit
answer-file build override with isolated outputs. Never swap the student's file.
Separate release-template validation from checking students' current answers.
Make zero fixtures, missing required suites, invalid expected verdicts, build
failures, unsupported instructions, and timeouts explicit outcomes. Preserve logs
instead of parsing the first word of combined stdout/stderr.

### 3. Correct factual claims before they become teaching conventions

| Location | Correction |
| --- | --- |
| `README.md:109`, `CLAUDE.md:31`, `INSTRUCTIONS.md:105` | SBI/CBI/SBIC/SBIS reach I/O 0x00–0x1F; IN/OUT reach 0x00–0x3F. Mega ports H–L still need memory access. |
| `CLAUDE.md:10` | AVR instructions are mostly 16-bit, with 32-bit instructions too; the ISA is not fixed-width. Shared lesson instructions do not imply identical device capabilities. |
| `lessons/01-blink/README.md:122` | RCALL/RET costs are 3/4 cycles on ATmega328P and 4/5 on ATmega2560, not three cycles each way. |
| `lessons/05-absolute-value/answer.inc:37` | MOV and LDI do not set N. Explain which operations update flags; this is why a compare/test is needed before branching. |
| `lessons/05-absolute-value/answer.inc:54` | The -128 limitation belongs to signed 8-bit representation, not every programming language. State the task's permitted input/output range explicitly. |
| Lesson 05 README, checker comments, and `CLAUDE.md:170` | Negating zero still gives zero. Output grading cannot distinguish choosing the negate path for zero from choosing the copy path. Remove the claimed zero-sign bug detection. |
| `lessons/04-sum/answer.inc` | Extra scratch is not required: save INPUT directly in OUTPUT, request input two, ADD into OUTPUT, then signal done. Accept this four-instruction solution as a fixture. |
| `INSTRUCTIONS.md` | Distinguish student vocabulary, checker internals, and optional exercises. The current “every instruction ... and nothing else” claim does not match these scopes or simulator support. |

Instruction corrections are grounded in Microchip's
[AVR Instruction Set Manual](https://ww1.microchip.com/downloads/aemDocuments/documents/MCU08/ProductDocuments/ReferenceManuals/AVR-InstructionSet-Manual-DS40002198.pdf),
especially COM, NEG, SBC/SBCI, IN/OUT, RCALL/RET and their status-register tables.

Use “no calls in the student code” in place of whole-program “no stack” claims:
the linked runtime initializes the stack, and its startup sequence must be included
when making claims about the entire executable. Move recorded binary sizes and
addresses into dated verification records rather than presenting them as invariants.

### 4. The documented universal level contract has an intentional exception

`CLAUDE.md` requires multiple rounds, cleared OUTPUT, `jmp done`, a no-signal guard,
and three result states for every level. Lesson 02 has one constant task, falls
through to grading, does not clear OUTPUT, and has two result states.

Keep lesson 02 as an explicit introductory exception: initializing OUTPUT is needed,
but multiple rounds add no value when loading a specified constant is the objective.
Introduce explicit completion and multiple inputs in lesson 03. Document contracts
by stage rather than making earlier exercises more complex merely for uniformity.

### 5. Five public test inputs are useful feedback, not proof or isolation

Repeated inputs catch a single hardcoded answer; they do not prove the student used
INPUT. Predictable sequences can be reproduced, and the inline answer can jump to
`all_correct` or overwrite checker state. These are not separate protection domains.
Several READMEs also publish complete solutions, as do `tests/correct*.inc` files.
Moving only the checker will not remove spoilers.

For practice, explicitly treat the grader as feedback for answers following the
register/control-flow contract. Use diverse boundary cases and alternative correct
solutions. Consider exhaustive inputs for small unary tasks in host-side checks.
No private assessment infrastructure is proposed for the confirmed practice use case.
Do not claim that hiding files in VS Code, binaries, or another folder prevents access.

### 6. The helper's portability does not match the setup promise

`avr:50–66` recognizes macOS serial device names only. Upload and monitor fail on
Linux through the wrapper even when PlatformIO could detect the board itself.
The Bash entry point also needs an explicit Windows support strategy.
`./avr help` and `list` unnecessarily require PlatformIO to be installed.

Use PlatformIO's port detection for uploads, with an explicit port override when
needed. Only resolve dependencies for commands that need them. Keep the existing
student command concepts; with Windows support confirmed, replace the growing shell
implementation with a small Python CLI. Offer `python tools/avr.py ...` on Windows
and retain `./avr ...` as a thin launcher on macOS/Linux. Document supported commands
for each OS and respect configurable PlatformIO/toolchain locations.

### 7. Documentation has become a second, drifting implementation

`CLAUDE.md` mixes agent instructions, hardware shopping, project history, lesson
contracts, local machine state, and research. It says “all four envs” alongside
twelve configured environments. The root addition guide uses an already occupied
lesson number and adds only a Mega environment, with no fixture requirements.
Setup presents one Mac's state as general installation guidance.

Make README the student entry point, SETUP an OS-specific installation guide,
INSTRUCTIONS the scoped instruction reference, and a new AUTHORING guide the
single source of level contracts and verification requirements. Keep CLAUDE.md
short: project intent, commands, constraints, and links. Move historical hardware
measurements and unvalidated debugging proposals into dated instructor notes.
Retain attribution, but shorten the promotional section so quick start comes first.

## Proposed structure

```text
CLAUDE.md                     concise agent guidance
README.md                     student start and lesson index
INSTRUCTIONS.md               student vocabulary, introduced by lesson
docs/SETUP.md                 supported OS setup
docs/AUTHORING.md              contracts and author acceptance checklist
include/board.inc             existing board abstraction
include/level.inc             small common register/interface definitions
include/feedback.inc          shared PASS/WRONG/DARK LED routines
lessons/03-echo/
  README.md                   explanation without an immediate solution
  answer.inc                  short task, interface, editable area
  checker.S                   lesson-specific input and comparison logic
  instructor.md               solution and teaching notes
  tests/*.inc                 author regression fixtures
tools/                        CLI and simulator adapter/tests
```

This is an authoring layout, not a privacy boundary. Keep everything in one repository
for the confirmed practice use case. Separating instructor notes and clearly labeling
solution fixtures reduces accidental spoilers. A separate student package is optional
and should be deferred unless classroom use demonstrates a need.

Keep demo sources readable and complete, including blink's delay loop. Sharing the
level LED routines does not require introducing calls into student answers: an
assembly include can emit the common labeled routines once per firmware.
Do not generalize the four different checkers into a macro-heavy framework.
Keep the twelve explicit PlatformIO environments for now; configure both boards
consistently and pin a validated platform version when establishing CI.

## Implementation sequence and completion criteria

1. **Restore trust in the existing project.** Correct the factual claims and
   lesson 02 initialization; repair simulator flags; isolate fixture execution;
   make missing tests fail. Done when focused semantic tests pass, all current
   fixtures execute on both board targets, and verification never changes answers
   even on build failure or interruption.
2. **Set the teaching and distribution contract.** Record readable practice checkers,
   support for all three desktop operating systems, and the lesson 02 exception,
   register ownership, scratch lifetime, completion protocol, permitted instructions,
   and input domains. Preserve lesson 04's handshake and explicitly name saving
   state across sequential input requests as its objective. Add a fixture proving
   that saving the first input directly in OUTPUT is a valid solution.
3. **Remove repeated maintenance.** Extract common feedback code, standardize
   checker naming and end labels, split solutions from student prose, shorten
   CLAUDE.md, and fix helper portability. Done when a student can find, edit, check,
   and upload one answer without reading instructor documentation.
4. **Establish a release gate before lesson 07.** Build all twelve environments;
   execute all level fixtures on both targets; test interpreter semantics and CLI
   failure behavior; check distributed templates for solutions. Record a Mega
   hardware smoke test covering blink and each feedback state, plus button input.
   Record Uno build verification separately from any actual Uno hardware testing.
5. **Then expand the curriculum.** Choose one next learning objective, add its
   contract and adversarial/alternative-correct fixtures first, and only extend
   emulator capabilities when justified. Evaluate a maintained simulator before
   taking on memory, stack, or interrupt emulation.

## Validation performed and limits

- Inspected all six lesson sources, answer templates, documentation, build/helper
  code, simulator, and fixture organization/content.
- `bash -n avr` passed.
- Four targeted interpreter reproductions exposed the flag bugs described above.
- `./avr help` failed because dependency detection precedes command dispatch.
- PlatformIO and AVR binutils are absent in this environment, so firmware builds,
  the full fixture suite, disassembly claims, and hardware behavior were not rerun.
- No implementation changes were made during this review.

## Sharing work between Claude, Codex, and workstations

Confirmed workflow: the instructor uses Git commits and push/pull between
workstations, with Claude Code and Codex through CLI/editor integrations. This
repository is the instructor's working copy and course source. Students clone it,
edit answers locally, and do not push their work back. No submission collection,
student branches, or student-answer synchronization feature is needed.

1. **One shared instruction file.** Add a short root `AGENTS.md` as the canonical
   agent guidance. Replace the current long `CLAUDE.md` with `@AGENTS.md` and only
   any genuinely Claude-specific instructions. First preserve useful existing
   material in the authoring guide and dated hardware notes. Do not simply duplicate
   all 17 KB under another filename. Codex discovers AGENTS.md; Claude Code supports
   importing it from CLAUDE.md. Use a regular file import, avoiding Windows symlink
   setup. See [Codex instruction discovery](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
   and [Claude Code shared instructions](https://code.claude.com/docs/en/memory#agentsmd).
2. **Portable handoffs.** Keep accepted decisions in AUTHORING.md and the active
   implementation checklist in PROJECT_REVIEW.md until this work is complete. For
   unfinished instructor tasks, use `docs/HANDOFF.md` with the task branch and base
   commit, work completed,
   exact checks and results, blockers, and next action. Update it at handoff, rather
   than maintaining an ever-growing conversation log. Tell both agents where to
   read it. Do not depend on either product's private chat history or automatic
   memory to convey decisions to the other agent or another machine.
3. **Reproducible setup.** Pin validated PlatformIO Core/platform versions, document
   the Python version requirement, and add a portable diagnostic command reporting
   tool availability, versions, board choice, and discovered ports. A new checkout
   should build and verify without hardware. Keep upload as a separate local step.
   Continue the planned Python CLI migration and remove fixed home-directory paths.
4. **Shared files versus machine state.** Version project instructions, source,
   dependency declarations, and portable editor settings. Keep build caches,
   virtual environments, credentials, serial-port overrides, and local agent settings
   outside shared source. Add targeted ignore patterns, not blanket exclusions of
   `.agents`, `.codex`, or `.claude`, which may later hold intentional shared config.
   Add `.gitattributes` with LF endings for source/scripts and `.editorconfig` for
   consistent whitespace. Validate in a fresh checkout to avoid unrelated churn.
5. **Explicit change ownership.** Use the confirmed Git handoff mechanism: checkpoint
   unfinished work on a task branch, push, and pull that branch on the next machine.
   A local stash does not travel with push/pull. For sequential agent use, stop the
   first agent before handing over the checkout. For simultaneous work, use separate
   branches and worktrees/checkouts, then review and merge. Both agents should inspect
   Git status before editing and preserve existing changes.
6. **Verify the handoff itself.** On a fresh checkout on each supported OS, confirm
   both agents can identify the shared instructions and current decisions. Run the
   same non-hardware checks, resume one unfinished task using its handoff note, and
   confirm local paths and ports never enter tracked changes. Agent authentication
   and local permissions remain workstation setup steps.

### Instructor and student workflow

- Instructor changes start from an up-to-date checkout. Use task branches for work
  that is not ready for students. Before switching machines or agents, update the
  handoff note, commit the intended changes, and push the task branch. On the next
  machine, fetch and check out that branch; inspect local changes before pulling.
  Commit/push actions remain explicit user actions or explicitly authorized agent
  actions; the shared guidance should not silently authorize publishing.
- Keep the default branch ready for student use, with blank answer templates and
  working build instructions. Merge completed work after the agreed checks. Use a
  course release tag when students need a stable starting point during a class.
- Students clone the course source and edit the existing `answer.inc` files locally.
  They need no write access, fork, remote branch, or push step. Their local Git
  changes are expected; do not hide tracked answers with ignore rules or require
  author-only blank-template checks as part of `check` or `build`.
- Instructor trial solutions should become fixtures when useful and should not
  enter published answer templates. The isolated fixture runner remains necessary
  even though the instructor repository is not a student-work store.
- Document class updates separately from first-time setup: pulling changes that
  touch edited answer files can require reconciliation. Avoid automatic resets or
  pulls in the build helper; a fixed release tag keeps that out of normal lessons.

### First implementation batch

Limit the initial change to shared agent context and predictable checkouts:
`AGENTS.md`, the small `CLAUDE.md` import, preservation of the existing rationale,
`docs/HANDOFF.md`, `.gitattributes`, `.editorconfig`, targeted ignore rules, and a
short contributor workflow. Put confirmed teaching decisions and links to the
remaining review tasks in the shared guidance. Keep grading fixes and the portable
CLI as subsequent changes, each with its own validation.

Do this instruction-and-handoff cleanup before the larger grading refactor so either
agent can implement that plan with the same context. Avoid extra hooks, custom skills,
containers, or shared chat databases until a concrete workflow requires them.
