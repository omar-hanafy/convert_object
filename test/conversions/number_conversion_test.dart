import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';

class _NumCase {
  const _NumCase(this.input, this.expected);
  final String input;
  final num expected;
}

class _IntCase {
  const _IntCase(this.input, this.expected);
  final Object? input;
  final int expected;
}

class _DoubleCase {
  const _DoubleCase(this.input, this.expected);
  final Object? input;
  final double expected;
}

void main() {
  late ConvertConfig prev;

  setUp(() {
    // Arrange
    prev = Convert.configure(makeTestConfig(locale: 'en_US'));
  });

  tearDown(() {
    // Arrange
    Convert.configure(prev);
  });

  group('Convert.toNum', () {
    test('should parse cleaned numeric strings', () {
      // Arrange
      final cases = <_NumCase>[
        const _NumCase('1234', 1234),
        const _NumCase('1,234', 1234),
        const _NumCase('1 234', 1234),
        const _NumCase('1_234', 1234),
        const _NumCase('(123)', -123),
        const _NumCase('\u00A01\u00A0234\u00A0', 1234), // NBSP grouping
      ];

      for (final c in cases) {
        // Act
        final result = Convert.toNum(c.input);

        // Assert
        expect(result, isA<num>());
        expect(result, equals(c.expected));
      }
    });

    test('should handle numeric input values', () {
      // Arrange

      // Act
      final a = Convert.toNum(12);
      final b = Convert.toNum(12.5);

      // Assert
      expect(a, isA<num>());
      expect(a, equals(12));
      expect(b, isA<num>());
      expect(b, equals(12.5));
    });

    test('should support mapKey and listIndex selection', () {
      // Arrange
      final data = <String, dynamic>{
        'n': ['1,234'],
      };

      // Act
      final result = Convert.toNum(data, mapKey: 'n', listIndex: 0);

      // Assert
      expect(result, isA<num>());
      expect(result, equals(1234));
    });

    test(
        'should parse locale-formatted numbers when format and locale are provided',
        () {
      // Arrange
      const input = '1.234,5';

      // Act
      final result = Convert.toNum(
        input,
        format: '#,##0.###',
        locale: 'de_DE',
      );

      // Assert
      expect(result, isA<num>());
      expect(result, equals(1234.5));
    });

    test(
        'should use config defaultFormat/defaultLocale when format/locale are omitted',
        () {
      // Arrange
      const input = '1.234,5';
      final overrides = const ConvertConfig(
        numbers: NumberOptions(
          defaultFormat: '#,##0.###',
          defaultLocale: 'de_DE',
          tryFormattedFirst: true,
        ),
      );

      // Act
      final result = withScopedConfig(overrides, () => Convert.toNum(input));

      // Assert
      expect(result, equals(1234.5));
    });

    test(
        'should throw ConversionException when input is malformed and no defaultValue is provided',
        () {
      // Arrange

      // Act + Assert
      expect(
        () => Convert.toNum('abc'),
        throwsConversionException(method: 'toNum'),
      );
    });

    test(
        'should return defaultValue when input is malformed and defaultValue is provided',
        () {
      // Arrange

      // Act
      final result = Convert.toNum('abc', defaultValue: 7);

      // Assert
      expect(result, equals(7));
    });
  });

  group('Convert.tryToNum', () {
    test('should return null when input is malformed', () {
      // Arrange

      // Act
      final result = Convert.tryToNum('abc');

      // Assert
      expect(result, isNull);
    });

    test(
        'should return defaultValue when input is malformed and defaultValue is provided',
        () {
      // Arrange

      // Act
      final result = Convert.tryToNum('abc', defaultValue: 7);

      // Assert
      expect(result, equals(7));
    });
  });

  group('Convert.toInt', () {
    test(
        'should parse integers from strings and clean common grouping characters',
        () {
      // Arrange
      final cases = <_IntCase>[
        const _IntCase('1234', 1234),
        const _IntCase('1,234', 1234),
        const _IntCase('1 234', 1234),
        const _IntCase('1_234', 1234),
        const _IntCase('(123)', -123),
        const _IntCase('1,234.50', 1234),
      ];

      for (final c in cases) {
        // Act
        final result = Convert.toInt(c.input);

        // Assert
        expect(result, isA<int>());
        expect(result, equals(c.expected));
      }
    });

    test('should truncate numeric input values when converting to int', () {
      // Arrange

      // Act
      final a = Convert.toInt(12.9);
      final b = Convert.toInt(-12.9);

      // Assert
      expect(a, equals(12));
      expect(b, equals(-12));
    });

    test('should support mapKey and listIndex selection', () {
      // Arrange
      final data = <String, dynamic>{
        'n': ['1,234.50'],
      };

      // Act
      final result = Convert.toInt(data, mapKey: 'n', listIndex: 0);

      // Assert
      expect(result, equals(1234));
    });

    test(
        'should parse locale-formatted integers when format and locale are provided',
        () {
      // Arrange
      const input = '1.234,5';

      // Act
      final result = Convert.toInt(
        input,
        format: '#,##0.###',
        locale: 'de_DE',
      );

      // Assert
      expect(result, equals(1234));
    });

    test('should behave consistently when tryFormattedFirst is toggled', () {
      // Arrange
      const input = '1.234,5';

      final cfgTryFirst = const ConvertConfig(
        numbers: NumberOptions(
          defaultFormat: '#,##0.###',
          defaultLocale: 'de_DE',
          tryFormattedFirst: true,
        ),
      );

      final cfgPlainFirst = const ConvertConfig(
        numbers: NumberOptions(
          defaultFormat: '#,##0.###',
          defaultLocale: 'de_DE',
          tryFormattedFirst: false,
        ),
      );

      // Act
      final a = withScopedConfig(cfgTryFirst, () => Convert.toInt(input));
      final b = withScopedConfig(cfgPlainFirst, () => Convert.toInt(input));

      // Assert
      expect(a, equals(1234));
      expect(b, equals(1234));
    });

    test(
        'should throw ConversionException when input is malformed and no defaultValue is provided',
        () {
      // Arrange

      // Act + Assert
      expect(
        () => Convert.toInt('abc'),
        throwsConversionException(method: 'toInt'),
      );
    });

    test('should preserve the underlying error and stack trace', () {
      // Arrange
      ConversionException? thrown;

      // Act
      try {
        Convert.toInt('abc');
      } catch (e) {
        thrown = e as ConversionException;
      }

      // Assert
      expect(thrown, isNotNull);
      expect(thrown!.error, isA<FormatException>());
      expect(thrown.stackTrace.toString(), contains('numbers.dart'));
      expect(thrown.stackTrace.toString(), isNot(contains('_fail')));
    });

    test('should include mapKey and listIndex in error context', () {
      // Arrange
      final data = <String, dynamic>{
        'n': <dynamic>['abc'],
      };
      ConversionException? thrown;

      // Act
      try {
        Convert.toInt(data, mapKey: 'n', listIndex: 0);
      } catch (e) {
        thrown = e as ConversionException;
      }

      // Assert
      expect(thrown, isNotNull);
      expect(thrown!.error, isA<FormatException>());
      expect(thrown.context['mapKey'], equals('n'));
      expect(thrown.context['listIndex'], equals(0));
    });

    test('should wrap custom converter errors in ConversionException', () {
      // Arrange
      ConversionException? thrown;

      // Act
      try {
        Convert.toInt(
          'x',
          converter: (_) => throw StateError('boom'),
        );
      } catch (e) {
        thrown = e as ConversionException;
      }

      // Assert
      expect(thrown, isNotNull);
      expect(thrown!.error, isA<StateError>());
      expect(thrown.context['method'], equals('toInt'));
    });

    test(
        'should return defaultValue when input is malformed and defaultValue is provided',
        () {
      // Arrange

      // Act
      final result = Convert.toInt('abc', defaultValue: 7);

      // Assert
      expect(result, equals(7));
    });
  });

  group('Convert.tryToInt', () {
    test('should return null when input is malformed', () {
      // Arrange

      // Act
      final result = Convert.tryToInt('abc');

      // Assert
      expect(result, isNull);
    });

    test(
        'should return defaultValue when input is malformed and defaultValue is provided',
        () {
      // Arrange

      // Act
      final result = Convert.tryToInt('abc', defaultValue: 7);

      // Assert
      expect(result, equals(7));
    });
  });

  group('Convert.toDouble', () {
    test(
        'should parse doubles from strings and clean common grouping characters',
        () {
      // Arrange
      final cases = <_DoubleCase>[
        const _DoubleCase('1234', 1234.0),
        const _DoubleCase('1,234.50', 1234.5),
        const _DoubleCase('(123)', -123.0),
      ];

      for (final c in cases) {
        // Act
        final result = Convert.toDouble(c.input);

        // Assert
        expect(result, isA<double>());
        expect(result, equals(c.expected));
      }
    });

    test('should support mapKey and listIndex selection', () {
      // Arrange
      final data = <String, dynamic>{
        'n': ['1,234.50'],
      };

      // Act
      final result = Convert.toDouble(data, mapKey: 'n', listIndex: 0);

      // Assert
      expect(result, equals(1234.5));
    });

    test(
        'should parse locale-formatted doubles when format and locale are provided',
        () {
      // Arrange
      const input = '1.234,5';

      // Act
      final result = Convert.toDouble(
        input,
        format: '#,##0.###',
        locale: 'de_DE',
      );

      // Assert
      expect(result, equals(1234.5));
    });

    test('should behave consistently when tryFormattedFirst is toggled', () {
      // Arrange
      const input = '1.234,5';

      final cfgTryFirst = const ConvertConfig(
        numbers: NumberOptions(
          defaultFormat: '#,##0.###',
          defaultLocale: 'de_DE',
          tryFormattedFirst: true,
        ),
      );

      final cfgPlainFirst = const ConvertConfig(
        numbers: NumberOptions(
          defaultFormat: '#,##0.###',
          defaultLocale: 'de_DE',
          tryFormattedFirst: false,
        ),
      );

      // Act
      final a = withScopedConfig(cfgTryFirst, () => Convert.toDouble(input));
      final b = withScopedConfig(cfgPlainFirst, () => Convert.toDouble(input));

      // Assert
      expect(a, equals(1234.5));
      expect(b, equals(1234.5));
    });

    test(
        'should throw ConversionException when input is malformed and no defaultValue is provided',
        () {
      // Arrange

      // Act + Assert
      expect(
        () => Convert.toDouble('abc'),
        throwsConversionException(method: 'toDouble'),
      );
    });

    test(
        'should return defaultValue when input is malformed and defaultValue is provided',
        () {
      // Arrange

      // Act
      final result = Convert.toDouble('abc', defaultValue: 7.5);

      // Assert
      expect(result, equals(7.5));
    });
  });

  group('Convert.tryToDouble', () {
    test('should return null when input is malformed', () {
      // Arrange

      // Act
      final result = Convert.tryToDouble('abc');

      // Assert
      expect(result, isNull);
    });

    test(
        'should return defaultValue when input is malformed and defaultValue is provided',
        () {
      // Arrange

      // Act
      final result = Convert.tryToDouble('abc', defaultValue: 7.5);

      // Assert
      expect(result, equals(7.5));
    });
  });
}
