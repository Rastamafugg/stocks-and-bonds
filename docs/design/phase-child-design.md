# SNB Phase-Child Architecture Design

Status: Current  
Authority: Runtime architecture  
Depends on: `specification.md`, `save-load-design.md`  
Supersedes: `archive/forkio-plan.md` and older child-process notes that refer to
retired modules such as `snbBuySell`, `divChild`, `tradeChild`, or `egChild`

This document describes the current file-based phase-child architecture used by
the coordinator in `src/basic/snb.b09`.

---

## 1. Coordinator Model

The top-level coordinator is `snb` in `src/basic/snb.b09`.

It runs this process sequence:

1. Load `snbUtil` into the current process.
2. Ensure `snbTradeUtil` before trade or revenue paths that need it.
3. Fork `snbSetup` for setup.
4. For each game year, fork these child entries in order:
   - `snbDividend`
   - `snbMarket`
   - `snbSell` or `snbSellAI`
   - `snbBuy` or `snbBuyAI`
4. If the configured final year has just completed, fork one extra
   `snbMarket` pass for the closing-price draw.
5. Fork `snbEndGame`.

All inter-process state handoff is done through `SNBSTATE`.

The coordinator also uses a separate controller-session handshake through
`SNBMODCS` when loading or releasing transient phase libraries via
`requestPhaseLib`, `releasePhaseLib`, `startCtlSession`, and
`stopCtlSession`.

---

## 1a. Controller State Record (`SNBMODCS`)

`SNBMODCS` is a single shared request-response record between the parent-side
bootstrap helper in `src/basic/snbModCtlBoot.b09` and the persistent child
controller in `src/basic/snbModMemCtl.b09`.

Current authority model:

- `reqSeq` plus `reqCmd` identify the active request.
- `rspSeq` plus `errCode` are the authoritative completion result observed by
  the parent.
- `statusCode` is a child-published phase or diagnostic field. It is useful for
  debugging and tracing, but it is not the authoritative wrapper-level success
  signal.
- `seenSig` and `seenCount` are intercept diagnostics written by the child.
  They are not the authoritative request identity.

### `CtlState` field purposes

| Field | Purpose |
|-------|---------|
| `magic` | Record signature for `SNBMODCS`. Current code expects `$53` before trusting the record contents. |
| `parentPid` | Process ID of the parent coordinator-side process. The child uses it to wake the parent after startup and after publishing a response. |
| `childPid` | Process ID of the persistent controller child. The parent uses it as the signal target for controller requests. |
| `reqSeq` | Parent-owned request generation number. A changed value means a new request is pending. |
| `rspSeq` | Child-owned response generation number. When it matches `reqSeq`, the parent treats that request as answered. |
| `reqCmd` | Parent-owned request command code. Current production flow uses values such as `200` for phase-library load, `213` for child-side unload, and `214` for controller stop. |
| `parentSleep` | Parent-side wait flag. The parent sets it before signaling a request and clears it after the matching response is accepted. The child uses it to decide whether to send a wake signal back to the parent. |
| `childSleep` | Child-side sleep-ready flag. The child sets it before entering its sleep wait and clears it after wake or response publication. The parent polls it as the child-ready handoff indicator. |
| `statusCode` | Child-published phase or outcome code. Common observed values include `10` for startup-ready, `11` for awake-idle, `40` for successful stop completion, and failure/diagnostic values such as `252` or `253`. This field may return to idle-state values after a successful response. |
| `errCode` | Child-published request error result. The parent currently treats `errCode = 0` with matching `rspSeq` as the authoritative success contract for a request. |
| `seenSig` | Last intercepted signal value observed by the child through `SLPICPT`. This is diagnostic signal-capture information. |
| `seenCount` | Count of intercepted signals observed by the child in the current wake window. This is diagnostic signal-capture information. |

### Field groups

- Record validity and process identity:
  `magic`, `parentPid`, `childPid`
- Parent-owned request publication:
  `reqSeq`, `reqCmd`, `parentSleep`
- Child-owned readiness and response publication:
  `childSleep`, `rspSeq`, `statusCode`, `errCode`
- Child-owned signal diagnostics:
  `seenSig`, `seenCount`

---

## 2. gameStage Constants

| Value | Constant | Written By | Coordinator Action |
|-------|----------|-----------|-------------------|
| 1 | `GS_PREGM` | `snbSetup` | Setup complete; enter year loop |
| 2 | `GS_YEAR` | `snbDividend`, `snbMarket`, `snbSell` | Continue current year sequence |
| 3 | `GS_DONE` | `snbBuy` | Leave year loop; run closing flow |

`GS_DONE` is currently written only by `snbBuy`, not by a combined trade child.

---

## 3. currYear Convention

`snbSetup` writes `currYear = 0` as pre-game state.

`snbDividend` increments `currYear` immediately after loading `SNBSTATE`.
After that increment:

- `snbMarket` reads the active year
- `snbSell` and `snbSellAI` read the active year
- `snbBuy` and `snbBuyAI` read the active year

| State | `currYear` value |
|-------|------------------|
| After `snbSetup` | 0 |
| During Year 1 after `snbDividend` | 1 |
| During Year 10 after `snbDividend` | 10 |

The closing-price draw does not increment `currYear`. It reuses the final-year
value and distinguishes itself by running after `GS_DONE`.

---

## 4. Child Process Entry Procedures

### 4.1 `snbSetup`
- File: `src/basic/snbSetup.b09`
- Entry procedure: `snbSetup`
- Writes: `currYear = 0`, `gameStage = GS_PREGM`
- Responsibility:
  - Runs `setup`
  - Handles S1, S2, S7
  - Initializes header, deck, players, and market state
  - Saves `SNBSTATE` on normal setup completion
  - Writes nothing if the user quits from setup

### 4.2 `snbDividend`
- File: `src/basic/snbDividend.b09`
- Entry procedure: `snbDividend`
- Writes: incremented `currYear`, `gameStage = GS_YEAR`
- Responsibility:
  - Advances the year counter
  - Displays S8
  - Applies dividends and bond interest for Years 2 through `maxYears`
  - Displays S9 per non-bankrupt player

### 4.3 `snbMarket`
- File: `src/basic/snbMarket.b09`
- Entry procedure: `snbMarket`
- Writes: `gameStage = GS_YEAR`
- Responsibility:
  - Draws and decodes the situation card
  - Generates market rolls
  - Resolves stock prices, splits, and dividend-status transitions
  - Displays S11 through S15
  - Applies the Card 1 dividend bonus when allowed by the rules
  - Runs once per normal year, plus one extra closing-price draw after the
    final year ends

### 4.4 `snbSell` and `snbSellAI`
- Files: `src/basic/snbSell.b09`, `src/basic/snbSellAI.b09`
- Entry procedures: `snbSell`, `snbSellAI`
- Writes: `gameStage = GS_YEAR`
- Responsibility:
  - Runs the sell phase for one current saved-turn player
  - Skips the sell editor in Year 1
  - `snbSell` handles human turns by forking `snbSellExec`
  - `snbSellAI` handles AI turns with `aiSell` plus `scrAISellTurn`
  - Applies sell orders to `SNBSTATE`
  - Advances `savedPlyr` within sell phase or transitions to buy phase

### 4.4a `snbSellExec`
- File: `src/basic/snbSellExec.b09`
- Entry procedure: `snbSellExec`
- Writes: updated player sell results in `SNBSTATE`
- Responsibility:
  - Orchestrates one human sell turn for the active saved-turn player
  - Uses `SNBDRFTH` and `SNBDRFTD` as per-turn draft files
  - Initializes the draft files for the turn
  - Forks `snbSellUI` for the interactive editor
  - Forks `snbSellDraftApply` only when the user confirms the draft
  - Writes the turn action back to `SNBDRFTH` for `snbSell`

### 4.4b `snbSellUI`
- File: `src/basic/snbSellUI.b09`
- Entry procedure: `snbSellUI`
- Writes: draft action/result in `SNBDRFTH`
- Responsibility:
  - Runs the human sell-turn interactive screen loop
  - Reads the active player from `SNBSTATE`
  - Reads the current draft summary from `SNBDRFTH`
  - Forks `snbSellLot` for per-asset quantity edits
  - Reports pass, confirm, save, or quit back to `snbSellExec`

### 4.5 `snbBuy` and `snbBuyAI`
- Files: `src/basic/snbBuy.b09`, `src/basic/snbBuyAI.b09`
- Entry procedures: `snbBuy`, `snbBuyAI`
- Writes: `gameStage = GS_YEAR` or `GS_DONE`
- Responsibility:
  - Runs the buy phase for one current saved-turn player
  - `snbBuy` handles human turns with `scrBuy`
  - `snbBuyAI` handles AI turns with `aiBuy` plus `scrAIBuyTurn`
  - Applies margin repayment and buy orders to `SNBSTATE`
  - Determines whether the main year loop is complete when buy phase ends
  - Writes `GS_DONE` when:
    - `currYear >= maxYears`, or
    - multiplayer game has one or zero non-bankrupt players left

### 4.6 `snbEndGame`
- File: `src/basic/snbEndGame.b09`
- Entry procedure: `snbEndGame`
- Writes: none
- Responsibility:
  - Loads the final saved state
  - Displays S24 through S27
  - Computes final wealth and winner display

---

## 5. Current Year/Phase Sequence

Normal year flow:

```text
snbSetup
  -> snbDividend
  -> snbMarket
  -> snbSell or snbSellAI
  -> snbBuy or snbBuyAI
```

Final-year completion flow:

```text
snbSetup
  -> yearly loop through snbBuy writing GS_DONE
  -> closing snbMarket pass
  -> snbEndGame
```

Coordinator pseudoflow:

```text
fork snbSetup
read SNBSTATE

LOOP
  EXITIF iCYr >= iMaxYr OR gameOver

  fork snbDividend -> readHdr
  fork snbMarket   -> readHdr
  fork snbSell*    -> readHdr
  fork snbBuy*     -> readHdr

  apply safety nets
ENDLOOP

IF final year completed THEN
  fork snbMarket   \ closing-price draw
ENDIF

fork snbEndGame
```

Notes:

- The extra closing `snbMarket` pass happens only after completion of the
  configured final year.
- `GS_DONE` alone does not imply that `snbEndGame` is immediate; the
  coordinator may insert the closing-price market pass first.

---

## 6. Current Module and Library Layout

This section reflects the current packed-module snapshot recorded in
`logs/modulelog`. The CSV is produced by `src/basic/moduleLogger.b09` and logs
the current workflow-disk packed modules, their constituent procedure names,
and each constituent module header size in bytes.

### 6.1 Packed module roster

| Packed Module | Source File | Entry Procedure | Entry Size | Procedures | Total Bytes |
|---------------|-------------|-----------------|------------|------------|-------------|
| `snb` | `src/basic/snb.b09` | `snb` | 4731 | 14 | 10576 |
| `snbSetup` | `src/basic/snbSetup.b09` | `snbSetup` | 371 | 14 | 5912 |
| `snbDividend` | `src/basic/snbDividend.b09` | `snbDividend` | 2387 | 20 | 9137 |
| `snbMgnInt` | `src/basic/snbMgnInt.b09` | `snbMgnInt` | 1649 | 18 | 11505 |
| `snbMarket` | `src/basic/snbMarket.b09` | `snbMarket` | 3009 | 21 | 12756 |
| `snbSellHumanStub` | `src/basic/snbSellHumanStub.b09` | `snbSellHumanStub` | 1014 | 8 | 2111 |
| `snbSellAI` | `src/basic/snbSellAI.b09` | `snbSellAI` | 1716 | 22 | 10594 |
| `snbBuy` | `src/basic/snbBuy.b09` | `snbBuy` | 391 | 17 | 11471 |
| `snbBuyAI` | `src/basic/snbBuyAI.b09` | `snbBuyAI` | 1847 | 17 | 8348 |
| `snbMarginPay` | `src/basic/snbMarginPay.b09` | `snbMarginPay` | 741 | 15 | 5565 |
| `snbYear10Clear` | `src/basic/snbYear10Clear.b09` | `snbYear10Clear` | 5626 | 19 | 12567 |
| `snbEndGame` | `src/basic/snbEndGame.b09` | `snbEndGame` | 745 | 16 | 6788 |

### 6.2 Constituent procedures and measured sizes

#### `snb`

- `snb`: 4731 bytes
- `readTurnPlyrType`: 966 bytes
- `chkStale`: 219 bytes
- `readHdr`: 218 bytes
- `stateExists`: 153 bytes
- `loadModuleList`: 354 bytes
- `unloadModuleList`: 281 bytes
- `loadOneModule`: 456 bytes
- `unloadOneModule`: 361 bytes
- `loadHdrMkt`: 810 bytes
- `loadPlyrRec`: 475 bytes
- `savePlyrRec`: 475 bytes
- `saveHdrOnly`: 746 bytes
- `copySaveFile`: 331 bytes

#### `snbSetup`

- `snbSetup`: 371 bytes
- `initPlayer`: 307 bytes
- `initMkt`: 136 bytes
- `scrStart`: 207 bytes
- `scrSetup`: 768 bytes
- `scrConfirm`: 523 bytes
- `setup`: 1181 bytes
- `saveGame`: 775 bytes
- `loadGame`: 820 bytes
- `fmtPlyrName`: 171 bytes
- `waitKey`: 140 bytes
- `clrScr`: 97 bytes
- `shuffleDeck`: 209 bytes
- `getMenuKey`: 207 bytes

#### `snbDividend`

- `snbDividend`: 2387 bytes
- `applyDivInt`: 639 bytes
- `scrYearHdr`: 360 bytes
- `scrDivInt`: 880 bytes
- `loadHdrMkt`: 810 bytes
- `loadPlyrRec`: 475 bytes
- `savePlyrRec`: 475 bytes
- `saveHdrOnly`: 746 bytes
- `copySaveFile`: 331 bytes
- `getPhaseNav`: 236 bytes
- `fmtPlyrName`: 171 bytes
- `getNumIn`: 152 bytes
- `waitKey`: 140 bytes
- `clrScr`: 97 bytes
- `fmtMoney`: 81 bytes
- `padNumber`: 240 bytes
- `initStockNames`: 251 bytes
- `getStockName`: 378 bytes
- `getStockDivRate`: 202 bytes
- `initBondPar`: 86 bytes

#### `snbMgnInt`

- `snbMgnInt`: 1649 bytes
- `applyLiqPlan`: 598 bytes
- `applyLiqOrdr`: 541 bytes
- `scrMgnInt`: 647 bytes
- `getPhaseNav`: 236 bytes
- `getNumIn`: 152 bytes
- `waitKey`: 140 bytes
- `clrScr`: 97 bytes
- `fmtMoney`: 81 bytes
- `padNumber`: 240 bytes
- `initBondPar`: 86 bytes
- `calcMgnTot`: 163 bytes
- `calcSaleMgnRpy`: 111 bytes
- `findNextActivePlyr`: 208 bytes
- `getLotQty`: 1958 bytes
- `scrBankrupt`: 619 bytes
- `scrForceLiq`: 3304 bytes
- `aiLiqOrdr`: 675 bytes

#### `snbMarket`

- `snbMarket`: 3009 bytes
- `loadMktState`: 881 bytes
- `saveHdrMktState`: 637 bytes
- `quitMktToMenu`: 186 bytes
- `saveMktToMenu`: 304 bytes
- `doRolls`: 753 bytes
- `getMktStockName`: 278 bytes
- `getMktDelta`: 938 bytes
- `getCard`: 1667 bytes
- `resolvePrice`: 212 bytes
- `applyMktYear`: 747 bytes
- `drawCard`: 123 bytes
- `scrCard`: 549 bytes
- `scrDice`: 593 bytes
- `scrMktBoard`: 639 bytes
- `scrSplit`: 429 bytes
- `scrDivFlag`: 356 bytes
- `getPhaseNav`: 236 bytes
- `waitKey`: 140 bytes
- `clrScr`: 37 bytes
- `shuffleDeck`: 42 bytes

#### `snbSellHumanStub`

- `snbSellHumanStub`: 1014 bytes
- `fmtPlyrName`: 171 bytes
- `getMenuKey`: 207 bytes
- `waitKey`: 140 bytes
- `clrScr`: 97 bytes
- `calcMgnTot`: 163 bytes
- `calcSaleMgnRpy`: 111 bytes
- `findNextActivePlyr`: 208 bytes

#### `snbSellAI`

- `snbSellAI`: 1716 bytes
- `aiSell`: 2549 bytes
- `scrAISellTurn`: 592 bytes
- `fmtPlyrName`: 171 bytes
- `waitKey`: 140 bytes
- `clrScr`: 97 bytes
- `fmtMoney`: 81 bytes
- `padNumber`: 240 bytes
- `getPhaseNav`: 236 bytes
- `initStockNames`: 251 bytes
- `getStockName`: 378 bytes
- `getStockDivRate`: 202 bytes
- `initBondPar`: 86 bytes
- `calcMgnTot`: 163 bytes
- `calcSaleMgnRpy`: 111 bytes
- `findNextActivePlyr`: 208 bytes
- `applyCashMgnRepay`: 405 bytes
- `applyStockMgnRepay`: 255 bytes
- `initAIProf`: 823 bytes
- `aiLiqOrdr`: 675 bytes
- `applySells`: 596 bytes
- `scrBankrupt`: 619 bytes

#### `snbBuy`

- `snbBuy`: 391 bytes
- `runBuyPlyr`: 989 bytes
- `scrBuy`: 5946 bytes
- `getSaveQuitAct`: 127 bytes
- `quitToMenu`: 279 bytes
- `saveQuitToMenu`: 332 bytes
- `fmtPlyrName`: 171 bytes
- `getNumIn`: 152 bytes
- `waitKey`: 140 bytes
- `clrScr`: 97 bytes
- `fmtMoney`: 81 bytes
- `padNumber`: 240 bytes
- `initBondPar`: 86 bytes
- `calcMgnTot`: 163 bytes
- `calcSaleMgnRpy`: 111 bytes
- `findNextActivePlyr`: 208 bytes
- `getLotQty`: 1958 bytes

#### `snbBuyAI`

- `snbBuyAI`: 1847 bytes
- `aiBuy`: 2599 bytes
- `scrAIBuyTurn`: 715 bytes
- `fmtPlyrName`: 171 bytes
- `waitKey`: 140 bytes
- `clrScr`: 97 bytes
- `fmtMoney`: 81 bytes
- `padNumber`: 240 bytes
- `getPhaseNav`: 236 bytes
- `initStockNames`: 251 bytes
- `getStockName`: 378 bytes
- `getStockDivRate`: 202 bytes
- `initBondPar`: 86 bytes
- `calcMgnTot`: 163 bytes
- `calcSaleMgnRpy`: 111 bytes
- `findNextActivePlyr`: 208 bytes
- `initAIProf`: 823 bytes

#### `snbMarginPay`

- `snbMarginPay`: 741 bytes
- `scrMgnRepay`: 2141 bytes
- `getNumIn`: 152 bytes
- `waitKey`: 140 bytes
- `clrScr`: 97 bytes
- `fmtMoney`: 81 bytes
- `padNumber`: 240 bytes
- `initStockNames`: 251 bytes
- `getStockName`: 378 bytes
- `getStockDivRate`: 202 bytes
- `calcMgnTot`: 163 bytes
- `calcSaleMgnRpy`: 111 bytes
- `findNextActivePlyr`: 208 bytes
- `applyCashMgnRepay`: 405 bytes
- `applyStockMgnRepay`: 255 bytes

#### `snbYear10Clear`

- `snbYear10Clear`: 5626 bytes
- `saveGame`: 775 bytes
- `loadGame`: 820 bytes
- `getNumIn`: 152 bytes
- `waitKey`: 140 bytes
- `clrScr`: 97 bytes
- `fmtMoney`: 81 bytes
- `padNumber`: 240 bytes
- `initStockNames`: 251 bytes
- `getStockName`: 378 bytes
- `getStockDivRate`: 202 bytes
- `initBondPar`: 86 bytes
- `calcMgnTot`: 163 bytes
- `calcSaleMgnRpy`: 111 bytes
- `findNextActivePlyr`: 208 bytes
- `applyCashMgnRepay`: 405 bytes
- `applyStockMgnRepay`: 255 bytes
- `getLotQty`: 1958 bytes
- `scrBankrupt`: 619 bytes

#### `snbEndGame`

- `snbEndGame`: 745 bytes
- `scrFinalMkt`: 692 bytes
- `scrWealth`: 1241 bytes
- `scrWinner`: 652 bytes
- `scrPostGame`: 189 bytes
- `saveGame`: 775 bytes
- `loadGame`: 820 bytes
- `getSaveQuitAct`: 127 bytes
- `quitToMenu`: 279 bytes
- `saveQuitToMenu`: 332 bytes
- `fmtPlyrName`: 171 bytes
- `waitKey`: 140 bytes
- `clrScr`: 97 bytes
- `fmtMoney`: 81 bytes
- `padNumber`: 240 bytes
- `getMenuKey`: 207 bytes

### 6.3 Notes on source files versus packed modules

- The `modulelog` snapshot records only the modules currently packed onto the
  workflow disk. It does not claim that every `src/basic/*.b09` file is a
  separate packed module.
- In particular, `snbSell.b09`, `snbSellExec.b09`, `snbSellUI.b09`,
  `snbSellDraftInit.b09`, `snbSellDraftUIState.b09`, `snbSellDrfHdr.b09`,
  `snbSellDraftEdit.b09`, `snbSellDraftApply.b09`, and `snbSellLot.b09`
  exist in source, but they are not listed as separate packed modules in the
  current `logs/modulelog` snapshot.
- Shared procedures such as `fmtPlyrName`, `waitKey`, `getNumIn`,
  `findNextActivePlyr`, `getLotQty`, `saveGame`, and `loadGame` are currently
  duplicated across packed modules rather than centralized in one measured
  utility module.

---

## 7. Retired Names and Structures

The following names are obsolete in the current implementation and should not
be used as if they were current runtime components:

- `divChild`
- `mktChild`
- `tradeChild`
- `egChild`
- `snbBuySell.b09`
- `snbSaveLoad.b09`
- `snbAI.b09`
- `snbMktEng`
- `snbMktScr`
- `snbYearLoop`

Their responsibilities have been redistributed into the current module set
listed above.

---

## 8. Current Execution Targets

The current implementation uses two execution patterns:

- The top-level coordinator in `src/basic/snb.b09` loads and runs these packed
  module entry procedures in-process: `snbSetup`, `snbDividend`, `snbMgnInt`,
  `snbMarket`, `snbSellHumanStub`, `snbSellAI`, `snbBuy`, `snbBuyAI`,
  `snbMarginPay`, `snbYear10Clear`, and `snbEndGame`.
- The human-sell path still uses nested process forks inside the sell-flow
  source modules: `snbSell` forks `snbSellExec`; `snbSellExec` forks
  `snbSellUI` and `snbSellDraftApply`; `snbSellUI` forks `snbSellLot`.

Any design note that says the coordinator directly calls `forkPhase(...)` for
the full year-phase list is historical.

