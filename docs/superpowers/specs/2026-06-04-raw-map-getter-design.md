# Raw map getter (`tryGetRaw`) + first-non-null fallback fix

- Date: 2026-06-04
- Status: Approved (design)
- Package: `convert_object`
- Target version: 1.1.0 (minor)

## Problem

v5 of `dart_helper_utils` exposed a public `Map.firstValueForKeys(key, {alternativeKeys})`
that returned the raw value for a key, falling back across alternative keys. In v6
(the `convert_object` split) that capability became the private `_firstValueForKeys`
helper that powers every typed getter (`getString`, `tryGetMap`, ...) through the
public `alternativeKeys` parameter.

The result is an asymmetry: `convert_object` publicly owns the "first value across
keys" concept (every getter takes `alternativeKeys`), but offers no way to read the
selected value WITHOUT converting it. Real call sites need the raw value when a field
is polymorphic or unknown-typed - for example a dynamic form's `errors` (Map | List |
String), or a schema `value` / `defaultValue` (num | bool | String | Map | List). For
those, typed getters either coerce (`tryGetString` turns `5` into `'5'`) or null out
the non-matching shapes (`tryGetMap` returns null for a List), silently losing data.

## Decision

Add a single raw selector to the map extensions, and align the fallback semantic to
"first non-null value." Keep `convert_object` conversion-focused everywhere else.

This is the v6-correct evolution of v5's `firstValueForKeys`: same intent, a name
consistent with the `tryGet*` family, living where the fallback logic already lives.
It is explicitly NOT a behavior-preserving reintroduction (see Migration).

## API

```dart
extension NullableMapConversionX<K, V> on Map<K, V>? {
  /// Returns the value at [key], or the first of [alternativeKeys] whose value
  /// is non-null, WITHOUT any type conversion. Returns null when nothing matches
  /// or the receiver is null.
  V? tryGetRaw(K key, {List<K>? alternativeKeys});
}
```

Contract:

- No conversion, no decoding, no coercion. `'5'` stays `'5'`; a Map/List value is
  returned as-is.
- Parameters limited to `key` + `alternativeKeys`. No `innerKey` / `innerListIndex` /
  `converter` / `defaultValue`. It is a pure selector, not a mini-converter.
- Placed on the nullable extension only (`Map<K,V>?`), which is also callable on a
  non-null `Map<K,V>`. A `getRaw` twin on the non-nullable extension is intentionally
  omitted: its return type would still be `V?` (a key can be absent), making it
  byte-identical and redundant.
- Delegates to `_firstValueForKeys`, so it always selects the same key the typed
  getters would.

Equivalence: after the fallback fix, `map.tryGetRaw('a', alternativeKeys: ['b','c'])`
is exactly a null-safe `map['a'] ?? map['b'] ?? map['c']`.

## Fallback semantic fix

Rewrite `_firstValueForKeys` in BOTH `MapConversionX` (non-nullable) and
`NullableMapConversionX` (nullable) from "first key that exists (`containsKey`)" to
"first key whose value is non-null":

```dart
var value = this[key];
if (value == null && alternativeKeys != null) {
  for (final altKey in alternativeKeys) {
    final candidate = this[altKey];
    if (candidate != null) {
      value = candidate;
      break;
    }
  }
}
return value;
```

Only the alternative-key selection changes. The nullable copy keeps its existing
`final map = this; if (map == null) return null;` receiver guard, and both copies keep
treating a null primary value as "fall through to the alternatives."

Why:

1. Internal consistency - a null PRIMARY value already falls through to the
   alternatives; alt values should too.
2. Cross-collection consistency - the iterable helper `_firstForIndices` already
   selects the first non-null element. Maps and lists should agree.
3. Intuition - `alternativeKeys: ['b','c']` is expected to mean "first of these with a
   real value," matching the `??` mental model.

Because every typed getter shares this helper, the fix applies to their
`alternativeKeys` behavior as well. That is the point: one coherent fallback semantic
everywhere.

## Migration / behavior change (guardrail)

This is an INTENTIONAL semantic fix, NOT an exact behavior-preserving migration of v5
`firstValueForKeys`.

```dart
// Old edge case (v5 firstValueForKeys / v6 pre-fix typed getters)
{'a': null, 'b': null, 'c': 'x'}
    .firstValueForKeys('a', alternativeKeys: ['b', 'c']); // null

// New behavior
{'a': null, 'b': null, 'c': 'x'}
    .tryGetRaw('a', alternativeKeys: ['b', 'c']); // 'x'
```

The CHANGELOG wording (1.1.0) must state, clearly:

- `tryGetRaw` preserves the raw value with no conversion.
- `alternativeKeys` now selects the first NON-NULL candidate.
- This changes the old "present-but-null alternative key" edge case.
- It affects every typed map getter that uses `alternativeKeys`.
- Callers who must distinguish "absent" from "present-but-null" should use `containsKey`
  directly; neither `tryGetRaw` nor a `??` chain can express that distinction.

Versioning: minor bump to 1.1.0 (additive method + one edge-case behavior change).

## Scope

- In scope: map extensions only (non-nullable + nullable `_firstValueForKeys` fix;
  `tryGetRaw` on the nullable extension).
- Out of scope (for now): an iterable by-index `tryGetRaw` with `alternativeIndices`.
  The iterable helper already uses first-non-null, and by-index raw access is thin on
  demand (`list[i]` is trivial; only the `alternativeIndices` fallback would be new).
  Trivial follow-up if requested.
- Out of scope: a `Convert` static-facade entry, a top-level function, and
  `Converter.fromMap` `alternativeKeys` support. Raw selection is inherently a
  map-receiver operation; folding it into the conversion facade adds surface without
  need.

## Docs

- README: a row + short example in the Map-extensions section, positioning `tryGetRaw`
  as the raw escape hatch for polymorphic fields (`errors`, schema
  `value`/`defaultValue`), and noting "for known types, prefer the typed `tryGetX`."
- `convert_object` CHANGELOG 1.1.0: new method line + the behavior-change wording above.
- `dart_helper_utils` migration guide: add a `firstValueForKeys` -> `tryGetRaw` (raw) /
  `tryGetX` (typed) row, and reference the present-but-null behavior change.

## Tests (`test/extensions/`, AAA)

`tryGetRaw`:

- primary key hit returns the raw value (no coercion: `'5'` stays `'5'`; Map/List
  preserved).
- single alt fallback.
- multi-alt skips a present-but-null key to the next non-null.
- all keys null/absent -> null.
- null receiver -> null.
- parity: result equals the corresponding `??` chain for representative maps.

Fallback fix:

- a typed getter (for example `tryGetString` / `getString`) with
  `{'a': null, 'b': null, 'c': 'x'}` and `alternativeKeys: ['b','c']` now yields `'x'`.
- audit existing `alternativeKeys` tests for any encoding the old "first present key"
  behavior; update them (the update is the evidence of the intended change).

## Non-goals

- Reintroducing the broader v5 conversion API surface.
- Distinguishing absent vs present-but-null in the return (use `containsKey`).
- Changing any conversion behavior of the typed getters beyond which key the fallback
  selects.
