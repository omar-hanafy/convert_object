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

      test('rejects trailing input after a GMT date', () {
        expect(
          'Tue, 03 Jun 2008 11:05:30 GMT extra'.tryToDateAutoFormat(),
          isNull,
        );
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

      test(
        'should parse slashed dates via intl patterns when DateTime.parse fails',
        () {
          // Arrange
          const input = '12/31/2025';

          // Act
          expect(() => DateTime.parse(input), throwsA(isA<FormatException>()));
          final result = input.toDateAutoFormat(locale: 'en_US');

          // Assert
          expect(result.year, equals(2025));
          expect(result.month, equals(12));
          expect(result.day, equals(31));
        },
      );

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

      test('should honor useCurrentLocale when locale is not provided', () {
        // Arrange
        Intl.defaultLocale = 'en_GB';
        const input = '01/02/2025';

        // Act
        final result = input.toDateAutoFormat(useCurrentLocale: true);

        // Assert
        expect(result.month, equals(2));
        expect(result.day, equals(1));
      });

      test(
        'uses the other slash order when the preferred month is invalid',
        () {
          final expected = DateTime(2025, 1, 31, 14, 30);
          expect(
            '31/01/2025 14:30:00'.toDateAutoFormat(locale: 'en_US'),
            expected,
          );
          expect(
            '01/31/2025 14:30:00'.toDateAutoFormat(locale: 'en_GB'),
            expected,
          );
        },
      );

      test('accepts the hyphenated US locale for ambiguous dates', () {
        expect(
          '01/02/2025'.toDateAutoFormat(locale: 'en-US'),
          DateTime(2025, 1, 2),
        );
      });

      test('rejects a date invalid in both slash orders', () {
        expect('02/29/2023'.tryToDateAutoFormat(locale: 'en_US'), isNull);
      });
    });

    group('compact numeric forms', () {
      test('rejects impossible dates and unrelated separators', () {
        for (final text in ['2025_02_30', '20250230', '2025//02//28']) {
          expect(text.tryToDateAutoFormat(), isNull, reason: text);
        }
        expect('2024_02_29'.toDateAutoFormat(), DateTime(2024, 2, 29));
      });

      test(
        'preserves year-first dates with common separators and ISO years',
        () {
          for (final text in [
            '2025/01/31 15:30',
            '2025.01.31 15:30',
            '2025-01-31_1530',
          ]) {
            expect(text.toDateAutoFormat(), DateTime(2025, 1, 31, 15, 30));
          }
          for (final text in ['15000131', '1500-01-31']) {
            expect(text.toDateAutoFormat(), DateTime.parse(text));
          }
        },
      );

      test('reads a signed calendar-shaped number as epoch milliseconds', () {
        for (final text in ['-202501191430', '+202501191430']) {
          expect(
            text.toDateAutoFormat(utc: true),
            DateTime.fromMillisecondsSinceEpoch(int.parse(text), isUtc: true),
          );
        }
      });

      test(
        'recognizes ISO clock separators outside the heuristic year range',
        () {
          for (final text in [
            '15000131 15:30',
            '26000131 153000',
            '1500-01-31 15:30',
            '15000131T153000',
          ]) {
            expect(text.toDateAutoFormat(), DateTime.parse(text), reason: text);
          }
          const epoch = '150001311530';
          expect(
            epoch.toDateAutoFormat(utc: true),
            DateTime.fromMillisecondsSinceEpoch(int.parse(epoch), isUtc: true),
          );
          expect('15000131_1530'.tryToDateAutoFormat(), isNull);
        },
      );

      test('disambiguates twelve digits by the actual calendar day', () {
        const text = '202502302319';
        expect(
          text.toDateAutoFormat(utc: true),
          DateTime.fromMillisecondsSinceEpoch(int.parse(text), isUtc: true),
        );
        expect(
          '202402292319'.toDateAutoFormat(),
          DateTime(2024, 2, 29, 23, 19),
        );
      });

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
      for (final locale in [null, 'xx_YY']) {
        test(
          'formatted dates follow the current locale with locale=$locale',
          () {
            const format = 'MMMM d, yyyy';
            final expected = DateTime(2025, 3, 5);
            expect(
              Intl.withLocale(
                'en_US',
                () => 'March 5, 2025'.toDateFormatted(format, locale),
              ),
              expected,
            );
            expect(
              Intl.withLocale(
                'fr_FR',
                () => 'mars 5, 2025'.toDateFormatted(format, locale),
              ),
              expected,
            );
          },
        );
      }

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

      test(
        'should parse long month names without skipping when intl data is available',
        () {
          // Arrange
          const input = 'March 5, 2025';

          // Act
          final result = input.toDateAutoFormat(locale: 'en_US');

          // Assert
          expect(result.year, equals(2025));
          expect(result.month, equals(3));
          expect(result.day, equals(5));
        },
      );
    });

    group('long name formats and ordinals', () {
      test('removes English ordinal suffixes and preserves the day', () {
        for (final (ordinal, day) in [
          ('1st', 1),
          ('2nd', 2),
          ('3rd', 3),
          ('11th', 11),
        ]) {
          expect(
            'January $ordinal, 2025'.toDateAutoFormat(locale: 'en_US'),
            DateTime(2025, 1, day),
          );
        }
      });
    });

    group('time-only inputs', () {
      test('requires an hour from 1 to 12 for meridiem clocks', () {
        for (final text in [
          '13:15 AM',
          '00:30 PM',
          '00:30:15 AM',
          'January 2, 2025 13:15 AM',
        ]) {
          expect(
            text.tryToDateAutoFormat(locale: 'en_US'),
            isNull,
            reason: text,
          );
        }
        expect('12:15 PM'.toDateAutoFormat(locale: 'en_US').hour, 12);
        expect('1:15 AM'.toDateAutoFormat(locale: 'en_US').hour, 1);
        expect('٠١:١٥ م'.toDateAutoFormat(locale: 'ar_EG').hour, 13);
        expect('٠٠:٣٠ م'.tryToDateAutoFormat(locale: 'ar_EG'), isNull);
      });

      test('reads AM/PM and rejects trailing text', () {
        expect('11:30 PM'.toDateAutoFormat().hour, 23);
        expect('12:15:01 AM'.toDateAutoFormat().hour, 0);
        expect('14:30junk'.tryToDateAutoFormat(), isNull);
      });
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
