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

  group('Convert.toList', () {
    test('should return the same list when input is already a List<T>', () {
      // Arrange
      final input = <int>[1, 2];

      // Act
      final result = Convert.toList<int>(input);

      // Assert
      expect(result, isA<List<int>>());
      expect(result, equals(input));
      expect(identical(result, input), isTrue);
    });

    test('should convert elements using toType<T> when types differ', () {
      // Arrange
      final input = <dynamic>['1', 2, '3'];

      // Act
      final result = Convert.toList<int>(input);

      // Assert
      expect(result, isA<List<int>>());
      expect(result, equals(<int>[1, 2, 3]));
    });

    test('should convert from a Set<T> into a List<T>', () {
      // Arrange
      final input = <int>{1, 2};

      // Act
      final result = Convert.toList<int>(input);

      // Assert
      expect(result, isA<List<int>>());
      expect(result.toSet(), equals(<int>{1, 2}));
      expect(result.length, equals(2));
    });

    test('should convert from map.values (Iterable) into a List<T>', () {
      // Arrange
      final map = <String, String>{'a': '1', 'b': '2'};

      // Act
      final result = Convert.toList<int>(map.values);

      // Assert
      expect(result, equals(<int>[1, 2]));
    });

    test('should wrap and convert a scalar input into a one-element list', () {
      // Arrange
      const input = '5';

      // Act
      final result = Convert.toList<int>(input);

      // Assert
      expect(result, equals(<int>[5]));
    });

    test('should apply elementConverter to every element', () {
      // Arrange
      final input = <int>[1, 2];

      // Act
      final result = Convert.toList<String>(
        input,
        elementConverter: (e) => 'v$e',
      );

      // Assert
      expect(result, equals(<String>['v1', 'v2']));
    });

    test('should decode a JSON list string into a List<dynamic>', () {
      // Arrange
      final input = kJsonList;

      // Act
      final result = Convert.toList<dynamic>(input);

      // Assert
      expect(result, isA<List<dynamic>>());
      expect(result.length, equals(7));
      expect(result[1], equals('2'));
      expect(result[3], equals('004'));
    });

    test('should decode a JSON list string and convert elements to int', () {
      // Arrange
      const input = '["1","2","3"]';

      // Act
      final result = Convert.toList<int>(input);

      // Assert
      expect(result, equals(<int>[1, 2, 3]));
    });

    test('should throw ConversionException when element conversion fails', () {
      // Arrange
      final input = <dynamic>['a'];

      // Act
      // Assert
      expect(
        () => Convert.toList<int>(input),
        throwsConversionException(method: 'toList<int>'),
      );
    });

    test(
        'should return defaultValue when conversion fails and defaultValue is provided',
        () {
      // Arrange
      const input = 'not-a-list';
      final fallback = <int>[9];

      // Act
      final result = Convert.toList<int>(input, defaultValue: fallback);

      // Assert
      expect(result, equals(fallback));
    });
  });

  group('Convert.tryToList', () {
    test(
        'should return null when input is a non-iterable scalar not assignable to T',
        () {
      // Arrange
      const input = 'abc';

      // Act
      final result = Convert.tryToList<int>(input);

      // Assert
      expect(result, isNull);
    });

    test('should return a one-element list when input is already of type T',
        () {
      // Arrange
      const input = 5;

      // Act
      final result = Convert.tryToList<int>(input);

      // Assert
      expect(result, equals(<int>[5]));
    });

    test('should return defaultValue when conversion fails', () {
      // Arrange
      const input = 'not-a-list';
      final fallback = <int>[9];

      // Act
      final result = Convert.tryToList<int>(input, defaultValue: fallback);

      // Assert
      expect(result, equals(fallback));
    });

    test('should return null when element conversion fails', () {
      // Arrange
      final input = <dynamic>['a'];

      // Act
      final result = Convert.tryToList<int>(input);

      // Assert
      expect(result, isNull);
    });

    test('should return an empty list when input is an empty iterable', () {
      // Arrange
      final input = <dynamic>[];

      // Act
      final result = Convert.tryToList<int>(input);

      // Assert
      expect(result, isA<List<int>>());
      expect(result, equals(<int>[]));
    });
  });
}
