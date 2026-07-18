---
name: parse-with-convert-object
description: Use when writing or reviewing Dart/Flutter code that turns dynamic or untyped data (JSON payloads, Map<String, dynamic>, lists, query params) into typed values with the convert_object package - fromJson factories and model layers, map getInt/getString/tryGetX getters, Convert.toX/tryToX calls, .convert fluent chains, List/Set/Map element conversion, enum parsing, alternativeKeys fallbacks, or nested key/index navigation.
---

# Parse dynamic data with convert_object

convert_object converts loosely-typed data into typed Dart values through five
equivalent surfaces backed by one engine. Your job is to pick the right surface
and the right failure policy, with the exact parameter names below - agents
reliably guess these wrong from memory.

## Step 0: Inspect the project first

1. Confirm the resolved version: `grep -A2 'convert_object' pubspec.lock`.
   `tryGetRaw` and the first-non-null `alternativeKeys` fallback need >= 1.1.0.
2. Find existing model patterns (`grep -rn "fromJson\|getInt\|convert\." lib/`)
   and match them; do not mix styles inside one file.
3. If the project also imports `dart_helper_utils` <= 5.x, stop: both packages
   define `getInt`-style extensions and calls become ambiguous. Use the
   migrate-from-dart-helper-utils skill first.

## Choosing a surface

| You have | Use | Example |
|---|---|---|
| `Map` payload, known keys | Map getters (most idiomatic) | `json.getInt('id')` |
| Possibly-null `Map?` | `tryGetX` getters (defined on `Map?`) | `json.tryGetString('email')` |
| A lone dynamic value | Fluent | `raw.convert.toIntOr(0)` |
| Value + one-off navigation | Static facade | `Convert.toInt(data, mapKey: 'id')` |
| `List`/`Iterable` by index | Iterable getters | `row.getString(0)`, `row.tryGetInt(1, alternativeIndices: [2])` |
| App-registered custom type | Generic routing | `Convert.toType<Money>(raw)` (needs TypeRegistry; see configure-convert-object) |

Top-level `convertToX`/`tryConvertToX` functions mirror `Convert.toX` exactly;
prefer whichever the project already uses.

## Choosing a failure policy

- `toX` / `getX`: throws `ConversionException` on failure - use when a missing
  or malformed value is a bug.
- `toX(..., defaultValue: v)` / `getX(..., defaultValue: v)`: returns `v`
  instead of throwing (also swallows converter errors).
- `tryToX` / `tryGetX`: never throws, returns `null` (or `defaultValue`).
- Fluent: `toIntOr(0)` and friends; `withDefault(v)` sets a chain-wide default.
- Exception: `toBool` NEVER throws - unparseable input returns `defaultValue`
  or `false`. If you need to detect failure, use `tryToBool` (returns `null`).

## Exact parameter names (agents get these wrong)

- Map getters: `alternativeKeys:` (NOT `altKeys`), `innerKey:`,
  `innerListIndex:` for one level of nested selection after the key lookup.
- Iterable try-getters: `alternativeIndices:` (maps use keys, iterables use
  indices).
- `Convert.toX` / top-level: `mapKey:`, `listIndex:` (applied to the input
  before converting).
- `alternativeKeys` picks the first key whose value is NON-null (>= 1.1.0).
  It cannot distinguish "key absent" from "key present but null"; use
  `Map.containsKey` for that, or `tryGetRaw` for the raw value.

## Enums: parser is required, case-insensitivity is opt-in

There is no automatic enum conversion. Every enum call takes `parser:`:

```dart
enum Role { admin, editor, viewer }

final role = json.getEnum('role', parser: Role.values.parser); // exact name
final role2 = json.getEnum(
  'role',
  parser: Role.values.parserCaseInsensitive, // accepts "EDITOR"
);
final role3 = Convert.toEnum<Role>(
  raw,
  parser: EnumParsers.byNameOrFallback(Role.values, Role.viewer), // unknown -> viewer
);
```

Other parsers: `EnumParsers.byIndex(values)` (accepts `1` or `"1"`),
`EnumParsers.fromString(MyEnum.parse)` for json_serializable-style parsers.
`byName` also accepts dotted input like `"Role.editor"` (uses the last
segment).

## Canonical fromJson

```dart
class User {
  User({required this.id, required this.createdAt, required this.role,
      required this.scores, this.email, this.settings});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json.getInt('id'), // "42" or 42 both work
        createdAt: json.getDateTime('created_at', utc: true),
        role: json.getEnum('role', parser: Role.values.parserCaseInsensitive),
        email: json.tryGetString('email', alternativeKeys: ['mail']),
        scores: json.getList<int>('scores'), // real list OR JSON string "[1,2,3]"
        settings: json.tryGetRaw('settings'), // polymorphic: raw, no coercion
      );

  final int id;
  final DateTime createdAt;
  final Role role;
  final String? email;
  final List<int> scores;
  final Object? settings;
}
```

## Collections

- `toList<T>`/`toSet<T>`/`toMap<K,V>` (and the get/tryGet forms) decode JSON
  strings first, wrap single values (`toList<int>(5)` -> `[5]`), and take
  map VALUES when given a map.
- Primitive conversions do NOT auto-decode JSON strings; use `.convert.decoded`
  or a collection conversion when the payload is a JSON string.
- Nested models: pass `elementConverter` and reuse the model factory:

```dart
final users = json.getList<User>(
  'users',
  elementConverter: (e) => User.fromJson(Convert.toMap<String, dynamic>(e)),
);
```

- For `toMap`, use `keyConverter:` / `valueConverter:`.
- Element failures throw with `elementIndex` in the exception context.

## Verification

After edits: `dart analyze` the touched paths and run the project's tests. If
you added parsing for a new payload shape, add a test feeding the raw payload
(including the string-typed variants) through the new factory.

## Failure handling

- Conversion throws at runtime -> read `e.fullReport()` (NOT `detailedReport`;
  `toString()` is intentionally concise). Then use the debug-convert-object
  skill's pitfall catalog.
- Need behavior changes app-wide (locales, bool tokens, custom types) -> use
  the configure-convert-object skill instead of per-call workarounds.

## Full API tables

For the complete signatures of all five surfaces (every method, every named
parameter), read [references/api-quick-reference.md](references/api-quick-reference.md).

## When NOT to use this package

- Data already statically typed end to end: plain Dart casts are fine.
- Full codegen serialization (json_serializable/freezed) already in place:
  convert_object complements field-level coercion but should not replace the
  generator; keep the project's existing approach.
