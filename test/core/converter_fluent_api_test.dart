import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';

void main() {
  late ConvertConfig prev;

  setUp(() {
    prev = Convert.configure(makeTestConfig());
  });

  tearDown(() {
    Convert.configure(prev);
  });

  group('Converter.fromMap', () {
    test('should read a nested value from a Map using the provided key', () {
      // Arrange
      final source = kNestedMap;

      // Act
      final result = Converter(source).fromMap('id').toInt();

      // Assert
      expect(result, isA<int>());
      expect(result, equals(42));
    });

    test('should read a nested value from a JSON string map', () {
      // Arrange
      final source = kNestedMapJson;

      // Act
      final result = Converter(source).fromMap('meta').fromMap('age').toInt();

      // Assert
      expect(result, equals(30));
    });

    test(
      'should return a Converter(null) when the receiver is not a Map or JSON map',
      () {
        // Arrange
        const source = 'not-a-map';

        // Act
        final result = const Converter(source).fromMap('x').tryToString();

        // Assert
        expect(result, isNull);
      },
    );

    test('should return a Converter(null) for invalid JSON strings', () {
      // Arrange
      const source = '{not-json}';

      // Act
      final result = const Converter(source).fromMap('x').tryToString();

      // Assert
      expect(result, isNull);
    });
  });

  group('Converter.fromList', () {
    test('should read a nested value from a List using the provided index', () {
      // Arrange
      final source = <Object?>['7', '8'];

      // Act
      final result = Converter(source).fromList(1).toInt();

      // Assert
      expect(result, equals(8));
    });

    test('should read a nested value from a JSON string list', () {
      // Arrange
      const source = kJsonList;

      // Act
      final result = const Converter(source).fromList(3).toInt();

      // Assert
      expect(result, equals(4)); // "004" -> 4
    });

    test('should return a Converter(null) when index is out of range', () {
      // Arrange
      final source = <Object?>['1'];

      // Act
      final result = Converter(source).fromList(99).tryToInt();

      // Assert
      expect(result, isNull);
    });

    test('should return Converter(null) when value is not a list', () {
      // Arrange
      final source = <String, dynamic>{'a': 1};

      // Act
      final result = Converter(source).withDefault(7).fromList(0).toInt();

      // Assert
      expect(result, equals(7));
    });
  });

  group('Converter.decoded', () {
    test('should decode JSON string input into a structured value', () {
      // Arrange
      const source = kNestedMapJson;

      // Act
      final decoded = const Converter(source).decoded;
      final map = decoded.to<Map<String, dynamic>>();

      // Assert
      expect(map, isA<Map<String, dynamic>>());
      expect(map['id'], equals('42'));
    });

    test('should return the same instance when the value is not a String', () {
      // Arrange
      final c = Converter(kNestedMap);

      // Act
      final decoded = c.decoded;

      // Assert
      expect(identical(decoded, c), isTrue);
    });

    test('should return original string when JSON decoding fails', () {
      // Arrange
      const source = '{not-json}';

      // Act
      final decoded = const Converter(source).decoded;
      final value = decoded.tryToString();

      // Assert
      expect(value, equals(source));
    });
  });

  group('Converter defaults', () {
    test('should use constructor defaultValue for primitive conversions', () {
      // Arrange
      final c = const Converter(null, defaultValue: 7);

      // Act
      final result = c.toInt();

      // Assert
      expect(result, equals(7));
    });

    test('should use withDefault to override defaultValue', () {
      // Arrange
      final c = const Converter('abc').withDefault(99);

      // Act
      final result = c.toInt();

      // Assert
      expect(result, equals(99));
    });

    test('withDefault should not affect generic to<T> conversion', () {
      // Arrange
      final c = const Converter('abc').withDefault(99);

      // Act + Assert
      expect(() => c.to<int>(), throwsConversionException(method: 'toInt'));
    });

    test(
      'toOr<T> should return the provided fallback when conversion throws',
      () {
        // Arrange
        final c = const Converter('abc');

        // Act
        final result = c.toOr<int>(123);

        // Assert
        expect(result, equals(123));
      },
    );

    test('toIntOr should return fallback when conversion fails', () {
      // Arrange
      final c = const Converter('abc');

      // Act
      final result = c.toIntOr(7);

      // Assert
      expect(result, equals(7));
    });
  });

  group('Converter generic conversion', () {
    test('to<T> should convert using Convert.toType routing', () {
      // Arrange
      final c = const Converter('5');

      // Act
      final result = c.to<int>();

      // Assert
      expect(result, isA<int>());
      expect(result, equals(5));
    });

    test('tryTo<T> should return null when conversion fails', () {
      // Arrange
      final c = const Converter('abc');

      // Act
      final result = c.tryTo<int>();

      // Assert
      expect(result, isNull);
    });

    test(
      'withConverter should transform the value before generic to<T> conversion',
      () {
        // Arrange
        final c = const Converter('ignored').withConverter((_) => '6');

        // Act
        final result = c.to<int>();

        // Assert
        expect(result, equals(6));
      },
    );

    test('withConverter should not affect primitive shortcut methods', () {
      // Arrange
      final c = const Converter('abc').withConverter((_) => '6');

      // Act + Assert
      expect(() => c.toInt(), throwsConversionException(method: 'toInt'));
    });

    test(
      'withConverter exceptions should be wrapped in ConversionException',
      () {
        // Arrange
        final c = const Converter('x').withConverter((_) {
          throw StateError('boom');
        });

        // Act + Assert
        expect(
          () => c.to<int>(),
          throwsConversionException(method: 'Converter.to<int>'),
        );
      },
    );

    test('withConverter should be preserved through fromMap navigation', () {
      // Arrange
      final c = Converter(kNestedMap).withConverter((_) => '7');

      // Act
      final result = c.fromMap('id').to<int>();

      // Assert
      expect(result, equals(7));
    });
  });
}
