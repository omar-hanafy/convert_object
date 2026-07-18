# convert_object API quick reference (v1.1.x)

Exact public signatures, grouped by surface. `ElementConverter<T>` =
`T Function(Object? element)`. `DynamicConverter<T>` = `T Function(Object? value)`.

## 1. Static facade `Convert`

Config helpers:

- `Convert.config` -> effective `ConvertConfig`
- `Convert.configure(ConvertConfig config)` -> previous config
- `Convert.updateConfig(ConvertConfig Function(ConvertConfig) updater)`
- `Convert.runScopedConfig<T>(ConvertConfig overrides, T Function() body)`

Conversions (each `toX` has a `tryToX` twin with identical parameters that
returns `X?` instead of throwing):

- `Convert.string(object, {mapKey, listIndex, String? defaultValue, converter})`
  NOTE: named `string`, not `toString`. Try-variant: `tryToString`.
- `Convert.toNum(object, {mapKey, listIndex, String? format, String? locale, num? defaultValue, converter})`
- `Convert.toInt(object, {mapKey, listIndex, String? format, String? locale, int? defaultValue, converter})`
- `Convert.toDouble(object, {mapKey, listIndex, String? format, String? locale, double? defaultValue, converter})`
- `Convert.toBigInt(object, {mapKey, listIndex, BigInt? defaultValue, converter})`
- `Convert.toBool(object, {mapKey, listIndex, bool? defaultValue, converter})` - never throws
- `Convert.toDateTime(object, {mapKey, listIndex, String? format, String? locale, bool autoDetectFormat = false, bool useCurrentLocale = false, bool utc = false, DateTime? defaultValue, converter})`
- `Convert.toUri(object, {mapKey, listIndex, Uri? defaultValue, converter})`
- `Convert.toMap<K, V>(object, {mapKey, listIndex, Map<K, V>? defaultValue, keyConverter, valueConverter})`
- `Convert.toSet<T>(object, {mapKey, listIndex, Set<T>? defaultValue, elementConverter})`
- `Convert.toList<T>(object, {mapKey, listIndex, List<T>? defaultValue, elementConverter})`
- `Convert.toEnum<T extends Enum>(object, {required T Function(dynamic) parser, mapKey, listIndex, T? defaultValue, Map<String, dynamic>? debugInfo})`
- `Convert.toType<T>(object)` / `Convert.tryToType<T>(object)` - built-in for
  bool, int, double, num, BigInt, String, DateTime, Uri; other types via
  TypeRegistry, else direct cast attempt, else throws/null.

Navigation semantics: with both `listIndex` and `mapKey`, a List input is
indexed first, then a Map lookup applies to the result.

## 2. Top-level functions

Mirror `Convert` exactly with a `convert` prefix: `convertToString`,
`tryConvertToString`, `convertToNum`, `convertToInt`, `convertToDouble`,
`convertToBigInt`, `convertToBool`, `convertToDateTime`, `convertToUri`,
`convertToMap<K, V>`, `convertToSet<T>`, `convertToList<T>`,
`convertToEnum<T>`, `convertToType<T>` plus `tryConvertToX` twins.
(`convertToString`, not `convertString`.)

## 3. Fluent `Converter` via `.convert` (on `Object?`)

State/navigation (all return a new `Converter`, preserving configured default
and custom converter):

- `value.convert` -> `Converter`
- `.withDefault(Object? value)` - chain-wide fallback for later conversions
- `.withConverter(DynamicConverter<dynamic> fn)` - pre-transform before converting
- `.fromMap(Object? key)` - descend into map key (JSON strings auto-decoded)
- `.fromList(int index)` - descend into list index (JSON strings auto-decoded)
- `.decoded` - explicitly JSON-decode a string value

Terminal conversions: `string()`, `toNum()`, `toInt()`, `toDouble()`,
`toBool()`, `toBigInt()`, `toDateTime()`, `toUri()`, `toEnum<T>(parser: ...)`,
`toList<T>()`, `toSet<T>()`, `toMap<K, V>()` - same named args as `Convert`,
minus mapKey/listIndex duplicates you did not pass, plus:

- `tryToX(...)` twins
- `toXOr(X fallback, {...})`: `toStringOr`, `toNumOr`, `toIntOr`,
  `toDoubleOr`, `toBoolOr`, `toBigIntOr`, `toDateTimeOr`, `toUriOr`
- `to<T>()` / `tryTo<T>()` / `toOr<T>(T defaultValue)` - generic routing
- CAUTION: `Converter.toString()` is overridden to run the string conversion.

## 4. Map extensions

`MapConversionX<K, V> on Map<K, V>` (throwing getters):

- `getString(key, {alternativeKeys, innerKey, innerListIndex, defaultValue, converter})`
- `getInt` / `getDouble` / `getNum` (add `format`, `locale`)
- `getBool`, `getBigInt`, `getUri`
- `getDateTime(key, {alternativeKeys, innerKey, innerListIndex, format, locale, autoDetectFormat, useCurrentLocale, utc, defaultValue, converter})`
- `getList<T>` / `getSet<T>` (add `elementConverter`), `getMap<K2, V2>` (adds
  `keyConverter`, `valueConverter`)
- `getEnum<T extends Enum>(key, {required parser, alternativeKeys, innerKey, innerListIndex, defaultValue, debugInfo})`
- `parse<T, K2, V2>(key, T Function(Map<K2, V2>) converter)` /
  `tryParse<...>` - convert value at key to a map, then run a factory on it
- Getters: `valuesList`, `keysList`, `valuesSet`, `keysSet`

`NullableMapConversionX<K, V> on Map<K, V>?` (null-safe):

- `tryGetString`, `tryGetInt`, `tryGetDouble`, `tryGetNum`, `tryGetBool`,
  `tryGetBigInt`, `tryGetDateTime`, `tryGetUri`, `tryGetList<T>`,
  `tryGetSet<T>`, `tryGetMap<K2, V2>`, `tryGetEnum<T>` - same parameters as
  the get twins
- `tryGetRaw(key, {alternativeKeys})` (>= 1.1.0) - raw value, no conversion,
  first non-null across key + alternativeKeys; equivalent to a null-safe
  `map[key] ?? map[alt1] ?? ...`

`alternativeKeys` selects the first candidate whose value is non-null.

## 5. Iterable extensions

`IterableConversionX<E> on Iterable<E>` (throwing, by index):

- `getString(index, {innerMapKey, innerIndex, defaultValue, converter})`
- `getInt` / `getDouble` / `getNum` (add `format`, `locale`), `getBool`,
  `getBigInt`, `getUri`
- `getDateTime(index, {innerMapKey, innerIndex, format, locale, autoDetectFormat, useCurrentLocale, utc, defaultValue, converter})`
- `getList<T>` / `getSet<T>` / `getMap<K2, V2>` / `getEnum<T>(index, {required parser, ...})`
- `convertAll<T>()` - convert every element via `toType<T>`
- `toMutableSet({converter})`
- `intersect(other, {converter})` - MISNAMED: performs a union/merge (kept for
  dart_helper_utils compatibility)
- `mapList(mapper, {converter})`, `mapIndexedList(mapper, {converter})`

`NullableIterableConversionX<E> on Iterable<E>?` (null-safe): `tryGetString`,
`tryGetInt`, `tryGetDouble`, `tryGetBool`, `tryGetNum`, `tryGetBigInt`,
`tryGetDateTime`, `tryGetUri`, `tryGetList<T>`, `tryGetSet<T>`,
`tryGetMap<K2, V2>`, `tryGetEnum<T>` - each takes
`alternativeIndices: List<int>?` (fallback positions, first non-null wins)
plus `innerMapKey`, `innerIndex`.

`SetConvertToX<E> on Set<E>?`: `convertTo<R>()`.

NOTE: iterable extensions use `innerMapKey`/`innerIndex`; map extensions use
`innerKey`/`innerListIndex`.

## 6. Enum helpers

- `EnumParsers.byName(values)` - exact `Enum.name`; accepts `"Role.editor"`
  (last dot segment); throws `StateError` on unknown
- `EnumParsers.byNameCaseInsensitive(values)` - throws `ArgumentError` on unknown
- `EnumParsers.byNameOrFallback(values, fallback)` - never throws
- `EnumParsers.byIndex(values)` - accepts int or numeric string
- `EnumParsers.fromString(MyType.parse)` - adapt a `T Function(String)`
- On `List<T extends Enum>`: `.parser`, `.parserCaseInsensitive`,
  `.parserWithFallback(fallback)`, `.parserByIndex`

## 7. Scope functions, results, JSON helpers

- On `T`: `let(block)`, `also(block)`, `takeIf(pred)`, `takeUnless(pred)`;
  on `T?` additionally `letOr(block, defaultValue: ...)`, `letNullable(block)`.
- `ConversionResult<T>`: `.success(v)` / `.failure(err)`, `isSuccess`,
  `isFailure`, `value` (rethrows original), `valueOrNull`, `valueOr(d)`,
  `error`, `map`, `flatMap`, `fold(onSuccess:, onFailure:)`.
- String: `'{"a":1}'.tryDecode()` (returns original string on bad JSON),
  `.decode()` (throws).
- Any value: `.toJsonSafe({options, toEncodable})`,
  `.toJsonString({indent, options, toEncodable})`; maps add `.toJsonMap(...)`,
  iterables add `.toJsonList(...)`; `jsonSafe(value, {options, toEncodable})`.
- `JsonOptions({encodeEnumsAsName = true, dateTimeStrategy = DateTimeStrategy.iso8601String, durationStrategy = DurationStrategy.milliseconds, nonFiniteDoubles = NonFiniteDoubleStrategy.string, stringifyUnknown = true, setsAsLists = true, dropNulls = false, sortKeys = false, detectCycles = false, cyclePlaceholder = '<cycle>'})`.
  Bytes (`Uint8List`/`ByteBuffer`/`ByteData`) encode as base64; `BigInt` and
  `Uri` as strings.
- Roman numerals: `intToRomanNumeral(int)` (1..3999),
  `romanNumeralToInt(String)`, `num.toRomanNumeral()`,
  `'XLII'.asRomanNumeralToInt`.
- `Object?.asBool` - lenient bool coercion getter, never throws.
