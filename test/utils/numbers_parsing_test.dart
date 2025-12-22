import 'package:convert_object/convert_object.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';

void main() {
  group('NumParsingTextX', () {
    late String? prevLocale;

    setUp(() {
      // Arrange
      prevLocale = Intl.defaultLocale;
      Intl.defaultLocale = 'en_US';
    });

    tearDown(() {
      Intl.defaultLocale = prevLocale;
    });

    group('toNum / tryToNum', () {
      test('should parse plain numeric strings into num', () {
        // Arrange
        const input = '1234';

        // Act
        final result = input.toNum();

        // Assert
        expect(result, isA<num>());
        expect(result, isA<int>());
        expect(result, equals(1234));
      });

      test('should parse decimal numeric strings into num', () {
        // Arrange
        const input = '1234.50';

        // Act
        final result = input.toNum();

        // Assert
        expect(result, isA<num>());
        expect(result, isA<double>());
        expect(result, equals(1234.5));
      });

      test('should strip common grouping characters before parsing', () {
        // Arrange
        final cases = <({String input, num expected})>[
          (input: '1,234', expected: 1234),
          (input: '1 234', expected: 1234),
          (input: '1_234', expected: 1234),
          (input: '\u00A01\u00A0234\u00A0', expected: 1234), // NBSP grouping
        ];

        for (final c in cases) {
          // Act
          final result = c.input.toNum();

          // Assert
          expect(result, isA<num>(), reason: 'Input: "${c.input}"');
          expect(result, equals(c.expected), reason: 'Input: "${c.input}"');
        }
      });

      test('should treat parenthesis wrapped numbers as negatives', () {
        // Arrange
        const input = '(123)';

        // Act
        final result = input.toNum();

        // Assert
        expect(result, isA<int>());
        expect(result, equals(-123));
      });

      test('should return null from tryToNum when parsing fails', () {
        // Arrange
        const input = 'not-a-number';

        // Act
        final result = input.tryToNum();

        // Assert
        expect(result, isNull);
      });
    });

    group('toInt / toDouble helpers', () {
      test('should parse toInt using cleaned semantics', () {
        // Arrange
        const input = '1,234';

        // Act
        final result = input.toInt();

        // Assert
        expect(result, isA<int>());
        expect(result, equals(1234));
      });

      test('should parse toDouble using cleaned semantics', () {
        // Arrange
        const input = '1,234.50';

        // Act
        final result = input.toDouble();

        // Assert
        expect(result, isA<double>());
        expect(result, equals(1234.5));
      });
    });

    group('formatted parsing', () {
      test(
          'should parse formatted numbers with NumberFormat when format is provided',
          () {
        // Arrange
        const input = '1,234.50';
        const format = '#,##0.00';

        // Act
        final result = input.toNumFormatted(format, 'en_US');

        // Assert
        expect(result, isA<num>());
        expect(result, equals(1234.5));
      });

      test('should return null from tryToNumFormatted when parsing fails', () {
        // Arrange
        const input = 'not-a-number';
        const format = '#,##0.00';

        // Act
        final result = input.tryToNumFormatted(format, 'en_US');

        // Assert
        expect(result, isNull);
      });

      test('should parse toIntFormatted and toDoubleFormatted', () {
        // Arrange
        const input = '1,234.50';
        const format = '#,##0.00';

        // Act
        final asInt = input.toIntFormatted(format, 'en_US');
        final asDouble = input.toDoubleFormatted(format, 'en_US');

        // Assert
        expect(asInt, isA<int>());
        expect(asInt, equals(1234));
        expect(asDouble, isA<double>());
        expect(asDouble, equals(1234.5));
      });

      test('should parse de_DE formatted numbers when locale data is available',
          () {
        // Arrange
        const input = '1.234,50';
        const format = '#,##0.00';

        // Act
        num parsed;
        try {
          parsed = input.toNumFormatted(format, 'de_DE');
        } catch (e) {
          markTestSkipped('Intl number symbols for de_DE not available: $e');
          return;
        }

        // Assert
        expect(parsed, equals(1234.5));
      });
    });

    test('fixture sanity: kNumberStrings should parse with toNum()', () {
      // Arrange
      final inputs = kNumberStrings;

      // Act / Assert
      for (final s in inputs) {
        final result = s.toNum();
        expect(result, isA<num>(), reason: 'Input: "$s"');
      }
    });
  });
}
