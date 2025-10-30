import 'package:intl/intl.dart';

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

  num toNum() {
    final cleaned = _cleanNumber();
    // Keep int if possible
    final n = num.parse(cleaned);
    return n;
  }

  num? tryToNum() {
    try {
      return toNum();
    } catch (_) {
      return null;
    }
  }

  int toInt() => toNum().toInt();

  int? tryToInt() => tryToNum()?.toInt();

  double toDouble() => toNum().toDouble();

  double? tryToDouble() => tryToNum()?.toDouble();

  num toNumFormatted(String format, String? locale) {
    final f = NumberFormat(format, locale);
    final parsed = f.parse(this);
    return parsed;
  }

  num? tryToNumFormatted(String format, String? locale) {
    try {
      return toNumFormatted(format, locale);
    } catch (_) {
      return null;
    }
  }

  int toIntFormatted(String format, String? locale) =>
      toNumFormatted(format, locale).toInt();

  int? tryToIntFormatted(String format, String? locale) =>
      tryToNumFormatted(format, locale)?.toInt();

  double toDoubleFormatted(String format, String? locale) =>
      toNumFormatted(format, locale).toDouble();

  double? tryToDoubleFormatted(String format, String? locale) =>
      tryToNumFormatted(format, locale)?.toDouble();
}
