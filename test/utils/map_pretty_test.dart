// File: test/utils/map_pretty_test.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert_object/src/utils/map_pretty.dart';
import 'package:test/test.dart';

enum Flavor { vanilla, chocolate, strawberry }

class Box {
  Box(this.x);

  final int x;
}

void main() {
  group('jsonSafe - primitives & numbers', () {
    test('passes through null, bool, string, finite number', () {
      expect(jsonSafe(null), isNull);
      expect(jsonSafe(true), isTrue);
      expect(jsonSafe('hi'), 'hi');
      expect(jsonSafe(42), 42);
      expect(jsonSafe(3.14), 3.14);
    });

    test('non-finite doubles as strings', () {
      expect(jsonSafe(double.nan), 'NaN');
      expect(jsonSafe(double.infinity), 'Infinity');
      expect(jsonSafe(double.negativeInfinity), '-Infinity');
    });

    test('non-finite doubles as null', () {
      const opts = JsonOptions(
        nonFiniteDoubles: NonFiniteDoubleStrategy.nullValue,
      );
      expect(jsonSafe(double.nan, options: opts), isNull);
      expect(jsonSafe(double.infinity, options: opts), isNull);
      expect(jsonSafe(double.negativeInfinity, options: opts), isNull);
    });

    test('non-finite doubles error', () {
      const opts = JsonOptions(
        nonFiniteDoubles: NonFiniteDoubleStrategy.error,
      );
      expect(() => jsonSafe(double.nan, options: opts), throwsUnsupportedError);
      expect(() => jsonSafe(double.infinity, options: opts),
          throwsUnsupportedError);
      expect(() => jsonSafe(double.negativeInfinity, options: opts),
          throwsUnsupportedError);
    });
  });

  group('jsonSafe - enums, DateTime, Duration', () {
    test('enum by name (default) and by index', () {
      expect(jsonSafe(Flavor.chocolate), 'chocolate');

      const idx = JsonOptions(encodeEnumsAsName: false);
      expect(jsonSafe(Flavor.chocolate, options: idx), Flavor.chocolate.index);
    });

    test('DateTime strategies', () {
      final dt = DateTime.utc(2025, 11, 11, 10, 15, 30, 123, 456);
      expect(
        jsonSafe(dt),
        // Default: ISO-8601 string
        '2025-11-11T10:15:30.123456Z',
      );

      const ms = JsonOptions(
        dateTimeStrategy: DateTimeStrategy.millisecondsSinceEpoch,
      );
      const us = JsonOptions(
        dateTimeStrategy: DateTimeStrategy.microsecondsSinceEpoch,
      );

      expect(jsonSafe(dt, options: ms), dt.millisecondsSinceEpoch);
      expect(jsonSafe(dt, options: us), dt.microsecondsSinceEpoch);
    });

    test('Duration strategies (ms, us, iso8601)', () {
      const d = Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 500);

      // default: milliseconds
      expect(jsonSafe(d), 3723500);

      const micros =
          JsonOptions(durationStrategy: DurationStrategy.microseconds);
      expect(jsonSafe(d, options: micros), 3723500000);

      const iso = JsonOptions(durationStrategy: DurationStrategy.iso8601);
      expect(jsonSafe(d, options: iso), 'PT1H2M3.5S');

      // Zero duration
      expect(jsonSafe(Duration.zero, options: iso), 'PT0S');

      // Fractional seconds with trimmed zeros
      const d2 = Duration(seconds: 3, microseconds: 250000); // 3.25s
      expect(jsonSafe(d2, options: iso), 'PT3.25S');
    });
  });

  group('jsonSafe - Uri, BigInt, binary', () {
    test('Uri encodes to string', () {
      final u = Uri.parse('https://example.com/a?b=c');
      expect(jsonSafe(u), 'https://example.com/a?b=c');
    });

    test('BigInt encodes to string', () {
      final b = BigInt.parse('12345678901234567890');
      expect(jsonSafe(b), '12345678901234567890');
    });

    test('Uint8List -> base64', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      expect(jsonSafe(bytes), 'AQIDBA==');
    });

    test('ByteBuffer -> base64', () {
      final buffer = Uint8List.fromList([1, 2, 3]).buffer;
      expect(jsonSafe(buffer), 'AQID');
    });

    test('ByteData -> base64', () {
      final data = ByteData.view(Uint8List.fromList([255, 0, 1]).buffer);
      expect(jsonSafe(data), '/wAB');
    });
  });

  group('Map helpers', () {
    test('toJsonMap stringifies keys and recurses', () {
      final map = {
        1: 'a',
        'b': DateTime.utc(2025, 1, 2, 3, 4, 5),
      };

      final result = map.toJsonMap();
      expect(result.keys, containsAll(<String>['1', 'b']));
      expect(result['1'], 'a');
      expect(result['b'], '2025-01-02T03:04:05.000Z');
    });

    test('toJsonMap dropNulls removes explicit nulls', () {
      final input = {
        'a': null,
        'b': double.nan, // becomes null but is still kept (source non-null)
        'c': 1,
      };

      const opts = JsonOptions(
        dropNulls: true,
        nonFiniteDoubles: NonFiniteDoubleStrategy.nullValue,
      );

      final out = input.toJsonMap(options: opts);
      expect(out.containsKey('a'), isFalse);
      expect(out.containsKey('b'), isTrue);
      expect(out['b'], isNull);
      expect(out['c'], 1);
    });

    test('toJsonMap sortKeys sorts lexicographically', () {
      final input = {'b': 1, 'a': 2, 'c': 3};
      final out = input.toJsonMap(
        options: const JsonOptions(sortKeys: true),
      );
      expect(out.keys.toList(), ['a', 'b', 'c']);
    });

    test('toJsonString produces valid JSON', () {
      final input = {
        'x': [1, 2, 3]
      };
      final jsonText = input.toJsonString();
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      expect(decoded['x'], [1, 2, 3]);
    });

    test('encodeWithIndent equals toJsonString(indent: "  ")', () {
      final input = {'a': 1, 'b': 2};
      final a = input.encodeWithIndent;
      final b = input.toJsonString(indent: '  ');
      expect(a, b);
      expect(a.startsWith('{\n  '), isTrue);
      expect(a.endsWith('\n}'), isTrue);
    });
  });

  group('Iterable helpers', () {
    test('toJsonList recurses', () {
      final list = [Flavor.vanilla, DateTime.utc(2025, 1, 1)];
      final out = list.toJsonList();
      expect(out[0], 'vanilla');
      expect(out[1], '2025-01-01T00:00:00.000Z');
    });

    test('toJsonString produces valid JSON', () {
      final list = [1, 2, 3];
      final jsonText = list.toJsonString();
      final decoded = jsonDecode(jsonText);
      expect(decoded, [1, 2, 3]);
    });

    test('encodeWithIndent adds two-space indentation', () {
      final list = [1, 2];
      final pretty = list.encodeWithIndent;
      expect(pretty.startsWith('[\n  '), isTrue);
      expect(pretty.endsWith('\n]'), isTrue);
    });
  });

  group('Set behavior', () {
    test('setsAsLists=true converts to list', () {
      final s = {1, 2};
      final out = jsonSafe(s);
      expect(out, isA<List<Object?>>());
      expect((out as List).length, 2);
      expect(out.contains(1), isTrue);
      expect(out.contains(2), isTrue);
    });
  });

  group('Unknown objects + stringifyUnknown', () {
    test('stringifyUnknown=true falls back to toString()', () {
      final out = jsonSafe(Box(42));
      expect(out, equals('Instance of \'Box\''));
    });

    test('stringifyUnknown=false throws', () {
      expect(
        () => jsonSafe(
          Box(99),
          options: const JsonOptions(stringifyUnknown: false),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('toEncodable hook', () {
    Object? enc(dynamic o) {
      if (o is Box) return {'x': o.x, 'at': DateTime.utc(2020, 1, 2, 3, 4, 5)};
      return o;
    }

    test('applies toEncodable at top-level', () {
      final out = jsonSafe(Box(7), toEncodable: enc);
      expect(out, isA<Map<String, dynamic>>());
      final map = out as Map<String, dynamic>;
      expect(map['x'], 7);
      expect(map['at'], '2020-01-02T03:04:05.000Z');
    });

    test('applies toEncodable for nested values', () {
      final out = jsonSafe({'box': Box(9)}, toEncodable: enc);
      expect(out, isA<Map<String, dynamic>>());
      final m = out as Map<String, dynamic>;
      expect(m['box'], isA<Map<String, dynamic>>());
      final nested = m['box'] as Map<String, dynamic>;
      expect(nested['x'], 9);
      expect(nested['at'], '2020-01-02T03:04:05.000Z');
    });

    test('Object?.toJsonSafe/toJsonString use hook', () {
      final safe = Box(3).toJsonSafe(toEncodable: enc);
      expect((safe as Map<String, dynamic>)['x'], 3);

      final text = Box(4).toJsonString(toEncodable: enc);
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      expect(decoded['x'], 4);
      expect(decoded['at'], '2020-01-02T03:04:05.000Z');
    });
  });

  group('Cycle detection', () {
    test('self-referential list', () {
      final a = <dynamic>[];
      a.add(a);
      final out = jsonSafe(
        a,
        options: const JsonOptions(detectCycles: true),
      );
      expect(out, isA<List<Object?>>());
      expect((out as List).single, '<cycle>');
    });

    test('self-referential map', () {
      final m = <String, dynamic>{};
      m['self'] = m;
      final out = jsonSafe(
        m,
        options: const JsonOptions(detectCycles: true),
      );
      expect(out, isA<Map<String, dynamic>>());
      expect((out as Map<String, dynamic>)['self'], '<cycle>');
    });
  });

  group('Integration - encode results are JSON encodable by dart:convert', () {
    test('map', () {
      final encoded = jsonSafe({
        'ok': true,
        'n': 1.5,
        'flavor': Flavor.vanilla,
        'at': DateTime.utc(2025, 1, 1),
        'd': const Duration(seconds: 1),
        'b': BigInt.one,
        'u': Uri.parse('https://dart.dev'),
        'bytes': Uint8List.fromList([1, 2, 3]),
        'list': [1, 2, 3],
        'set': {4, 5},
      });
      expect(() => json.encode(encoded), returnsNormally);
    });

    test('iterable helpers produce encodable text', () {
      final text = [Flavor.chocolate, DateTime.utc(2025, 2, 2)].toJsonString();
      expect(() => json.decode(text), returnsNormally);
    });

    test('map helpers produce encodable text', () {
      final text = {'a': 1, 'b': DateTime.utc(2025, 2, 2)}.toJsonString();
      expect(() => json.decode(text), returnsNormally);
    });
  });
}
