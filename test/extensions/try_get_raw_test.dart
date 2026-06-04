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
}
