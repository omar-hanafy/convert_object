import 'dart:convert';

import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../_setup/test_config.dart';

// Local enum for testing encodable conversion.
enum Fruit { apple, banana }

class Point {
  Point(this.x, this.y);

  final int x, y;

  @override
  String toString() => 'Point($x,$y)';
}

void main() {
  configureTests(defaultLocale: 'en_US');

  group('map_pretty.dart', () {
    test('makeValueEncodable on primitives/enum/list/set/map/custom', () {
      final data = {
        1: 'a', // non-string key
        'num': 3.14,
        'bool': true,
        'enum': Fruit.banana,
        'list': [
          1,
          Fruit.apple,
          {'k': 'v'}
        ],
        'set': {1, 2, 3},
        'map': {'x': 1, 'y': 2},
        'custom': Point(2, 5), // falls back to toString()
        'null': null,
      };

      final enc = data.encodableCopy;

      // Keys become strings
      expect(enc.containsKey('1'), isTrue);
      expect(enc['1'], 'a');

      // Enum -> name
      expect(enc['enum'], 'banana');

      // List and Set become encodable lists
      expect(enc['list'], [
        1,
        'apple',
        {'k': 'v'}
      ]);
      expect(enc['set'], [1, 2, 3]);

      // Nested maps stay maps with string keys
      expect(enc['map'], {'x': 1, 'y': 2});

      // Custom object -> toString()
      expect(enc['custom'], 'Point(2,5)');

      // Null preserved
      expect(enc['null'], isNull);
    });

    test('encodedJsonString produces pretty JSON', () {
      final m = {
        'a': 1,
        'b': [1, 2]
      };
      final pretty = m.encodedJsonText;
      // Basic sanity checks (don’t assert exact whitespace)
      expect(pretty, contains('\n'));
      final decoded = json.decode(pretty) as Map<String, dynamic>;
      expect(decoded, {
        'a': 1,
        'b': [1, 2]
      });
    });

    test('PrettyJsonIterable encodedJson / encodedJsonWithIndent', () {
      final values = [
        1,
        Fruit.apple,
        {'k': 'v'},
        {
          'set': {1, 2}
        }
      ];
      final enc = values.encodableList;
      // [1, 'apple', {'k':'v'}, {'set':[1,2]}]
      expect(enc[1], 'apple');
      expect((enc[3] as Map)['set'], [1, 2]);

      final compact = values.encodedJson;
      final pretty = values.encodedJsonWithIndent('    ');
      // Both should decode to the same structure
      expect(json.decode(compact), json.decode(pretty));
    });

    test('PrettyJsonObject.encode with toEncodable fallback', () {
      final obj = {
        'when': DateTime.utc(2024, 1, 2, 3, 4, 5),
        'p': Point(1, 2),
      };

      final jsonText = obj.encode(toEncodable: (o) {
        if (o is DateTime) return o.toIso8601String();
        // For any custom type, fall back to toString()
        return o.toString();
      });

      final decoded = json.decode(jsonText);
      expect(decoded['when'], '2024-01-02T03:04:05.000Z');
      expect(decoded['p'], 'Point(1,2)');
    });
  });
}
