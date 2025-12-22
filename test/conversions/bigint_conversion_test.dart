import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';

void main() {
  late ConvertConfig prev;

  setUp(() {
    // Arrange
    prev = Convert.configure(makeTestConfig());
  });

  tearDown(() {
    // Arrange
    Convert.configure(prev);
  });

  group('Convert.toBigInt', () {
    test('should convert numeric inputs to BigInt', () {
      // Arrange

      // Act
      final a = Convert.toBigInt(12);
      final b = Convert.toBigInt(12.0);

      // Assert
      expect(a, isA<BigInt>());
      expect(a, equals(BigInt.from(12)));
      expect(b, equals(BigInt.from(12)));
    });

    test('should parse BigInt from numeric strings', () {
      // Arrange
      const input = '9007199254740993';

      // Act
      final result = Convert.toBigInt(input);

      // Assert
      expect(result, equals(BigInt.parse(input)));
    });

    test('should support mapKey and listIndex selection', () {
      // Arrange
      final data = <String, dynamic>{
        'v': ['9007199254740993'],
      };

      // Act
      final result = Convert.toBigInt(data, mapKey: 'v', listIndex: 0);

      // Assert
      expect(result, equals(BigInt.parse('9007199254740993')));
    });

    test(
        'should throw ConversionException when input is malformed and no defaultValue is provided',
        () {
      // Arrange

      // Act + Assert
      expect(
        () => Convert.toBigInt('abc'),
        throwsConversionException(method: 'toBigInt'),
      );
    });

    test(
        'should return defaultValue when input is malformed and defaultValue is provided',
        () {
      // Arrange
      final fallback = BigInt.from(7);

      // Act
      final result = Convert.toBigInt('abc', defaultValue: fallback);

      // Assert
      expect(result, equals(fallback));
    });
  });

  group('Convert.tryToBigInt', () {
    test('should return null when input is malformed', () {
      // Arrange

      // Act
      final result = Convert.tryToBigInt('abc');

      // Assert
      expect(result, isNull);
    });

    test(
        'should return defaultValue when input is malformed and defaultValue is provided',
        () {
      // Arrange
      final fallback = BigInt.from(7);

      // Act
      final result = Convert.tryToBigInt('abc', defaultValue: fallback);

      // Assert
      expect(result, equals(fallback));
    });

    test(
        'should return defaultValue when input is null and defaultValue is provided',
        () {
      // Arrange
      final fallback = BigInt.from(7);

      // Act
      final result = Convert.tryToBigInt(null, defaultValue: fallback);

      // Assert
      expect(result, equals(fallback));
    });
  });
}
