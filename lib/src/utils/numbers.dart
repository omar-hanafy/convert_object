import 'dart:collection';

import 'package:intl/intl.dart';

const int _kMaxNumberFormatCacheSize = 32;
final LinkedHashMap<String, NumberFormat> _numberFormatCache =
    LinkedHashMap<String, NumberFormat>();

NumberFormat _getNumberFormat(String format, String? locale) {
  final key = '$format|${locale ?? ''}';
  final cached = _numberFormatCache.remove(key);
  if (cached != null) {
    _numberFormatCache[key] = cached;
    return cached;
  }
  final created = NumberFormat(format, locale);
  _numberFormatCache[key] = created;
  if (_numberFormatCache.length > _kMaxNumberFormatCacheSize) {
    _numberFormatCache.remove(_numberFormatCache.keys.first);
  }
  return created;
}

/// Extension methods for parsing numeric strings with lenient formatting.
extension NumParsingTextX on String {
  String _cleanNumber() {
    var s = replaceAll('\u00A0', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .trim();
    if (s.startsWith('(') && s.endsWith(')')) {
      s = '-${s.substring(1, s.length - 1)}';
    }
    return s;
  }

  /// Parses this string into a [num] after stripping grouping characters.
  num toNum() {
    final cleaned = _cleanNumber();
    // Keep int if possible
    final n = num.parse(cleaned);
    return n;
  }

  /// Attempts [toNum], returning `null` when parsing fails.
  num? tryToNum() {
    try {
      return toNum();
    } catch (_) {
      return null;
    }
  }

  /// Parses an integer from this string.
  int toInt() => toNum().toInt();

  /// Attempts [toInt], returning `null` on failure.
  int? tryToInt() => tryToNum()?.toInt();

  /// Parses a double from this string.
  double toDouble() => toNum().toDouble();

  /// Attempts [toDouble], returning `null` on failure.
  double? tryToDouble() => tryToNum()?.toDouble();

  /// Parses this string using an [NumberFormat] described by [format] and [locale].
  num toNumFormatted(String format, String? locale) {
    final f = _getNumberFormat(format, locale);
    final parsed = f.parse(this);
    return parsed;
  }

  /// Attempts [toNumFormatted], returning `null` on failure.
  num? tryToNumFormatted(String format, String? locale) {
    try {
      return toNumFormatted(format, locale);
    } catch (_) {
      return null;
    }
  }

  /// Parses an integer using the provided numeric [format] and [locale].
  int toIntFormatted(String format, String? locale) =>
      toNumFormatted(format, locale).toInt();

  /// Attempts [toIntFormatted], returning `null` on failure.
  int? tryToIntFormatted(String format, String? locale) =>
      tryToNumFormatted(format, locale)?.toInt();

  /// Parses a double using the provided numeric [format] and [locale].
  double toDoubleFormatted(String format, String? locale) =>
      toNumFormatted(format, locale).toDouble();

  /// Attempts [toDoubleFormatted], returning `null` on failure.
  double? tryToDoubleFormatted(String format, String? locale) =>
      tryToNumFormatted(format, locale)?.toDouble();
}
