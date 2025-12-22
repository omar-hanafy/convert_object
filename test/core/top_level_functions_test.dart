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

  group('Top-level string functions', () {
    test('convertToString should match Convert.string', () {
      // Arrange
      const input = 123;

      // Act
      final result = convertToString(input);
      final expected = Convert.string(input);

      // Assert
      expect(result, isA<String>());
      expect(result, equals(expected));
    });

    test('tryConvertToString should match Convert.tryToString', () {
      // Arrange
      const Object? input = null;

      // Act
      final result = tryConvertToString(input);
      final expected = Convert.tryToString(input);

      // Assert
      expect(result, equals(expected));
    });
  });

  group('Top-level number functions', () {
    test('convertToNum should match Convert.toNum', () {
      // Arrange
      const input = '1_234';

      // Act
      final result = convertToNum(input);
      final expected = Convert.toNum(input);

      // Assert
      expect(result, isA<num>());
      expect(result, equals(expected));
    });

    test('tryConvertToNum should match Convert.tryToNum', () {
      // Arrange
      const input = 'abc';

      // Act
      final result = tryConvertToNum(input);
      final expected = Convert.tryToNum(input);

      // Assert
      expect(result, equals(expected));
    });

    test('convertToInt should match Convert.toInt including mapKey', () {
      // Arrange
      final map = <String, Object?>{'v': '7'};

      // Act
      final result = convertToInt(map, mapKey: 'v');
      final expected = Convert.toInt(map, mapKey: 'v');

      // Assert
      expect(result, equals(expected));
    });

    test('tryConvertToInt should match Convert.tryToInt', () {
      // Arrange
      const input = 'abc';

      // Act
      final result = tryConvertToInt(input);
      final expected = Convert.tryToInt(input);

      // Assert
      expect(result, equals(expected));
    });

    test('convertToDouble should match Convert.toDouble', () {
      // Arrange
      const input = '5.5';

      // Act
      final result = convertToDouble(input);
      final expected = Convert.toDouble(input);

      // Assert
      expect(result, isA<double>());
      expect(result, equals(expected));
    });

    test('tryConvertToDouble should match Convert.tryToDouble', () {
      // Arrange
      const input = 'abc';

      // Act
      final result = tryConvertToDouble(input);
      final expected = Convert.tryToDouble(input);

      // Assert
      expect(result, equals(expected));
    });

    test('convertToBigInt should match Convert.toBigInt', () {
      // Arrange
      const input = '1234';

      // Act
      final result = convertToBigInt(input);
      final expected = Convert.toBigInt(input);

      // Assert
      expect(result, isA<BigInt>());
      expect(result, equals(expected));
    });

    test('tryConvertToBigInt should match Convert.tryToBigInt', () {
      // Arrange
      const input = 'abc';

      // Act
      final result = tryConvertToBigInt(input);
      final expected = Convert.tryToBigInt(input);

      // Assert
      expect(result, equals(expected));
    });

    test('convertToInt should forward custom converter', () {
      // Arrange
      const input = 'anything';

      // Act
      final result = convertToInt(input, converter: (_) => 123);
      final expected = Convert.toInt(input, converter: (_) => 123);

      // Assert
      expect(result, equals(expected));
    });
  });

  group('Top-level bool functions', () {
    test('convertToBool should match Convert.toBool', () {
      // Arrange
      const input = 'true';

      // Act
      final result = convertToBool(input);
      final expected = Convert.toBool(input);

      // Assert
      expect(result, isA<bool>());
      expect(result, equals(expected));
    });

    test('tryConvertToBool should match Convert.tryToBool', () {
      // Arrange
      const input = 'maybe';

      // Act
      final result = tryConvertToBool(input);
      final expected = Convert.tryToBool(input);

      // Assert
      expect(result, equals(expected));
    });
  });

  group('Top-level DateTime functions', () {
    test('convertToDateTime should match Convert.toDateTime', () {
      // Arrange
      const input = '2025-11-11T10:15:30Z';

      // Act
      final result = convertToDateTime(input);
      final expected = Convert.toDateTime(input);

      // Assert
      expect(result, isA<DateTime>());
      expect(result, sameInstantAs(expected));
      expect(result, sameInstantAs(kKnownUtcInstant));
    });

    test('tryConvertToDateTime should match Convert.tryToDateTime', () {
      // Arrange
      const input = 'not-a-date';

      // Act
      final result = tryConvertToDateTime(input);
      final expected = Convert.tryToDateTime(input);

      // Assert
      expect(result, equals(expected));
    });
  });

  group('Top-level Uri functions', () {
    test('convertToUri should match Convert.toUri', () {
      // Arrange
      const input = 'https://example.com';

      // Act
      final result = convertToUri(input);
      final expected = Convert.toUri(input);

      // Assert
      expect(result, isA<Uri>());
      expect(result, uriEquals(expected.toString()));
    });

    test('tryConvertToUri should match Convert.tryToUri', () {
      // Arrange
      const input = '::not a uri::';

      // Act
      final result = tryConvertToUri(input);
      final expected = Convert.tryToUri(input);

      // Assert
      expect(result?.toString(), equals(expected?.toString()));
    });
  });

  group('Top-level collection functions', () {
    test('convertToMap should match Convert.toMap', () {
      // Arrange
      final input = <String, Object?>{'a': 1};

      // Act
      final result = convertToMap<String, Object?>(input);
      final expected = Convert.toMap<String, Object?>(input);

      // Assert
      expect(result, equals(expected));
    });

    test('tryConvertToMap should match Convert.tryToMap', () {
      // Arrange
      const input = 'not-a-map';

      // Act
      final result = tryConvertToMap<String, Object?>(input);
      final expected = Convert.tryToMap<String, Object?>(input);

      // Assert
      expect(result, equals(expected));
    });

    test('convertToList should match Convert.toList', () {
      // Arrange
      final input = <Object?>['1', '2'];

      // Act
      final result = convertToList<int>(input);
      final expected = Convert.toList<int>(input);

      // Assert
      expect(result, equals(expected));
    });

    test('tryConvertToList should match Convert.tryToList', () {
      // Arrange
      const input = 'not-a-list';

      // Act
      final result = tryConvertToList<int>(input);
      final expected = Convert.tryToList<int>(input);

      // Assert
      expect(result, equals(expected));
    });

    test('convertToSet should match Convert.toSet', () {
      // Arrange
      final input = <Object?>['1', '2', '2'];

      // Act
      final result = convertToSet<int>(input);
      final expected = Convert.toSet<int>(input);

      // Assert
      expect(result, equals(expected));
    });

    test('tryConvertToSet should match Convert.tryToSet', () {
      // Arrange
      const input = 'not-a-set';

      // Act
      final result = tryConvertToSet<int>(input);
      final expected = Convert.tryToSet<int>(input);

      // Assert
      expect(result, equals(expected));
    });
  });

  group('Top-level generic functions', () {
    test('convertToType should match Convert.toType', () {
      // Arrange
      const input = '5';

      // Act
      final result = convertToType<int>(input);
      final expected = Convert.toType<int>(input);

      // Assert
      expect(result, equals(expected));
    });

    test('tryConvertToType should match Convert.tryToType', () {
      // Arrange
      const input = 'abc';

      // Act
      final result = tryConvertToType<int>(input);
      final expected = Convert.tryToType<int>(input);

      // Assert
      expect(result, equals(expected));
    });

    test('convertToType should throw ConversionException when Convert.toType throws',
        () {
      // Arrange
      const Object? input = null;

      // Act + Assert
      expect(
        () => convertToType<int>(input),
        throwsConversionException(method: 'toType<int>'),
      );
    });
  });
}
