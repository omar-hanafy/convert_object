import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';

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

  group('Convert.toBool', () {
    test('should convert common truthy inputs to true', () {
      // Arrange
      for (final input in kTruthyValues) {
        // Act
        final result = Convert.toBool(input);

        // Assert
        expect(result, isTrue, reason: 'Expected "$input" to be true');
      }
    });

    test('should convert common falsy inputs to false', () {
      // Arrange
      for (final input in kFalsyValues) {
        // Act
        final result = Convert.toBool(input);

        // Assert
        expect(result, isFalse, reason: 'Expected "$input" to be false');
      }
    });

    test('should return false for unknown strings by default', () {
      // Arrange

      // Act
      final result = Convert.toBool('maybe');

      // Assert
      expect(result, isFalse);
    });

    test(
      'should return defaultValue when parsing fails and defaultValue is provided',
      () {
        // Arrange

        // Act
        final result = Convert.toBool('maybe', defaultValue: true);

        // Assert
        expect(result, isTrue);
      },
    );

    test('should support mapKey and listIndex selection', () {
      // Arrange
      final data = <String, dynamic>{
        'b': ['true', 'false'],
      };

      // Act
      final a = Convert.toBool(data, mapKey: 'b', listIndex: 0);
      final b = Convert.toBool(data, mapKey: 'b', listIndex: 1);

      // Assert
      expect(a, isTrue);
      expect(b, isFalse);
    });

    test(
      'should honor BoolOptions.numericPositiveIsTrue when set to false',
      () {
        // Arrange
        const overrides = ConvertConfig(
          bools: BoolOptions(numericPositiveIsTrue: false),
        );

        // Act
        final r1 = withScopedConfig(overrides, () => Convert.toBool(-1));
        final r2 = withScopedConfig(overrides, () => Convert.toBool('-1'));
        final r3 = withScopedConfig(overrides, () => Convert.toBool(0));
        final r4 = withScopedConfig(overrides, () => Convert.toBool('0'));

        // Assert
        expect(r1, isTrue, reason: '-1 should be true when != 0');
        expect(r2, isTrue, reason: '"-1" should be true when != 0');
        expect(r3, isFalse);
        expect(r4, isFalse);
      },
    );

    test('should honor custom truthy/falsy tokens from config', () {
      // Arrange
      const overrides = ConvertConfig(
        bools: BoolOptions(
          truthy: {'sure'},
          falsy: {'nah'},
          numericPositiveIsTrue: true,
        ),
      );

      // Act
      final sure = withScopedConfig(overrides, () => Convert.tryToBool('sure'));
      final nah = withScopedConfig(overrides, () => Convert.tryToBool('nah'));
      final yes = withScopedConfig(overrides, () => Convert.tryToBool('yes'));

      // Assert
      expect(sure, isTrue);
      expect(nah, isFalse);
      expect(yes, isNull, reason: '"yes" is not in custom truthy/falsy sets');
    });
  });

  group('Convert.tryToBool', () {
    test('should return null for unknown strings', () {
      // Arrange

      // Act
      final result = Convert.tryToBool('maybe');

      // Assert
      expect(result, isNull);
    });

    test(
      'should return defaultValue when parsing fails and defaultValue is provided',
      () {
        // Arrange

        // Act
        final result = Convert.tryToBool('maybe', defaultValue: true);

        // Assert
        expect(result, isTrue);
      },
    );
  });
}
