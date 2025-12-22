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