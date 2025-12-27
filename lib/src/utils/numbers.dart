import 'dart:collection';

import 'package:intl/intl.dart';

const int _kMaxNumberFormatCacheSize = 32;
final LinkedHashMap<String, NumberFormat> _numberFormatCache =
    LinkedHashMap<String, NumberFormat>();

/// A map of integers to Roman numeral representations.
///
/// This map is used to convert integers into their corresponding Roman numeral forms.
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

/// Converts an integer into a Roman numeral string.
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

/// Converts a Roman numeral string into an integer.
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

/// Roman numeral helpers for integers.
extension RomanNumeralIntX on num {
  /// Converts this integer to a Roman numeral string.
  String toRomanNumeral() => intToRomanNumeral(toInt());
}

/// Roman numeral helpers for strings.
extension RomanNumeralStringX on String {
  /// Returns the integer value of the Roman numeral string.
  int get asRomanNumeralToInt => romanNumeralToInt(this);
}

/// Roman numeral helpers for nullable strings.
extension RomanNumeralNullableStringX on String? {
  /// Returns the integer value of the Roman numeral string, or `null`.
  int? get asRomanNumeralToInt =>
      this == null ? null : romanNumeralToInt(this!);
}
