import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('LetExtension', () {
    test(
        'let should execute the block and return its result for non-null values',
        () {
      // Arrange
      const value = 'hello';

      // Act
      final result = value.let((it) => it.length);

      // Assert
      expect(result, equals(5));
    });
  });

  group('LetExtensionNullable', () {
    test('let should return null and not execute when receiver is null', () {
      // Arrange
      String? value;

      // Act
      final result = value.let((it) => it.length);

      // Assert
      expect(result, isNull);
    });

    test('let should execute when receiver is non-null', () {
      // Arrange
      String? value = 'hi';

      // Act
      final result = value.let((it) => it.toUpperCase());

      // Assert
      expect(result, equals('HI'));
    });

    test('letOr should return defaultValue when receiver is null', () {
      // Arrange
      String? value;

      // Act
      final result = value.letOr((it) => it.length, defaultValue: -1);

      // Assert
      expect(result, equals(-1));
    });

    test('letOr should execute block when receiver is non-null', () {
      // Arrange
      String? value = 'abcd';

      // Act
      final result = value.letOr((it) => it.length, defaultValue: -1);

      // Assert
      expect(result, equals(4));
    });

    test('letNullable should return null when receiver is null', () {
      // Arrange
      String? value;

      // Act
      final result = value.letNullable((it) => it?.length);

      // Assert
      expect(result, isNull);
    });

    test('letNullable should pass the receiver to the block when non-null', () {
      // Arrange
      String? value = 'a';

      // Act
      final result = value.letNullable((it) => it?.toUpperCase());

      // Assert
      expect(result, equals('A'));
    });
  });
}
