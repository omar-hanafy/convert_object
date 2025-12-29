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
      },
    );

    test('also should execute block and return the receiver', () {
      // Arrange
      final values = <int>[];

      // Act
      final result = values.also((it) => it.add(1));

      // Assert
      expect(result, same(values));
      expect(values, equals([1]));
    });

    test('takeIf should return receiver when predicate is true', () {
      // Arrange
      const value = 'hello';

      // Act
      final result = value.takeIf((it) => it.startsWith('h'));

      // Assert
      expect(result, equals('hello'));
    });

    test('takeIf should return null when predicate is false', () {
      // Arrange
      const value = 'hello';

      // Act
      final result = value.takeIf((it) => it.startsWith('x'));

      // Assert
      expect(result, isNull);
    });

    test('takeUnless should return receiver when predicate is false', () {
      // Arrange
      const value = 'hello';

      // Act
      final result = value.takeUnless((it) => it.startsWith('x'));

      // Assert
      expect(result, equals('hello'));
    });

    test('takeUnless should return null when predicate is true', () {
      // Arrange
      const value = 'hello';

      // Act
      final result = value.takeUnless((it) => it.startsWith('h'));

      // Assert
      expect(result, isNull);
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

    test('also should return null and not execute when receiver is null', () {
      // Arrange
      String? value;
      var called = false;

      // Act
      final result = value.also((it) => called = true);

      // Assert
      expect(result, isNull);
      expect(called, isFalse);
    });

    test('also should execute when receiver is non-null', () {
      // Arrange
      String? value = 'hi';
      var calledWith = '';

      // Act
      final result = value.also((it) => calledWith = it);

      // Assert
      expect(result, equals('hi'));
      expect(calledWith, equals('hi'));
    });

    test('takeIf should return null and not execute when receiver is null', () {
      // Arrange
      String? value;
      var called = false;

      // Act
      final result = value.takeIf((it) {
        called = true;
        return it.isNotEmpty;
      });

      // Assert
      expect(result, isNull);
      expect(called, isFalse);
    });

    test('takeIf should return receiver when predicate is true', () {
      // Arrange
      String? value = 'hi';

      // Act
      final result = value.takeIf((it) => it.length == 2);

      // Assert
      expect(result, equals('hi'));
    });

    test('takeUnless should return receiver when predicate is false', () {
      // Arrange
      String? value = 'hi';

      // Act
      final result = value.takeUnless((it) => it.length == 3);

      // Assert
      expect(result, equals('hi'));
    });

    test('takeUnless should return null when predicate is true', () {
      // Arrange
      String? value = 'hi';

      // Act
      final result = value.takeUnless((it) => it.length == 2);

      // Assert
      expect(result, isNull);
    });
  });
}
