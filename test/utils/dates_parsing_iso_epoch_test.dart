import 'package:convert_object/convert_object.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';

void main() {
  group('DateParsingTextX (ISO + formatted + epoch)', () {
    late String? prevLocale;

    setUp(() {
      // Arrange
      prevLocale = Intl.defaultLocale;
      Intl.defaultLocale = 'en_US';
    });

    tearDown(() {
      Intl.defaultLocale = prevLocale;
    });

    group('toDateTime / tryToDateTime', () {
      test('should parse ISO-8601 strings using DateTime.parse', () {
        // Arrange
        const input = '2025-11-11T10:15:30Z';

        // Act
        final result = input.toDateTime();

        // Assert
        expect(result, isA<DateTime>());
        expect(result, isUtcDateTime);
        expect(result, sameInstantAs(kKnownUtcInstant));
      });

      test('should return null from tryToDateTime when parsing fails', () {
        // Arrange
        const input = 'not-a-date';

        // Act
        final result = input.tryToDateTime();

        // Assert
        expect(result, isNull);
      });
    });

    group('toDateFormatted / tryToDateFormatted', () {
      test(
          'should parse a date using a provided format in local time by default',
          () {
        // Arrange
        const input = '2025-01-31';
        const format = 'yyyy-MM-dd';

        // Act
        final result = input.toDateFormatted(format, 'en_US');

        // Assert
        expect(result, isA<DateTime>());
        expect(result.isUtc, isFalse);
        expect(result.year, equals(2025));
        expect(result.month, equals(1));
        expect(result.day, equals(31));
        expect(result.hour, equals(0));
        expect(result.minute, equals(0));
      });

      test(
          'should parse a date using a provided format as UTC when utc is true',
          () {
        // Arrange
        const input = '2025-01-31';
        const format = 'yyyy-MM-dd';
        final expected = DateTime.utc(2025, 1, 31);

        // Act
        final result = input.toDateFormatted(format, 'en_US', utc: true);

        // Assert
        expect(result, isUtcDateTime);
        expect(result, sameInstantAs(expected));
      });

      test('should return null from tryToDateFormatted when parsing fails', () {
        // Arrange
        const input = 'invalid';
        const format = 'yyyy-MM-dd';

        // Act
        final result = input.tryToDateFormatted(format, 'en_US');

        // Assert
        expect(result, isNull);
      });
    });

    group('toDateAutoFormat epoch digits', () {
      test('should parse 9–10 digit epoch seconds when utc is true', () {
        // Arrange
        const input = '1700000000';
        final expected =
            DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000, isUtc: true);

        // Act
        final result = input.toDateAutoFormat(utc: true);

        // Assert
        expect(result, isUtcDateTime);
        expect(result, sameInstantAs(expected));
      });

      test('should parse 12–13 digit epoch milliseconds when utc is true', () {
        // Arrange
        const input = '1700000000000';
        final expected =
            DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);

        // Act
        final result = input.toDateAutoFormat(utc: true);

        // Assert
        expect(result, isUtcDateTime);
        expect(result, sameInstantAs(expected));
      });

      test('should not treat yyyyMMddHHmm (12 digits) as epoch milliseconds',
          () {
        // Arrange
        const input = '202501311530';

        // Act
        final result = input.toDateAutoFormat(utc: false);

        // Assert
        // Deterministic: compare local components only.
        expect(result.isUtc, isFalse);
        expect(result.year, equals(2025));
        expect(result.month, equals(1));
        expect(result.day, equals(31));
        expect(result.hour, equals(15));
        expect(result.minute, equals(30));
      });
    });
  });
}
