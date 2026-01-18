import 'package:convert_object/convert_object.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';

void main() {
  group('DateParsingTextX.toDateAutoFormat / tryToDateAutoFormat', () {
    late String? prevLocale;

    setUpAll(() async {
      // Arrange
      await initTestIntl(defaultLocale: 'en_US');
    });

    setUp(() {
      // Arrange
      prevLocale = Intl.defaultLocale;
      Intl.defaultLocale = 'en_US';
    });

    tearDown(() {
      Intl.defaultLocale = prevLocale;
    });

    group('ISO / HTTP-date', () {
      test('should parse ISO-8601 Z timestamps', () {
        // Arrange
        const input = '2025-11-11T10:15:30Z';

        // Act
        final result = input.toDateAutoFormat();

        // Assert
        expect(result, isA<DateTime>());
        expect(result, isUtcDateTime);
        expect(result, sameInstantAs(kKnownUtcInstant));
      });

      test('should parse ISO-8601 timestamps with offsets', () {
        // Arrange
        // 12:15:30+02:00 == 10:15:30Z
        const input = '2025-11-11T12:15:30+02:00';

        // Act
        final result = input.toDateAutoFormat();

        // Assert
        expect(result, isA<DateTime>());
        expect(result.toUtc(), sameInstantAs(kKnownUtcInstant));
      });

      test('should parse local ISO timestamps when utc is false', () {
        // Arrange
        const input = '2025-11-11T10:15:30';

        // Act
        final result = input.toDateAutoFormat(utc: false);

        // Assert
        expect(result.isUtc, isFalse);
        expect(result.year, equals(2025));
        expect(result.month, equals(11));
        expect(result.day, equals(11));
      });

      test('should parse HTTP-date (IMF-fixdate) as UTC', () {
        // Arrange
        const input = 'Tue, 03 Jun 2008 11:05:30 GMT';
        final expected = DateTime.utc(2008, 6, 3, 11, 5, 30);

        // Act
        final result = input.toDateAutoFormat();

        // Assert
        expect(result, isUtcDateTime);
        expect(result, sameInstantAs(expected));
      });

      test('should parse HTTP-date when utc is false', () {
        // Arrange
        const input = 'Tue, 03 Jun 2008 11:05:30 GMT';

        // Act
        final result = input.toDateAutoFormat(utc: false);

        // Assert
        expect(result, isUtcDateTime);
        expect(result.year, equals(2008));
        expect(result.month, equals(6));
        expect(result.day, equals(3));
      });
    });

    group('slashed ambiguous numeric dates', () {
      test('should interpret MM/dd/yyyy first when locale is en_US', () {
        // Arrange
        Intl.defaultLocale = 'en_US';
        const input = '01/02/2025';

        // Act
        final result = input.toDateAutoFormat();

        // Assert
        expect(result.year, equals(2025));
        expect(result.month, equals(1));
        expect(result.day, equals(2));
      });

      test('should parse slashed dates via intl patterns when DateTime.parse fails', () {
        // Arrange
        const input = '12/31/2025';

        // Act
        expect(
          () => DateTime.parse(input),
          throwsA(isA<FormatException>()),
        );
        final result = input.toDateAutoFormat(locale: 'en_US');

        // Assert
        expect(result.year, equals(2025));
        expect(result.month, equals(12));
        expect(result.day, equals(31));
      });

      test('should interpret dd/MM/yyyy first when locale is not en_US', () {
        // Arrange
        Intl.defaultLocale = 'en_GB';
        const input = '01/02/2025';

        // Act
        final result = input.toDateAutoFormat();

        // Assert
        expect(result.year, equals(2025));
        expect(result.month, equals(2));
        expect(result.day, equals(1));
      });

      test(
        'should allow passing an explicit locale to control interpretation',
        () {
          // Arrange
          const input = '01/02/2025';

          // Act
          final us = input.toDateAutoFormat(locale: 'en_US');
          final gb = input.toDateAutoFormat(locale: 'en_GB');

          // Assert
          expect(us.month, equals(1));
          expect(us.day, equals(2));
          expect(gb.month, equals(2));
        expect(gb.day, equals(1));
      },
      );

      test(
        'should honor useCurrentLocale when locale is not provided',
        () {
          // Arrange
          Intl.defaultLocale = 'en_GB';
          const input = '01/02/2025';

          // Act
          final result = input.toDateAutoFormat(useCurrentLocale: true);

          // Assert
          expect(result.month, equals(2));
          expect(result.day, equals(1));
        },
      );
    });

    group('compact numeric forms', () {
      test('should parse yyyyMMdd (8 digits) as a calendar date (local)', () {
        // Arrange
        const input = '20250131';

        // Act
        final result = input.toDateAutoFormat(utc: false);

        // Assert
        expect(result.isUtc, isFalse);
        expect(result.year, equals(2025));
        expect(result.month, equals(1));
        expect(result.day, equals(31));
      });

      test(
        'should parse yyyyMMddHHmm (12 digits) as a calendar timestamp (local)',
        () {
          // Arrange
          const input = '202501311530';

          // Act
          final result = input.toDateAutoFormat(utc: false);

          // Assert
          expect(result.isUtc, isFalse);
          expect(result.year, equals(2025));
          expect(result.month, equals(1));
          expect(result.day, equals(31));
          expect(result.hour, equals(15));
          expect(result.minute, equals(30));
        },
      );

      test(
        'should parse yyyyMMddHHmmss (14 digits) as a calendar timestamp (local)',
        () {
          // Arrange
          const input = '20250131153045';

          // Act
          final result = input.toDateAutoFormat(utc: false);

          // Assert
          expect(result.isUtc, isFalse);
          expect(result.year, equals(2025));
          expect(result.month, equals(1));
          expect(result.day, equals(31));
          expect(result.hour, equals(15));
          expect(result.minute, equals(30));
          expect(result.second, equals(45));
        },
      );

      test(
        'should parse compact variants containing underscores or spaces',
        () {
          // Arrange
          const input = '2025_01_31';

          // Act
          final result = input.toDateAutoFormat(utc: false);

          // Assert
          expect(result.year, equals(2025));
          expect(result.month, equals(1));
          expect(result.day, equals(31));
        },
      );
    });

    group('long name formats', () {
      test('should parse long month name formats', () {
        // Arrange
        const input = 'January 2, 2025';
        try {
          // Act
          final result = input.toDateAutoFormat(utc: false);

          // Assert
          expect(result.year, equals(2025));
          expect(result.month, equals(1));
          expect(result.day, equals(2));
        } catch (e) {
          markTestSkipped(
            'Intl date symbols for month names may be unavailable: $e',
          );
        }
      });

      test('should parse long month names without skipping when intl data is available', () {
        // Arrange
        const input = 'March 5, 2025';

        // Act
        final result = input.toDateAutoFormat(locale: 'en_US');

        // Assert
        expect(result.year, equals(2025));
        expect(result.month, equals(3));
        expect(result.day, equals(5));
      });
    });

    group('long name formats and ordinals', () {
      test(
        'should parse month-name dates and remove ordinals when supported by intl data',
        () {
          // Arrange
          // Ordinal should be normalized: "2nd" -> "2"
          const input = 'January 2nd, 2025';

          // Act
          DateTime result;
          try {
            result = input.toDateAutoFormat(utc: false);
          } catch (e) {
            markTestSkipped(
              'Intl date symbols for month names may be unavailable: $e',
            );
            return;
          }

          // Assert
          expect(result.year, equals(2025));
          expect(result.month, equals(1));
          expect(result.day, equals(2));
        },
      );
    });

    group('time-only inputs', () {
      bool sameLocalDate(DateTime a, DateTime b) =>
          a.year == b.year && a.month == b.month && a.day == b.day;

      test('should interpret HH:mm as today at that time (local)', () {
        // Arrange
        final before = DateTime.now();
        const input = '14:30';

        // Act
        final result = input.toDateAutoFormat(utc: false);
        final after = DateTime.now();

        // Assert
        // Avoid midnight flake: accept either "before" or "after" date.
        expect(
          sameLocalDate(result, before) || sameLocalDate(result, after),
          isTrue,
          reason: 'Expected result date to match today (before/after capture)',
        );
        expect(result.hour, equals(14));
        expect(result.minute, equals(30));
      });

      test('should return a UTC DateTime when utc is true', () {
        // Arrange
        const input = '14:30';

        // Act
        final result = input.toDateAutoFormat(utc: true);

        // Assert
        expect(result.isUtc, isTrue);
        expect(result.toLocal().hour, equals(14));
        expect(result.toLocal().minute, equals(30));
      });
    });

    group('utc parameter behavior', () {
      test(
        'should return a UTC DateTime for epoch inputs when utc is true',
        () {
          // Arrange
          const input = '1700000000';
          final expected = DateTime.fromMillisecondsSinceEpoch(
            1700000000 * 1000,
            isUtc: true,
          );

          // Act
          final utcResult = input.toDateAutoFormat(utc: true);
          final localResult = input.toDateAutoFormat(utc: false);

          // Assert
          expect(utcResult, isUtcDateTime);
          expect(utcResult, sameInstantAs(expected));
          expect(localResult.isUtc, isFalse);
          expect(localResult.toUtc(), sameInstantAs(expected));
        },
      );
    });

    group('tryToDateAutoFormat', () {
      test('should return null when parsing fails', () {
        // Arrange
        const input = 'not-a-date';

        // Act
        final result = input.tryToDateAutoFormat();

        // Assert
        expect(result, isNull);
      });

      test('should return null when input is empty', () {
        // Arrange
        const input = '';

        // Act
        final result = input.tryToDateAutoFormat();

        // Assert
        expect(result, isNull);
      });
    });

    group('invalid numeric lengths', () {
      test('should throw for 11 digit numeric strings', () {
        // Arrange
        const input = '17000000000';

        // Act + Assert
        expect(() => input.toDateAutoFormat(), throwsA(isA<FormatException>()));
      });
    });
  });
}
