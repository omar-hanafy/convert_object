# Convert Object

> A comprehensive **type conversion** toolkit for Dart & Flutter
> Fluent API • Safe `try*` variants • Collections • Enums • Dates/Numbers/URIs • JSON helpers • Ergonomic map/list extensions

[![pub package](https://img.shields.io/pub/v/convert_object.svg)](https://pub.dev/packages/convert_object)
[![Dart](https://img.shields.io/badge/Dart-≥2.17-blue.svg)](#)
[![Null-safety](https://img.shields.io/badge/null--safe-yes-success.svg)](#)

---

## Table of contents

* [Why convert_object?](#why-convert_object)
* [Install](#install)
* [Quick start](#quick-start)
* [Core APIs](#core-apis)

  * [Static facade: `Convert`](#static-facade-convertobject)
  * [Fluent API: `Converter` + `.convert` extension](#fluent-api-converter--convert-extension)
  * [Top‑level functions (`toInt`, `tryToDateTime`, …)](#top-level-functions)
  * [Global configuration (`ConvertConfig`)](#global-configuration-convertconfig)
  * [Map/Iterable/Object extensions](#mapiterableobject-extensions)
  * [Strict vs try vs default](#strict-vs-try-vs-default)
  * [Low-token usage patterns](#low-token-usage-patterns)
  * [Enum helpers: `EnumParsers`](#enum-helpers-enumparsers)
  * [Results: `ConversionResult<T>`](#results-conversionresultt)
* [Deep‑dive: Date & time parsing](#deep-dive-date--time-parsing)
* [Numbers & booleans](#numbers--booleans)
* [URIs (http/mail/phone)](#uris-httpmailphone)
* [JSON + pretty utilities](#json--pretty-utilities)
* [Error reporting](#error-reporting)
* [Advanced usage & recipes](#advanced-usage--recipes)
* [Migration beta to stable](#migration-beta-to-stable)
* [Migration from `dart_helper_utils`](#migration-from-dart_helper_utils)
* [Performance notes](#performance-notes)
* [FAQ](#faq)
* [Contributing](#contributing)
* [License](#license)

---

## Why `convert_object`?

`convert_object` gives you a **single, consistent API** to turn loosely‑typed or dynamic data (maps, lists, JSON, strings) into strongly‑typed values — with:

* **Fluent** conversion (`obj.convert.toInt()`) and **static** helpers (`Convert.toInt(obj)`).
* **Safe** `try*` variants that never throw (return `null` or a default).
* **Collections**: convert to `List<T>`, `Set<T>`, `Map<K,V>` with custom element/key/value converters.
* **Enums**: robust parsers (`byName`, `caseInsensitive`, `byIndex`, fallback).
* **Dates**: smart auto‑detection, explicit formats & locales, clear local/UTC behavior.
* **Numbers**: forgiving parsing (`"1234.56"`, `"(1,234)"`), localized formats.
* **URIs**: parse http/https + detect emails and phone numbers → `mailto:` / `tel:`.
* Ergonomic **map/list extensions** for inner selection and fallbacks.
* Helpful **exceptions** (`ConversionException`) with context for debugging.

---

## Install

```yaml
dependencies:
  convert_object: ^latest
```

Import:

```dart
import 'package:convert_object/convert_object.dart';
```

---

## Quick start

```dart
import 'package:convert_object/convert_object.dart';

void main() {
  dynamic data = {
    'id': '42',
    'price': '1,234.56',
    'when': '2024-02-29T10:15:00Z',
    'site': 'https://example.com',
    'tags': ['1', 2, '3'],
    'user': {'email': 'alice@example.com'},
    'status': 'Active',
  };

  // Static facade
  final id = Convert.toInt(data, mapKey: 'id');                // 42
  final price = Convert.toDouble(data, mapKey: 'price');       // 1234.56
  final when = Convert.toDateTime(data, mapKey: 'when', utc: true);
  final site = Convert.toUri(data, mapKey: 'site');            // Uri
  final tags = Convert.toList<int>(data, mapKey: 'tags');      // [1,2,3]
  final email = Convert.toUri(data, mapKey: 'user', listIndex: null,
                                    defaultValue: null);             // mailto:alice@example.com

  // Fluent API
  final asBool = 'ok'.convert.toBool();                              // true
  final maybeNum = 'oops'.convert.tryToNum();                        // null

  // Enums
  enum Status { Active, Disabled }
  final s = Convert.toEnum<Status>(data['status'],
            parser: EnumParsers.byName(Status.values));              // Status.Active

  print([id, price, when, site, tags, asBool, maybeNum, s]);
}
```

---

## Core APIs

### Static facade: `Convert`

Backwards‑compatible, static helpers that cover primitives, dates, URIs, enums, collections, and generic routing.

#### Primitives

```dart
// Text
String        Convert.string(obj, {mapKey, listIndex, defaultValue, converter});
String?       Convert.tryToString(obj, { ... });

// Numbers
num           Convert.toNum(obj, {format, locale, ...});
num?          Convert.tryToNum(obj, {format, locale, ...});
int           Convert.toInt(obj, {format, locale, ...});
int?          Convert.tryToInt(obj, {format, locale, ...});
double        Convert.toDouble(obj, {format, locale, ...});
double?       Convert.tryToDouble(obj, {format, locale, ...});
BigInt        Convert.toBigInt(obj, {...});
BigInt?       Convert.tryToBigInt(obj, {...});

// Bool (predictable truthiness; see below)
bool          Convert.toBool(obj, {defaultValue});
bool?         Convert.tryToBool(obj, {defaultValue});

// DateTime
DateTime      Convert.toDateTime(obj, {
                format, locale, autoDetectFormat=false,
                useCurrentLocale=false, utc=false, ...
              });
DateTime?     Convert.tryToDateTime(obj, { ... });

// Uri (detects email/phone and builds mailto:/tel:)
Uri           Convert.toUri(obj, {defaultValue});
Uri?          Convert.tryToUri(obj, {defaultValue});
```

#### Collections

```dart
// Map
Map<K,V>      Convert.toMap<K,V>(obj, {
                keyConverter, valueConverter, defaultValue
              });
Map<K,V>?     Convert.tryToMap<K,V>(...);

// Set
Set<T>        Convert.toSet<T>(obj, {elementConverter, defaultValue});
Set<T>?       Convert.tryToSet<T>(...);

// List
List<T>       Convert.toList<T>(obj, {elementConverter, defaultValue});
List<T>?      Convert.tryToList<T>(...);
```

#### Enums

```dart
T             Convert.toEnum<T extends Enum>(obj, { required parser, defaultValue });
T?            Convert.tryToEnum<T extends Enum>(obj, { required parser, defaultValue });
```

#### Generic routing

```dart
T             Convert.toType<T>(obj);   // supports bool,int,double,num,BigInt,String,DateTime,Uri
T?            Convert.tryToType<T>(obj);
```

> Strict `to*` methods **throw** `ConversionException` on failure unless a
> `defaultValue` is provided (then the default is returned).
> `tryTo*` methods **never throw**; they return `null` or the provided
> `defaultValue`.
> `toBool` always returns a `bool` and defaults to `false` when parsing fails.

---

### Fluent API: `Converter` + `.convert` extension

Prefer writing code like this:

```dart
final value = someDynamic.convert
    .withDefault(0)
    .withConverter((v) => v is String ? v.trim() : v) // optional pre-transform
    .toInt();
```

Key features:

* `.convert` — extension on `Object?` returning a `Converter`.
* Navigation helpers: `.fromMap(key)`, `.fromList(index)`, `.decoded` (JSON decode if the source is a `String`).
* Generic targets: `.to<T>()`, `.tryTo<T>()`, `.toOr(default)`.
* Primitive shortcuts: `.toInt()`, `.tryToDouble()`, `.toDateTimeOr(fallback)`, etc.
* Collections: `.toList<T>(elementConverter: ...)`, `.toMap<K,V>(keyConverter: ..., valueConverter: ...)`.

Example:

```dart
final jsonText = '{"user": {"age": " 21 ", "email": "bob@example.com"}}';

final age = jsonText.convert.decoded
    .fromMap('user')
    .fromMap('age')
    .withConverter((v) => v is String ? v.trim() : v)
    .toInt();                          // 21

final emailUri = jsonText.convert.decoded
    .fromMap('user')
    .fromMap('email')
    .toUri();                          // mailto:bob@example.com
```

---

### Top‑level functions

All static methods also exist as **free functions** if you prefer shorter calls:

```dart
import 'package:convert_object/convert_object.dart';

final n = toInt('1,234');           // 1234
final dt = toDateTime('20240229');  // Feb 29, 2024 (local)
final list = toList<int>(['1', 2]); // [1,2]
```

---

### Global configuration (`ConvertConfig`)

Tune default behaviour once at app start, or override it in specific zones. Precedence is:

`call-site arguments > Convert.runScopedConfig(...) overrides > global Convert.configure(...) > library defaults`.

```dart
import 'package:convert_object/convert_object.dart';

void main() {
  Convert.configure(Convert.config.copyWith(
    locale: 'en_GB',
    numbers: Convert.config.numbers.copyWith(
      defaultLocale: 'de_DE',
      defaultFormat: '#,##0.##',
    ),
    dates: Convert.config.dates.copyWith(
      defaultFormat: 'dd/MM/yyyy',
      autoDetectFormat: true,
      utc: true,
    ),
    bools: const BoolOptions(truthy: {'si'}, falsy: {'no'}),
    uri: const UriOptions(
      defaultScheme: 'https',
      coerceBareDomainsToDefaultScheme: true,
      allowRelative: false,
    ),
    registry: TypeRegistry.empty().register<Duration>(
      (value) => Duration(seconds: Convert.toInt(value)),
    ),
    onException: (ex) {
      // Send to telemetry / logging sink.
    },
  ));
}

final utcDate = Convert.runScopedConfig(
  Convert.config.copyWith(
    dates: Convert.config.dates.copyWith(utc: true),
  ),
  () => Convert.toDateTime('2024-12-31T23:59:59'),
);
```

If you want to override with default-valued options (or explicitly clear a
field), use `ConvertConfig.overrides`:

```dart
Convert.runScopedConfig(
  ConvertConfig.overrides(
    numbers: const NumberOptions(), // explicit override
    clearLocale: true,
  ),
  () => Convert.toNum('1,234'),
);
```

The configuration primitives are exposed via `ConvertConfig`, but convenience helpers exist on the facade:

```dart
Convert.configure(...);               // set process-wide defaults
Convert.updateConfig((cfg) => ...);   // atomic updates
Convert.runScopedConfig(...);         // temporary overrides (uses Zone)
final active = Convert.config;        // inspect effective config
```

---

### Map/Iterable/Object extensions

#### Map

Ergonomic getters with inner selection and alternative keys:

```dart
final user = {'id': '42', 'joined': '29/02/2024', 'tags': ['1', 2, '3']};

final id    = user.getInt('id');                      // 42
final when  = user.getDateTime('joined', locale: 'en_GB');
final tags  = user.getList<int>('tags');              // [1,2,3]

// Try variants + alt keys
final name  = user.tryGetString('name', alternativeKeys: ['username', 'handle']);
```

Available getters on `Map<K,V>` and `Map<K,V>?`:
`get/tryGetString`, `get/tryGetInt`, `get/tryGetDouble`, `get/tryGetNum`,
`get/tryGetBool`, `get/tryGetBigInt`, `get/tryGetDateTime`, `get/tryGetUri`,
`get/tryGetList<T>`, `get/tryGetSet<T>`, `get/tryGetMap<K2,V2>`, `get/tryGetEnum<T>()`.

Quality‑of‑life:
`valuesList`, `valuesSet`, `keysList`, `keysSet`, and parsing helpers:

```dart
final model = map.parse<String, String, Object?>('payload', MyModel.fromJson);
final maybe = map.tryParse<String, Object?, Object?>('optional', MyModel.fromJson);
```

#### Iterable

```dart
final items = ['100', '200', 'oops', '300'];

// Positional conversions with optional inner selection
final a = items.getInt(0);                      // 100
final b = items.tryGetInt(2, alternativeIndices: [3, 1]); // 300 (falls back)

// Convert the whole iterable
final asInts = items.convertAll<int>();         // [100,200,Exception->throws at 'oops']

// Safer: try variants / element converters
final safe = items.mapList<int>((s) => toInt(s)); // [100,200,throws at 'oops']
final withTry = items.mapIndexedList((i, s) => tryToInt(s) ?? i); // [100,200,2,300]

// Set helpers
final union = {1,2,3}.intersect([3,4,5]);       // {1,2,3,4,5}  (legacy: name kept)
```

#### Object → Converter

```dart
someObj.convert.toBool();
```

#### Scope functions

```dart
final x = '  hello '.let((s) => s.trim());          // "hello"
final y = (null as String?).letOr((s) => s.length, defaultValue: 0); // 0
final z = 'hi'.also((s) => print(s)).takeIf((s) => s.length == 2); // "hi"
final w = 'no'.takeUnless((s) => s == 'no');        // null
```

---

### Strict vs try vs default

Use strict conversions when failure is exceptional, try conversions when failure
is expected, and defaults when you want a fallback without branching.

* Strict `to*`: throws `ConversionException` when conversion fails and no
  `defaultValue` is provided.
* Defaulted strict `to*`: returns `defaultValue` instead of throwing (including
  converter errors).
* Try `tryTo*`: never throws; returns `null` or `defaultValue`.
* `toBool` always returns a bool; when parsing fails it returns `defaultValue`
  or `false`. `tryToBool` returns `null` on failure.

---

### Low-token usage patterns

Prefer extensions for short, readable conversion pipelines:

```dart
final id = json.getInt('id');
final ok = json.getBool('ok'); // defaults to false
final price = json.getDouble('price');
final created = json.getDateTime('created_at');

final count = payload['count'].convert.toIntOr(0);
final maybe = payload['count'].convert.tryToInt();
final tag = list.getString(0);
```

---

### Enum helpers: `EnumParsers`

```dart
enum Mode { light, dark }

final parserByName          = EnumParsers.byName(Mode.values);
final parserCaseInsensitive = EnumParsers.byNameCaseInsensitive(Mode.values);
final parserByIndex         = EnumParsers.byIndex(Mode.values);
final parserWithFallback    = EnumParsers.byNameOrFallback(Mode.values, Mode.light);

// Usage with Convert
final m1 = Convert.toEnum<Mode>('dark',  parser: parserByName);            // dark
final m2 = Convert.toEnum<Mode>('DARK',  parser: parserCaseInsensitive);   // dark
final m3 = Convert.toEnum<Mode>('oops',  parser: parserWithFallback);      // light
final m4 = Convert.toEnum<Mode>(1,       parser: parserByIndex);           // dark

// Shortcuts from a list of enum values:
final byName = Mode.values.parser;
```

---

### Results: `ConversionResult<T>`

A tiny monad to carry success/failure without throwing:

```dart
ConversionResult<int> parseAge(Object? v) {
  try {
    return ConversionResult.success(Convert.toInt(v));
  } on ConversionException catch (e) {
    return ConversionResult.failure(e);
  }
}

final res = parseAge('not a number');
final age = res.valueOr(0);   // 0
res.error?.toString();        // Human‑readable diagnostic
```

---

## Deep‑dive: Date & time parsing

`toDateTime` and friends support **explicit** formats (via `intl`) and a robust **auto‑detect** mode with predictable time‑zone semantics.

```dart
// Explicit format
final birth = Convert.toDateTime('29/02/2024',
              format: 'dd/MM/yyyy', locale: 'en_GB');

// Auto‑detect (set `autoDetectFormat: true`)
final a = Convert.toDateTime('20240229', autoDetectFormat: true);
final b = Convert.toDateTime('02/29/2024', autoDetectFormat: true, locale: 'en_US');
final c = Convert.toDateTime('Thu, 20 Jun 2024 12:34:56 GMT',
                                   autoDetectFormat: true, utc: true);
```

**Auto‑detection priority** (simplified):

0. **Unix epoch** (`9–10` digits = sec, `12–13` digits = ms; `12` digits guarded to avoid `yyyyMMddHHmm`).
1. **ISO‑8601/RFC3339** (via `DateTime.parse`).
2. **HTTP date** (`IMF-fixdate`, `GMT`) → treated as UTC.
3. **Slashed ambiguous** (`MM/dd` vs `dd/MM`) by locale (e.g., `en_US` vs `en_GB`).
4. **Compact numeric** `yyyyMMdd[HHmm[ss]]` (spaces/underscores allowed).
5. **Long names** via `intl` (e.g., `March 5, 2024`).
6. **Time‑only** (`HH:mm[:ss]`) → today’s date (local).

**Time zone rules**

* **Calendar‑like inputs** (no explicit offset) return **local** time by default; set `utc: true` to force UTC.
* **Instant‑like inputs** (ISO with `Z`/offsets, HTTP date, Unix epoch) preserve their UTC meaning; if `utc: false` we convert back to local for convenience.

---

## Numbers & booleans

### Numbers

* Accepts inputs like `"1234.56"`, `"1,234"`, `"  123_456  "`, `"(2,500)"` (→ `-2500`).
* Localized parsing via `format` + `locale` (uses `intl:NumberFormat`).

```dart
Convert.toInt('1,234');                           // 1234
Convert.toNum('1.234,56', format: '#,##0.##', locale: 'de_DE'); // 1234.56
```

### Booleans (`toBool`, `tryToBool`, `asBool`)

Predictable, explicit rules (case-insensitive). `toBool` always returns a
bool; if parsing fails it returns `defaultValue` or `false`. `tryToBool`
returns `null` on failure.

* `null -> false`
* `bool -> value`
* `num -> value > 0`
* `String` truthy: `'true','1','yes','y','on','ok','t'`
* `String` falsy : `'false','0','no','n','off','f'`
* `String` numeric -> parsed then `> 0`
* anything else -> `false`

```dart
final ok = 'OK'.convert.toBool();     // true
final nope = 'nope'.convert.toBool(); // false
final maybe = 'oops'.convert.tryToBool(); // null
```

---

## URIs (http/mail/phone)

`toUri` understands:

* Regular URIs (`http`, `https`, `file`, …)
* **Emails** → `mailto:user@domain.tld`
* **Phone numbers** → `tel:+14155551234`

```dart
Convert.toUri('alice@example.com');   // mailto:alice@example.com
Convert.toUri('+1 (415) 555-1234');   // tel:+14155551234
Convert.toUri('https://example.com'); // Uri
```

Parsing safeguards (invalid host/path) are enforced. Use `tryToUri` or `defaultValue` to avoid throwing.

---

## JSON + pretty utilities

A few helpers are re‑exported to make JSON‑heavy flows ergonomic:

```dart
// Strings -> try to decode JSON else return the original text
final dynamic decoded = '{"a":1}'.tryDecode(); // Map<String,dynamic>

// Map/Iterable pretty JSON + normalization options
final pretty = {'a': 1, 'b': {'c': 3}}.toJsonString(indent: '  ');

final normalized = {
  DateTime.utc(2024, 1, 1): Duration(milliseconds: 1500),
  'payload': {'keep': 1, 'drop': null},
}.toJsonMap(
  options: const JsonOptions(
    sortKeys: true,
    dropNulls: true,
    dateTimeStrategy: DateTimeStrategy.millisecondsSinceEpoch,
    durationStrategy: DurationStrategy.iso8601,
  ),
);

final cyc = <String, dynamic>{};
cyc['self'] = cyc;
final safe = jsonSafe(
  cyc,
  options: const JsonOptions(detectCycles: true, cyclePlaceholder: '<cycle>'),
);

/* Also available:
   - Iterable: .toJsonList() / .toJsonString(indent: ...)
   - Any object: .toJsonSafe() / .toJsonString()
*/
```

---

## Error reporting

All throwing conversions use a single exception type and preserve the original
stack trace.

```dart
try {
  final n = Convert.toInt('oops');
} on ConversionException catch (e, s) {
  print(e);              // concise summary
  // print(e.fullReport()); // full JSON context + stack trace
  // e.stackTrace is the original trace (same as s).
}
```

`ConversionException` records method, objectType, targetType, map/list context
(`mapKey`, `listIndex`), formatting/locale options, and any caller-supplied
debug info.

Use `onException` for logging/telemetry (fires once per thrown exception; hook
errors are swallowed):

```dart
Convert.configure(Convert.config.copyWith(
  onException: (e) {
    // Send to logs or telemetry.
    // Use e.stackTrace for the original trace.
  },
));
```

Scoped override:

```dart
Convert.runScopedConfig(
  ConvertConfig.overrides(
    onException: (e) {
      // Scoped logging here.
    },
  ),
  () => Convert.toInt('oops'),
);
```

> Prefer the `tryTo*` family or pass a `defaultValue` when failures are expected.

---

## Advanced usage & recipes

### 1) Converting nested and mixed collections

```dart
final input = {
  'prices': ['1.2', 3, '4.56'],
  'attrs':  {'a': '1', 'b': 2.5, 'c': '3'},
};

final prices = Convert.toList<double>(input, mapKey: 'prices'); // [1.2,3.0,4.56]

final attrs = Convert.toMap<String, int>(
  input,
  mapKey: 'attrs',
  keyConverter: (k) => k.toString(),
  valueConverter: (v) => v is int ? v : Convert.toInt(v),
); // {'a':1,'b':2,'c':3}
```

### 2) Model parsing with map extensions

```dart
class User {
  final int id;
  final String email;
  final DateTime createdAt;

  User(this.id, this.email, this.createdAt);

  factory User.fromJson(Map<String, Object?> json) => User(
        json.getInt('id'),
        json.getString('email', alternativeKeys: ['mail']),
        json.getDateTime('created_at',
          autoDetectFormat: true, useCurrentLocale: true),
      );
}
```

### 3) Safe list indexing with fallbacks

```dart
final row = ['name', null, '42'];

final id = row.tryGetInt(1, alternativeIndices: [2]) ?? -1; // 42
```

### 4) Enum parsing shortcuts

```dart
enum Role { admin, editor, viewer }

final role = Convert.toEnum<Role>(
  'EDITOR',
  parser: Role.values.parserCaseInsensitive,
);
```

---

## Migration beta to stable

If you are upgrading from the beta (`1.0.0-dev.x`), check these behavioral
changes:

* Stack traces for `ConversionException` are preserved on throw (error
  reporters point to the original failure site).
* `ConversionException.toString()` is concise; use `fullReport()` for verbose
  JSON context + stack trace.
* `tryToType<T>()` now returns `null` for unsupported types instead of
  throwing.
* `Converter.tryTo` / `toOr` only catch `ConversionException`; other errors
  now surface.
* `runScopedConfig` no longer treats default-valued option objects as
  overrides. Use `ConvertConfig.overrides(...)` to explicitly override defaults
  or clear values.
* Core converters no longer log; use `onException` for logging/telemetry.

---

## Migration from `dart_helper_utils`

This package provides a **backwards‑compatible** static facade named `Convert` with the original method names and signatures, while offering a complete, modernized implementation.

Notable notes:

* The list/set/map conversion logic now **auto‑decodes JSON strings** when it makes sense (e.g., a `String` holding a JSON array/map).
* The `Iterable.intersect` extension mirrors historical behavior from DHU where the method name implied intersection but effectively **merged** elements (set union). That name is preserved for compatibility.
* Boolean parsing merges rules from legacy DHU and this library into a single, explicit policy.
* Prefer the new **fluent API** (`.convert`) for readable pipelines.

---

## Performance notes

* `format`/`locale` formatters are cached with a small LRU. Many unique patterns
  or locales still pay creation cost.
* Normalizing inputs (e.g., pre-trim, pre-clean) and using non-formatted
  `toNum/toInt/toDouble` where possible is fastest.
* Supplying an **elementConverter** for collections avoids repeated generic
  routing.
* `try*` methods are exception-free and cheaper when failures are expected.
* `toList<T>` and friends can convert single values by wrapping them (`T` or
  `List<T>`); use element converters for maximal control.

---

## FAQ

**Q: What happens if a conversion fails?**
A: Strict `to*` methods throw `ConversionException` unless you pass a
`defaultValue` (then the default is returned). `tryTo*` methods return `null`
or `defaultValue`. `toBool` always returns a bool and defaults to `false`.

**Q: How are ambiguous dates like `02/03/2024` handled?**
A: By `locale` (`en_US` → `MM/dd`, most others → `dd/MM`). For deterministic behavior, pass `format`.

**Q: Does `toUri` accept plain emails/phone numbers?**
A: Yes. Emails become `mailto:`; phone numbers become `tel:` with digits normalized.

**Q: Which types does `toType<T>` handle specially?**
A: `bool`, `int`, `double`, `num`, `BigInt`, `String`, `DateTime`, `Uri`. Other `T` values are cast directly if already of type `T`; otherwise a `ConversionException` is thrown.

---

## Contributing

Issues and PRs are welcome!
Please include tests where possible and keep APIs consistent with the existing style (`to*` / `tryTo*`, defaults, and context‑rich errors).

---

## License

This project is open‑source. See **LICENSE** in the repository for details.

---

## API reference

See the generated API docs on pub.dev:
`https://pub.dev/documentation/convert_object/latest/`

---
## Appendix — Full API cheat‑sheet

### Type aliases

```dart
typedef ElementConverter<T> = T Function(Object? element);
typedef DynamicConverter<T> = T Function(Object? value);
```

---

### Static facade — `Convert`

```dart
// Text
String  Convert.string(
  dynamic object, {dynamic mapKey, int? listIndex, String? defaultValue,
  ElementConverter<String>? converter});

String? Convert.tryToString(
  dynamic object, {dynamic mapKey, int? listIndex, String? defaultValue,
  ElementConverter<String>? converter});

// Numbers
num  Convert.toNum(
  dynamic object, {dynamic mapKey, int? listIndex, String? format, String? locale,
  num? defaultValue, ElementConverter<num>? converter});

num? Convert.tryToNum(
  dynamic object, {dynamic mapKey, int? listIndex, String? format, String? locale,
  num? defaultValue, ElementConverter<num>? converter});

int  Convert.toInt(
  dynamic object, {dynamic mapKey, int? listIndex, String? format, String? locale,
  int? defaultValue, ElementConverter<int>? converter});

int? Convert.tryToInt(
  dynamic object, {dynamic mapKey, int? listIndex, String? format, String? locale,
  int? defaultValue, ElementConverter<int>? converter});

double  Convert.toDouble(
  dynamic object, {dynamic mapKey, int? listIndex, String? format, String? locale,
  double? defaultValue, ElementConverter<double>? converter});

double? Convert.tryToDouble(
  dynamic object, {dynamic mapKey, int? listIndex, String? format, String? locale,
  double? defaultValue, ElementConverter<double>? converter});

// BigInt
BigInt  Convert.toBigInt(
  dynamic object, {dynamic mapKey, int? listIndex, BigInt? defaultValue,
  ElementConverter<BigInt>? converter});

BigInt? Convert.tryToBigInt(
  dynamic object, {dynamic mapKey, int? listIndex, BigInt? defaultValue,
  ElementConverter<BigInt>? converter});

// Bool  (never throws; defaults to false if not convertible)
bool   Convert.toBool(
  dynamic object, {dynamic mapKey, int? listIndex, bool? defaultValue,
  ElementConverter<bool>? converter});

bool?  Convert.tryToBool(
  dynamic object, {dynamic mapKey, int? listIndex, bool? defaultValue,
  ElementConverter<bool>? converter});

// DateTime
DateTime  Convert.toDateTime(
  dynamic object, {
    dynamic mapKey, int? listIndex, String? format, String? locale,
    bool autoDetectFormat=false, bool useCurrentLocale=false, bool utc=false,
    DateTime? defaultValue, ElementConverter<DateTime>? converter
  });

DateTime? Convert.tryToDateTime(
  dynamic object, {
    dynamic mapKey, int? listIndex, String? format, String? locale,
    bool autoDetectFormat=false, bool useCurrentLocale=false, bool utc=false,
    DateTime? defaultValue, ElementConverter<DateTime>? converter
  });

// Uri (supports email→mailto and phone→tel)
Uri   Convert.toUri(
  dynamic object, {dynamic mapKey, int? listIndex, Uri? defaultValue,
  ElementConverter<Uri>? converter});

Uri?  Convert.tryToUri(
  dynamic object, {dynamic mapKey, int? listIndex, Uri? defaultValue,
  ElementConverter<Uri>? converter});

// Collections
Map<K,V>  Convert.toMap<K,V>(
  dynamic object, {dynamic mapKey, int? listIndex, Map<K,V>? defaultValue,
  ElementConverter<K>? keyConverter, ElementConverter<V>? valueConverter});

Map<K,V>? Convert.tryToMap<K,V>(
  dynamic object, {dynamic mapKey, int? listIndex, Map<K,V>? defaultValue,
  ElementConverter<K>? keyConverter, ElementConverter<V>? valueConverter});

Set<T>  Convert.toSet<T>(
  dynamic object, {dynamic mapKey, int? listIndex, Set<T>? defaultValue,
  ElementConverter<T>? elementConverter});

Set<T>? Convert.tryToSet<T>(
  dynamic object, {dynamic mapKey, int? listIndex, Set<T>? defaultValue,
  ElementConverter<T>? elementConverter});

List<T>  Convert.toList<T>(
  dynamic object, {dynamic mapKey, int? listIndex, List<T>? defaultValue,
  ElementConverter<T>? elementConverter});

List<T>? Convert.tryToList<T>(
  dynamic object, {dynamic mapKey, int? listIndex, List<T>? defaultValue,
  ElementConverter<T>? elementConverter});

// Enums
T   Convert.toEnum<T extends Enum>(
  dynamic object, {required T Function(dynamic) parser,
  dynamic mapKey, int? listIndex, T? defaultValue, Map<String, dynamic>? debugInfo});

T?  Convert.tryToEnum<T extends Enum>(
  dynamic object, {required T Function(dynamic) parser,
  dynamic mapKey, int? listIndex, T? defaultValue, Map<String, dynamic>? debugInfo});

// Generic routing
T   Convert.toType<T>(dynamic object);
T?  Convert.tryToType<T>(dynamic object);

// Testing-helper (only for tests)
@visibleForTesting
Map<String, dynamic> Convert.buildParsingInfo({ ... });
```

---

### Top‑level functions (mirror the static API)

```dart
// Text
String  convertToString(dynamic object, {Object? mapKey, int? listIndex, String? defaultValue,
        String Function(Object?)? converter});
String? tryConvertToString(dynamic object, {Object? mapKey, int? listIndex, String? defaultValue,
        String Function(Object?)? converter});

// Numbers
num   convertToNum(dynamic object, {Object? mapKey, int? listIndex, String? format, String? locale,
        num? defaultValue, num Function(Object?)? converter});
num?  tryConvertToNum(dynamic object, {Object? mapKey, int? listIndex, String? format, String? locale,
        num? defaultValue, num Function(Object?)? converter});

int   convertToInt(dynamic object, {Object? mapKey, int? listIndex, String? format, String? locale,
        int? defaultValue, int Function(Object?)? converter});
int?  tryConvertToInt(dynamic object, {Object? mapKey, int? listIndex, String? format, String? locale,
        int? defaultValue, int Function(Object?)? converter});

double   convertToDouble(dynamic object, {Object? mapKey, int? listIndex, String? format, String? locale,
           double? defaultValue, double Function(Object?)? converter});
double?  tryConvertToDouble(dynamic object, {Object? mapKey, int? listIndex, String? format, String? locale,
           double? defaultValue, double Function(Object?)? converter});

// BigInt
BigInt   convertToBigInt(dynamic object, {Object? mapKey, int? listIndex, BigInt? defaultValue,
           BigInt Function(Object?)? converter});
BigInt?  tryConvertToBigInt(dynamic object, {Object? mapKey, int? listIndex, BigInt? defaultValue,
           BigInt Function(Object?)? converter});

// Bool
bool   convertToBool(dynamic object, {Object? mapKey, int? listIndex, bool? defaultValue,
         bool Function(Object?)? converter});
bool?  tryConvertToBool(dynamic object, {Object? mapKey, int? listIndex, bool? defaultValue,
         bool Function(Object?)? converter});

// DateTime
DateTime   convertToDateTime(dynamic object, {
            Object? mapKey, int? listIndex, String? format, String? locale,
            bool autoDetectFormat=false, bool useCurrentLocale=false, bool utc=false,
            DateTime? defaultValue, DateTime Function(Object?)? converter});
DateTime?  tryConvertToDateTime(dynamic object, {
            Object? mapKey, int? listIndex, String? format, String? locale,
            bool autoDetectFormat=false, bool useCurrentLocale=false, bool utc=false,
            DateTime? defaultValue, DateTime Function(Object?)? converter});

// Uri
Uri   convertToUri(dynamic object, {Object? mapKey, int? listIndex, Uri? defaultValue,
        Uri Function(Object?)? converter});
Uri?  tryConvertToUri(dynamic object, {Object? mapKey, int? listIndex, Uri? defaultValue,
        Uri Function(Object?)? converter});

// Collections
Map<K,V>   toMap<K,V>(dynamic object, {Object? mapKey, int? listIndex, Map<K,V>? defaultValue,
             K Function(Object?)? keyConverter, V Function(Object?)? valueConverter});
Map<K,V>?  tryToMap<K,V>(dynamic object, {Object? mapKey, int? listIndex, Map<K,V>? defaultValue,
             K Function(Object?)? keyConverter, V Function(Object?)? valueConverter});

Set<T>   convertToSet<T>(dynamic object, {Object? mapKey, int? listIndex, Set<T>? defaultValue,
           T Function(Object?)? elementConverter});
Set<T>?  tryConvertToSet<T>(dynamic object, {Object? mapKey, int? listIndex, Set<T>? defaultValue,
           T Function(Object?)? elementConverter});

List<T>   convertToList<T>(dynamic object, {Object? mapKey, int? listIndex, List<T>? defaultValue,
            T Function(Object?)? elementConverter});
List<T>?  tryConvertToList<T>(dynamic object, {Object? mapKey, int? listIndex, List<T>? defaultValue,
            T Function(Object?)? elementConverter});

// Generic
T   convertToType<T>(dynamic object);
T?  tryConvertToType<T>(dynamic object);
```

---

### Fluent API — `Converter` + `.convert` extension

```dart
// Entry point
extension ConvertExtension on Object? {
  Converter get convert;
}

class Converter {
  const Converter(Object? value, {Object? defaultValue, DynamicConverter<dynamic>? customConverter});

  // Options
  Converter withDefault(Object? value);
  Converter withConverter(DynamicConverter<dynamic> converter);

  // Navigation
  Converter fromMap(Object? key);
  Converter fromList(int index);
  Converter get decoded; // JSON-decodes if source is a String

  // Generic targets
  T  to<T>();
  T? tryTo<T>();
  T  toOr<T>(T defaultValue);

  // Primitive shortcuts
  String  convertToString();   String?  tryToString();   String  toStringOr(String defaultValue);
  num     toNum();    num?     tryToNum();    num     toNumOr(num defaultValue);
  int     toInt();    int?     tryToInt();    int     toIntOr(int defaultValue);
  double  toDouble(); double?  tryConvertToDouble(); double  toDoubleOr(double defaultValue);
  bool    toBool();   bool?    tryToBool();   bool    toBoolOr(bool defaultValue);
  BigInt  toBigInt(); BigInt?  tryConvertToBigInt(); BigInt  toBigIntOr(BigInt defaultValue);
  DateTime  toDateTime(); DateTime? tryToDateTime(); DateTime toDateTimeOr(DateTime defaultValue);
  Uri       toUri();      Uri?      tryToUri();      Uri      toUriOr(Uri defaultValue);

  // Collections
  List<T>  toList<T>({DynamicConverter<T>? elementConverter});
  List<T>? tryToList<T>({DynamicConverter<T>? elementConverter});
  Set<T>   convertToSet<T>({DynamicConverter<T>? elementConverter});
  Set<T>?  tryConvertToSet<T>({DynamicConverter<T>? elementConverter});
  Map<K,V>  toMap<K,V>({DynamicConverter<K>? keyConverter, DynamicConverter<V>? valueConverter});
  Map<K,V>? tryToMap<K,V>({DynamicConverter<K>? keyConverter, DynamicConverter<V>? valueConverter});
}
```

---

### Map extensions

```dart
// Non-nullable Map<K,V>
extension MapConversionX<K, V> on Map<K, V> {
  // Getters with inner selection and alternative keys
  String  getString(K key, {List<K>? alternativeKeys, dynamic innerKey, int? innerListIndex, String? defaultValue});
  int     getInt(K key,  {List<K>? alternativeKeys, dynamic innerKey, int? innerListIndex, int? defaultValue, String? format, String? locale});
  double  getDouble(K key, {List<K>? alternativeKeys, dynamic innerKey, int? innerListIndex, double? defaultValue, String? format, String? locale});
  num     getNum(K key, {List<K>? alternativeKeys, dynamic innerKey, int? innerListIndex, num? defaultValue, String? format, String? locale, ElementConverter<num>? converter});
  bool    getBool(K key, {List<K>? alternativeKeys, dynamic innerKey, int? innerListIndex, bool? defaultValue});
  BigInt  getBigInt(K key, {List<K>? alternativeKeys, dynamic innerKey, int? innerListIndex, BigInt? defaultValue});
  DateTime getDateTime(K key, {List<K>? alternativeKeys, dynamic innerKey, int? innerListIndex,
           String? format, String? locale, bool autoDetectFormat=false, bool useCurrentLocale=false, bool utc=false, DateTime? defaultValue});
  Uri     getUri(K key, {List<K>? alternativeKeys, dynamic innerKey, int? innerListIndex, Uri? defaultValue});

  List<T>     getList<T>(K key, {List<K>? alternativeKeys, dynamic innerKey, int? innerListIndex, List<T>? defaultValue});
  Set<T>      getSet<T>(K key,  {List<K>? alternativeKeys, dynamic innerKey, int? innerListIndex, Set<T>? defaultValue});
  Map<K2,V2>  getMap<K2,V2>(K key, {List<K>? alternativeKeys, dynamic innerKey, int? innerListIndex, Map<K2,V2>? defaultValue});

  T getEnum<T extends Enum>(K key, {required T Function(dynamic) parser,
           List<K>? alternativeKeys, dynamic innerKey, int? innerListIndex, T? defaultValue});

  // Quality-of-life
  List<V> get valuesList;
  Set<V>  get valuesSet;
  List<K> get keysList;
  Set<K>  get keysSet;

  // Parsing helpers
  T  parse<T, K2, V2>(K key, T Function(Map<K2, V2> json) converter);
  T? tryParse<T, K2, V2>(K key, T Function(Map<K2, V2> json) converter);
}

// Nullable Map<K,V> → try* getters
extension NullableMapConversionX<K, V> on Map<K, V>? {
  String?  tryGetString(...);
  int?     tryGetInt(...);
  double?  tryGetDouble(...);
  num?     tryGetNum(...);
  bool?    tryGetBool(...);
  BigInt?  tryGetBigInt(...);
  DateTime? tryGetDateTime(...);
  Uri?     tryGetUri(...);
  List<T>? tryGetList<T>(...);
  Set<T>?  tryGetSet<T>(...);
  Map<K2,V2>? tryGetMap<K2,V2>(...);
  T?       tryGetEnum<T extends Enum>(...);
}
```

---

### Iterable extensions

```dart
// On Iterable<E>
extension IterableConversionX<E> on Iterable<E> {
  // Positional getters (with optional inner map/list selection)
  String  getString(int index, {dynamic innerMapKey, int? innerIndex, String? defaultValue, ElementConverter<String>? converter});
  int     getInt(int index, {dynamic innerMapKey, int? innerIndex, String? format, String? locale, int? defaultValue, ElementConverter<int>? converter});
  double  getDouble(int index, {dynamic innerMapKey, int? innerIndex, String? format, String? locale, double? defaultValue, ElementConverter<double>? converter});
  num     getNum(int index, {dynamic innerMapKey, int? innerIndex, String? format, String? locale, num? defaultValue, ElementConverter<num>? converter});
  bool    getBool(int index, {dynamic innerMapKey, int? innerIndex, bool? defaultValue, ElementConverter<bool>? converter});
  BigInt  getBigInt(int index, {dynamic innerMapKey, int? innerIndex, BigInt? defaultValue, ElementConverter<BigInt>? converter});
  DateTime getDateTime(int index, {dynamic innerMapKey, int? innerIndex, String? format, String? locale,
           bool autoDetectFormat=false, bool useCurrentLocale=false, bool utc=false,
           DateTime? defaultValue, ElementConverter<DateTime>? converter});
  Uri     getUri(int index, {dynamic innerMapKey, int? innerIndex, Uri? defaultValue, ElementConverter<Uri>? converter});

  List<T>     getList<T>(int index, {dynamic innerMapKey, int? innerIndex, List<T>? defaultValue});
  Set<T>      getSet<T>(int index,  {dynamic innerMapKey, int? innerIndex, Set<T>? defaultValue});
  Map<K2,V2>  getMap<K2,V2>(int index, {dynamic innerMapKey, int? innerIndex, Map<K2,V2>? defaultValue});

  T getEnum<T extends Enum>(int index, {required T Function(dynamic) parser,
         dynamic innerMapKey, int? innerIndex, T? defaultValue});

  // Bulk helpers
  List<T> convertAll<T>();                       // Convert all elements via toType<T>()
  Set<E>  toMutableSet({ElementConverter<E>? converter});
  Set<E>  intersect(Iterable<dynamic> other, {ElementConverter<E>? converter}); // union-like

  // Mapping helpers (eager)
  List<R> mapList<R>(R Function(E e) mapper, {ElementConverter<R>? converter});
  List<R> mapIndexedList<R>(R Function(int i, E e) mapper, {ElementConverter<R>? converter});
}

// Nullable Iterable<E> → try* positional getters with fallbacks
extension NullableIterableConversionX<E> on Iterable<E>? {
  String?  tryGetString(int index, {List<int>? alternativeIndices, dynamic innerMapKey, int? innerIndex, String? defaultValue, ElementConverter<String>? converter});
  int?     tryGetInt(int index, {List<int>? alternativeIndices, dynamic innerMapKey, int? innerIndex, String? format, String? locale, int? defaultValue, ElementConverter<int>? converter});
  double?  tryGetDouble(int index, {List<int>? alternativeIndices, dynamic innerMapKey, int? innerIndex, String? format, String? locale, double? defaultValue, ElementConverter<double>? converter});
  num?     tryGetNum(int index, {List<int>? alternativeIndices, dynamic innerMapKey, int? innerIndex, String? format, String? locale, num? defaultValue, ElementConverter<num>? converter});
  bool?    tryGetBool(int index, {List<int>? alternativeIndices, dynamic innerMapKey, int? innerIndex, bool? defaultValue, ElementConverter<bool>? converter});
  BigInt?  tryGetBigInt(int index, {List<int>? alternativeIndices, dynamic innerMapKey, int? innerIndex, BigInt? defaultValue, ElementConverter<BigInt>? converter});
  DateTime? tryGetDateTime(int index, {List<int>? alternativeIndices, dynamic innerMapKey, int? innerIndex,
            String? format, String? locale, bool autoDetectFormat=false, bool useCurrentLocale=false, bool utc=false,
            DateTime? defaultValue, ElementConverter<DateTime>? converter});
  Uri?     tryGetUri(int index, {List<int>? alternativeIndices, dynamic innerMapKey, int? innerIndex, Uri? defaultValue, ElementConverter<Uri>? converter});

  List<T>?    tryGetList<T>(int index, {List<int>? alternativeIndices, dynamic innerMapKey, int? innerIndex, List<T>? defaultValue});
  Set<T>?     tryGetSet<T>(int index, {List<int>? alternativeIndices, dynamic innerMapKey, int? innerIndex, Set<T>? defaultValue});
  Map<K2,V2>? tryGetMap<K2,V2>(int index, {List<int>? alternativeIndices, dynamic innerMapKey, int? innerIndex, Map<K2,V2>? defaultValue});
  T?          tryGetEnum<T extends Enum>(int index, {required T Function(dynamic) parser,
                 List<int>? alternativeIndices, dynamic innerMapKey, int? innerIndex, T? defaultValue});
}

// Set helper
extension SetConvertToX<E> on Set<E>? {
  Set<R> convertTo<R>();
}
```

---

### Scope functions

```dart
extension LetExtension<T extends Object> on T {
  R let<R>(R Function(T it) block);
  T also(void Function(T it) block);
  T? takeIf(bool Function(T it) predicate);
  T? takeUnless(bool Function(T it) predicate);
}

extension LetExtensionNullable<T extends Object> on T? {
  R? let<R>(R Function(T it) block);
  R  letOr<R>(R Function(T it) block, {required R defaultValue});
  R? letNullable<R>(R? Function(T? it) block); // legacy-compat variant
  T? also(void Function(T it) block);
  T? takeIf(bool Function(T it) predicate);
  T? takeUnless(bool Function(T it) predicate);
}
```

---

### Enum helpers — `EnumParsers` & shortcuts

```dart
class EnumParsers {
  static T Function(dynamic) byName<T extends Enum>(List<T> values);
  static T Function(dynamic) fromString<T>(T Function(String) fromString);
  static T Function(dynamic) byNameOrFallback<T extends Enum>(List<T> values, T fallback);
  static T Function(dynamic) byNameCaseInsensitive<T extends Enum>(List<T> values);
  static T Function(dynamic) byIndex<T extends Enum>(List<T> values);
}

// Shortcuts on List<T extends Enum>
extension EnumValuesParsing<T extends Enum> on List<T> {
  T Function(dynamic) get parser;                    // byName
  T Function(dynamic) parserWithFallback(T fallback);
  T Function(dynamic) get parserCaseInsensitive;
  T Function(dynamic) get parserByIndex;
}
```

---

### Utilities

```dart
// JSON (String)
extension TextJsonX on String {
  Object? tryDecode(); // returns jsonDecode or original String
  dynamic decode();    // jsonDecode (throws on error)
}

// Numbers (String)
extension NumParsingTextX on String {
  num toNum();          num? tryToNum();
  int toInt();          int? tryToInt();
  double toDouble();    double? tryToDouble();

  // Localized via intl
  num toNumFormatted(String format, String? locale);
  num? tryToNumFormatted(String format, String? locale);
  int toIntFormatted(String format, String? locale);
  int? tryToIntFormatted(String format, String? locale);
  double toDoubleFormatted(String format, String? locale);
  double? tryToDoubleFormatted(String format, String? locale);
}

// Dates (String)
extension DateParsingTextX on String {
  DateTime  toDateTime();           DateTime? tryToDateTime();
  DateTime  toDateFormatted(String format, String? locale, {bool utc=false});
  DateTime? tryToDateFormatted(String format, String? locale, {bool utc=false});
  DateTime  toDateAutoFormat({String? locale, bool useCurrentLocale=false, bool utc=false});
  DateTime? tryToDateAutoFormat({String? locale, bool useCurrentLocale=false, bool utc=false});
}

// URIs (String)
extension UriParsingX on String {
  bool get isValidPhoneNumber;
  bool get isEmailAddress;
  Uri  get toPhoneUri; // tel:
  Uri  get toMailUri;  // mailto:
  Uri  get toUri;      // Uri.parse(this)
}

// JSON normalization / pretty helpers
enum DateTimeStrategy { iso8601String, millisecondsSinceEpoch, microsecondsSinceEpoch }
enum DurationStrategy { milliseconds, microseconds, iso8601 }
enum NonFiniteDoubleStrategy { string, nullValue, error }

class JsonOptions {
  const JsonOptions({
    this.encodeEnumsAsName = true,
    this.dateTimeStrategy = DateTimeStrategy.iso8601String,
    this.durationStrategy = DurationStrategy.milliseconds,
    this.nonFiniteDoubles = NonFiniteDoubleStrategy.string,
    this.stringifyUnknown = true,
    this.setsAsLists = true,
    this.dropNulls = false,
    this.sortKeys = false,
    this.detectCycles = false,
    this.cyclePlaceholder = '<cycle>',
  });

  final bool encodeEnumsAsName;
  final DateTimeStrategy dateTimeStrategy;
  final DurationStrategy durationStrategy;
  final NonFiniteDoubleStrategy nonFiniteDoubles;
  final bool stringifyUnknown;
  final bool setsAsLists;
  final bool dropNulls;
  final bool sortKeys;
  final bool detectCycles;
  final String cyclePlaceholder;
}

dynamic jsonSafe(dynamic value,
    {JsonOptions options = const JsonOptions(),
    Object? Function(dynamic object)? toEncodable});

extension JsonMapX<K, V> on Map<K, V> {
  Map<String, dynamic> toJsonMap(
      {JsonOptions options = const JsonOptions(),
      Object? Function(dynamic object)? toEncodable});
  String toJsonString(
      {String? indent,
      JsonOptions options = const JsonOptions(),
      Object? Function(dynamic object)? toEncodable});
  String get encodeWithIndent; // 2-space pretty JSON
}

extension JsonIterableX<T> on Iterable<T> {
  List<dynamic> toJsonList(
      {JsonOptions options = const JsonOptions(),
      Object? Function(dynamic object)? toEncodable});
  String toJsonString(
      {String? indent,
      JsonOptions options = const JsonOptions(),
      Object? Function(dynamic object)? toEncodable});
  String get encodeWithIndent; // 2-space pretty JSON
}

extension JsonAnyX on Object? {
  dynamic toJsonSafe(
      {JsonOptions options = const JsonOptions(),
      Object? Function(dynamic object)? toEncodable});
  String toJsonString(
      {String? indent,
      JsonOptions options = const JsonOptions(),
      Object? Function(dynamic object)? toEncodable});
}

// Booleans (Object?)
extension BoolParsingX on Object? {
  bool get asBool; // deterministic truthiness
}
```

---

### Results — `ConversionResult<T>`

```dart
class ConversionResult<T> {
  // Constructors
  factory ConversionResult.success(T value);
  factory ConversionResult.failure(ConversionException error);

  // State
  bool get isSuccess;
  bool get isFailure;

  // Access
  T   get value;            // throws if failure
  T?  get valueOrNull;      // null if failure
  T   valueOr(T defaultValue);

  ConversionException? get error;

  // Combinators
  ConversionResult<R> map<R>(R Function(T value) transform);
  ConversionResult<R> flatMap<R>(ConversionResult<R> Function(T value) next);

  // Fold
  R fold<R>({required R Function(T value) onSuccess,
             required R Function(ConversionException error) onFailure});
}
```

---

### Exceptions — `ConversionException`

```dart
try {
  final n = Convert.toInt('oops');
} on ConversionException catch (e) {
  e.toString();     // concise one-line summary
  e.fullReport();   // verbose JSON context + stack trace (safe for logs)
}
```

---

### Behavior highlights (quick)

```dart
// Booleans: Convert.toBool always returns bool (false default);
//           truthy('true','1','yes','y','on','ok','t'), falsy('false','0','no','n','off','f')
// Numbers: accepts "1234.56", "1,234", "(2,500)" → -2500, underscores/spaces ignored
// Dates: auto-detect supports ISO/RFC3339, HTTP-date (GMT), Unix epoch, slashed by locale,
//        compact yyyyMMdd[HHmm[ss]], long names via intl, time-only → today
// URIs: plain emails → mailto:, phones → tel:, http/https validation for host/path
// Collections: JSON strings auto-decoded when converting to List/Set/Map
// Generic: toType<T>() routes special types (bool,int,double,num,BigInt,String,DateTime,Uri)
```
