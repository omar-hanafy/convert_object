import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';
import '../helpers/test_enums.dart';

void main() {
  late ConvertConfig prev;

  setUp(() {
    prev = Convert.configure(makeTestConfig());
  });

  tearDown(() {
    Convert.configure(prev);
  });

  group('EnumParsers.byName', () {
    test('should resolve enum values by bare name', () {
      // Arrange
      final parser = EnumParsers.byName(TestColor.values);

      // Act
      final result = parser('green');

      // Assert
      expect(result, isA<TestColor>());
      expect(result, equals(TestColor.green));
    });

    test('should resolve enum values by qualified name', () {
      // Arrange
      final parser = EnumParsers.byName(TestColor.values);

      // Act
      final result = parser('TestColor.red');

      // Assert
      expect(result, equals(TestColor.red));
    });

    test('should throw StateError when name cannot be resolved', () {
      // Arrange
      final parser = EnumParsers.byName(TestColor.values);

      // Act + Assert
      expect(() => parser('unknown'), throwsA(isA<StateError>()));
    });
  });

  group('EnumParsers.byNameCaseInsensitive', () {
    test('should resolve enum names ignoring case', () {
      // Arrange
      final parser = EnumParsers.byNameCaseInsensitive(TestColor.values);

      // Act
      final result = parser('BLUE');

      // Assert
      expect(result, equals(TestColor.blue));
    });

    test('should throw ArgumentError for invalid values', () {
      // Arrange
      final parser = EnumParsers.byNameCaseInsensitive(TestColor.values);

      // Act + Assert
      expect(() => parser('not-a-color'), throwsA(isA<ArgumentError>()));
    });
  });

  group('EnumParsers.byNameOrFallback', () {
    test('should return fallback when the name is unknown', () {
      // Arrange
      final parser = EnumParsers.byNameOrFallback(
        TestColor.values,
        TestColor.red,
      );

      // Act
      final result = parser('unknown');

      // Assert
      expect(result, equals(TestColor.red));
    });
  });

  group('EnumParsers.fromString', () {
    test('should wrap a String parser for dynamic inputs', () {
      // Arrange
      TestColor parseColor(String input) =>
          TestColor.values.firstWhere((e) => e.name == input);
      final parser = EnumParsers.fromString<TestColor>(parseColor);

      // Act
      final result = parser('blue');

      // Assert
      expect(result, equals(TestColor.blue));
    });
  });

  group('EnumParsers.byIndex', () {
    test('should resolve enum values by index', () {
      // Arrange
      final parser = EnumParsers.byIndex(TestColor.values);

      // Act
      final result = parser(1);

      // Assert
      expect(result, equals(TestColor.green));
    });

    test('should parse numeric strings for index lookup', () {
      // Arrange
      final parser = EnumParsers.byIndex(TestColor.values);

      // Act
      final result = parser('2');

      // Assert
      expect(result, equals(TestColor.blue));
    });

    test('should throw ArgumentError when index is out of range', () {
      // Arrange
      final parser = EnumParsers.byIndex(TestColor.values);

      // Act + Assert
      expect(() => parser(99), throwsA(isA<ArgumentError>()));
    });
  });

  group('EnumValuesParsing extension', () {
    test('parser should behave like EnumParsers.byName', () {
      // Arrange
      final parser = TestColor.values.parser;

      // Act
      final result = parser('red');

      // Assert
      expect(result, equals(TestColor.red));
    });

    test('parserCaseInsensitive should ignore case', () {
      // Arrange
      final parser = TestColor.values.parserCaseInsensitive;

      // Act
      final result = parser('gReEn');

      // Assert
      expect(result, equals(TestColor.green));
    });

    test('parserWithFallback should return fallback on unknown values', () {
      // Arrange
      final parser = TestColor.values.parserWithFallback(TestColor.blue);

      // Act
      final result = parser('unknown');

      // Assert
      expect(result, equals(TestColor.blue));
    });

    test('parserByIndex should resolve by index', () {
      // Arrange
      final parser = TestColor.values.parserByIndex;

      // Act
      final result = parser(0);

      // Assert
      expect(result, equals(TestColor.red));
    });
  });

  group('Convert.toEnum / Convert.tryToEnum', () {
    test('Convert.toEnum should parse values using the provided parser', () {
      // Arrange
      const input = 'green';

      // Act
      final result = Convert.toEnum<TestColor>(
        input,
        parser: TestColor.values.parser,
      );

      // Assert
      expect(result, equals(TestColor.green));
    });

    test('Convert.tryToEnum should return null when parsing fails', () {
      // Arrange
      const input = 'unknown';

      // Act
      final result = Convert.tryToEnum<TestColor>(
        input,
        parser: TestColor.values.parser,
      );

      // Assert
      expect(result, isNull);
    });

    test('Convert.tryToEnum should return defaultValue when parsing fails', () {
      // Arrange
      const input = 'unknown';

      // Act
      final result = Convert.tryToEnum<TestColor>(
        input,
        parser: TestColor.values.parser,
        defaultValue: TestColor.red,
      );

      // Assert
      expect(result, equals(TestColor.red));
    });

    test(
      'Convert.toEnum should throw ConversionException when parsing fails and no defaultValue is provided',
      () {
        // Arrange
        const input = 'unknown';

        // Act + Assert
        expect(
          () =>
              Convert.toEnum<TestColor>(input, parser: TestColor.values.parser),
          throwsConversionException(method: 'toEnum<TestColor>'),
        );
      },
    );

    test('Convert.toEnum should rethrow ConversionException from parser', () {
      // Arrange
      TestColor parser(dynamic _) => throw ConversionException(
            error: 'boom',
            context: {'method': 'toEnum<TestColor>'},
            stackTrace: StackTrace.current,
          );

      // Act / Assert
      expect(
        () => Convert.toEnum<TestColor>('x', parser: parser),
        throwsA(isA<ConversionException>()),
      );
    });

    test('Convert.toEnum should include debug info on parser errors', () {
      // Arrange
      TestColor parser(dynamic _) => throw StateError('boom');
      ConversionException? thrown;

      // Act
      try {
        Convert.toEnum<TestColor>('x', parser: parser);
      } catch (e) {
        thrown = e as ConversionException;
      }

      // Assert
      expect(thrown, isNotNull);
      expect(thrown!.context['reason'], equals('enum parse failed'));
      expect(thrown.context['enumType'], equals('TestColor'));
    });

    test('Convert.toEnum should preserve supplied debugInfo on error', () {
      // Arrange
      TestColor parser(dynamic _) => throw StateError('boom');
      ConversionException? thrown;

      // Act
      try {
        Convert.toEnum<TestColor>(
          'x',
          parser: parser,
          debugInfo: const {'source': 'unit-test'},
        );
      } catch (e) {
        thrown = e as ConversionException;
      }

      // Assert
      expect(thrown, isNotNull);
      expect(thrown!.context['source'], equals('unit-test'));
    });

    test('Convert.toEnum should throw null object when input is null', () {
      // Act / Assert
      expect(
        () => Convert.toEnum<TestColor>(null, parser: TestColor.values.parser),
        throwsConversionException(method: 'toEnum<TestColor>'),
      );
    });

    test('Convert.toEnum should include debugInfo when input is null', () {
      ConversionException? thrown;

      try {
        Convert.toEnum<TestColor>(
          null,
          parser: TestColor.values.parser,
          debugInfo: const {'case': 'null-input'},
        );
      } catch (e) {
        thrown = e as ConversionException;
      }

      expect(thrown, isNotNull);
      expect(thrown!.context['case'], equals('null-input'));
      expect(thrown.context['reason'], equals('enum parse failed'));
    });
  });
}
