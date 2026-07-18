# dart_helper_utils -> convert_object API mapping

Verified against dart_helper_utils 5.4.2/5.5.0 sources and its 6.0.x
changelog, and against convert_object 1.1.x.

## Static facade

| DHU <= 5.x | convert_object | Notes |
|---|---|---|
| `ConvertObject.toString1(obj, ...)` | `Convert.string(obj, ...)` | renamed (static `toString` is impossible); try-variant stays `tryToString` |
| `ConvertObject.tryToString` | `Convert.tryToString` | |
| `ConvertObject.toNum` / `tryToNum` | `Convert.toNum` / `tryToNum` | same `mapKey`, `listIndex`, `format`, `locale`, `defaultValue`, `converter` args |
| `ConvertObject.toInt` / `tryToInt` | `Convert.toInt` / `tryToInt` | |
| `ConvertObject.toDouble` / `tryToDouble` | `Convert.toDouble` / `tryToDouble` | |
| `ConvertObject.toBigInt` / `tryToBigInt` | `Convert.toBigInt` / `tryToBigInt` | |
| `ConvertObject.toBool` / `tryToBool` | `Convert.toBool` / `tryToBool` | merged token policy; see behavior notes |
| `ConvertObject.toDateTime` / `tryToDateTime` | `Convert.toDateTime` / `tryToDateTime` | same format/locale/autoDetectFormat/useCurrentLocale/utc args |
| `ConvertObject.toUri` / `tryToUri` | `Convert.toUri` / `tryToUri` | |
| `ConvertObject.toMap` / `tryToMap` | `Convert.toMap` / `tryToMap` | |
| `ConvertObject.toSet` / `tryToSet` | `Convert.toSet` / `tryToSet` | |
| `ConvertObject.toList` / `tryToList` | `Convert.toList` / `tryToList` | |
| `ConvertObject.toEnum` / `tryToEnum` (DHU >= 5.5.0) | `Convert.toEnum` / `tryToEnum` | `parser:` still required |
| `ConvertObject.buildParsingInfo` | `Convert.buildParsingInfo` | `@visibleForTesting` |

## Top-level functions

DHU <= 5.x exposed BARE names; convert_object prefixes them:

| DHU | convert_object |
|---|---|
| `toNum(x)` | `convertToNum(x)` |
| `toInt(x)` | `convertToInt(x)` |
| `toDouble(x)` | `convertToDouble(x)` |
| `toBigInt(x)` | `convertToBigInt(x)` |
| `toBool(x)` | `convertToBool(x)` |
| `toDateTime(x)` | `convertToDateTime(x)` |
| `toUri(x)` | `convertToUri(x)` |
| `toMap<K, V>(x)` | `convertToMap<K, V>(x)` |
| `toSet<T>(x)` | `convertToSet<T>(x)` |
| `toList<T>(x)` | `convertToList<T>(x)` |
| `toEnum<T>(x, parser: p)` | `convertToEnum<T>(x, parser: p)` |
| `toType<T>(x)` | `convertToType<T>(x)` |
| `tryToX(...)` (each) | `tryConvertToX(...)` |

## Exceptions

| DHU | convert_object |
|---|---|
| `ParsingException` | `ConversionException` |
| (verbose toString) | `toString()` concise; `fullReport()` for full JSON context + stack trace |
| - | `e.stackTrace` preserves the ORIGINAL failure trace |

## Map / Iterable extensions

| DHU | convert_object | Notes |
|---|---|---|
| `map.getString/getInt/.../getEnum(key, ...)` | same names | non-nullable `Map` |
| `map.tryGetString/... (on Map?)` | same names | nullable receiver |
| `map.firstValueForKeys(key, alternativeKeys: a)` (DHU >= 5.2.2) | `map.tryGetRaw(key, alternativeKeys: a)` | raw value, no conversion; requires convert_object >= 1.1.0 |
| `iterable.getString(i)/tryGetInt(i, ...)` | same names | `alternativeIndices:` for fallbacks |
| `iterable.firstElementForIndices(...)` | no direct public equivalent | use `tryGetX(i, alternativeIndices: [...])` |
| `iterable.intersect(other)` | `intersect(other)` | STILL a union/merge - preserved historical behavior |
| `iterable.convertAll<T>()` | same | |
| `set.convertTo<R>()` | same | |

## Enum helpers (DHU >= 5.5.0 -> same names)

`EnumParsers.byName`, `fromString`, `byNameOrFallback`,
`byNameCaseInsensitive`, `byIndex`; list shortcuts `.parser`,
`.parserWithFallback`, `.parserCaseInsensitive`, `.parserByIndex` - unchanged.

## JSON helpers

| DHU | convert_object |
|---|---|
| `makeEncodable(value)` | `value.toJsonSafe()` (any) / `map.toJsonMap()` |
| `safelyEncodedJson(value)` | `value.toJsonString()`; pretty: `toJsonString(indent: '  ')` or `encodeWithIndent` |
| - | `JsonOptions` controls enums/DateTime/Duration/bytes/nulls/sorting/cycles |

## Stayed in DHU (do NOT migrate to convert_object)

Date/time convenience extensions (`isSameDayAs`, `httpDateFormat`, ...),
collections (`flatMap`, `deepMerge`, `getPath`...), strings/MIME, futures/
streams/debounce/throttle, country/timezone utils. DHU 6 keeps all of these
and re-exports convert_object for the conversion surface.
