# convert_object parsing rules (v1.1.x, verified against source)

Exact behavior tables for debugging. Source files quoted are under
`lib/src/` in the package.

## Date & time (`toDateTime`, `tryToDateTime`; utils/dates.dart)

### Input routing

1. NUMERIC input (int/double, before any string logic):
   `abs(value) >= 100000000000` -> milliseconds since epoch, else SECONDS
   since epoch. (1735689600 -> 2025-01-01T00:00:00Z, correctly.) There is no
   microseconds tier.
2. `format:` given (or `DateOptions.defaultFormat` set) -> strict
   `DateFormat(format, locale)` parse; no auto-detection.
3. `autoDetectFormat: true` (or via DateOptions) -> auto-detect pipeline below.
4. Otherwise -> `DateTime.parse` (strict ISO-8601/RFC3339 only).

### Auto-detect pipeline order (string input)

0. Unix epoch DIGIT RULES: 9-10 digits = seconds; 12-13 digits =
   milliseconds; optional leading +/-. GUARD: a 12-digit string that
   validates as `yyyyMMddHHmm` (year 1800-2500, valid month/day/hour/minute)
   is a calendar timestamp, NOT epoch.
1. ISO-8601 / RFC 3339 via `DateTime.parse` (offsets, `Z`, fractional secs).
2. HTTP date (IMF-fixdate, `GMT`) -> UTC instant.
3. Slashed ambiguous numeric: locale `en_US*` tries MM/dd/yyyy first, all
   other locales dd/MM/yyyy first; falls back to the other order.
4. Compact numeric: 8 (`yyyyMMdd`), 12 (`yyyyMMddHHmm`), 14
   (`yyyyMMddHHmmss`) digits, manually validated (year 1800-2500);
   underscores/spaces tolerated.
5. Long month names via intl (`March 5, 2024`), with English ordinal
   stripping (`5th` -> `5`).
6. Time-only (`HH:mm[:ss]`, `hh:mm[:ss] a`) -> TODAY's date, local.

`extraAutoDetectPatterns` from DateOptions are tried BEFORE the built-in
pipeline. `useCurrentLocale: true` pulls `Intl.getCurrentLocale()` when no
locale was resolved.

### Timezone semantics

- Calendar-like input (no offset info: formatted dates, compact numeric,
  long names, slashed) -> LOCAL DateTime; `utc: true` forces UTC
  interpretation/result.
- Instant-like input (ISO with offset/Z, HTTP date, epoch numbers) -> the
  instant is preserved; returned in UTC when `utc: true`, else converted to
  local. The moment in time never shifts, only representation.

## Numbers (`toNum/toInt/toDouble`; utils/numbers.dart)

- Numeric input: `toInt()` truncates doubles; `toDouble()` widens ints.
- String cleaning before plain parse: strips commas, spaces, non-breaking
  spaces, underscores; accounting negatives `(2,500)` -> `-2500`.
- `format:` + `locale:` use `intl NumberFormat` (e.g. `'#,##0.##'` with
  `de_DE` parses `'1.234,56'`).
- `NumberOptions.tryFormattedFirst` (default true): with a format configured,
  formatted parse is attempted before plain parse.
- Formatter instances are LRU-cached (32 entries) keyed by format|locale.

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
- Map input to toList/toSet -> its VALUES.
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
- Strict paths with `defaultValue:` return the default instead of throwing -
  and the `onException` hook does NOT fire in that case (nor for `tryToX`).

## alternativeKeys / alternativeIndices (since 1.1.0)

- Map getters: primary key's value if non-null, else the first alternative
  key whose value is non-null. Before 1.1.0 the first EXISTING alternative
  key won even when its value was null.
- `tryGetRaw(key, alternativeKeys: [...])`: same selection, NO conversion.
- Neither can distinguish absent-key from null-value: use `containsKey`.
- Iterable try-getters use `alternativeIndices` the same way.
