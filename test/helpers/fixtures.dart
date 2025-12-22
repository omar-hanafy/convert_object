/// Shared fixtures and small utilities for convert_object tests.
///
/// Keep this file focused on:
/// - stable inputs (maps, lists, JSON strings)
/// - locale/config helpers that reduce boilerplate
library;

import 'dart:async';

import 'package:convert_object/convert_object.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Initializes Intl date formatting data for common locales used in tests.
///
/// Call from `setUpAll()` in test files that depend on localized month/day names.
Future<void> initTestIntl({
  String defaultLocale = 'en_US',
  List<String> localesToInit = const ['en_US', 'en_GB', 'de_DE', 'fr_FR'],
}) async {
  Intl.defaultLocale = defaultLocale;

  // In most pure-Dart test environments, initializeDateFormatting works fine.
  // If the runtime cannot load symbols, we swallow errors so tests that don't
  // need them still run.
  try {
    for (final loc in localesToInit) {
      await initializeDateFormatting(loc);
    }
  } catch (_) {
    // Ignore. Tests that require locale symbols should ensure their environment
    // supports it.
  }
}

/// A baseline test config that aims to be predictable.
///
/// You can override any piece via the named params.
ConvertConfig makeTestConfig({
  String? locale = 'en_US',
  NumberOptions numbers = const NumberOptions(),
  DateOptions dates = const DateOptions(),
  BoolOptions bools = const BoolOptions(),
  UriOptions uri = const UriOptions(),
  TypeRegistry registry = const TypeRegistry.empty(),
  void Function(ConversionException error)? onException,
}) {
  return ConvertConfig(
    locale: locale,
    numbers: numbers,
    dates: dates,
    bools: bools,
    uri: uri,
    registry: registry,
    onException: onException,
  );
}

/// Runs [body] inside a zone-scoped config without permanently mutating globals.
T withScopedConfig<T>(ConvertConfig overrides, T Function() body) {
  return Convert.runScopedConfig(overrides, body);
}

/// Restores global config after a block. Useful when a test needs `configure()`.
T withGlobalConfig<T>(ConvertConfig config, T Function() body) {
  final prev = Convert.configure(config);
  try {
    return body();
  } finally {
    Convert.configure(prev);
  }
}

/// ----------------------------
/// Common fixture values
/// ----------------------------

/// A nested map useful for exercising mapKey/listIndex logic.
final Map<String, dynamic> kNestedMap = <String, dynamic>{
  'id': '42',
  'name': 'Omar',
  'active': 'true',
  'score': '1,234.50',
  'meta': <String, dynamic>{
    'age': '30',
    'created': '2025-11-11T10:15:30Z',
    'tags': <dynamic>['a', 'b', 'c'],
    'coords': <String, dynamic>{'lat': '30.0444', 'lng': '31.2357'},
  },
  'items': <dynamic>[
    <String, dynamic>{'price': '10.0', 'qty': '2'},
    <String, dynamic>{'price': '5.5', 'qty': 4},
  ],
};

/// Same data but as a JSON string (used to test JSON decode paths).
const String kNestedMapJson = '''
{
  "id": "42",
  "name": "Omar",
  "active": "true",
  "score": "1,234.50",
  "meta": {
    "age": "30",
    "created": "2025-11-11T10:15:30Z",
    "tags": ["a", "b", "c"],
    "coords": {"lat": "30.0444", "lng": "31.2357"}
  },
  "items": [
    {"price": "10.0", "qty": "2"},
    {"price": "5.5", "qty": 4}
  ]
}
''';

/// Useful list fixtures for Iterable conversions.
final List<dynamic> kMixedList = <dynamic>[
  1,
  '2',
  3.0,
  '004',
  true,
  'false',
  null,
];

/// A JSON list fixture (tests `.decoded` and decodeInput list branches).
const String kJsonList = '[1, "2", 3, "004", true, "false", null]';

/// Number parsing fixtures (plain + formatted-looking strings).
const List<String> kNumberStrings = <String>[
  '1234',
  '1,234',
  '1 234',
  '1_234',
  '(123)',
  '\u00A01\u00A0234\u00A0', // NBSP grouping
];

/// Bool parsing fixtures.
const List<Object?> kTruthyValues = <Object?>[
  true,
  1,
  10,
  'true',
  'TRUE',
  ' yes ',
  'y',
  'on',
  'ok',
  't',
];

const List<Object?> kFalsyValues = <Object?>[
  false,
  0,
  -1, // default BoolOptions: numericPositiveIsTrue => -1 is false
  'false',
  'FALSE',
  ' no ',
  'n',
  'off',
  'f',
  '0',
];

/// Date fixtures (ISO, HTTP-date, compact numeric, slashed, time-only).
const List<String> kDateStringsAutoDetect = <String>[
  '2025-11-11T10:15:30Z',
  'Tue, 03 Jun 2008 11:05:30 GMT',
  '20250131',
  '202501311530',
  '20250131153045',
  '01/02/2025', // ambiguous; interpretation depends on locale
  '14:30', // time-only => today at 14:30 (local)
];

/// URI fixtures.
const List<String> kUriStrings = <String>[
  'https://example.com',
  'http://example.com/path?q=1',
  'example.com',
  '/relative/path',
  'user@example.com',
  '+1 (555) 123-4567',
];

/// A known timestamp used across date tests.
final DateTime kKnownUtcInstant = DateTime.utc(2025, 11, 11, 10, 15, 30);
