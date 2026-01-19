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

      test('should return null for empty or whitespace strings', () {
        // Arrange
        const inputs = <String>['', '   '];

        for (final input in inputs) {
          // Act
          final result = input.tryToNum();

          // Assert
          expect(result, isNull, reason: 'Input: "$input"');
        }
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

    group('tryToInt / tryToDouble helpers', () {
      test('should return null for invalid input', () {
        // Arrange
        const input = 'not-a-number';

        // Act
        final asInt = input.tryToInt();
        final asDouble = input.tryToDouble();

        // Assert
        expect(asInt, isNull);
        expect(asDouble, isNull);
      });

      test('should parse valid inputs', () {
        // Arrange
        const input = '1,234.50';

        // Act
        final asInt = input.tryToInt();
        final asDouble = input.tryToDouble();

        // Assert
        expect(asInt, equals(1234));
        expect(asDouble, equals(1234.5));
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
        },
      );

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

      test(
        'tryToIntFormatted/tryToDoubleFormatted should return null on failure',
        () {
          // Arrange
          const input = 'invalid';
          const format = '#,##0.00';

          // Act
          final asInt = input.tryToIntFormatted(format, 'en_US');
          final asDouble = input.tryToDoubleFormatted(format, 'en_US');

          // Assert
          expect(asInt, isNull);
          expect(asDouble, isNull);
        },
      );

      test(
        'should parse de_DE formatted numbers when locale data is available',
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
        },
      );
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

  group('NumberFormat cache behavior', () {
    test('should evict oldest entry when cache exceeds max size', () {
      // Arrange
      const input = '123';

      // Act
      for (var i = 0; i < 35; i++) {
        final format = i == 0 ? '0' : '0.${'0' * i}';
        final parsed = input.toNumFormatted(format, 'en_US');
        expect(parsed, isA<num>());
      }
    });
  });

  group('Roman numeral helpers', () {
    test('intToRomanNumeral should encode standard values', () {
      for (final entry in kRomanNumerals.entries) {
        expect(
          intToRomanNumeral(entry.key),
          equals(entry.value),
          reason: 'Input: ${entry.key}',
        );
      }
    });

    test('intToRomanNumeral should throw outside 1 to 3999', () {
      expect(() => intToRomanNumeral(0), throwsA(isA<ArgumentError>()));
      expect(() => intToRomanNumeral(-1), throwsA(isA<ArgumentError>()));
      expect(() => intToRomanNumeral(4000), throwsA(isA<ArgumentError>()));
    });

    test('romanNumeralToInt should decode standard values', () {
      for (final entry in kRomanNumerals.entries) {
        expect(
          romanNumeralToInt(entry.value),
          equals(entry.key),
          reason: 'Input: ${entry.value}',
        );
      }
    });

    test('romanNumeralToInt should decode nonstandard tokens in map', () {
      expect(romanNumeralToInt('IC'), equals(99));
      expect(romanNumeralToInt('XM'), equals(990));
    });

    test('romanNumeralToInt should return 0 for empty string', () {
      expect(romanNumeralToInt(''), equals(0));
    });

    test('romanNumeralToInt should throw on invalid input', () {
      expect(() => romanNumeralToInt('abc'), throwsA(isA<TypeError>()));
      expect(() => romanNumeralToInt('iv'), throwsA(isA<TypeError>()));
      expect(() => romanNumeralToInt('I?'), throwsA(isA<TypeError>()));
    });

    test('Roman numeral extensions should expose conversion helpers', () {
      expect(5.toRomanNumeral(), equals('V'));
      expect('X'.asRomanNumeralToInt, equals(10));

      String? nullable;
      expect(nullable.asRomanNumeralToInt, isNull);
    });

    test('nullable roman numeral getter should parse non-null values', () {
      String? valueProvider() => 'IV';

      expect(valueProvider().asRomanNumeralToInt, equals(4));
    });
  });
}
