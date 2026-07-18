---
name: add-conversion-api
description: Use when adding a new conversion target type or changing any conversion method signature in THIS convert_object repository - new toX/tryToX pair, new optional parameter, changed defaults - anything that must stay consistent across the Convert facade, top-level functions, Converter fluent API, Map extensions, and Iterable extensions.
---

# Add or change a conversion API (maintainers)

One conversion capability = five synchronized public surfaces + engine +
tests + docs. PR #22 exists because these drifted. Work through every file
below; skipping one is the failure mode this skill prevents.

## Touch list (in this order)

1. Engine: `lib/src/core/convert_object_impl.dart`
   - `toX` (strict, `_fail` on error, honors `defaultValue`) and `tryToX`
     pair, both with `mapKey`, `listIndex`, `defaultValue`, `converter`,
     `debugInfo`; formatted types add `format`, `locale`.
   - Wire into `toType<T>`/`tryToType<T>` routing if the type is primitive-like.
2. Facade: `lib/src/core/convert_object.dart` - static `toX`/`tryToX`
   delegating verbatim (keep parameter order consistent with siblings).
3. Top-level: `lib/src/top_level_functions.dart` - `convertToX`/`tryConvertToX`.
4. Fluent: `lib/src/core/converter.dart` - `toX()`, `tryToX()`, AND `toXOr()`;
   thread `_defaultValue` (`defaultValue ?? _defaultValue as X?`).
5. Map extensions: `lib/src/extensions/map_extensions.dart` - `getX` on
   `Map<K, V>` and `tryGetX` on `Map<K, V>?`, both with `alternativeKeys`,
   `innerKey`, `innerListIndex`, `debugInfo` `{'key': key, 'altKeys': ...}`.
6. Iterable extensions: `lib/src/extensions/iterable_extensions.dart` -
   `getX(index, ...)` and `tryGetX(index, alternativeIndices: ...)`.
7. Exports: `lib/convert_object.dart` if a new symbol/library appeared.

## Parity checklist (verify explicitly, do not assume)

- Optional parameter SET identical across all five surfaces for the type
  (formatted types carry `format`/`locale` everywhere, incl. map/iterable
  getters - this was the PR #22 bug).
- `@optionalTypeArgs` on generic methods (matches existing style).
- Strict methods: `defaultValue` rescues BOTH conversion failures and null
  results; try methods never throw.
- `toBool`-style exceptions to conventions must be documented in the Dartdoc
  and in README "Strict vs try vs default".

## Tests (mirror existing layout)

- `test/conversions/<x>_conversion_test.dart` - engine behavior + edge cases.
- Add coverage in `test/core/convert_facade_test.dart`,
  `test/core/top_level_functions_test.dart`,
  `test/core/converter_fluent_api_test.dart` (+ `_shortcuts` for `toXOr`),
  `test/extensions/map_extensions_test.dart`,
  `test/extensions/iterable_extensions_test.dart`.
- Follow `test/README.md` (config snapshot/restore, `initTestIntl`, UTC
  assertions).

## Docs + release metadata (same PR)

- Dartdoc per `docs_guide.md` on every new public member (analyzer error
  otherwise).
- README: relevant section + the "Appendix - Full API cheat-sheet".
- AI plugin: update
  `tooling/ai/convert-object/skills/parse-with-convert-object/references/api-quick-reference.md`
  (and parsing-rules.md if behavior rules changed).
- `CHANGELOG.md` entry; version bump per release process in AGENTS.md.

## Verify

```bash
dart format . && dart analyze . && dart test && dart run tool/validate_agent_plugin.dart
```

All green plus `dart pub publish --dry-run` with 0 warnings before the PR.
