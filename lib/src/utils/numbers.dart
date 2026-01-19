import 'dart:collection';

import 'package:intl/intl.dart';

/// Maximum entries in the [NumberFormat] LRU cache.
///
/// Caching avoids repeated construction of [NumberFormat] objects for the same
/// format/locale combination, which can be expensive.
const int _kMaxNumberFormatCacheSize = 32;

/// LRU cache for [NumberFormat] instances keyed by `'$format|$locale'`.
final LinkedHashMap<String, NumberFormat> _numberFormatCache =
    LinkedHashMap<String, NumberFormat>();

/// Lookup table mapping integers to their Roman numeral representations.
///
/// Includes common values up to 1000. For arbitrary conversions, use
/// [intToRomanNumeral] which handles values from 1 to 3999.
const romanNumerals = <int, String>{
  1: 'I', // One
  2: 'II', // Two
  3: 'III', // Three
  4: 'IV', // Four
  5: 'V', // Five
  6: 'VI', // Six
  7: 'VII', // Seven
  8: 'VIII', // Eight
  9: 'IX', // Nine
  10: 'X', // Ten
  11: 'XI', // Eleven
  12: 'XII', // Twelve
  13: 'XIII', // Thirteen
  14: 'XIV', // Fourteen
  15: 'XV', // Fifteen
  20: 'XX', // Twenty
  30: 'XXX', // Thirty
  40: 'XL', // Forty
  50: 'L', // Fifty
  60: 'LX', // Sixty
  70: 'LXX', // Seventy
  90: 'XC', // Ninety
  99: 'IC', // Ninety-Nine (rarely used; common alternative is XCIX)
  100: 'C', // One Hundred
  200: 'CC', // Two Hundred
  400: 'CD', // Four Hundred
  500: 'D', // Five Hundred
  600: 'DC', // Six Hundred
  900: 'CM', // Nine Hundred
  990: 'XM', // Nine Hundred Ninety (non-standard; commonly use CMXC)
  1000: 'M', // One Thousand
};

const _romanNumeralParts = <int, String>{
  1000: 'M',
  900: 'CM',
  500: 'D',
  400: 'CD',
  100: 'C',
  90: 'XC',
  50: 'L',
  40: 'XL',
  10: 'X',
  9: 'IX',
  5: 'V',
  4: 'IV',
  1: 'I',
};

// LRU-cached NumberFormat lookup to avoid repeated construction overhead.
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
///
/// These methods strip common grouping characters (commas, spaces, underscores,
/// non-breaking spaces) before parsing. Accounting-style negatives like `(123)`
/// are converted to `-123`.
///
/// Used internally by `Convert.toInt`, `Convert.toDouble`, etc.
extension NumParsingTextX on String {
  // Strips grouping separators (commas, spaces, non-breaking spaces, underscores)
  // and converts accounting-style negatives like "(123)" to "-123".
  String _cleanNumber() {
    var s = replaceAll(
      '\u00A0',
      '',
    ).replaceAll(',', '').replaceAll(' ', '').replaceAll('_', '').trim();
    if (s.startsWith('(') && s.endsWith(')')) {
      s = '-${s.substring(1, s.length - 1)}';
    }
    return s;
  }

  /// Parses this string into a [num] after stripping grouping characters.
  ///
  /// Preserves integer precision when possible (returns [int] for whole numbers).
  /// Throws [FormatException] if parsing fails.
  num toNum() {
    final cleaned = _cleanNumber();
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

  /// Parses this string as an integer, truncating any fractional component.
  ///
  /// Throws [FormatException] if the underlying numeric parse fails.
  int toInt() => toNum().toInt();

  /// Attempts [toInt], returning `null` on failure.
  int? tryToInt() => tryToNum()?.toInt();

  /// Parses this string as a double.
  ///
  /// Throws [FormatException] if parsing fails.
  double toDouble() => toNum().toDouble();

  /// Attempts [toDouble], returning `null` on failure.
  double? tryToDouble() => tryToNum()?.toDouble();

  /// Parses this string using a [NumberFormat] pattern.
  ///
  /// The [format] pattern follows [NumberFormat] conventions (e.g., `'#,##0.00'`).
  /// Uses [locale] for localized grouping and decimal separators.
  ///
  /// Throws if the string does not match the expected format.
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

  /// Parses a formatted integer using [NumberFormat].
  ///
  /// See [toNumFormatted] for parameter details.
  int toIntFormatted(String format, String? locale) =>
      toNumFormatted(format, locale).toInt();

  /// Attempts [toIntFormatted], returning `null` on failure.
  int? tryToIntFormatted(String format, String? locale) =>
      tryToNumFormatted(format, locale)?.toInt();

  /// Parses a formatted double using [NumberFormat].
  ///
  /// See [toNumFormatted] for parameter details.
  double toDoubleFormatted(String format, String? locale) =>
      toNumFormatted(format, locale).toDouble();

  /// Attempts [toDoubleFormatted], returning `null` on failure.
  double? tryToDoubleFormatted(String format, String? locale) =>
      tryToNumFormatted(format, locale)?.toDouble();
}

/// Converts an integer to its Roman numeral representation.
///
/// Supports values from `1` to `3999`. Values outside this range throw
/// [ArgumentError] since Roman numerals cannot represent zero or negatives,
/// and values 4000+ require special notation.
///
/// Example: `intToRomanNumeral(42)` returns `'XLII'`.
String intToRomanNumeral(int value) {
  if (value <= 0 || value >= 4000) {
    throw ArgumentError('Value must be between 1 and 3999');
  }
  var num = value;
  final result = StringBuffer();
  _romanNumeralParts.forEach((entryValue, numeral) {
    while (num >= entryValue) {
      result.write(numeral);
      num -= entryValue;
    }
  });
  return result.toString();
}

/// Parses a Roman numeral string into its integer value.
///
/// Expects uppercase Roman numerals (I, V, X, L, C, D, M). Handles subtractive
/// notation (e.g., `'IV'` = 4, `'IX'` = 9).
///
/// Throws if the string contains unrecognized characters.
int romanNumeralToInt(String romanNumeral) {
  final romanMap = romanNumerals.map((key, value) => MapEntry(value, key));
  var i = 0;
  var result = 0;
  while (i < romanNumeral.length) {
    if (i + 1 < romanNumeral.length &&
        romanMap.containsKey(romanNumeral.substring(i, i + 2))) {
      result += romanMap[romanNumeral.substring(i, i + 2)]!;
      i += 2;
    } else {
      result += romanMap[romanNumeral[i]]!;
      i += 1;
    }
  }
  return result;
}

/// Adds Roman numeral conversion to numeric types.
extension RomanNumeralIntX on num {
  /// Converts this number to a Roman numeral string.
  ///
  /// Truncates to integer first. Throws [ArgumentError] if the value is
  /// outside the range `1-3999`.
  String toRomanNumeral() => intToRomanNumeral(toInt());
}

/// Adds Roman numeral parsing to strings.
extension RomanNumeralStringX on String {
  /// Parses this string as a Roman numeral and returns its integer value.
  ///
  /// Throws if the string is not a valid Roman numeral.
  int get asRomanNumeralToInt => romanNumeralToInt(this);
}

/// Adds nullable-safe Roman numeral parsing to strings.
extension RomanNumeralNullableStringX on String? {
  /// Parses this string as a Roman numeral, returning `null` if the string is `null`.
  ///
  /// Throws if the non-null string is not a valid Roman numeral.
  int? get asRomanNumeralToInt =>
      this == null ? null : romanNumeralToInt(this!);
}
