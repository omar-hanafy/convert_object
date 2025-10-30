/// Helpers to run code blocks or tests with a specific Intl locale.
///
/// Examples:
///
///   withLocale('en_US', () {
///     // expectations that rely on en_US number/date formats
///   });
///
///   final value = withLocaleReturn('fr_FR', () => someParsing());
///
///   testWithLocale('parses FR decimal', 'fr_FR', () {
///     // test body...
///   });
library;

import 'package:intl/intl.dart';
import 'package:test/test.dart';

/// Runs [body] with [locale] set as Intl.defaultLocale, restoring it afterward.
void withLocale(String locale, void Function() body) {
  final prev = Intl.getCurrentLocale();
  Intl.defaultLocale = locale;
  try {
    body();
  } finally {
    Intl.defaultLocale = prev;
  }
}

/// Like [withLocale] but returns a value from [body].
T withLocaleReturn<T>(String locale, T Function() body) {
  final prev = Intl.getCurrentLocale();
  Intl.defaultLocale = locale;
  try {
    return body();
  } finally {
    Intl.defaultLocale = prev;
  }
}

/// Defines a `test()` that runs with the given [locale].
///
/// Adds a `intl` tag automatically so you can filter/identify locale-sensitive tests.
void testWithLocale(
  String description,
  String locale,
  dynamic Function() body, {
  dynamic skip, // pass-through to test()
  Timeout? timeout,
}) {
  test(
    description,
    () => withLocale(locale, () => body()),
    tags: const ['intl'],
    skip: skip,
    timeout: timeout,
  );
}
