import 'package:convert_object/src/utils/numbers.dart';
import 'package:test/test.dart';

void main() {
  group('NumParsingStringX', () {
    test('basic toNum / toInt / toDouble', () {
      expect('1234'.toNum(), 1234);
      expect('1234'.toInt(), 1234);
      expect('1234'.toDouble(), 1234.0);
    });

    test('handles commas and spaces (US style)', () {
      expect('1,234.56'.toNum(), 1234.56);
      expect('  1,234  '.toInt(), 1234);
      // NBSP (U+00A0) is removed as well
      expect('1\u00A0234'.toInt(), 1234);
    });

    test('negative numbers', () {
      expect('-10'.toNum(), -10);
      expect('-10'.toInt(), -10);
      expect('-10.75'.toDouble(), -10.75);
    });

    test('tryToNum returns null for non-numeric', () {
      expect('abc'.tryToNum(), isNull);
      expect('abc'.tryToInt(), isNull);
      expect('abc'.tryToDouble(), isNull);
    });

    test('formatted parsing with locale (en_US)', () {
      // Formats are handled by NumberFormat; this respects grouping/decimal.
      expect('1,234.5'.toNumFormatted('#,##0.###', 'en_US'), 1234.5);
      expect('1,234'.toIntFormatted('#,##0', 'en_US'), 1234);
      expect('1,234.56'.toDoubleFormatted('#,##0.##', 'en_US'), 1234.56);
    });

    test('tryToNumFormatted returns null on mismatch', () {
      expect('abc'.tryToNumFormatted('#,##0.##', 'en_US'), isNull);
    });
  });
}
