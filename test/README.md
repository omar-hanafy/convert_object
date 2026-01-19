# convert_object — Test Suite

This folder contains unit + integration tests for the `convert_object` package.

## Running tests

From the package root:

```bash
dart pub get
dart test
````

Helpful options:

```bash
dart test -r expanded
dart test -j 1
```

## Conventions

### 1) Prefer public API imports

Tests should generally import:

```dart
import 'package:convert_object/convert_object.dart';
```

Avoid importing `lib/src/...` directly unless you’re intentionally testing internals.

### 2) Isolate global + zone config

`ConvertConfig` supports global configuration and zone-scoped overrides.

**Rule:** each test must not leak config changes.

Recommended pattern:

```dart
late ConvertConfig _prev;

setUp(() {
  _prev = Convert.configure(makeTestConfig());
});

tearDown(() {
  Convert.configure(_prev);
});
```

If you need per-test overrides:

```dart
final result = Convert.runScopedConfig(
  makeTestConfig(uri: const UriOptions(allowRelative: false)),
  () => Convert.toUri('https://example.com'),
);
```

### 3) Locale-sensitive tests

Some numeric/date parsing depends on `intl` locale.

Use:

* `Intl.defaultLocale = 'en_US'` (or the locale you’re testing)
* `await initTestIntl()` in `setUpAll()` when you need date symbol initialization for multiple locales.

Example:

```dart
setUpAll(() async {
  await initTestIntl(defaultLocale: 'en_US');
});
```

### 4) Avoid timezone-dependent assertions

DateTime parsing may produce local times depending on inputs + `utc` flags.

Prefer assertions against:

* `.toUtc()` instants, or
* specific components only when unavoidable.

Helpers in `test/helpers/matchers.dart` include:

* `sameInstantAs(DateTime)`
* `isUtcDateTime`

### 5) Test data helpers

Shared fixtures and utilities live in:

* `test/helpers/fixtures.dart`
* `test/helpers/test_models.dart`
* `test/helpers/test_enums.dart`
* `test/helpers/matchers.dart`

Use them for consistent datasets and matchers across the suite.

## API to test matrix

This matrix tracks coverage of the public API and core utilities.

| Area                  | APIs                                                              | Tests                                                                                                                                                                                                          |
|-----------------------|-------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Convert facade        | `Convert.*` primitives, collections, enums, uri, datetime, toType | `test/core/convert_facade_test.dart`, `test/conversions/*_conversion_test.dart`, `test/core/convert_to_type_routing_test.dart`, `test/core/enum_parsers_test.dart`, `test/conversions/collections_*_test.dart` |
| Converter fluent API  | `Converter`, `.convert`, chaining, defaults                       | `test/core/converter_fluent_api_test.dart`, `test/extensions/object_convert_extension_test.dart`                                                                                                               |
| Top level functions   | `convertTo*` and `tryConvertTo*`                                  | `test/core/top_level_functions_test.dart`                                                                                                                                                                      |
| Config and registry   | `ConvertConfig`, overrides, merge, hooks, registry                | `test/config/options_merge_test.dart`, `test/config/convert_config_scoping_test.dart`, `test/config/on_exception_hook_test.dart`, `test/config/type_registry_test.dart`                                        |
| Extensions - map      | `get*`, `tryGet*`, parse helpers                                  | `test/extensions/map_extensions_test.dart`                                                                                                                                                                     |
| Extensions - iterable | `get*`, `tryGet*`, convertAll, mapList                            | `test/extensions/iterable_extensions_test.dart`                                                                                                                                                                |
| Extensions - let      | `let`, `also`, `takeIf`, `takeUnless`                             | `test/extensions/let_extensions_test.dart`                                                                                                                                                                     |
| Utils - numbers       | parsing, formatted, roman numerals                                | `test/utils/numbers_parsing_test.dart`                                                                                                                                                                         |
| Utils - dates         | ISO, formatted, auto detect                                       | `test/utils/dates_parsing_iso_epoch_test.dart`, `test/utils/dates_auto_format_test.dart`                                                                                                                       |
| Utils - bools         | `asBool`                                                          | `test/utils/bools_as_bool_test.dart`                                                                                                                                                                           |
| Utils - uri           | `isEmailAddress`, `isValidPhoneNumber`, conversions               | `test/utils/uri_parsing_utils_test.dart`                                                                                                                                                                       |
| Utils - json          | `tryDecode`, jsonSafe, map and iterable helpers                   | `test/utils/json_try_decode_test.dart`, `test/utils/map_pretty_json_safe_test.dart`                                                                                                                            |
| Exceptions            | `ConversionException`                                             | `test/exceptions/conversion_exception_test.dart`                                                                                                                                                               |
| Results               | `ConversionResult`                                                | `test/result/conversion_result_test.dart`                                                                                                                                                                      |
