# Certificate-State Save Prototype

Status: Draft prototype  
Authority: Prototype only. Not yet adopted by the main app.

## Goal

Define a separate game-state file format that can represent certificate-level
margin holdings without modifying the production save path yet.

## Scope

This prototype is for:

1. round-trip serialization tests,
2. structural validation of certificate-aware state,
3. rule-model validation for future margin refactoring.

It is not yet a replacement for `SNBSTATE` or `SNBGAME`.

## Proposed file order

The prototype file is written sequentially in this order:

1. `ProtoHdr`
2. trimmed `deckOrd` section: `maxYears + 1` bytes
3. `ProtoPlyr(6)`
4. `MktState`
5. `CertRec(1..certCount)`

## Header

```
TYPE ProtoHdr
    magic      : BYTE
    fmtVersion : BYTE
    maxYears   : BYTE
    plyrCount  : BYTE
    rollMode   : BYTE
    mgnRule    : BYTE
    currYear   : BYTE
    savedPhase : BYTE
    savedPlyr  : BYTE
    gameStage  : BYTE
    bnkrFlgs   : BYTE
    certCount  : BYTE
    checksum   : BYTE
```
```

Notes:

- `magic` distinguishes this file from the production save format.
- `certCount` records how many certificate records follow the market block.
- `checksum` is a simple low-byte sum of the preceding 12 header bytes.

## Player record

```
TYPE ProtoPlyr
    plyrName    : STRING[20]
    plyrType    : BYTE
    cashBal     : INTEGER
    marginTot   : INTEGER
    obligation  : INTEGER
    isBankrupt  : BOOLEAN
    hadCashPur  : BOOLEAN
    aiTier      : BYTE
    stckShrs(9) : INTEGER
    bondUnts(3) : INTEGER
```
```

Notes:

- `marginTot` is retained as a cached aggregate.
- The authoritative source for margin holdings is the certificate section.

## Certificate record

```
TYPE CertRec
    ownerId    : BYTE
    stockId    : BYTE
    purchTyp   : BYTE   ! 1=CASH 2=MARGIN
    sharesQty  : INTEGER
    purchPrc   : INTEGER
    marginBal  : INTEGER
```
```

Interpretation:

- One record represents one stock certificate or remaining fragment of a
  previously split certificate after partial sales.
- `marginBal` is fixed from purchase time and only reduced by repayment or sale
  from that same certificate.
- Cash certificates must carry `marginBal = 0`.

## Validation rules

The prototype validator should reject state when any of the following occurs:

1. invalid header magic or format version,
2. `certCount` exceeds the prototype slot limit,
3. a certificate owner is outside `1..plyrCount`,
4. a certificate stock index is outside `1..9`,
5. a certificate share count is non-positive or not a multiple of 10,
6. a cash certificate has non-zero `marginBal`,
7. a margin certificate has non-positive `marginBal`,
8. player `stckShrs(stock)` does not equal the sum of that player's
   certificates for the stock,
9. player `marginTot` does not equal the sum of that player's margin
   certificate balances.

## Prototype decision

Use a counted certificate section, not a full fixed-size certificate array on
disk. The in-memory harness can still reserve a fixed slot count for simplicity.
