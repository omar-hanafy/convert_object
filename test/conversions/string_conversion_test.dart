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

  group('Convert.string', () {
    test('should convert non-string inputs using toString', () {
      // Arrange
      final inputs = <Object?>[
        123,
        true,
        BigInt.parse('9007199254740993'),
        Uri.parse('https://example.com'),
        DateTime.utc(2025, 1, 1, 0, 0, 0),
      ];

      // Act
      final outputs = inputs.map((v) => Convert.string(v)).toList();

      // Assert
      expect(outputs[0], equals('123'));
      expect(outputs[1], equals('true'));
      expect(outputs[2], equals('9007199254740993'));
      expect(outputs[3], equals('https://example.com'));
      expect(outputs[4], contains('2025-01-01'));
    });

    test('should support mapKey and listIndex selection', () {
      // Arrange
      final data = <String, dynamic>{
        'a': ['x', 2, null],
      };

      // Act
      final v0 = Convert.string(data, mapKey: 'a', listIndex: 0);
      final v1 = Convert.string(data, mapKey: 'a', listIndex: 1);

      // Assert
      expect(v0, equals('x'));
      expect(v1, equals('2'));
    });

    test('should return defaultValue when selected value is missing', () {
      // Arrange
      final data = <String, dynamic>{
        'a': ['x'],
      };

      // Act
      final result = Convert.string(
        data,
        mapKey: 'a',
        listIndex: 999,
        defaultValue: 'fallback',
      );

      // Assert
      expect(result, equals('fallback'));
    });

    test(
      'should throw ConversionException when input is null and no defaultValue',
      () {
        // Arrange

        // Act + Assert
        expect(
          () => Convert.string(null),
          throwsConversionException(method: 'string'),
        );
      },
    );

    test('should use custom converter when provided', () {
      // Arrange

      // Act
      final result = Convert.string(123, converter: (_) => 'custom');

      // Assert
      expect(result, equals('custom'));
    });

    test('should return defaultValue when custom converter throws', () {
      // Arrange
      String throwingConverter(Object? _) => throw StateError('boom');

      // Act
      final result = Convert.string(
        123,
        converter: throwingConverter,
        defaultValue: 'fallback',
      );

      // Assert
      expect(result, equals('fallback'));
    });
  });

  group('Convert.tryToString', () {
    test('should return null when input is null', () {
      // Arrange

      // Act
      final result = Convert.tryToString(null);

      // Assert
      expect(result, isNull);
    });

    test(
      'should return defaultValue when input is null and defaultValue is provided',
      () {
        // Arrange

        // Act
        final result = Convert.tryToString(null, defaultValue: 'fallback');

        // Assert
        expect(result, equals('fallback'));
      },
    );

    test('should return defaultValue when selection fails', () {
      // Arrange
      final data = <String, dynamic>{
        'a': ['x'],
      };

      // Act
      final result = Convert.tryToString(
        data,
        mapKey: 'a',
        listIndex: 2,
        defaultValue: 'fallback',
      );

      // Assert
      expect(result, equals('fallback'));
    });
  });
}
