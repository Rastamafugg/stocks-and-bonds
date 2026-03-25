## Basic09 Error Handling

This document defines the project's verified error-handling patterns for Basic09 code.
Use it together with `bestPractices.md`. `bestPractices.md` gives the short rule set.
This document explains when a local handler is required, when it is optional, and what
patterns to use in each case.

### 1. Core Model

Basic09 error handling is procedure-scoped.

- `ON ERROR GOTO` only affects the procedure in which it appears.
- Variables, line numbers, and handlers are local to that procedure.
- There is no valid cross-procedure shared error label pattern.

This means each procedure must decide whether it needs its own handler based on its
runtime-error surface and cleanup responsibility.

### 2. When a Local Handler Is Required

Add `ON ERROR GOTO` when the procedure does any of the following:

- Performs file I/O such as `OPEN`, `CREATE`, `DELETE`, `GET`, `PUT`, `READ`, or `WRITE`
- Performs syscall or other OS-facing work
- Uses conversion or input paths that may trap at runtime, such as `VAL`
- Owns cleanup that must run on failure, such as closing a path or restoring state
- Needs to distinguish an expected runtime condition from an unexpected one

Typical examples in this codebase:

- State-file readers and writers
- Procedures that open or close paths
- Syscall wrappers and module-loading helpers
- Procedures that intentionally catch conversion failures and convert them to a status flag

### 3. When a Local Handler May Be Omitted

A small pure-logic procedure may omit a local handler when all of the following are true:

- It performs no file I/O
- It performs no syscall or OS-facing work
- It performs no runtime conversion that can trap
- It owns no cleanup
- It operates only on already-validated in-memory values

This is an allowed omission, not a default habit. The author should be able to justify
why the procedure has no meaningful runtime-error surface of its own.

### 4. Expected vs Unexpected Errors

Use a local handler when the procedure must treat one runtime condition as expected.

Examples:

- File-not-found during an existence probe
- End-of-file in a reader that intentionally reads until exhaustion
- A `VAL` conversion failure being translated into `ok := FALSE`

In these cases, the handler should convert the runtime event into the procedure's
documented behavior. Do not print generic diagnostics for an expected control path unless
the procedure contract says to do so.

### 5. Cleanup Ownership

If a procedure opens a path, allocates temporary state, or changes a resource that must
be restored, it should usually own a local handler.

Typical pattern:

```basic09
PROCEDURE readThing
PARAM ok : BOOLEAN
DIM path : BYTE
DIM pathOpen : BOOLEAN

ON ERROR GOTO 900

pathOpen := FALSE
ok := FALSE

OPEN #path, "FILE":READ
pathOpen := TRUE

! normal work here

CLOSE #path
pathOpen := FALSE
ok := TRUE
END

900 IF pathOpen THEN
      CLOSE #path
    ENDIF
    ok := FALSE
END
```

The key point is not the exact message text. The key point is that the procedure cleans
up what it owns before it returns.

### 6. Prefer Status Returns for Recoverable Failures

For recoverable operations, prefer explicit status/result out-parameters over attempts to
escalate with `ERROR(ERR)`.

Good fit:

- `loadOK : BOOLEAN`
- `hasState : BOOLEAN`
- `numOk : BOOLEAN`

Use this pattern when the caller can choose between continue, retry, alternate path, or
quiet failure.

### 7. Do Not Rely on `ERROR(ERR)` for Delegation

Do not treat `ERROR(ERR)` as a reliable bubbling mechanism in this project.

- It is not the project's verified propagation model.
- It is especially unsafe inside a procedure's own error-handler block.
- Using `ERROR(ERR)` inside the `900` handler can loop back into the same handler.

If a procedure cannot recover locally, prefer one of these:

- print a targeted diagnostic and `END`
- set a status output and `END`
- return control through documented caller-visible state

### 8. Handler Shape

Choose the smallest handler shape that fits the procedure.

Common patterns:

1. Cleanup plus status return
2. Cleanup plus targeted diagnostic
3. Expected-condition branch plus normal completion

Not every handler needs verbose printing. Not every handler needs a separate expected
condition branch. The procedure contract should drive the choice.

### 9. Review Questions

Before adding or removing a handler, check:

- Does this procedure have any real runtime-error surface?
- Does it own cleanup?
- Does it convert an expected runtime event into a documented result?
- If it omits a handler, is that omission intentional and defensible?
- If it includes a handler, does the handler actually do useful work?

### 10. Summary Rule

Use `ON ERROR GOTO` where the procedure has something meaningful to catch, clean up, or
translate. Do not add a `900` block by reflex to tiny pure-logic procedures that have no
independent failure surface.
