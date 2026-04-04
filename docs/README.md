# Stocks And Bonds

Status: Current  
Authority: Documentation index and reading order

## Canonical Design Set

Read these files in this order when working on the game design:

1. `docs/design/stock-and-bonds-rules.md`
   Source transcription of the original Avalon Hill rules. Preserve this as the
   historical rules text. Project interpretations of ambiguous rules are
   defined in the specification.
2. `docs/design/specification.md`
   Canonical gameplay and rules-behavior document for this project.
3. `docs/design/phase-child-design.md`
   Canonical runtime architecture document for the current file-based
   phase-child implementation.
4. `docs/design/save-load-design.md`
   Canonical save format and resume-semantics document.
5. `docs/design/ui-screen-flow.md`
   Canonical UI and screen-navigation document.
6. `docs/design/ai-player-logic.md`
   Canonical AI behavior document.
7. `docs/design/ai-difficulty-tiers.md`
   Canonical AI parameterization document.

## Archived Design Files

- `docs/design/archive/forkio-plan.md`
  Historical transition document. Useful for rationale and some retained file
  IPC details, but not authoritative where it conflicts with the canonical set.
- `docs/design/archive/module-phase-transition.md`
  Historical module-loading design. Keep for code division notes and measured
  memory figures only; the runtime loading model is superseded.
- `docs/design/archive/project-timeline.md`
  Historical implementation planning artifact. Not authoritative for current
  rules or architecture.

A new Color Computer 3 NitrOS-9 project written in Basic09

## Project Structure

- `src/basic`: BASIC09 source
- `src/tests`: BASIC09 test code source
- `docs`: Project documentation
- `disks`: CoCo floppy disk images

## Build

This repository builds directly from `src/basic` and writes the source disk
image to `disks/snbsrc.dsk`.

Requirement:

- Install the ToolShed `os9` command-line utility and ensure `os9` is on your
  `PATH`.
- ToolShed repository: [https://github.com/n6il/toolshed](https://github.com/n6il/toolshed)

Run from the repository root:

```bash
./build.sh
```

Build behavior:

- Creates `disks/snbsrc.dsk` if it does not already exist.
- Uses `os9 format` and `os9 attr` to initialize the floppy image.
- Copies `.b09` files from `src/basic` directly into the disk image.
