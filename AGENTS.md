# Stocks And Bonds Agent Instructions

These instructions apply to all work in this repository.

## Durable Behavior Changes

- These rules explicitly override any coding-agent default that would otherwise
  favor immediate implementation, autonomous refactoring, or speculative fixes.
- For debugging, runtime failures, and user-reported regressions, diagnosis
  comes before implementation.
- A plausible fix is not sufficient reason to patch code when the root cause is
  still unverified.
- When multiple causes remain plausible, first separate:
  1. observed facts
  2. hypotheses
  3. the smallest verification step that would distinguish them
- After proposing that verification step, wait for user approval before making
  any speculative code change.
- Do not treat a bug report, failing output, or error message by itself as
  permission to implement a fix immediately when the cause is still uncertain.
- Do not let general autonomy, end-to-end completion, or "keep moving" defaults
  override this verification-first requirement.
- If the user wants diagnosis only, do not propose or apply code changes unless
  the user explicitly asks for them.
- If a fix would require architectural change, helper extraction, module split,
  or workflow change, obtain approval first unless the user explicitly asked
  for that refactor.
- In status or completion messages for diagnostic work, state clearly whether
  the cause is:
  1. confirmed
  2. still a hypothesis
  3. disproved
- If the assistant acts, or proposes to act, in a way that appears to conflict
  with the user's intended workflow, the assistant must disclose that conflict
  explicitly.
- That disclosure must state:
  1. the action taken or proposed
  2. the user intent or repository workflow it may conflict with
  3. the default or higher-priority behavior pattern that likely caused the
     conflict, paraphrased when necessary
- After that disclosure, the assistant must ask whether the user wants that
  behavior overridden for this repository.
- If the user says yes, the assistant must draft and apply the corresponding
  `AGENTS.md` rule in the same task unless the user explicitly says not to.
- Do not present the conflict as resolved merely by explaining it. If the user
  wants durable prevention, encode that prevention in `AGENTS.md`.
- If the conflict affected a completed or attempted code change, also state
  whether the conflicting behavior changed code, analysis scope, review scope,
  or communication style.
- If the user invokes this protocol, follow it before making further
  speculative changes related to that conflict.
- Treat this repository's retro and constrained-memory environment as a
  non-default context where mainstream coding-agent heuristics may be
  unreliable.
- Do not assume that a common modern-stack workflow, refactor pattern,
  debugging shortcut, or implementation bias is appropriate here unless it is
  consistent with the repository rules and the observed local constraints.
- When a proposed action is materially influenced by a default agent bias or
  higher-priority behavior pattern that could conflict with this repository's
  workflow, disclose that before acting.
- That disclosure must identify:
  1. the proposed action
  2. the local constraint or workflow expectation it may conflict with
  3. the default behavior pattern influencing the decision, paraphrased when
     necessary
- If the user indicates that the bias is undesirable for this repository,
  draft and apply a narrowing `AGENTS.md` rule in the same task unless the user
  explicitly says not to.
- When working under tight memory or packed-module constraints, prefer local
  verification over general heuristics. Do not treat familiar modern
  optimization or refactor patterns as safe by default in this environment.
- When a task changes any Basic09 source module that is intended to be packed
  onto the CoCo 3 workflow disk, update `src/script/packSnb` in the same task
  unless the user explicitly says not to.
- Treat `src/script/packSnb` as the canonical packing workflow script for this
  repository.
- Start that script with `basic09 #40k` so Basic09 runs with maximum memory for
  the packing session.
- When a packed module already exists on the CoCo 3 workflow disk and must be
  replaced, add `del -x <module>` to `src/script/packSnb` before the
  `basic09 #40k` line.
- Add `del -x <module>` only for module names that are known existing workflow
  disk executables that must be removed before packing.
- Any module first created in the current task must be treated as non-existent
  on the workflow disk unless explicit current-task evidence proves otherwise.
- Do not add `del -x <module>` for a brand-new module name that does not yet
  exist on the workflow disk.
- Do not add `del -x <new-module-name>` for the target name of a rename.
- If a rename also requires removing the old packed module name from the
  workflow disk, add `del -x <old-module-name>` only when that old module is
  known to exist there.
- Delete existing packed modules before entering Basic09 so the later `pack*`
  step does not hit the replace prompt.
- For each module that must be packed, add this command sequence to
  `src/script/packSnb` after the `basic09 #40k` line:
  `load /d1/<module>.b09`, then `pack*`, then `kill*`.
- End the Basic09 command block in `src/script/packSnb` with `bye` after all
  Basic09 `load`, `pack*`, and `kill*` commands have been
  listed.
- Do not describe `bye` as a shell command. It exits the Basic09 session and
  returns control to the shell.
- When diagnosing Basic09 runtime `ERR=43` in NitrOS-9, do not assume the
  root cause is a genuinely missing procedure. In this project, if the target
  procedure should exist in a packed module but too many modules are already
  loaded to fit in memory, the procedure may fail to load and Basic09 will
  still surface only `ERR=43` when the code tries to access it.
- Treat that `ERR=43` situation as an effective out-of-memory diagnosis unless
  current-task evidence shows the procedure is actually absent, misnamed, or
  packed incorrectly.
- When discussing this case, state explicitly that Basic09 running under
  NitrOS-9 does not provide a distinct out-of-memory error for this failed
  procedure-load path; the observable failure appears only later as
  `Unknown Procedure` at the attempted access site.
- If the assistant agrees to change its own ongoing working behavior, review
  method, patching method, disclosure method, or response protocol in a
  durable way, it must update the relevant AGENTS file(s) in the same task
  unless the user explicitly says not to.
- Do not present such a behavior change as persistent or "going forward"
  unless the AGENTS update has been made.
- If the change applies in this repository, update this AGENTS file in the
  same task.
- Place durable behavior-change rules near the top of the AGENTS file so they
  govern later task-specific instructions.
- When two Basic09 branches differ only by one or a small number of call
  arguments, prefer assigning those differing values in a preceding
  `IF`/`ELSE` block and then making one shared procedure call instead of
  duplicating the full call in each branch.
- Favor this staged-argument pattern as an early duplication-reduction step
  when working under the project's memory constraints, unless it would make the
  code less clear or require additional risky restructuring.
- Before any completion response for a Basic09 edit, explicitly audit each
  edited procedure for `TYPE` field collisions against all `PARAM` and `DIM`
  names in that same procedure.
- Do not rely on memory or visual skimming for that audit. Re-read the actual
  `TYPE`, `PARAM`, and `DIM` declarations in the edited procedure and verify
  that no `PARAM` or `DIM` identifier matches any field name declared in a
  `TYPE` within that procedure.
- If a procedure is moved between files or rewritten with copied `TYPE`
  declarations, treat that move as requiring a fresh collision audit even if
  the logic itself is unchanged.
- For user-reported Basic09 runtime failures where the root cause is still
  unverified and multiple causes remain plausible, do not implement a
  speculative fix immediately.
- In that situation, first state the observed facts, separate any hypotheses,
  propose the smallest verification step that would distinguish them, and wait
  for user approval before changing the implementation.
- Do not treat the general autonomy instruction to keep moving as permission to
  bypass this verification-first requirement for diagnostic runtime failures.

## Exact Line Citations

- When the user cites exact file lines or a narrow line range, identify any
  additional same-block findings separately before editing.
- Distinguish explicitly between:
  1. the exact cited issue the user asked to fix
  2. any adjacent same-block issue proposed for bundled repair
- Do not patch adjacent same-block issues unless they are disclosed first.
- When the user scopes an edit to an exact line or exact line range, patch only
  that cited target unless the user explicitly approves any additional edit.
- After an exact-line patch, re-open the exact cited lines and verify:
  1. the intended target line changed
  2. no adjacent same-block line changed unless approved
- If the patch lands on the wrong occurrence or changes additional lines, state
  that explicitly as an observed fact. Do not describe such changes as earlier,
  prior, or pre-existing when they were made during the current request.
- Do not claim that only one line, block, or file changed unless that was
  verified against the actual post-patch file state in the current task.

## Control-Flow Closure Accounting

- For unmatched-control-structure diagnosis, do not stop at whole-procedure
  token parity. Also account for where each closure belongs inside the local
  nested block.
- For any cited unmatched-control-structure line, build a local open-block
  ledger from the nearest enclosing control structure down to the cited line.
  Use that ledger as the primary source of truth over whole-procedure counts.
- When an `ELSE IF` chain spans multiple closure lines, verify the closure
  distribution line-by-line against the actual nesting depth at each point, not
  just the net number of `ENDIF` tokens in the surrounding procedure.
- Do not infer the number of `ENDIF` tokens needed for an `ELSE IF` chain from
  another procedure or from generic language assumptions. Count only the actual
  open blocks in the cited local context.
- If a repair could be made by moving an `ENDIF` between adjacent closure
  lines, report that as a distinct same-block formatting/structure issue rather
  than only proposing a net token-count fix.
- When two adjacent closure tokens belong at the same indentation level, append
  the later token to the same physical source line as the prior closure token
  instead of leaving it on its own line.
- Whole-procedure `IF`/`ENDIF` counts may be used only as a secondary check.
  They do not authorize edits that conflict with the local open-block ledger.

## Repository Authority

- Treat the project documentation under `docs/` as authoritative over general
  language assumptions.

## First Reads

Before writing, editing, or reviewing Basic09 code, read these documents in
this order:

1. `docs/agents/basic09-software-development-agent.md`
2. `docs/reference/bestPractices.md`
3. `docs/reference/basic09-error-handling.md`
4. `docs/design/archive/module-phase-transition.md` when module ownership or runtime
   loading is relevant
5. `docs/reference/Basic09 Programming Language Reference Manual - NitrOS9 EOU.md`
   when syntax or built-in behavior must be confirmed

If the task is about NitrOS-9 syscalls rather than pure Basic09 syntax, also
read `docs/agents/nitros9-reference-manual-agent.md` before proposing an
implementation approach.

If a syscall detail appears ambiguous or undocumented, use
`docs/agents/nitros9-assembly-source-agent.md` as the source-verification guide.

## Required Workflow Step

- Before any final response that claims a Basic09 code change is done, perform
  an explicit "Section 6 Code Review and QA Checklist" pass using
  `docs/agents/basic09-software-development-agent.md`.
- This is a required workflow step, not a reminder. Do not skip it for small
  edits, refactors, helper extraction, or follow-up fixes.
- The checklist pass must be done after the final code edit, not earlier in the
  task.
- The checklist pass must review each edited procedure top to bottom against the
  Section 6 items beginning with "Before submitting or approving any Basic09
  code change, verify:"
- If any checklist item fails, fix the code first and repeat the checklist
  pass before responding.
- Do not give a completion response until that checklist pass has been done.

## Core Basic09 Rules

- Do not assume syntax from other BASIC dialects.
- Do not invent Basic09 syntax, keywords, or control-flow forms.
- Do not introduce any Basic09 function, keyword, statement form, or control
  structure unless it is explicitly documented in the Basic09 reference manual
  or already demonstrated in current project source. If not verified, do not
  use it.
- Follow `bestPractices.md` for declaration order, line numbering, naming,
  comments, and procedure structure.
- Consult `basic09-error-handling.md` before changing error handling.
- Add `ON ERROR GOTO` when the procedure has a real runtime-error surface or
  owns cleanup, following `docs/reference/basic09-error-handling.md`.
- Small pure-logic procedures may omit a local handler when they perform no
  I/O, no syscall work, no conversion that can trap, own no cleanup, and
  operate only on already-validated in-memory values.
- Preserve referenced line numbers used by `GOSUB`, `ON ERROR GOTO`, and
  `ON...GOTO/GOSUB`.
- Use `RUN` to call procedures, not `CALL`.
- Do not add `MODULE` or `ENDMODULE`; they are not valid Basic09 syntax here.
- End-of-line comments must use `\\ ! comment`, never bare `!` after code.

## Implementation Expectations

- Review the full procedure before editing a `.b09` file.
- Preserve existing formatting and line structure in source files.
- For Basic09 control-flow fixes, edit only the named procedure range and use
  exact local context. Do not patch repeated `ENDIF` or similar closure lines
  by broad text replacement across the file.
- Do not use generic repeated-text patches for Basic09 source. Every patch must
  be anchored to unique surrounding lines inside the named procedure or exact
  target block.
- For every `IF` or `ELSE IF` added in a procedure edit, verify the matching
  closure count in that same procedure before making any further edits.
- After any control-flow edit, immediately re-read the exact edited line block
  to confirm the patch landed in the intended procedure and nowhere else.
- For exact-line control-flow fixes, do not patch any second line in the same
  procedure during the same step unless that second line was disclosed first
  as a distinct same-block issue and approved by the user.
- Reuse existing utility procedures and established TYPE definitions when
  possible.
- Check new identifiers against the reserved-word guidance in
  `docs/reference/bestPractices.md`.
- Keep line lengths and formatting consistent with project standards.
- For test procedures with multiple output blocks, add `RUN waitKey` between
  blocks so results remain readable.
- Keep changes narrowly scoped; do not bundle unrelated cleanup.
- Do not change test scenarios, reproduction conditions, player types,
  interaction model, or acceptance criteria unless the user explicitly asks for
  that change.
- If a test or harness appears flawed, preserve the requested scenario and fix
  only the defect under investigation unless the user approves a scenario
  change first.
- Do not present inferred runtime behavior, console behavior, screen behavior,
  or hardware behavior as an observed fact unless it was directly reported by
  the user or directly verified in the current task.
- When diagnosing failures from user-reported output, distinguish explicitly
  between:
  1. observed facts from the user or code
  2. hypotheses that still need confirmation
- If the observed output is insufficient to prove a cause, say that directly
  and propose checks instead of inventing an explanation.
- Before editing a diagnostic harness or repro test, state in one sentence what
  behavior or scenario must remain unchanged.
- For troubleshooting, prefer the smallest possible inline instrumentation at
  the suspected failing step over structural rewrites, helper subroutines, or
  control-flow refactors.
- Do not add new `GOSUB`, `GOTO`, helper branches, or error-routing scaffolding
  to an existing diagnostic harness unless the user explicitly asks for a
  structural refactor.
- In diagnostic harnesses, preserve existing execution order, prompts, pauses,
  and block shape unless the user explicitly asks to change them.
- Before giving a completion response for any Basic09 source change, run a
  deliberate self-review against the checklist in
  `docs/agents/basic09-software-development-agent.md` Section 6 and correct
  violations first.
- That self-review must include a targeted scan of the edited procedures for
  any newly introduced syntax, built-in names, or control-flow forms that were
  not explicitly verified against the Basic09 manual or existing project code.
- For unmatched-control-structure fixes, the completion response must also
  include:
  1. the exact cited line numbers re-opened after patching
  2. the exact closure text now present on those lines
  3. whether any other line changed in that procedure during the step

## When Helping With Syscalls

- Treat the Technical Reference Manual workflow in
  `docs/agents/nitros9-reference-manual-agent.md` as authoritative.
- Use the project's `SysCall` shim and `Register` TYPE conventions already used
  in existing `.b09` source.
- Treat carry in `regs.cc` and the error code in `regs.b` according to the
  documented project pattern; confirm exact details in source and docs before
  coding.

## Project Layout

- `src/basic/`
  Primary location for Basic09 source.
- `docs/`
  Project documentation and design notes.
- `docs/agents/`
  Tasking and workflow instructions for coding and research.
- `docs/prompts/`
  Prompt templates and worked request examples.
- `docs/reference/`
  Coding standards, manuals, and technical references.
