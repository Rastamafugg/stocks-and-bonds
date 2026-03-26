Here is a list of rules and general tips for writing Basic09 code.

---

## Reserved Words

The following identifiers are reserved by Basic09 and **must not** be used as variable names, TYPE attribute names, array names, or procedure names. This includes lowercase or mixed case versions of the identifiers.

### Statements & Control Flow

```
ABS       ACS       ADDR      AND       ASC       ASN
ATN       BASE      BYE       CHAIN     CHD       CHR$
CHX       CLOSE     COS       CREATE    DATA      DATE$
DEG       DELETE    DIM       DO        ELSE      END
ENDEXIT   ENDIF     ENDLOOP   ENDWHILE  EOF       ERR
ERROR     EXITIF    EXP       FALSE     FIX       FLOAT
FOR       GET       GOSUB     GOTO      IF        INKEY
INPUT     INT       KILL      LAND      LEFT$     LEN
LET       LNOT      LOG       LOG10     LOOP      LOR
LXOR      MID$      MOD       NEXT      NOT       ON
OPEN      OR        PARAM     PAUSE     PEEK      PI
POKE      POS       PRINT     PROCEDURE PUT       RAD
READ      REM       REPEAT    RESTORE   RETURN    RIGHT$
RND       RUN       SEEK      SGN       SHELL     SIZE
SIN       SQ        SQR       SQRT      STEP      STOP
STR$      STR       SUBSTR    SYSCALL   TAB       TAN
THEN      TO        TRIM$     TROFF     TRON      TRUE
TYPE      UNTIL     UPPER$    USING     VAL       WHILE
WRITE     XOR
```

### Data Types

```
BOOLEAN   BYTE      INTEGER   REAL      STRING
```

### File Access Parameters

```
DIR       EXEC      READ      UPDATE    WRITE
```

> **Note:** `READ`, `WRITE`, and `DIR` appear in both the Statements and File Access lists. They are reserved in all contexts.

---

## Rules

### Code Structure

* **Use structured programming techniques.** Large, complex programs are easier to develop, test, and maintain when they are divided into multiple procedures, each with a specific function.

* **Limit source changes to the task at hand.** This is a GitHub-managed project. Check-ins should be targeted to solving the assigned task only. Leave unrelated code unchanged.

* **Use the `:=` operator for assignment, `=` for comparison.** Although `=` is also accepted for assignment, using `:=` distinguishes assignment from comparison.

* **Declare variables with `TYPE`, `PARAM`, and `DIM` at the start of a procedure.** This is not mandatory, but improves readability. The declaration order is strict: `TYPE` first, then `PARAM`, then `DIM`.

* **`TYPE` declarations must occupy a single line.** You cannot split a `TYPE` declaration across multiple lines.

* **Initialize variables.** Basic09 does not automatically initialize variables. Assign initial values explicitly.

* **Use parentheses to override operator precedence.** This improves expression readability.

### Line Numbers and Formatting

* **Reserve line numbers for `GOSUB`, `ON ERROR`, and `ON...GOTO/GOSUB` targets.** Line numbers make programs harder to read and increase compile time. Use them only where required by syntax.

* **Line numbers must increase in value within a procedure.** Separate procedures' line numbering is independent. Start line numbers at 100 and increment by 100. Reserve line number `900` for the end-of-procedure error handler. Keep all other line numbers below this value and increasing in value as you progress down the procedure listing.

  ```basic09
  PROCEDURE ProcExample
    PARAM branchValue:BYTE
    ON ERROR GOTO 900
    ON branchValue GOSUB 100, 200
    END

  100 \ ! Branch A
    RETURN

  200 \ ! Branch B
    RETURN

  900 \ ! Error handler
    END
  ```

* **Write one program statement per line.** The backslash statement concatenation syntax (`\`) hides program structure and offers no speed advantage. Exceptions: inline comments (`\ ! comment`) and multi-`ENDIF` switch closures (`ENDIF \ENDIF \ENDIF`).

* **Program statements cannot be extended across multiple lines.** The `\` symbol cannot be used to bridge a single statement across multiple lines.

* **Use end-of-line comments to clarify, not narrate.** End-of-line comments use the syntax `\ ! comment text`. The `!` alone is only legal at the start of a line or after a `\`.

  ```basic09
  IF testVal = 0 THEN \ ! Guard clause
    ! Handle zero case
  ENDIF
  ```

* **Prefer lines of 79 characters or fewer.** This is a readability guideline, not a hard rule. The maximum is 256 characters, but Basic09's line editor has UI issues beyond 79. Valid one-line exceptions are acceptable when splitting would reduce clarity or break the syntax, especially for single-line `TYPE` declarations, `PRINT USING` statements, and `RUN` statements that must remain intact.

* **Place all comments and logic inside `PROCEDURE` blocks.** Procedure header comments must immediately follow `PROCEDURE name`, before any declarations.

  ```basic09
  PROCEDURE demo
  (* ================================================== *)
  (* PROCEDURE: demo                                    *)
  (* ================================================== *)
  TYPE ...
  PARAM ...
  DIM ...
  END
  ```

### Logic Blocks and Termination

* **Terminate all logic blocks with their correct closing keyword.**

  | Opening | Closing |
  |---|---|
  | `IF`/`THEN` | `ENDIF` |
  | `WHILE`/`DO` | `ENDWHILE` |
  | `FOR` | `NEXT` |
  | `REPEAT` | `UNTIL` |
  | `LOOP` | `ENDLOOP` |
  | `EXITIF` | `ENDEXIT` |

* **Use explicit, nested `ENDIF` statements for `IF`/`ELSE IF` logic.** Each `ELSE IF` is a nested `IF` block. The total count of `ENDIF` statements must exactly match the total count of `IF` statements in the block.

* **Write switch/case logic using nested `IF`/`ELSE IF`.** `SWITCH`, `CASE`, and `ELSEIF` are not reserved words in Basic09.

  ```basic09
  IF condition1 THEN
    ! Branch 1
  ELSE IF condition2 THEN
    ! Branch 2
  ELSE IF condition3 THEN
    ! Branch 3
  ELSE \ ! Default
    ! Default branch
  ENDIF \ENDIF \ENDIF
  ```

* **Count `IF` tokens to verify `ENDIF` count before finalizing any
  procedure.** The number of `ENDIF` statements in a procedure must
  exactly equal the number of `IF` keywords, including every `IF` that
  appears after `ELSE`. This is a mechanical count, not a visual check.
  Indentation is not reliable evidence of correct closure.

  Quick reference:

  | Pattern                          | IF count | ENDIF count |
  |----------------------------------|----------|-------------|
  | `IF...ENDIF`                     | 1        | 1           |
  | `IF...ELSE IF...ENDIF \ENDIF`    | 2        | 2           |
  | `IF...ELSE IF...ELSE IF...ENDIF \ENDIF \ENDIF` | 3 | 3    |

  The `\ENDIF \ENDIF` suffix pattern on a single line is correct and
  required when closing nested `ELSE IF` chains; it is not a style
  preference.
  
* **Reserved-word functions are called in function form, not infix form.** Do not assume that a reserved word that performs a calculation can be written between operands. Write it as a function call with parentheses and arguments.

  Examples:
  - Correct: `MOD(num1, num2)`
  - Wrong: `num1 MOD num2`
  - Correct: `LAND(mask, $01)`
  - Wrong: `mask LAND $01`
  - Correct: `LOR(flagA, flagB)`
  - Wrong: `flagA LOR flagB`

* **Numeric INPUT logic should handle non-numeric edge cases.** Use an INPUT plus validation pattern. Always guard with: (1) if the string is empty, treat it as zero or the documented default. (2) Otherwise, validate the conversion path explicitly before trusting the numeric result.

* **Audit percentage arithmetic for 16-bit overflow.** Basic09 `INTEGER` is signed 16-bit with a maximum safe value of 32,767. Any expression `A * B` where the product may exceed 32,767 silently wraps and produces a wrong result.

  The common pattern to audit is `value * pct / 100`.

  | pct | overflows when value > |
  |-----|------------------------|
  | 100 | 327 |
  |  75 | 437 |
  |  50 | 655 |
  |  40 | 819 |
  |  25 | 1310 |
  |  20 | 1638 |
  |  10 | 3276 |
  |   5 | 6553 |

  Fix strategies depend on context:
  1. Constant percentage with a clean reciprocal. Replace with a single integer division when exact.
  2. Value is always a multiple of 10. Divide into lots first, then scale.
  3. General case. Divide before multiplying if the calling context tolerates truncation.

### Procedure Calls and Parameters

* **Use `RUN` to execute a procedure.** `CALL` is not a valid keyword.

* **Rely on pass-by-reference as the default parameter behavior.** All `PARAM` variables are passed by reference. To force pass-by-value, re-evaluate the variable at the call site, for example `RUN proc(myVar + 0)`.

* **Use line numbers, not labels, in `ON...GOTO` and `ON...GOSUB` statements.** Example: `ON ERROR GOTO 100`, not `ON ERROR GOTO MyLabel`.

* **Use `END` to terminate a `PROCEDURE`.** `RETURN` is valid only for returning from a `GOSUB` subroutine. It does not return data to the caller. Use passed-by-reference parameters to return values.

* **Declare a `TYPE` at the top of every procedure that receives or uses it.** When a `TYPE` variable is passed as a parameter, its `TYPE` definition must appear at the top of both the calling and called procedures.

### Scope

* **Treat all variables, line numbers, and error handlers as strictly local to their procedure.** There is no global scope in Basic09. A variable defined in one procedure has no meaning in another unless explicitly passed via `RUN`/`PARAM`.

### Error Handling

* **Include an `ON ERROR GOTO` handler when the procedure has a real runtime-error surface or owns cleanup.** Common triggers are file I/O, syscalls, `GET`/`PUT`/`OPEN`/`CREATE`/`DELETE`, `INPUT` or `VAL` conversion traps, and any procedure that must close paths, restore state, or release resources on failure.

* **A small pure-logic procedure may omit a local handler when all of the following are true:** it performs no I/O, no syscall work, no conversion that can trap, owns no cleanup, and operates only on already-validated in-memory values. Omission should be intentional, not accidental.

* **Do not treat `ERROR(ERR)` as a reliable bubbling mechanism.** In this codebase it is not a verified way to delegate an error to the caller's `ON ERROR` handler. Prefer explicit local handling, verified control-flow patterns, or status/result out-parameters.

* **Use `MODULE`/`ENDMODULE` syntax only in other languages.** These are not reserved words in Basic09 and must not appear in `.b09` source files.

### Naming

* **Use descriptive variable and type names.** Favor names that are clear in context. Short names are useful for loop counters or tightly local values, but clarity matters more than forcing an arbitrary length limit.

* **Ensure all variable, parameter, and TYPE attribute names are unique within a procedure.** Duplicate names within the same procedure cause definition errors.

* **Never use a reserved word (see table above) as a variable name, TYPE attribute name, array name, or procedure name.**

### Parameters, Variables, and Types

* **Variable, Param, and Type Attribute names must be unique within a procedure.** It is a syntax error when a variable or parameter shares the same name as a TYPE attribute.

* **PARAM passing is governed by storage size compatibility, not semantic type identity.** Basic09 does not enforce declared type identity at the call site. It checks storage size. This means size-compatible reinterpretation can be intentional, but a size mismatch causes the called procedure to read the wrong bytes silently. The rules by caller source are:

  | Caller passes          | BYTE PARAM result        | INTEGER PARAM result |
  |------------------------|--------------------------|----------------------|
  | Integer literal (e.g. `42`) | High byte of 2-byte int = **0** | Correct: `42` |
  | BYTE variable          | Correct: `42`            | **Reads 2 bytes from BYTE address: `byteVal * 256 + nextMemByte`** |
  | INTEGER variable       | High byte only = **0**   | Correct: `42` |
  | BYTE struct field      | Correct: field value     | **Reads 2 bytes from field address: same garbage pattern** |

  Practical rules derived from the table:
  - Declare PARAMs to match the storage size the caller will actually pass.
  - Declare PARAMs as `INTEGER` for values callers will pass as literals or `INTEGER` variables.
  - Never pass a `BYTE` variable or `BYTE` struct field directly to an `INTEGER` PARAM. Stage through a local `INTEGER` DIM variable first.
  - Reserve `BYTE` PARAMs only for procedures whose callers will exclusively pass 1-byte storage such as `BYTE` variables or `BYTE` struct fields.
  - Size-compatible reinterpretation is possible in Basic09, but it must be deliberate and documented at the procedure boundary.
  - Reserve `BYTE` for `TYPE` record fields and `BYTE` arrays. Prefer `INTEGER` for most working variables, arithmetic, loop counters, and procedure parameters.

* **Stage BYTE fields through an INTEGER variable before passing to an INTEGER PARAM.** Passing a `BYTE` variable or `BYTE` struct field directly to a procedure expecting an `INTEGER` PARAM causes Basic09 to read 2 bytes starting at the BYTE's 1-byte address. The BYTE value lands in the high byte and the low byte is whatever memory follows, producing deterministic but wrong results.

  Always use an explicit INTEGER staging variable:

  ```basic09
  DIM iStage: INTEGER
  iStage := rec.bFld      \ ! safe: BYTE->INTEGER assignment promotes correctly
  RUN someProc(iStage)    \ ! INTEGER var to INTEGER PARAM: correct
  ```

  The inverse, passing an `INTEGER` variable to a `BYTE` PARAM, delivers only the high byte. That failure mode is silent. Do not rely on implicit narrowing in either direction.

* **Stage BYTE values into INTEGER working variables before arithmetic, loop bounds, bit tests, and syscall flag handling.** This is a core `Stocks and Bonds` pattern. When a `BYTE` field is about to be used in arithmetic, as a `FOR` bound, or as input to routines such as `LAND` or `LOR`, first copy it into a local `INTEGER` variable.

* **Declare `STRING` variables with an explicit length when the default is insufficient.** Without a length specifier, `STRING` defaults to 32 characters. Use `DIM name:STRING[40]` to declare a longer string.

* **Account for the 32K variable memory limit.** Basic09 has only 32 KB available for variable storage. Size arrays with this constraint in mind.

* **`FOR` incrementer variables must be of type INTEGER.** BYTE incrementer variables will cause a syntax error.

  ```basic09
  DIM i: INTEGER
  FOR i := 1 TO 9
    ! Logic here
  NEXT i
  ```

### Shared Types and Contracts

* **Keep shared TYPE layouts byte-for-byte identical everywhere they are redeclared.** In `Stocks and Bonds`, records such as save headers, player records, market state, syscall register blocks, and AI profiles are redeclared in multiple procedures and modules. When a TYPE defines a cross-procedure or persisted contract, every copy must remain structurally identical: same field order, same field types, same array sizes.

* **Document persisted record contracts when they cross file or process boundaries.** If a TYPE is written to disk, read back later, or passed indirectly through a child-process workflow, its layout is part of the application contract and must be treated as stable unless an intentional format migration is designed.

### File I/O

* **Isolate file I/O in dedicated procedures.** This enables I/O-specific error handling and allows callers to fail gracefully on I/O errors.

* **Prefer explicit success/failure out-parameters for recoverable I/O and load paths.** In this codebase, procedures such as loaders and lightweight state readers often return a boolean status output rather than trying to escalate via `ERROR(ERR)`. Use that pattern when the caller can recover or choose an alternate path.

### Application Patterns

* **Use a documented save/resume checkpoint contract when a phase can be resumed.** For multi-phase applications such as `Stocks and Bonds`, persist enough state to resume at a known checkpoint. Document the meaning of any saved phase code, player index, stage code, or similar control fields, and ensure readers and writers follow the same contract.

* **Document coordinator/child-process handoff rules explicitly.** If a parent procedure loads modules, forks child phases, or shares state through a file or other indirect mechanism, document which procedure owns each transition, what state the child expects on entry, and what state it must write before exit.

* **Use persistent keyed-editor loops for interactive screens that edit one asset at a time.** In `Stocks and Bonds`, human buy, sell, forced-liquidation, and similar screens keep a stable main screen, let the user select one row to edit, then return to the main view with simulated preview state. Reuse that pattern for consistency rather than inventing a new interaction model per screen.

* **Use standard action-code contracts for screen navigation.** When a screen can continue, save, quit, confirm, or pass, define and document the action codes at the procedure boundary and keep those meanings stable across similar screens.

### Logging

* **Use diagnostics deliberately, not as default progress chatter.** In screen-driven applications, prefer user-facing screens for normal flow and keep debug logging narrow, optional, and purpose-specific.

  ```basic09
  IF logVerbose THEN
    PRINT "> Loading Variable Definitions"
  ENDIF
  ```

---

## General Tips

* **ON ERROR GOTO and ON...GOTO/GOSUB are procedure-scoped.** A shared handler label across multiple procedures is syntactically invalid.

  ```basic09
  PROCEDURE ProcA
    ON ERROR GOTO 900
    ! ...
    END
  900 \ ! ProcA error handler
    END

  PROCEDURE ProcB
    ON ERROR GOTO 900
    ! ...
    END
  900 \ ! ProcB error handler - separate from ProcA's
    END
  ```

* **`STRING` variables with a `$` suffix are automatically typed.** Variables like `title$` are implicitly `STRING[32]`. In this codebase, prefer explicit `DIM ... : STRING[n]` declarations when the variable is part of maintained application code.
