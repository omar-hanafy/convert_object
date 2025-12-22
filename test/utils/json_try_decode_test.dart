import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('TextJsonX.tryDecode / decode', () {
    test('should decode valid JSON objects', () {
      // Arrange
      const input = '{"a": 1, "b": "x"}';

      // Act
      final decoded = input.tryDecode();

      // Assert
      expect(decoded, isA<Map>());
      final map = decoded as Map;
      expect(map['a'], equals(1));
      expect(map['b'], equals('x'));
    });

    test('should decode valid JSON arrays', () {
      // Arrange
      const input = '[1, 2, 3]';

      // Act
      final decoded = input.tryDecode();

      // Assert
      expect(decoded, isA<List>());
      expect(decoded, equals(<dynamic>[1, 2, 3]));
    });

    test('should return the original string when JSON decoding fails', () {
      // Arrange
      const input = 'not json';

      // Act
      final decoded = input.tryDecode();

      // Assert
      expect(decoded, isA<String>());
      expect(decoded, equals(input));
    });

    test('should return the original string when input is empty', () {
      // Arrange
      const input = '';

      // Act
      final decoded = input.tryDecode();

      // Assert
      expect(decoded, isA<String>());
      expect(decoded, equals(input));
    });

    test('decode() should throw when JSON is invalid', () {
      // Arrange
      const input = 'not json';

      // Act / Assert
      expect(() => input.decode(), throwsA(isA<FormatException>()));
    });

    test('decode() should return parsed output when JSON is valid', () {
      // Arrange
      const input = '{"a": 1}';

      // Act
      final decoded = input.decode();

      // Assert
      expect(decoded, isA<Map>());
      expect((decoded as Map)['a'], equals(1));
    });
  });
}
