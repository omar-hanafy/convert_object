# convert_object parsing rules (v1.1.x, verified against source)

Exact behavior tables for debugging. Source files quoted are under
`lib/src/` in the package.

## Date & time (`toDateTime`, `tryToDateTime`; utils/dates.dart)

### Input routing

1. NUMERIC input (int/double, before any string logic):
   `abs(value) >= 100000000000` -> milliseconds since epoch, else SECONDS
   since epoch. (1735689600 -> 2025-01-01T00:00:00Z, correctly.) There is no
   microseconds tier.
2. `format:` given (or `DateOptions.defaultFormat` set) selects
   `DateFormat(format, locale)` parsing, using intl’s explicit-pattern behavior.
3. `autoDetectFormat: true` (or via DateOptions) -> auto-detect pipeline below.
4. Otherwise -> `DateTime.parse` with Dart’s ISO parsing and normalization rules.

### Auto-detect pipeline order (string input)

0. Numeric strings include compact calendar dates and Unix epochs. Compact
   dates accept `yyyyMMdd`, `yyyyMMddHHmm`, or `yyyyMMddHHmmss`. For twelve
   unsigned digits, a valid calendar timestamp in years 1800-2500 takes
   precedence over milliseconds. Signed values use the epoch rules. Epochs
   take 9-10 digits for seconds or 12-13 for milliseconds.
1. ISO-8601 / RFC 3339 via `DateTime.parse` (offsets, `Z`, fractional secs).
2. HTTP date (IMF-fixdate, `GMT`) -> UTC instant.
3. Slashed ambiguous numeric: locale `en_US*` tries MM/dd/yyyy first, all
   other locales dd/MM/yyyy first; falls back to the other order.
4. Long month names via intl (`March 5, 2024`), with English ordinal
   stripping (`5th` -> `5`).
5. Time-only (`HH:mm[:ss]`, `hh:mm[:ss] a`) -> TODAY's date, local.

`extraAutoDetectPatterns` from DateOptions are tried BEFORE the built-in
pipeline. `useCurrentLocale: true` pulls `Intl.getCurrentLocale()` when no
locale was resolved.

### Timezone semantics

- Plain ISO text without an offset and automatically detected calendar formats
  use local time. Setting `utc: true` converts that instant to UTC.
- ISO strings with offsets or Z and HTTP dates with GMT return UTC. Epochs
  use local time by default and UTC when requested.
- Explicit formats and configured extra patterns interpret calendar fields
  in UTC when `utc: true`.

## Numbers (`toNum/toInt/toDouble`; utils/numbers.dart)

- Numeric input: `toInt()` truncates doubles; `toDouble()` widens ints.
- String cleaning before plain parse: strips commas, spaces, non-breaking
  spaces, underscores; accounting negatives `(2,500)` -> `-2500`.
- `format:` + `locale:` use `intl NumberFormat` (e.g. `'#,##0.##'` with
  `de_DE` parses `'1.234,56'`).
- `NumberOptions.tryFormattedFirst` (default true): with a format configured,
  formatted parse is attempted before plain parse.
- Without an explicit or configured locale, formatted parsing follows the
  current `Intl` locale, including `Intl.withLocale` scopes.
- Send arbitrary-precision integers as quoted decimal strings. Use the
  primitive BigInt converter on a decoded field or pass the entire array of
  quoted strings to the list converter. Selecting a scalar string with a
  collection converter decodes it again as JSON and can round large integers.

## Booleans (`toBool/tryToBool`; utils/bools.dart, config BoolOptions)

Evaluation order for input v:

1. `null` -> null (so `toBool` -> defaultValue ?? false).
2. `bool` -> itself.
3. `num` -> `numericPositiveIsTrue` (default true): `v > 0`; if configured
   false: `v != 0`.
4. String: trim + lowercase; empty -> null; numeric string -> rule 3;
   truthy set (default `true,1,yes,y,on,ok,t`) -> true; falsy set (default
   `false,0,no,n,off,f`) -> false; anything else -> null.
5. `toBool` maps null-result to `defaultValue ?? false`; `tryToBool` returns
   null. `toBool` NEVER throws.

Token sets and the numeric rule are configurable (BoolOptions via
ConvertConfig) - never hardcode wrappers for extra tokens.

## URIs (`toUri/tryToUri`; utils/uri.dart, config UriOptions)

Order: phone check -> email check -> URI parse with policy.

- Phone: trimmed input matching `^\+?[0-9\-\s\(\)]{3,}$` -> `tel:` URI with
  everything except digits/+ stripped. NOTE: digit-only strings (IDs!) match.
- Email: `^[^@\s]+@[^@\s]+\.[^@\s]+$` on the EXACT string (surrounding
  whitespace makes it fail) -> `mailto:`.
- Bare domain (`example.com`) + `coerceBareDomainsToDefaultScheme: true` +
  `defaultScheme` -> scheme prepended.
- Rejections (FormatException -> ConversionException): empty input;
  http/https without host; mailto/tel without path; relative URIs when
  `allowRelative: false`.

## JSON auto-decode boundary

- `toList`/`toSet`/`toMap` (all surfaces) DECODE string input as JSON first;
  on decode failure the original string flows on (usually then failing with
  a type error).
- Primitive conversions (string/int/double/num/bool/BigInt/DateTime/Uri) do
  NOT decode JSON strings.
- Fluent `.fromMap(key)`/`.fromList(i)` decode JSON-string values during
  navigation; `.decoded` decodes explicitly.
- `'x'.tryDecode()` returns the ORIGINAL STRING (not null) on invalid JSON;
  `.decode()` throws.

## Collection shape rules (`toList<T>`/`toSet<T>`/`toMap<K,V>`)

- Empty iterable/map -> empty result.
- Already `List<T>`/`Set<T>`/`Map<K,V>` -> returned as-is.
- Single value of type T -> wrapped: `toList<int>(5)` -> `[5]`.
- A map used as a collection source supplies its values for element conversion.
  A map already assignable to the requested element type can be wrapped as a
  single element. Pass `[map]` to apply a model converter to the whole record.
- Element conversion: `elementConverter` if given, else `is T` pass-through,
  else `toType<T>` routing. Failures carry `elementIndex` in context.
- `toMap` converts entries only when not already `Map<K,V>`:
  `keyConverter`/`valueConverter` or direct casts per entry.

## Generic routing (`toType<T>`/`tryToType<T>`)

1. `object is T` -> returned unchanged (registry NOT consulted).
2. null -> throws (`toType`) / null (`tryToType`).
3. TypeRegistry parser for T, if registered (null return = fall through).
4. Built-ins: bool, int, double, num, BigInt, String, DateTime, Uri.
5. Last resort `as T` cast, else ConversionException "Unsupported type" /
   null.

## ConversionException anatomy

- `error` (original error/message), `errorType`, `context`
  (unmodifiable map), `stackTrace` (ORIGINAL failure trace).
- `toString()`: `ConversionException(<errorType>): <error>` plus
  method/targetType/objectType/mapKey/listIndex suffix - concise on purpose.
- `fullReport()`: multi-line, context as indented JSON (jsonSafe-normalized),
  plus stack trace. Use for logs/issues.
- Nullable and defaulted collection conversions recover from a failed element.
  A strict collection failure reports its element index once. An independent
  conversion error caught by a callback reaches its original hook before the
  collection call finishes.

## alternativeKeys / alternativeIndices (since 1.1.0)

- Map getters: primary key's value if non-null, else the first alternative
  key whose value is non-null. Before 1.1.0 the first EXISTING alternative
  key won even when its value was null.
- `tryGetRaw(key, alternativeKeys: [...])`: same selection, NO conversion.
- Neither can distinguish absent-key from null-value: use `containsKey`.
- Iterable try-getters use `alternativeIndices` the same way.
