---
name: migrate-from-dart-helper-utils
description: Use when a Dart/Flutter project uses dart_helper_utils (DHU) conversion APIs and should move to the convert_object package - ConvertObject.toX/tryToX calls, ConvertObject.toString1, ParsingException, bare top-level toNum/toInt/toDateTime helpers, firstValueForKeys, makeEncodable/safelyEncodedJson, DHU <= 5.x map/iterable getX/tryGetX conversions - or when upgrading dart_helper_utils to v6+, which delegates all conversion to convert_object.
---

# Migrate from dart_helper_utils conversions to convert_object

In dart_helper_utils (DHU) 6.0.0 all conversion logic moved into
convert_object, which DHU 6 now depends on and re-exports. This skill migrates
the CONVERSION surface only; DHU's other utilities (dates helpers, streams,
collections, strings) are out of scope here - for those follow DHU's own
migration guide
(https://github.com/omar-hanafy/dart_helper_utils/blob/main/migration_guides.md).

## Supported paths

- Source: any project using DHU <= 5.x conversion APIs.
- Target A (least churn): upgrade to `dart_helper_utils: ^6.0.2` and keep the
  single DHU import - conversions arrive re-exported from convert_object, but
  the renames below still apply.
- Target B (conversions only, lighter deps): add `convert_object: ^1.1.0`,
  drop DHU if nothing else is used from it.

## Preconditions

1. Clean git working tree (the migration is a broad text/API change; rollback
   is `git restore`/branch discard - get user confirmation for any reset).
2. Test suite green BEFORE migrating: run it and record the result.
3. Determine DHU version in use: `grep -A2 'dart_helper_utils' pubspec.lock`.
   If already >= 6.0.0, only the rename table below applies (DHU 6 already
   re-exports convert_object; skip dependency changes).

## Detect usage (scope the work)

```bash
grep -rln "package:dart_helper_utils" lib/ test/
grep -rn "ConvertObject\.\|ParsingException\|toString1\|firstValueForKeys\|makeEncodable\|safelyEncodedJson" lib/ test/
# bare top-level conversion helpers (DHU <= 5.x):
grep -rnE "\b(toNum|toInt|toDouble|toBool|toDateTime|toUri|toList|toSet|toMap|toBigInt|tryTo[A-Z][a-zA-Z]*)\(" lib/ test/
```

For a large codebase, delegate the sweep to a read-only explore/search
subagent and have it return the file list plus per-symbol counts.

## Critical hazard: do not import both conversion surfaces

DHU <= 5.x and convert_object define map/iterable extensions with the SAME
names (`getInt`, `tryGetString`, ...). If both packages are imported in one
file the extension calls become ambiguous and fail to compile. Migrate
file-by-file so each file imports exactly one provider, or complete Target A
(DHU 6) so only DHU's re-export exists.

## Ordered steps

1. Update pubspec per chosen target; `dart pub get`.
2. Apply the mechanical renames - full table with signatures in
   [references/dhu-api-mapping.md](references/dhu-api-mapping.md). Headlines:
   - `ConvertObject.` -> `Convert.` (same method names, same mapKey/listIndex
     args)
   - `ConvertObject.toString1(x)` -> `Convert.string(x)`
   - `on ParsingException` -> `on ConversionException`
   - bare top-level `toInt(x)` -> `convertToInt(x)` (all `toX`/`tryToX`
     top-level helpers gain the `convert`/`tryConvert` prefix)
   - `map.firstValueForKeys(k, alternativeKeys: ...)` -> `map.tryGetRaw(k, alternativeKeys: ...)`
   - `makeEncodable(v)` -> `v.toJsonSafe()` / maps: `v.toJsonMap()`
   - `safelyEncodedJson(v)` -> `v.toJsonString(...)` (pretty:
     `indent: '  '`)
   - Map/iterable `getX`/`tryGetX` extension calls keep their names.
3. Swap imports per file:
   `import 'package:convert_object/convert_object.dart';` (Target B) or keep
   `package:dart_helper_utils/dart_helper_utils.dart` (Target A).
4. `dart analyze` - fix remaining references; ambiguous-extension errors mean
   a file still imports both providers.
5. Run the full test suite; compare against the pre-migration baseline.

## Behavior differences to audit (not just renames)

- Collection conversions now AUTO-DECODE JSON strings ("[1,2]" becomes a
  list). If old code pre-decoded then converted, the double handling is now
  redundant but harmless; if old code RELIED on a JSON string failing, add an
  explicit type check.
- Boolean parsing is one merged, explicit policy (see BoolOptions defaults);
  DHU edge cases may differ - grep `toBool|asBool` call sites with unusual
  tokens.
- `Iterable.intersect` still MERGES (union) - historical DHU behavior kept
  for compatibility. Do not "fix" call sites to expect intersection.
- Since convert_object 1.1.0, `alternativeKeys` selects the first NON-NULL
  value (a present-but-null key no longer short-circuits).
- `ConversionException.toString()` is concise; verbose context moved to
  `fullReport()`. Update log/telemetry code that parsed the old
  ParsingException text.

## Cases requiring human judgment

- Custom error handling that inspected `ParsingException` internals.
- Dynamic dispatch (`(obj as dynamic).toInt()`) - greps will not find these;
  rely on the test suite.
- Code depending on DHU-only utilities in the same files: keep DHU (Target A)
  rather than forcing removal.

## Validation and rollback

- Success = `dart analyze` clean + test suite at or above baseline +
  no remaining `grep -rn "ParsingException\|toString1\|firstValueForKeys" lib/ test/` hits.
- Rollback = discard the migration branch (never `git reset` user work
  without explicit confirmation).

## Before/after example

```dart
// Before (DHU <= 5.x)
import 'package:dart_helper_utils/dart_helper_utils.dart';
final id = ConvertObject.toInt(json, mapKey: 'id');
final name = ConvertObject.toString1(json['name']);
final when = toDateTime(json['when']);
try { ... } on ParsingException catch (e) { log(e.toString()); }

// After (convert_object)
import 'package:convert_object/convert_object.dart';
final id = Convert.toInt(json, mapKey: 'id');
final name = Convert.string(json['name']);
final when = convertToDateTime(json['when']);
try { ... } on ConversionException catch (e) { log(e.fullReport()); }
```
