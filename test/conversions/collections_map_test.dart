import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';

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

  group('Convert.toMap', () {
    test('should return the same map when input is already a Map<K, V>', () {
      // Arrange
      final input = <String, int>{'a': 1, 'b': 2};

      // Act
      final result = Convert.toMap<String, int>(input);

      // Assert
      expect(result, isA<Map<String, int>>());
      expect(result, equals(input));
      expect(identical(result, input), isTrue);
    });

    test('should return an empty typed map when input map is empty', () {
      // Arrange
      final input = <String, int>{};

      // Act
      final result = Convert.toMap<String, int>(input);

      // Assert
      expect(result, isA<Map<String, int>>());
      expect(result, isEmpty);
    });

    test('should honor mapKey even when input already matches Map<K, V>', () {
      // Arrange
      final input = <String, dynamic>{
        'outer': <String, dynamic>{'x': 1},
        'other': 2,
      };

      // Act
      final result = Convert.toMap<String, dynamic>(input, mapKey: 'outer');

      // Assert
      expect(result, equals(<String, dynamic>{'x': 1}));
    });

    test(
      'should throw ConversionException when map value types are incompatible and no converters are provided',
      () {
        // Arrange
        final input = <String, dynamic>{'a': '1'};

        // Act
        // Assert
        expect(
          () => Convert.toMap<String, int>(input),
          throwsConversionException(method: 'toMap<String, int>'),
        );
      },
    );

    test(
      'should convert keys and values when keyConverter/valueConverter are provided',
      () {
        // Arrange
        final input = <String, String>{'1': '2', '3': '4'};

        // Act
        final result = Convert.toMap<int, int>(
          input,
          keyConverter: (k) => Convert.toInt(k),
          valueConverter: (v) => Convert.toInt(v),
        );

        // Assert
      expect(result, isA<Map<int, int>>());
      expect(result, equals(<int, int>{1: 2, 3: 4}));
    },
    );

    test('should wrap keyConverter errors in ConversionException', () {
      // Arrange
      final input = <String, String>{'a': '1'};

      // Act + Assert
      expect(
        () => Convert.toMap<int, int>(
          input,
          keyConverter: (_) => throw StateError('boom'),
          valueConverter: (v) => Convert.toInt(v),
        ),
        throwsConversionException(method: 'toMap<int, int>'),
      );
    });

    test(
      'should decode JSON string input into a map when decodeInput is enabled',
      () {
        // Arrange
        const json = '{"a":"1","b":2}';

        // Act
        final result = Convert.toMap<String, dynamic>(json);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['a'], equals('1'));
        expect(result['b'], equals(2));
      },
    );

    test(
      'should decode JSON string and convert values with valueConverter',
      () {
        // Arrange
        const json = '{"a":"1","b":2}';

        // Act
        final result = Convert.toMap<String, int>(
          json,
          valueConverter: (v) => Convert.toInt(v),
        );

        // Assert
        expect(result, equals(<String, int>{'a': 1, 'b': 2}));
      },
    );

    test('should support mapKey selection to convert a nested map', () {
      // Arrange
      final input = <String, dynamic>{
        'outer': <String, dynamic>{'x': '1'},
      };

      // Act
      final result = Convert.toMap<String, int>(
        input,
        mapKey: 'outer',
        valueConverter: (v) => Convert.toInt(v),
      );

      // Assert
      expect(result, equals(<String, int>{'x': 1}));
    });

    test(
      'should support listIndex selection to convert a map stored inside a list',
      () {
        // Arrange
        final input = <dynamic>[
          <String, dynamic>{'x': '1'},
          <String, dynamic>{'y': '2'},
        ];

        // Act
        final result = Convert.toMap<String, int>(
          input,
          listIndex: 1,
          valueConverter: (v) => Convert.toInt(v),
        );

        // Assert
        expect(result, equals(<String, int>{'y': 2}));
      },
    );

    test(
      'should return defaultValue when conversion fails and defaultValue is provided',
      () {
        // Arrange
        final fallback = <String, int>{'fallback': 1};

        // Act
        final result = Convert.toMap<String, int>(
          'not-a-map',
          defaultValue: fallback,
        );

        // Assert
      expect(result, equals(fallback));
    },
    );

    test('should rethrow ConversionException from keyConverter', () {
      // Arrange
      final input = <String, dynamic>{'a': '1'};

      // Act / Assert
      expect(
        () => Convert.toMap<String, int>(
          input,
          keyConverter: (_) => throw ConversionException(
            error: 'boom',
            context: {'method': 'toMap<String, int>'},
            stackTrace: StackTrace.current,
          ),
        ),
        throwsA(isA<ConversionException>()),
      );
    });

    test('should throw when input is null and no defaultValue is provided', () {
      // Act / Assert
      expect(
        () => Convert.toMap<String, int>(null),
        throwsConversionException(method: 'toMap<String, int>'),
      );
    });
  });

  group('Convert.tryToMap', () {
    test(
      'should return null when conversion fails and no defaultValue is provided',
      () {
        // Arrange
        final input = <String, dynamic>{'a': '1'};

        // Act
        final result = Convert.tryToMap<String, int>(input);

        // Assert
        expect(result, isNull);
      },
    );

    test(
      'should return defaultValue when conversion fails and defaultValue is provided',
      () {
        // Arrange
        final input = <String, dynamic>{'a': '1'};
        final fallback = <String, int>{'x': 9};

        // Act
        final result = Convert.tryToMap<String, int>(
          input,
          defaultValue: fallback,
        );

        // Assert
        expect(result, equals(fallback));
      },
    );

    test('should decode JSON string input into a map when possible', () {
      // Arrange
      const json = '{"a":"1","b":"2"}';

      // Act
      final result = Convert.tryToMap<String, dynamic>(json);

      // Assert
      expect(result, isNotNull);
      expect(result, isA<Map<String, dynamic>>());
      expect(result!['a'], equals('1'));
      expect(result['b'], equals('2'));
    });

    test('should apply key and value converters when provided', () {
      // Arrange
      final input = <String, dynamic>{'1': '2'};

      // Act
      final result = Convert.tryToMap<int, int>(
        input,
        keyConverter: (k) => int.parse(k as String),
        valueConverter: (v) => int.parse(v as String),
      );

      // Assert
      expect(result, equals(<int, int>{1: 2}));
    });
  });
}
