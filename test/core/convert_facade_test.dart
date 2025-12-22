import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';

void main() {
  late ConvertConfig _prev;

  setUp(() {
    _prev = Convert.configure(makeTestConfig());
  });

  tearDown(() {
    Convert.configure(_prev);
  });

  group('Convert.string', () {
    test('should coerce non-null values using toString by default', () {
      // Arrange
      const input = 123;

      // Act
      final result = Convert.string(input);

      // Assert
      expect(result, isA<String>());
      expect(result, equals('123'));
    });

    test('should read from mapKey when object is a Map', () {
      // Arrange
      final map = <String, Object?>{'name': 'Omar'};

      // Act
      final result = Convert.string(map, mapKey: 'name');

      // Assert
      expect(result, equals('Omar'));
    });

    test('should read from listIndex when object is a List', () {
      // Arrange
      final list = <Object?>['x', 2];

      // Act
      final result = Convert.string(list, listIndex: 1);

      // Assert
      expect(result, equals('2'));
    });

    test('should return defaultValue when object is null', () {
      // Arrange
      const fallback = 'N/A';

      // Act
      final result = Convert.string(null, defaultValue: fallback);

      // Assert
      expect(result, equals(fallback));
    });

    test(
        'should throw ConversionException when object is null and no defaultValue is provided',
        () {
      // Arrange
      const Object? input = null;

      // Act + Assert
      expect(
        () => Convert.string(input),
        throwsConversionException(method: 'string'),
      );
    });

    test('should use a custom converter when provided', () {
      // Arrange
      const input = 5;

      // Act
      final result = Convert.string(
        input,
        converter: (o) => 'custom:$o',
      );

      // Assert
      expect(result, equals('custom:5'));
    });
  });

  group('Convert.tryToString', () {
    test('should return null when input is null and no defaultValue is provided',
        () {
      // Arrange
      const Object? input = null;

      // Act
      final result = Convert.tryToString(input);

      // Assert
      expect(result, isNull);
    });

    test('should return defaultValue when input is null', () {
      // Arrange
      const Object? input = null;

      // Act
      final result = Convert.tryToString(input, defaultValue: 'fallback');

      // Assert
      expect(result, equals('fallback'));
    });

    test('should read from mapKey when object is a Map', () {
      // Arrange
      final map = <String, Object?>{'id': 42};

      // Act
      final result = Convert.tryToString(map, mapKey: 'id');

      // Assert
      expect(result, equals('42'));
    });
  });

  group('Convert.toInt', () {
    test('should convert numeric strings to int', () {
      // Arrange
      const input = '42';

      // Act
      final result = Convert.toInt(input);

      // Assert
      expect(result, isA<int>());
      expect(result, equals(42));
    });

    test('should read from mapKey when object is a Map', () {
      // Arrange
      final map = <String, Object?>{'v': '7'};

      // Act
      final result = Convert.toInt(map, mapKey: 'v');

      // Assert
      expect(result, equals(7));
    });

    test('should read from listIndex when object is a List', () {
      // Arrange
      final list = <Object?>['9'];

      // Act
      final result = Convert.toInt(list, listIndex: 0);

      // Assert
      expect(result, equals(9));
    });

    test('should return defaultValue when conversion fails', () {
      // Arrange
      const input = 'abc';

      // Act
      final result = Convert.toInt(input, defaultValue: 5);

      // Assert
      expect(result, equals(5));
    });

    test('should throw ConversionException when conversion fails and no defaultValue is provided',
        () {
      // Arrange
      const input = 'abc';

      // Act + Assert
      expect(
        () => Convert.toInt(input),
        throwsConversionException(method: 'toInt'),
      );
    });

    test('should use a custom converter when provided', () {
      // Arrange
      const input = 'anything';

      // Act
      final result = Convert.toInt(
        input,
        converter: (_) => 123,
      );

      // Assert
      expect(result, equals(123));
    });
  });

  group('Convert.tryToInt', () {
    test('should return null when conversion fails and no defaultValue is provided',
        () {
      // Arrange
      const input = 'abc';

      // Act
      final result = Convert.tryToInt(input);

      // Assert
      expect(result, isNull);
    });

    test('should return defaultValue when conversion fails and defaultValue is provided',
        () {
      // Arrange
      const input = 'abc';

      // Act
      final result = Convert.tryToInt(input, defaultValue: 77);

      // Assert
      expect(result, equals(77));
    });
  });

  group('Convert.toBool', () {
    test('should parse common truthy strings', () {
      // Arrange
      const input = 'true';

      // Act
      final result = Convert.toBool(input);

      // Assert
      expect(result, isA<bool>());
      expect(result, isTrue);
    });

    test('should return false for unknown tokens when no defaultValue is provided',
        () {
      // Arrange
      const input = 'maybe';

      // Act
      final result = Convert.toBool(input);

      // Assert
      expect(result, isFalse);
    });

    test('should return defaultValue when input is null', () {
      // Arrange
      const Object? input = null;

      // Act
      final result = Convert.toBool(input, defaultValue: true);

      // Assert
      expect(result, isTrue);
    });

    test('should read from mapKey when object is a Map', () {
      // Arrange
      final map = <String, Object?>{'active': 'yes'};

      // Act
      final result = Convert.toBool(map, mapKey: 'active');

      // Assert
      expect(result, isTrue);
    });

    test('should read from listIndex when object is a List', () {
      // Arrange
      final list = <Object?>['no'];

      // Act
      final result = Convert.toBool(list, listIndex: 0);

      // Assert
      expect(result, isFalse);
    });
  });

  group('Convert.tryToBool', () {
    test('should return null for unknown tokens when no defaultValue is provided',
        () {
      // Arrange
      const input = 'maybe';

      // Act
      final result = Convert.tryToBool(input);

      // Assert
      expect(result, isNull);
    });

    test('should return defaultValue for unknown tokens when defaultValue is provided',
        () {
      // Arrange
      const input = 'maybe';

      // Act
      final result = Convert.tryToBool(input, defaultValue: true);

      // Assert
      expect(result, isTrue);
    });
  });

  group('Convert.toDateTime', () {
    test('should parse ISO-8601 strings', () {
      // Arrange
      const input = '2025-11-11T10:15:30Z';

      // Act
      final result = Convert.toDateTime(input);

      // Assert
      expect(result, isA<DateTime>());
      expect(result, isUtcDateTime);
      expect(result, sameInstantAs(kKnownUtcInstant));
    });

    test('should return defaultValue when input is null', () {
      // Arrange
      final fallback = DateTime.utc(2000, 1, 1);

      // Act
      final result = Convert.toDateTime(null, defaultValue: fallback);

      // Assert
      expect(result, sameInstantAs(fallback));
    });

    test('should throw ConversionException when input is null and no defaultValue is provided',
        () {
      // Arrange
      const Object? input = null;

      // Act + Assert
      expect(
        () => Convert.toDateTime(input),
        throwsConversionException(method: 'toDateTime'),
      );
    });
  });
}
