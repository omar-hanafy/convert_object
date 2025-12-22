import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';

void main() {
  group('BoolParsingX.asBool', () {
    test('should return false for null', () {
      // Arrange
      Object? value;

      // Act
      final result = value.asBool;

      // Assert
      expect(result, isFalse);
    });

    test('should return the same value for boolean inputs', () {
      // Arrange
      const t = true;
      const f = false;

      // Act
      final tResult = t.asBool;
      final fResult = f.asBool;

      // Assert
      expect(tResult, isTrue);
      expect(fResult, isFalse);
    });

    test('should treat numeric values as true only when > 0', () {
      // Arrange
      const values = <num>[10, 1, 0, -1, -100];

      // Act
      final results = values.map((v) => v.asBool).toList();

      // Assert
      expect(results, equals(<bool>[true, true, false, false, false]));
    });

    test('should parse known truthy values as true', () {
      // Arrange
      final values = kTruthyValues;

      // Act / Assert
      for (final v in values) {
        expect(
          v.asBool,
          isTrue,
          reason: 'Expected "$v" to be parsed as true',
        );
      }
    });

    test('should parse known falsy values as false', () {
      // Arrange
      final values = kFalsyValues;

      // Act / Assert
      for (final v in values) {
        expect(
          v.asBool,
          isFalse,
          reason: 'Expected "$v" to be parsed as false',
        );
      }
    });

    test('should parse numeric strings using numeric semantics (> 0)', () {
      // Arrange
      const cases = <String, bool>{
        '1': true,
        '0': false,
        '-1': false,
        ' 10 ': true,
        '  -2  ': false,
      };

      for (final entry in cases.entries) {
        // Act
        final result = entry.key.asBool;

        // Assert
        expect(result, entry.value, reason: 'Input: "${entry.key}"');
      }
    });

    test('should return false for unknown or empty strings', () {
      // Arrange
      const cases = <String>['maybe', 'unknown', '', '   '];

      for (final input in cases) {
        // Act
        final result = input.asBool;

        // Assert
        expect(result, isFalse, reason: 'Input: "$input"');
      }
    });

    test('should return false for non-string, non-numeric, non-bool objects',
        () {
      // Arrange
      final value = <String, dynamic>{'a': 1};

      // Act
      final result = value.asBool;

      // Assert
      expect(result, isFalse);
    });
  });
}
