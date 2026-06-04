# tryGetRaw + first-non-null fallback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `Map.tryGetRaw` (raw value lookup, no conversion) and align the shared `alternativeKeys` fallback to "first non-null value" across all map getters.

**Architecture:** The map extensions already centralize key-with-fallback selection in a private `_firstValueForKeys` (one copy on the non-nullable `MapConversionX`, one on the nullable `NullableMapConversionX`). We (1) change those two copies to pick the first key whose value is non-null, then (2) expose a thin `tryGetRaw` on the nullable extension that returns that selected value untouched. Spec: `docs/superpowers/specs/2026-06-04-raw-map-getter-design.md`.

**Tech Stack:** Dart (package `convert_object`), `package:test`, AAA-style tests under `test/extensions/`.

---

## File structure

- `lib/src/extensions/map_extensions.dart` - the only library file changed. Holds both `_firstValueForKeys` copies (lines 41-50 non-nullable, 379-390 nullable) and the nullable extension where `tryGetRaw` is added.
- `test/extensions/try_get_raw_test.dart` - new test file covering both the changed fallback semantic (via typed getters) and the new `tryGetRaw` method.
- `README.md` - Map-extensions section gains a `tryGetRaw` example + signature.
- `CHANGELOG.md` + `pubspec.yaml` - 1.1.0 entry and version bump.
- `../dart_helper_utils/migration_guides.md` - cross-repo: a `firstValueForKeys` migration row (separate commit in that repo).

Ordering: fix the foundation first (Task 1), then build the new method on it (Task 2), then docs/version (Tasks 3-5). Each task is an independent, shippable commit.

---

### Task 1: Fix `alternativeKeys` to select the first non-null value

**Files:**
- Create: `test/extensions/try_get_raw_test.dart`
- Modify: `lib/src/extensions/map_extensions.dart:46` (non-nullable copy) and `lib/src/extensions/map_extensions.dart:386` (nullable copy)

- [ ] **Step 1: Write the failing test**

Create `test/extensions/try_get_raw_test.dart` with exactly this content:

```dart
// Covers Map.tryGetRaw and the shared first-non-null `alternativeKeys` fallback
// used by every map getter. See
// docs/superpowers/specs/2026-06-04-raw-map-getter-design.md
import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('alternativeKeys first-non-null fallback', () {
    test('getString skips a present-but-null alt key to the next non-null', () {
      // Arrange
      final map = <String, dynamic>{'a': null, 'b': null, 'c': 'x'};

      // Act
      final result = map.getString('a', alternativeKeys: const ['b', 'c']);

      // Assert
      expect(result, equals('x'));
    });

    test('tryGetString skips a present-but-null alt key', () {
      // Arrange
      final map = <String, dynamic>{'a': null, 'b': null, 'c': 'x'};

      // Act
      final result = map.tryGetString('a', alternativeKeys: const ['b', 'c']);

      // Assert
      expect(result, equals('x'));
    });

    test('a present-but-null primary still falls through to alternatives', () {
      // Arrange
      final map = <String, dynamic>{'a': null, 'b': 'y'};

      // Act
      final result = map.getString('a', alternativeKeys: const ['b']);

      // Assert
      expect(result, equals('y'));
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `dart test test/extensions/try_get_raw_test.dart -n "first-non-null"`
Expected: FAIL. With the current "first key that exists" logic, `getString` throws a `ConversionException` (it selects `b`, whose value is null) and `tryGetString` returns `null`, so the `equals('x')` assertions fail.

- [ ] **Step 3: Change the non-nullable copy's predicate**

In `lib/src/extensions/map_extensions.dart`, inside `extension MapConversionX<K, V> on Map<K, V>`, change line 46 from:

```dart
      final altKey = alternativeKeys.firstWhereOrNull(containsKey);
```

to:

```dart
      final altKey = alternativeKeys.firstWhereOrNull((k) => this[k] != null);
```

Leave the rest of `_firstValueForKeys` (the `value == null && alternativeKeys != null && alternativeKeys.isNotEmpty` guard and `value = this[altKey]`) unchanged.

- [ ] **Step 4: Change the nullable copy's predicate**

In the same file, inside `extension NullableMapConversionX<K, V> on Map<K, V>?`, change line 386 from:

```dart
      final altKey = alternativeKeys.firstWhereOrNull(map.containsKey);
```

to:

```dart
      final altKey = alternativeKeys.firstWhereOrNull((k) => map[k] != null);
```

Leave the receiver guard (`final map = this; if (map == null) return null;`) and `value = map[altKey]` unchanged. This preserves null-safety on a null receiver while only changing which alternative key wins.

- [ ] **Step 5: Run the test to verify it passes**

Run: `dart test test/extensions/try_get_raw_test.dart -n "first-non-null"`
Expected: PASS (3 tests).

- [ ] **Step 6: Run the full suite to confirm no regressions**

Run: `dart test`
Expected: PASS. Existing `alternativeKeys` tests use an absent primary key with a valued alternative, so first-non-null returns the same result as before.

- [ ] **Step 7: Analyze**

Run: `dart analyze`
Expected: "No issues found!" (the `firstWhereOrNull` helper is still used, so no unused-element warning).

- [ ] **Step 8: Commit**

```bash
git add lib/src/extensions/map_extensions.dart test/extensions/try_get_raw_test.dart
git commit -m "fix: alternativeKeys fallback selects the first non-null value across map getters"
```

---

### Task 2: Add `Map.tryGetRaw`

**Files:**
- Modify: `lib/src/extensions/map_extensions.dart` (add method to `NullableMapConversionX`, after the nullable `_firstValueForKeys` which ends at line 390)
- Modify: `test/extensions/try_get_raw_test.dart` (add a `tryGetRaw` group)

- [ ] **Step 1: Write the failing tests**

In `test/extensions/try_get_raw_test.dart`, add this group inside `main()` (after the existing `group(...)`, before the final closing `}` of `main`):

```dart
  group('tryGetRaw', () {
    test('returns the primary value without conversion', () {
      // Arrange
      final map = <String, dynamic>{'n': '5'};

      // Act
      final result = map.tryGetRaw('n');

      // Assert
      expect(result, '5'); // String, not int 5
      expect(result, isA<String>());
    });

    test('preserves Map and List values as-is', () {
      // Arrange
      final map = <String, dynamic>{
        'list': [1, 2],
        'map': {'a': 1},
      };

      // Act & Assert
      expect(map.tryGetRaw('list'), isA<List<dynamic>>());
      expect(map.tryGetRaw('list'), equals([1, 2]));
      expect(map.tryGetRaw('map'), isA<Map<dynamic, dynamic>>());
      expect(map.tryGetRaw('map'), equals({'a': 1}));
    });

    test('falls back to a single alternative key', () {
      // Arrange
      final map = <String, dynamic>{'fields': 'X'};

      // Act
      final result = map.tryGetRaw('errors', alternativeKeys: const ['fields']);

      // Assert
      expect(result, equals('X'));
    });

    test('skips a present-but-null alternative key to the next non-null', () {
      // Arrange
      final map = <String, dynamic>{'a': null, 'b': null, 'c': 'x'};

      // Act
      final result = map.tryGetRaw('a', alternativeKeys: const ['b', 'c']);

      // Assert
      expect(result, equals('x'));
    });

    test('returns null when nothing has a non-null value', () {
      // Arrange
      final map = <String, dynamic>{'a': null};

      // Act & Assert
      expect(map.tryGetRaw('a', alternativeKeys: const ['b']), isNull);
      expect(<String, dynamic>{}.tryGetRaw('missing'), isNull);
    });

    test('returns null on a null receiver', () {
      // Arrange
      final Map<String, dynamic>? map = null;

      // Act
      final result = map.tryGetRaw('a', alternativeKeys: const ['b']);

      // Assert
      expect(result, isNull);
    });

    test('equals a null-safe ?? chain over the keys', () {
      // Arrange
      final map = <String, dynamic>{'a': null, 'b': 2, 'c': 3};

      // Act
      final raw = map.tryGetRaw('a', alternativeKeys: const ['b', 'c']);

      // Assert
      expect(raw, equals(map['a'] ?? map['b'] ?? map['c']));
    });
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `dart test test/extensions/try_get_raw_test.dart -n "tryGetRaw"`
Expected: FAIL to compile / run with "The method 'tryGetRaw' isn't defined for the type ...".

- [ ] **Step 3: Implement `tryGetRaw`**

In `lib/src/extensions/map_extensions.dart`, inside `extension NullableMapConversionX<K, V> on Map<K, V>?`, immediately after the closing brace of `_firstValueForKeys` (line 390) and before the `/// Tries to convert the value at [key] ...` doc for `tryGetString`, insert:

```dart
  /// Returns the value at [key], or the first of [alternativeKeys] whose value
  /// is non-null, WITHOUT any type conversion.
  ///
  /// Use this for polymorphic or unknown-typed fields (for example a payload
  /// whose `errors` may be a `Map`, `List`, or `String`) where the typed
  /// `tryGetX` getters would coerce or discard the value. For known types,
  /// prefer the typed getters.
  ///
  /// Returns `null` when neither [key] nor any of [alternativeKeys] has a
  /// non-null value, or when the receiver is `null`. This cannot distinguish an
  /// absent key from a key whose value is `null`; use [Map.containsKey] for
  /// that distinction.
  ///
  /// After fallback, this is exactly a null-safe `this[key] ?? this[alt1] ?? ...`.
  V? tryGetRaw(K key, {List<K>? alternativeKeys}) =>
      _firstValueForKeys(key, alternativeKeys: alternativeKeys);
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `dart test test/extensions/try_get_raw_test.dart`
Expected: PASS (all groups).

- [ ] **Step 5: Analyze**

Run: `dart analyze`
Expected: "No issues found!"

- [ ] **Step 6: Commit**

```bash
git add lib/src/extensions/map_extensions.dart test/extensions/try_get_raw_test.dart
git commit -m "feat: add Map.tryGetRaw for raw value lookup with alternativeKeys"
```

---

### Task 3: Document in README

**Files:**
- Modify: `README.md` (Map-extensions narrative near line 335, and the nullable signature block near line 1076)

- [ ] **Step 1: Add the narrative example**

In `README.md`, find this block (lines 332-335):

```
Available getters on `Map<K,V>` and `Map<K,V>?`:
`get/tryGetString`, `get/tryGetInt`, `get/tryGetDouble`, `get/tryGetNum`,
`get/tryGetBool`, `get/tryGetBigInt`, `get/tryGetDateTime`, `get/tryGetUri`,
`get/tryGetList<T>`, `get/tryGetSet<T>`, `get/tryGetMap<K2,V2>`, `get/tryGetEnum<T>()`.
```

Insert immediately after it (before the `Quality...life:` line) this content:

````
**Raw escape hatch.** When a field is polymorphic or unknown-typed, `tryGetRaw`
returns the selected value with **no conversion** (the typed getters would coerce
or discard it). `alternativeKeys` selects the first key whose value is non-null,
so it behaves like a null-safe `??` chain:

```dart
// `errors` may be a Map, a List, or a String depending on the response.
final raw = json.tryGetRaw('errors', alternativeKeys: ['fields']);
if (raw is Map) {/* field -> message */}
else if (raw is List) {/* flat messages */}
else if (raw is String) {/* single message */}

// Exactly: json['a'] ?? json['b'] ?? json['c']
json.tryGetRaw('a', alternativeKeys: ['b', 'c']);
```

````

- [ ] **Step 2: Add the signature to the nullable block**

In `README.md`, find the nullable signature block ending (lines 1076-1077):

```
  T?       tryGetEnum<T extends Enum>(...);
}
```

Replace it with:

```
  T?       tryGetEnum<T extends Enum>(...);

  // Raw value, no conversion; alternativeKeys picks the first non-null match.
  V?       tryGetRaw(K key, {List<K>? alternativeKeys});
}
```

- [ ] **Step 3: Verify the README still renders**

Run: `grep -n "tryGetRaw" README.md`
Expected: at least two matches (narrative + signature).

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs(readme): document tryGetRaw and first-non-null fallback"
```

---

### Task 4: CHANGELOG + version bump (1.1.0)

**Files:**
- Modify: `CHANGELOG.md:1` (prepend new section)
- Modify: `pubspec.yaml:6` (version)

- [ ] **Step 1: Prepend the CHANGELOG entry**

In `CHANGELOG.md`, change the first line from:

```
## 1.0.4
```

to:

```
## 1.1.0

- Add `Map.tryGetRaw(key, {alternativeKeys})`: returns the selected value with no type conversion, for polymorphic or unknown-typed fields. It preserves the raw value (no coercion, no decoding).
- `alternativeKeys` now selects the first NON-NULL candidate across all map getters (`getString`/`tryGetString`/etc.). Previously it selected the first key that merely existed, so a present-but-null alternative key short-circuited the lookup.
- This is a behavior change for the "present-but-null alternative key" edge case and affects every typed map getter that uses `alternativeKeys`.
- To distinguish an absent key from a key whose value is `null`, use `Map.containsKey` directly; neither `tryGetRaw` nor a `??` chain can express that distinction.

## 1.0.4
```

- [ ] **Step 2: Bump the package version**

In `pubspec.yaml`, change line 6 from:

```
version: 1.0.4
```

to:

```
version: 1.1.0
```

- [ ] **Step 3: Sanity-check the package resolves**

Run: `dart pub get`
Expected: "Got dependencies!" (no version errors).

- [ ] **Step 4: Run the full suite once more**

Run: `dart test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CHANGELOG.md pubspec.yaml
git commit -m "chore: release 1.1.0 (tryGetRaw + first-non-null fallback)"
```

Note: actual publishing (`dart pub publish`) is a separate, manual step owned by the maintainer and is out of scope for this plan.

---

### Task 5 (cross-repo, optional now): dart_helper_utils migration note

**Files:**
- Modify: `/Users/omarhanafy/Development/MyProjects/dart_helper_utils/migration_guides.md`

This file lives in the separate `dart_helper_utils` repo and should be a separate commit/PR there. Do it only if updating both packages in this pass.

- [ ] **Step 1: Add a migration subsection**

In the v6 guide, near the existing "Map Extension Parameter Changes" section (the one documenting `altKeys` -> `alternativeKeys`), add:

```
### Raw value lookup: `firstValueForKeys` -> `tryGetRaw`

v5's public `Map.firstValueForKeys` is replaced by `Map.tryGetRaw` in
`convert_object` (re-exported here).

| v5 (Old)                                   | v6 (New)                                  |
|:-------------------------------------------|:------------------------------------------|
| `map.firstValueForKeys('k')`               | `map.tryGetRaw('k')`                       |
| `map.firstValueForKeys('k', alternativeKeys: ['a'])` | `map.tryGetRaw('k', alternativeKeys: ['a'])` |

For typed reads, prefer the typed getters (`map.tryGetString('k', alternativeKeys: ['a'])`).

Behavior change: `alternativeKeys` now selects the first key whose value is
NON-NULL (like a `??` chain), not merely the first key that exists. A
present-but-null alternative key no longer short-circuits the lookup. Use
`Map.containsKey` if you must distinguish absent from present-but-null.
```

- [ ] **Step 2: Commit (in the dart_helper_utils repo)**

```bash
cd /Users/omarhanafy/Development/MyProjects/dart_helper_utils
git add migration_guides.md
git commit -m "docs: migrate firstValueForKeys to tryGetRaw in v6 guide"
```

---

## Self-review

- **Spec coverage:** New method (Task 2) ✓; first-non-null fallback fix in both copies (Task 1) ✓; nullable receiver guard preserved (Task 1 Step 4) ✓; maps-only scope (no iterable change) ✓; no inner-nav/converter/default on `tryGetRaw` (Task 2 Step 3 signature) ✓; README (Task 3) ✓; CHANGELOG with the four mandated bullets + version (Task 4) ✓; dhu migration row (Task 5) ✓; tests for raw + the present-but-null typed-getter case + parity + no-coercion + null receiver (Tasks 1-2) ✓; existing-test audit (Task 1 Step 6) ✓.
- **Placeholder scan:** none; every code/edit step shows literal content.
- **Type consistency:** `tryGetRaw(K key, {List<K>? alternativeKeys}) -> V?` is used identically in the implementation (Task 2 Step 3), the README signature (Task 3 Step 2), and the tests. `_firstValueForKeys` signature is unchanged; only its internal predicate changes.
- **Non-goal honored:** no iterable by-index twin, no `Convert`/top-level/`Converter` surface.
