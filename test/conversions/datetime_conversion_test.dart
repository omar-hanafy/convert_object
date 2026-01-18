import 'package:convert_object/convert_object.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';

void main() {
  late ConvertConfig prev;
  late String? prevIntlLocale;
  late String? prevTestLocale;

  setUpAll(() async {
    // Arrange
    prevIntlLocale = Intl.defaultLocale;

    // Act
    await initTestIntl(defaultLocale: 'en_US');

    // Assert
    expect(Intl.defaultLocale, equals('en_US'));
  });

  tearDownAll(() {
    // Arrange
    Intl.defaultLocale = prevIntlLocale;
  });

  setUp(() {
    // Arrange
    prevTestLocale = Intl.defaultLocale;
    Intl.defaultLocale = 'en_US';
    prev = Convert.configure(makeTestConfig(locale: 'en_US'));
  });

  tearDown(() {
    // Arrange
    Convert.configure(prev);
    Intl.defaultLocale = prevTestLocale;
  });

  group('Convert.toDateTime (epoch numbers)', () {
    test('should treat 10-digit numbers as seconds since epoch', () {
      // Arrange
      const seconds = 1700000000;
      final expected = DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000,
        isUtc: true,
      );

      // Act
      final utcResult = Convert.toDateTime(seconds, utc: true);
      final localResult = Convert.toDateTime(seconds);

      // Assert
      expect(utcResult, isUtcDateTime);
      expect(utcResult, sameInstantAs(expected));
      expect(localResult, sameInstantAs(expected));
      expect(localResult.isUtc, isFalse);
    });

    test('should treat 13-digit numbers as milliseconds since epoch', () {
      // Arrange
      const ms = 1700000000000;
      final expected = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

      // Act
      final utcResult = Convert.toDateTime(ms, utc: true);
      final localResult = Convert.toDateTime(ms);

      // Assert
      expect(utcResult, isUtcDateTime);
      expect(utcResult, sameInstantAs(expected));
      expect(localResult, sameInstantAs(expected));
      expect(localResult.isUtc, isFalse);
    });
  });

  group('Convert.toDateTime (explicit format)', () {
    test('should parse using an explicit format with utc true', () {
      // Arrange
      const input = '2025-01-31';

      // Act
      final result = Convert.toDateTime(input, format: 'yyyy-MM-dd', utc: true);

      // Assert
      expect(result, isUtcDateTime);
      expect(result.year, equals(2025));
      expect(result.month, equals(1));
      expect(result.day, equals(31));
      expect(result.hour, equals(0));
      expect(result.minute, equals(0));
      expect(result.second, equals(0));
    });

    test('should parse using an explicit format with utc false', () {
      // Arrange
      const input = '2025-01-31';

      // Act
      final result = Convert.toDateTime(input, format: 'yyyy-MM-dd');

      // Assert
      expect(result.isUtc, isFalse);
      expect(result.year, equals(2025));
      expect(result.month, equals(1));
      expect(result.day, equals(31));
    });

    test('explicit format should take precedence over autoDetectFormat', () {
      // Arrange
      const input = '2025-01-31';

      // Act
      final result = Convert.toDateTime(
        input,
        format: 'yyyy-MM-dd',
        autoDetectFormat: true,
      );

      // Assert
      expect(result.year, equals(2025));
      expect(result.month, equals(1));
      expect(result.day, equals(31));
    });
  });

  group('Convert.toDateTime (autoDetectFormat)', () {
    test('should parse ISO-8601 inputs and preserve the same instant', () {
      // Arrange
      const input = '2025-11-11T10:15:30Z';

      // Act
      final result = Convert.toDateTime(input, autoDetectFormat: true);

      // Assert
      expect(result, sameInstantAs(kKnownUtcInstant));
      expect(result.isUtc, isTrue);
    });

    test('should parse HTTP-date inputs and preserve the same instant', () {
      // Arrange
      const input = 'Tue, 03 Jun 2008 11:05:30 GMT';
      final expected = DateTime.utc(2008, 6, 3, 11, 5, 30);

      // Act
      final result = Convert.toDateTime(input, autoDetectFormat: true);

      // Assert
      expect(result, sameInstantAs(expected));
      expect(result.isUtc, isTrue);
    });

    test('should parse compact numeric calendar inputs (8 digits)', () {
      // Arrange
      const input = '20250131';

      // Act
      final result = Convert.toDateTime(input, autoDetectFormat: true);

      // Assert
      expect(result.isUtc, isFalse);
      expect(result.year, equals(2025));
      expect(result.month, equals(1));
      expect(result.day, equals(31));
      expect(result.hour, equals(0));
      expect(result.minute, equals(0));
      expect(result.second, equals(0));
    });

    test('should parse compact numeric calendar inputs (12 digits)', () {
      // Arrange
      const input = '202501311530';

      // Act
      final result = Convert.toDateTime(input, autoDetectFormat: true);

      // Assert
      expect(result.isUtc, isFalse);
      expect(result.year, equals(2025));
      expect(result.month, equals(1));
      expect(result.day, equals(31));
      expect(result.hour, equals(15));
      expect(result.minute, equals(30));
      expect(result.second, equals(0));
    });

    test('should parse compact numeric calendar inputs (14 digits)', () {
      // Arrange
      const input = '20250131153045';

      // Act
      final result = Convert.toDateTime(input, autoDetectFormat: true);

      // Assert
      expect(result.isUtc, isFalse);
      expect(result.year, equals(2025));
      expect(result.month, equals(1));
      expect(result.day, equals(31));
      expect(result.hour, equals(15));
      expect(result.minute, equals(30));
      expect(result.second, equals(45));
    });

    test(
      'should interpret ambiguous slashed dates using en_US semantics by default',
      () {
        // Arrange
        const input = '01/02/2025';

        // Act
        final result = Convert.toDateTime(input, autoDetectFormat: true);

        // Assert
        // en_US -> MM/dd/yyyy => Jan 2, 2025
        expect(result.year, equals(2025));
        expect(result.month, equals(1));
        expect(result.day, equals(2));
      },
    );

    test(
      'should interpret ambiguous slashed dates using en_GB semantics when config locale is en_GB',
      () {
        // Arrange
        const input = '01/02/2025';
        const overrides = ConvertConfig(locale: 'en_GB');

        // Act
        final result = withScopedConfig(
          overrides,
          () => Convert.toDateTime(input, autoDetectFormat: true),
        );

        // Assert
        // en_GB -> dd/MM/yyyy => Feb 1, 2025
        expect(result.year, equals(2025));
        expect(result.month, equals(2));
      expect(result.day, equals(1));
    },
    );

    test('should honor useCurrentLocale when enabled', () {
      // Arrange
      const input = '01/02/2025';
      Intl.defaultLocale = 'en_GB';
      final overrides = ConvertConfig.overrides(clearLocale: true);

      // Act
      final result = withScopedConfig(
        overrides,
        () => Convert.toDateTime(
          input,
          autoDetectFormat: true,
          useCurrentLocale: true,
        ),
      );

      // Assert
      expect(result.month, equals(2));
      expect(result.day, equals(1));
    });

    test('should parse time-only inputs as today at the parsed time', () {
      // Arrange
      final before = DateTime.now();

      // Act
      final result = Convert.toDateTime('14:30', autoDetectFormat: true);
      final after = DateTime.now();

      // Assert
      expect(result.hour, equals(14));
      expect(result.minute, equals(30));
      expect(result.second, equals(0));

      final matchesBefore =
          result.year == before.year &&
          result.month == before.month &&
          result.day == before.day;

      final matchesAfter =
          result.year == after.year &&
          result.month == after.month &&
          result.day == after.day;

      expect(
        matchesBefore || matchesAfter,
        isTrue,
        reason:
            'Result date should match today (guards against rare midnight boundary).',
      );
    });

    test('should respect extraAutoDetectPatterns when provided', () {
      // Arrange
      const input = '31-01-2025';

      // Baseline: should fail without extra pattern.
      final baseline = Convert.tryToDateTime(input, autoDetectFormat: true);

      const overrides = ConvertConfig(
        dates: DateOptions(extraAutoDetectPatterns: ['dd-MM-yyyy']),
      );

      // Act
      final parsed = withScopedConfig(
        overrides,
        () => Convert.toDateTime(input, autoDetectFormat: true),
      );

      // Assert
      expect(baseline, isNull);
      expect(parsed.year, equals(2025));
      expect(parsed.month, equals(1));
      expect(parsed.day, equals(31));
    });
  });

  group('Convert.toDateTime error handling', () {
    test(
      'should throw ConversionException when input is malformed and no defaultValue is provided',
      () {
        // Arrange

        // Act + Assert
        expect(
          () => Convert.toDateTime('not a date'),
          throwsConversionException(method: 'toDateTime'),
        );
      },
    );

    test(
      'should return defaultValue when input is malformed and defaultValue is provided',
      () {
        // Arrange

        // Act
        final result = Convert.toDateTime(
          'not a date',
          defaultValue: kKnownUtcInstant,
        );

        // Assert
        expect(result, equals(kKnownUtcInstant));
      },
    );

    test('should return null when tryToDateTime receives malformed input', () {
      // Arrange

      // Act
      final result = Convert.tryToDateTime('not a date');

      // Assert
      expect(result, isNull);
    });

    test(
      'should return defaultValue when tryToDateTime receives malformed input and defaultValue is provided',
      () {
        // Arrange

        // Act
        final result = Convert.tryToDateTime(
          'not a date',
          defaultValue: kKnownUtcInstant,
        );

        // Assert
        expect(result, equals(kKnownUtcInstant));
      },
    );
  });

  group('Convert.toDateTime selection (mapKey/listIndex)', () {
    test('should parse values selected by mapKey', () {
      // Arrange
      final data = <String, dynamic>{'d': '2025-11-11T10:15:30Z'};

      // Act
      final result = Convert.toDateTime(
        data,
        mapKey: 'd',
        autoDetectFormat: true,
      );

      // Assert
      expect(result, sameInstantAs(kKnownUtcInstant));
    });

    test('should parse values selected by listIndex', () {
      // Arrange
      final data = <dynamic>['2025-11-11T10:15:30Z'];

      // Act
      final result = Convert.toDateTime(
        data,
        listIndex: 0,
        autoDetectFormat: true,
      );

      // Assert
      expect(result, sameInstantAs(kKnownUtcInstant));
    });
  });
}
