// Covers Map.tryGetRaw and the shared first-non-null `alternativeKeys` fallback
// used by every map getter. See
// docs/superpowers/specs/2026-06-04-raw-map-getter-design.md
import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('alternativeKeys first-non-null fallback', () {
    test('getString skips a present-but-null alt key to the next non-null', () {
      // Arrange
      final map = <String, dynamic>{'a': null, 'b': null, 'c': 'x'};

      // Act
      final result = map.getString('a', alternativeKeys: const ['b', 'c']);

      // Assert
      expect(result, equals('x'));
    });

    test('tryGetString skips a present-but-null alt key', () {
      // Arrange
      final map = <String, dynamic>{'a': null, 'b': null, 'c': 'x'};

      // Act
      final result = map.tryGetString('a', alternativeKeys: const ['b', 'c']);

      // Assert
      expect(result, equals('x'));
    });

    test('a present-but-null primary still falls through to alternatives', () {
      // Arrange
      final map = <String, dynamic>{'a': null, 'b': 'y'};

      // Act
      final result = map.getString('a', alternativeKeys: const ['b']);

      // Assert
      expect(result, equals('y'));
    });
  });

  group('tryGetRaw', () {
    test('returns the primary value without conversion', () {
      // Arrange
      final map = <String, dynamic>{'n': '5'};

      // Act
      final result = map.tryGetRaw('n');

      // Assert
      expect(result, '5'); // String, not int 5
      expect(result, isA<String>());
    });

    test('preserves Map and List values as-is', () {
      // Arrange
      final map = <String, dynamic>{
        'list': [1, 2],
        'map': {'a': 1},
      };

      // Act & Assert
      expect(map.tryGetRaw('list'), isA<List<dynamic>>());
      expect(map.tryGetRaw('list'), equals([1, 2]));
      expect(map.tryGetRaw('map'), isA<Map<dynamic, dynamic>>());
      expect(map.tryGetRaw('map'), equals({'a': 1}));
    });

    test('falls back to a single alternative key', () {
      // Arrange
      final map = <String, dynamic>{'fields': 'X'};

      // Act
      final result = map.tryGetRaw('errors', alternativeKeys: const ['fields']);

      // Assert
      expect(result, equals('X'));
    });

    test('skips a present-but-null alternative key to the next non-null', () {
      // Arrange
      final map = <String, dynamic>{'a': null, 'b': null, 'c': 'x'};

      // Act
      final result = map.tryGetRaw('a', alternativeKeys: const ['b', 'c']);

      // Assert
      expect(result, equals('x'));
    });

    test('returns null when nothing has a non-null value', () {
      // Arrange
      final map = <String, dynamic>{'a': null};

      // Act & Assert
      expect(map.tryGetRaw('a', alternativeKeys: const ['b']), isNull);
      expect(<String, dynamic>{}.tryGetRaw('missing'), isNull);
    });

    test('returns null on a null receiver', () {
      // Arrange
      Map<String, dynamic>? map;

      // Act
      final result = map.tryGetRaw('a', alternativeKeys: const ['b']);

      // Assert
      expect(result, isNull);
    });

    test('equals a null-safe ?? chain over the keys', () {
      // Arrange
      final map = <String, dynamic>{'a': null, 'b': 2, 'c': 3};

      // Act
      final raw = map.tryGetRaw('a', alternativeKeys: const ['b', 'c']);

      // Assert
      expect(raw, equals(map['a'] ?? map['b'] ?? map['c']));
    });
  });
}
