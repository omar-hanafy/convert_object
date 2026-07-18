---
name: debug-convert-object
description: Use when a convert_object conversion in Dart fails or returns surprising values - ConversionException thrown, dates off by timezone or wrong month/decade, Unix epoch seconds vs milliseconds confusion, toBool silently returning false, unexpected null from tryToX/tryGetX, strings coerced into mailto/tel URIs, list/set element conversion errors, alternativeKeys not picking the expected key, or when reading ConversionException context and fullReport output.
---

# Debug convert_object conversions

Work from evidence, not memory: agents reliably misremember this package's
parsing rules (epoch unit selection, bool tokens, auto-decode boundaries).
Every rule you need is in
[references/parsing-rules.md](references/parsing-rules.md) - cite it, don't
guess.

## Step 1: Capture the evidence

For a thrown error:

```dart
try {
  final v = Convert.toInt(raw);
} on ConversionException catch (e) {
  print(e);              // concise: ConversionException(<errorType>): <error> + method/types
  print(e.fullReport()); // full JSON context + original stack trace
}
```

- The API is `fullReport()` - there is no `detailedReport`.
- `e.stackTrace` is the ORIGINAL failure site (error reporters show the real
  frame, not the rethrow).
- Context keys to read: `method`, `object`, `objectType`, `targetType`,
  `mapKey`/`listIndex` (facade navigation), `key`/`altKeys` (map getters),
  `index`/`altIndexes` (iterable getters), `elementIndex` (which collection
  element failed), `format`, `locale`, and any caller `debugInfo`.

For a WRONG VALUE (no throw): reproduce with the raw input in a 3-line test,
then classify against the rules below.

## Step 2: Classify the failure

| Symptom | Likely rule (all exact values in references/parsing-rules.md) |
|---|---|
| Date off by hours | Calendar-like input returns LOCAL time unless `utc: true`; instant-like input (ISO with offset/Z, HTTP date, epoch) keeps its UTC meaning and converts to local when `utc: false` |
| `02/03/2024` flips month/day | Slashed dates resolved by locale: `en_US*` prefers MM/dd, everything else dd/MM. Deterministic fix: explicit `format:` |
| Epoch seconds parsed as 1970 or year 56xxx | NUMERIC input: abs >= 100000000000 -> milliseconds, else seconds. STRING input via auto-detect: 9-10 digits sec, 12-13 digits ms, with a 12-digit calendar guard. There is NO microseconds tier |
| `"202501191430"` becomes a weird epoch | It doesn't: 12-digit strings that validate as `yyyyMMddHHmm` (year 1800-2500) are calendar timestamps, not epoch ms |
| `toBool` gives false "wrongly" | Only listed tokens are truthy; unknown strings -> `false` from `toBool` and `null` from `tryToBool`. Token sets are CONFIGURABLE via BoolOptions (use configure-convert-object skill), not compile-time constants |
| String became `tel:`/`mailto:` | `toUri` coerces phone-like (`^\+?[0-9\-\s\(\)]{3,}$`) and email-like strings first; digit-only IDs can match the phone regex |
| `toList`/`toMap` worked on a String | Collection conversions JSON-decode string input first; primitives do NOT |
| `toType<T>` "Unsupported type" | Built-ins are only bool/int/double/num/BigInt/String/DateTime/Uri; anything else needs TypeRegistry or an exact-type input |
| Wrong `alternativeKeys` pick | Since 1.1.0 the first NON-NULL value wins across key + alternatives; a present-but-null primary key falls through to alternatives |
| Element conversion fails | Exception context has `elementIndex`; inspect that element, or pass `elementConverter` for custom handling |
| `tryTo*` returned null but you expected default | `defaultValue:` must be passed to that same call; fluent `withDefault` only feeds the terminal conversions of that chain |

## Step 3: Choose the fix

Prefer, in order:

1. Explicit arguments at the call site (`format:`, `locale:`, `utc: true`) for
   deterministic parsing of known shapes.
2. App-wide config (BoolOptions/DateOptions/NumberOptions/UriOptions,
   TypeRegistry) when the payload convention is global - see
   configure-convert-object.
3. `tryToX` + explicit handling, or `defaultValue:`, when the data is
   legitimately unreliable.
4. Only then custom `converter:`/`elementConverter:` code.

Do not "fix" by weakening: replacing a strict `getX` with `tryGetX` to silence
an exception hides real payload bugs - justify the change from the payload
contract.

## Step 4: Verify

Write/keep a regression test with the exact raw payload value (not a cleaned
version) and run `dart test` for the touched area, then `dart analyze`.

## Escalation

If behavior contradicts the reference tables, verify against the installed
version: `grep -A2 'convert_object' pubspec.lock`, then read the relevant
source file in the pub cache
(`~/.pub-cache/hosted/pub.dev/convert_object-<version>/lib/src/utils/`).
Version differences that matter: `alternativeKeys` first-non-null and
`tryGetRaw` exist only since 1.1.0 (see upgrade-convert-object skill).
