import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';

void main() {
  late ConvertConfig _prev;

  setUp(() {
    // Arrange
    _prev = Convert.configure(makeTestConfig(locale: 'en_US'));
  });

  tearDown(() {
    // Arrange
    Convert.configure(_prev);
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
    });

    test('should convert keys and values when keyConverter/valueConverter are provided',
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
    });

    test('should decode JSON string input into a map when decodeInput is enabled',
        () {
      // Arrange
      const json = '{"a":"1","b":2}';

      // Act
      final result = Convert.toMap<String, dynamic>(json);

      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result['a'], equals('1'));
      expect(result['b'], equals(2));
    });

    test('should decode JSON string and convert values with valueConverter', () {
      // Arrange
      const json = '{"a":"1","b":2}';

      // Act
      final result = Convert.toMap<String, int>(
        json,
        valueConverter: (v) => Convert.toInt(v),
      );

      // Assert
      expect(result, equals(<String, int>{'a': 1, 'b': 2}));
    });

    test('should support mapKey selection to convert a nested map', () {
      // Arrange
      final input = <String, dynamic>{
        'outer': <String, dynamic>{'x': '1'}
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

    test('should support listIndex selection to convert a map stored inside a list',
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
    });

    test('should return defaultValue when conversion fails and defaultValue is provided',
        () {
      // Arrange
      final fallback = <String, int>{'fallback': 1};

      // Act
      final result = Convert.toMap<String, int>('not-a-map', defaultValue: fallback);

      // Assert
      expect(result, equals(fallback));
    });
  });

  group('Convert.tryToMap', () {
    test('should return null when conversion fails and no defaultValue is provided',
        () {
      // Arrange
      final input = <String, dynamic>{'a': '1'};

      // Act
      final result = Convert.tryToMap<String, int>(input);

      // Assert
      expect(result, isNull);
    });

    test('should return defaultValue when conversion fails and defaultValue is provided',
        () {
      // Arrange
      final input = <String, dynamic>{'a': '1'};
      final fallback = <String, int>{'x': 9};

      // Act
      final result = Convert.tryToMap<String, int>(input, defaultValue: fallback);

      // Assert
      expect(result, equals(fallback));
    });

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
  });
}
