// Additional tests for let or scope extensions covering gaps identified in audit.
//
// This file focuses on:
// - Chaining multiple scope functions
// - Different return types
// - Complex predicates
// - letOr with complex block logic
import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('LetExtension chaining scenarios', () {
    test('let -> also chain should work correctly', () {
      // Arrange
      const value = 'hello';
      var sideEffectValue = '';

      // Act
      final result = value.let((it) => it.toUpperCase()).also((it) {
        sideEffectValue = 'processed: $it';
      });

      // Assert
      expect(result, equals('HELLO'));
      expect(sideEffectValue, equals('processed: HELLO'));
    });

    test('let -> let chain should transform correctly', () {
      // Arrange
      const value = '42';

      // Act
      final result = value.let((it) => int.parse(it)).let((it) => it * 2);

      // Assert
      expect(result, equals(84));
    });

    test('also -> let chain should work correctly', () {
      // Arrange
      final list = <int>[];

      // Act
      final result = list.also((it) => it.add(1)).let((it) => it.length);

      // Assert
      expect(result, equals(1));
      expect(list, equals([1]));
    });

    test('let -> takeIf chain should filter transformed value', () {
      // Arrange
      const value = '10';

      // Act
      final result = value
          .let((it) => int.parse(it))
          .takeIf((it) => it > 5);

      // Assert
      expect(result, equals(10));
    });

    test('let -> takeIf chain should return null when predicate fails', () {
      // Arrange
      const value = '3';

      // Act
      final result = value
          .let((it) => int.parse(it))
          .takeIf((it) => it > 5);

      // Assert
      expect(result, isNull);
    });

    test('multiple takeIf chain should apply all predicates', () {
      // Arrange
      const value = 15;

      // Act
      final result = value
          .takeIf((it) => it > 10)
          ?.takeIf((it) => it < 20)
          ?.takeIf((it) => it % 5 == 0);

      // Assert
      expect(result, equals(15));
    });

    test('takeIf -> takeUnless chain should work correctly', () {
      // Arrange
      const value = 'hello';

      // Act
      final result = value
          .takeIf((it) => it.isNotEmpty)
          ?.takeUnless((it) => it.contains('x'));

      // Assert
      expect(result, equals('hello'));
    });
  });

  group('LetExtension with different return types', () {
    test('let should transform String to int', () {
      // Arrange
      const value = '123';

      // Act
      final result = value.let((it) => int.parse(it));

      // Assert
      expect(result, isA<int>());
      expect(result, equals(123));
    });

    test('let should transform int to double', () {
      // Arrange
      const value = 42;

      // Act
      final result = value.let((it) => it.toDouble());

      // Assert
      expect(result, isA<double>());
      expect(result, equals(42.0));
    });

    test('let should transform to List', () {
      // Arrange
      const value = 'a,b,c';

      // Act
      final result = value.let((it) => it.split(','));

      // Assert
      expect(result, isA<List<String>>());
      expect(result, equals(['a', 'b', 'c']));
    });

    test('let should transform to Map', () {
      // Arrange
      const value = 'key=value';

      // Act
      final result = value.let((it) {
        final parts = it.split('=');
        return {parts[0]: parts[1]};
      });

      // Assert
      expect(result, isA<Map<String, String>>());
      expect(result, equals({'key': 'value'}));
    });

    test('let should return null when block returns null', () {
      // Arrange
      const value = 'test';

      // Act
      final result = value.let<String?>((it) => null);

      // Assert
      expect(result, isNull);
    });
  });

  group('LetExtension with complex predicates', () {
    test('takeIf with multi-condition predicate', () {
      // Arrange
      const value = 'HelloWorld';

      // Act
      final result = value.takeIf((it) {
        return it.length > 5 &&
            it.startsWith('H') &&
            it.endsWith('d') &&
            !it.contains(' ');
      });

      // Assert
      expect(result, equals('HelloWorld'));
    });

    test('takeUnless with multi-condition predicate', () {
      // Arrange
      const value = 'safe_string';

      // Act
      final result = value.takeUnless((it) {
        return it.contains('<') || it.contains('>') || it.contains('&');
      });

      // Assert
      expect(result, equals('safe_string'));
    });

    test('takeIf with external state in predicate', () {
      // Arrange
      const value = 100;
      const threshold = 50;

      // Act
      final result = value.takeIf((it) => it > threshold);

      // Assert
      expect(result, equals(100));
    });
  });

  group('LetExtensionNullable chaining scenarios', () {
    test('let chain should short-circuit on null', () {
      // Arrange
      String? value;
      var blockCalled = false;

      // Act
      final result = value
          .let((it) => it.toUpperCase())
          ?.let((it) {
            blockCalled = true;
            return it.length;
          });

      // Assert
      expect(result, isNull);
      expect(blockCalled, isFalse);
    });

    test('let chain should continue when non-null', () {
      // Arrange
      String? value = 'hello';

      // Act
      final result = value.let((it) => it.toUpperCase()).let((it) => it.length);

      // Assert
      expect(result, equals(5));
    });

    test('letOr -> let chain should work correctly', () {
      // Arrange
      String? value;

      // Act
      final result = value
          .letOr((it) => it.toUpperCase(), defaultValue: 'DEFAULT')
          .let((it) => it.length);

      // Assert
      expect(result, equals(7));
    });

    test('also chain with nullable receiver', () {
      // Arrange
      String? value = 'test';
      var sideEffect1 = '';
      var sideEffect2 = '';

      // Act
      final result = value
          .also((it) => sideEffect1 = 'first: $it')
          .also((it) => sideEffect2 = 'second: $it');

      // Assert
      expect(result, equals('test'));
      expect(sideEffect1, equals('first: test'));
      expect(sideEffect2, equals('second: test'));
    });
  });

  group('LetExtensionNullable letOr edge cases', () {
    test('letOr with complex block returning different type', () {
      // Arrange
      String? value = '123';

      // Act
      final result = value.letOr(
        (it) => int.parse(it) * 2,
        defaultValue: -1,
      );

      // Assert
      expect(result, equals(246));
    });

    test('letOr with null receiver uses defaultValue', () {
      // Arrange
      String? value;

      // Act
      final result = value.letOr(
        (it) => int.parse(it) * 2,
        defaultValue: -1,
      );

      // Assert
      expect(result, equals(-1));
    });

    test('letOr with block that could throw (but receiver is null)', () {
      // Arrange
      String? value;
      var blockCalled = false;

      // Act
      final result = value.letOr(
        (it) {
          blockCalled = true;
          throw Exception('Should not be called');
        },
        defaultValue: 'safe',
      );

      // Assert
      expect(result, equals('safe'));
      expect(blockCalled, isFalse);
    });
  });

  group('LetExtensionNullable letNullable edge cases', () {
    test('letNullable with block that returns null', () {
      // Arrange
      String? value = 'test';

      // Act
      final result = value.letNullable((it) => null);

      // Assert
      expect(result, isNull);
    });

    test('letNullable with nullable return type', () {
      // Arrange
      String? value = 'test';

      // Act
      final result = value.letNullable<int?>((it) {
        return it?.length;
      });

      // Assert
      expect(result, equals(4));
    });

    test('letNullable block can safely access potentially null receiver', () {
      // Arrange
      String? value;

      // Act
      final result = value.letNullable((it) => it?.toUpperCase());

      // Assert
      expect(result, isNull);
    });
  });

  group('LetExtension also side effects', () {
    test('also should allow mutating mutable receiver', () {
      // Arrange
      final list = <int>[1, 2, 3];

      // Act
      final result = list.also((it) {
        it.add(4);
        it.add(5);
      });

      // Assert
      expect(result, same(list));
      expect(result, equals([1, 2, 3, 4, 5]));
    });

    test('also should allow logging-style side effects', () {
      // Arrange
      const value = 'important_data';
      final logs = <String>[];

      // Act
      final result = value.also((it) {
        logs.add('Processing: $it');
        logs.add('Length: ${it.length}');
      });

      // Assert
      expect(result, equals('important_data'));
      expect(logs, equals([
        'Processing: important_data',
        'Length: 14',
      ]));
    });

    test('also should not modify immutable receiver', () {
      // Arrange
      const value = 'original';
      var captured = '';

      // Act
      final result = value.also((it) {
        captured = it.toUpperCase();
      });

      // Assert
      expect(result, equals('original'));
      expect(captured, equals('ORIGINAL'));
    });
  });

  group('Scope function type safety', () {
    test('let preserves type through transformation', () {
      // Arrange
      const value = 42;

      // Act
      final result = value.let<String>((it) => 'Value: $it');

      // Assert
      expect(result, isA<String>());
      expect(result, equals('Value: 42'));
    });

    test('takeIf returns same type as receiver', () {
      // Arrange
      const value = 'hello';

      // Act
      final result = value.takeIf((it) => it.isNotEmpty);

      // Assert
      expect(result, isA<String?>());
      expect(result, equals('hello'));
    });

    test('also returns exactly the receiver', () {
      // Arrange
      final original = <int>[1, 2, 3];

      // Act
      final result = original.also((it) => it.length);

      // Assert
      expect(identical(result, original), isTrue);
    });
  });

  group('LetExtensionNullable non-null branches', () {
    test('also should execute block and return value for non-null receiver', () {
      // Arrange
      String? valueProvider() => 'hello';
      var sideEffect = '';

      // Act
      final result = valueProvider().also((it) {
        sideEffect = it;
      });

      // Assert
      expect(result, equals('hello'));
      expect(sideEffect, equals('hello'));
    });

    test('takeIf should return value when predicate is true', () {
      // Arrange
      String? valueProvider() => 'keep';

      // Act
      final result = valueProvider().takeIf((it) => it.startsWith('k'));

      // Assert
      expect(result, equals('keep'));
    });

    test('takeUnless should return value when predicate is false', () {
      // Arrange
      String? valueProvider() => 'keep';

      // Act
      final result = valueProvider().takeUnless((it) => it.contains('x'));

      // Assert
      expect(result, equals('keep'));
    });
  });
}
