import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/test_enums.dart';

void main() {
  group('jsonSafe', () {
    test('should return primitive values unchanged', () {
      // Arrange
      const n = 1;
      const d = 1.5;
      const s = 'hello';
      const b = true;
      const nil = null;

      // Act
      final outN = jsonSafe(n);
      final outD = jsonSafe(d);
      final outS = jsonSafe(s);
      final outB = jsonSafe(b);
      final outNil = jsonSafe(nil);

      // Assert
      expect(outN, equals(1));
      expect(outD, equals(1.5));
      expect(outS, equals('hello'));
      expect(outB, equals(true));
      expect(outNil, isNull);
    });

    test('should encode non-finite doubles as strings by default', () {
      // Arrange
      const nan = double.nan;
      const inf = double.infinity;
      const ninf = double.negativeInfinity;

      // Act
      final outNan = jsonSafe(nan);
      final outInf = jsonSafe(inf);
      final outNInf = jsonSafe(ninf);

      // Assert
      expect(outNan, equals('NaN'));
      expect(outInf, equals('Infinity'));
      expect(outNInf, equals('-Infinity'));
    });

    test('should encode non-finite doubles as null when configured', () {
      // Arrange
      const nan = double.nan;
      const options = JsonOptions(
        nonFiniteDoubles: NonFiniteDoubleStrategy.nullValue,
      );

      // Act
      final out = jsonSafe(nan, options: options);

      // Assert
      expect(out, isNull);
    });

    test('should throw when configured to error on non-finite doubles', () {
      // Arrange
      const nan = double.nan;
      const options = JsonOptions(
        nonFiniteDoubles: NonFiniteDoubleStrategy.error,
      );

      // Act / Assert
      expect(
        () => jsonSafe(nan, options: options),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test(
      'should encode enums as name by default and index when configured',
      () {
        // Arrange
        const e = TestColor.green;

        // Act
        final byName = jsonSafe(e);
        final byIndex = jsonSafe(
          e,
          options: const JsonOptions(encodeEnumsAsName: false),
        );

        // Assert
        expect(byName, equals('green'));
        expect(byIndex, equals(TestColor.green.index));
        expect(byIndex, isA<int>());
      },
    );

    test('should encode DateTime using configured strategies', () {
      // Arrange
      final dt = DateTime.utc(2025, 11, 11, 10, 15, 30);

      // Act
      final asIso = jsonSafe(
        dt,
        options: const JsonOptions(
          dateTimeStrategy: DateTimeStrategy.iso8601String,
        ),
      );
      final asMs = jsonSafe(
        dt,
        options: const JsonOptions(
          dateTimeStrategy: DateTimeStrategy.millisecondsSinceEpoch,
        ),
      );
      final asUs = jsonSafe(
        dt,
        options: const JsonOptions(
          dateTimeStrategy: DateTimeStrategy.microsecondsSinceEpoch,
        ),
      );

      // Assert
      expect(asIso, equals(dt.toIso8601String()));
      expect(asMs, equals(dt.millisecondsSinceEpoch));
      expect(asMs, isA<int>());
      expect(asUs, equals(dt.microsecondsSinceEpoch));
      expect(asUs, isA<int>());
    });

    test('should encode Duration using configured strategies', () {
      // Arrange
      const dur = Duration(hours: 1, minutes: 2, seconds: 3);
      const zero = Duration.zero;
      const fractional = Duration(seconds: 1, microseconds: 500000);

      // Act
      final ms = jsonSafe(
        dur,
        options: const JsonOptions(
          durationStrategy: DurationStrategy.milliseconds,
        ),
      );
      final us = jsonSafe(
        dur,
        options: const JsonOptions(
          durationStrategy: DurationStrategy.microseconds,
        ),
      );
      final iso = jsonSafe(
        dur,
        options: const JsonOptions(durationStrategy: DurationStrategy.iso8601),
      );
      final isoZero = jsonSafe(
        zero,
        options: const JsonOptions(durationStrategy: DurationStrategy.iso8601),
      );
      final isoFractional = jsonSafe(
        fractional,
        options: const JsonOptions(durationStrategy: DurationStrategy.iso8601),
      );
      final isoWithDays = jsonSafe(
        const Duration(days: 1, hours: 2),
        options: const JsonOptions(durationStrategy: DurationStrategy.iso8601),
      );

      // Assert
      expect(ms, equals(dur.inMilliseconds));
      expect(us, equals(dur.inMicroseconds));
      expect(iso, equals('PT1H2M3S'));
      expect(isoZero, equals('PT0S'));
      expect(isoFractional, equals('PT1.5S'));
      expect(isoWithDays, equals('P1DT2H'));
    });

    test('should handle sets when cycle detection is enabled', () {
      // Arrange
      final input = <int>{1, 2, 3};

      // Act
      final out = jsonSafe(
        input,
        options: const JsonOptions(detectCycles: true),
      );

      // Assert
      expect(out, equals(<int>[1, 2, 3]));
    });

    test('should encode Uri and BigInt as strings', () {
      // Arrange
      final uri = Uri.parse('https://example.com/path?q=1');
      final big = BigInt.parse('123456789012345678901234567890');

      // Act
      final outUri = jsonSafe(uri);
      final outBig = jsonSafe(big);

      // Assert
      expect(outUri, equals(uri.toString()));
      expect(outBig, equals(big.toString()));
      expect(outBig, isA<String>());
    });

    test('should base64 encode Uint8List, ByteBuffer, and ByteData', () {
      // Arrange
      final bytes = Uint8List.fromList(<int>[1, 2, 3]);
      final buffer = bytes.buffer;
      final data = ByteData.sublistView(bytes);
      final expected = base64Encode(bytes);

      // Act
      final outBytes = jsonSafe(bytes);
      final outBuffer = jsonSafe(buffer);
      final outData = jsonSafe(data);

      // Assert
      expect(outBytes, equals(expected));
      expect(outBuffer, equals(expected));
      expect(outData, equals(expected));
    });

    test('should stringify map keys and walk nested values', () {
      // Arrange
      final input = <Object, Object?>{
        1: 'a',
        true: 2,
        'nested': <Object, Object?>{3: TestColor.red},
      };

      // Act
      final out = jsonSafe(input);

      // Assert
      expect(out, isA<Map>());
      final map = out as Map;
      expect(map.containsKey('1'), isTrue);
      expect(map['1'], equals('a'));
      expect(map.containsKey('true'), isTrue);
      expect(map['true'], equals(2));

      final nested = map['nested'] as Map;
      expect(nested['3'], equals('red'));
    });

    test('should drop nulls recursively when dropNulls is true', () {
      // Arrange
      final input = <String, dynamic>{
        'a': null,
        'b': 1,
        'nested': <String, dynamic>{'c': null, 'd': 2},
      };

      // Act
      final out =
          jsonSafe(input, options: const JsonOptions(dropNulls: true)) as Map;

      // Assert
      expect(out.containsKey('a'), isFalse);
      expect(out['b'], equals(1));

      final nested = out['nested'] as Map;
      expect(nested.containsKey('c'), isFalse);
      expect(nested['d'], equals(2));
    });

    test('should sort keys lexicographically when sortKeys is true', () {
      // Arrange
      final input = <String, dynamic>{'b': 1, 'a': 2};

      // Act
      final out = jsonSafe(input, options: const JsonOptions(sortKeys: true));

      // Assert
      expect(out, isA<SplayTreeMap<String, dynamic>>());
      final map = out as Map<String, dynamic>;
      expect(map.keys.toList(), equals(<String>['a', 'b']));
    });

    test(
      'should replace cycles with a placeholder when detectCycles is true',
      () {
        // Arrange
        final a = <String, dynamic>{};
        a['self'] = a;

        // Act
        final out = jsonSafe(
          a,
          options: const JsonOptions(
            detectCycles: true,
            cyclePlaceholder: '<cycle>',
          ),
        );

        // Assert
        expect(out, isA<Map>());
        final map = out as Map;
      expect(map['self'], equals('<cycle>'));
    },
    );

    test('should replace cycles inside lists when detectCycles is true', () {
      // Arrange
      final list = <dynamic>[];
      list.add(list);

      // Act
      final out = jsonSafe(
        list,
        options: const JsonOptions(
          detectCycles: true,
          cyclePlaceholder: '<cycle>',
        ),
      );

      // Assert
      expect(out, isA<List>());
      expect((out as List).first, equals('<cycle>'));
    });

    test('should still serialize sets when setsAsLists is false', () {
      // Arrange
      final input = <int>{1, 2};

      // Act
      final out = jsonSafe(
        input,
        options: const JsonOptions(setsAsLists: false),
      );

      // Assert
      expect(out, isA<List>());
      expect((out as List).toSet(), equals(<int>{1, 2}));
    });

    test('should allow toEncodable to transform unknown objects', () {
      // Arrange
      final input = const _Custom(7);

      Object? encoder(dynamic obj) {
        if (obj is _Custom) {
          return <String, dynamic>{'x': obj.x};
        }
        return null;
      }

      // Act
      final out = jsonSafe(input, toEncodable: encoder);

      // Assert
      expect(out, isA<Map>());
      expect((out as Map)['x'], equals(7));
    });

    test('should stringify unknown objects when stringifyUnknown is true', () {
      // Arrange
      final input = _Unknown();

      // Act
      final out = jsonSafe(
        input,
        options: const JsonOptions(stringifyUnknown: true),
      );

      // Assert
      expect(out, equals('Unknown!'));
    });

    test('should throw for unknown objects when stringifyUnknown is false', () {
      // Arrange
      final input = _Unknown();

      // Act / Assert
      expect(
        () => jsonSafe(
          input,
          options: const JsonOptions(stringifyUnknown: false),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('JsonMapX / JsonIterableX / JsonAnyX', () {
    test('Map.toJsonMap should produce JSON-safe values', () {
      // Arrange
      final dt = DateTime.utc(2025, 11, 11, 10, 15, 30);
      final input = <Object, Object?>{
        'enum': TestStatus.active,
        'dt': dt,
        'n': double.nan,
        1: 'stringified-key',
      };

      // Act
      final out = input.toJsonMap();

      // Assert
      expect(out, isA<Map<String, dynamic>>());
      expect(out['enum'], equals('active'));
      expect(out['dt'], equals(dt.toIso8601String()));
      expect(out['n'], equals('NaN'));
      expect(out['1'], equals('stringified-key'));
    });

    test('Map.toJsonMap should sort keys when configured', () {
      // Arrange
      final input = <String, Object?>{'b': 2, 'a': 1};

      // Act
      final out = input.toJsonMap(options: const JsonOptions(sortKeys: true));

      // Assert
      expect(out.keys.toList(), equals(<String>['a', 'b']));
    });

    test('Map.toJsonString should encode to valid JSON and round-trip', () {
      // Arrange
      final input = <String, Object?>{'a': 1, 'b': TestColor.blue};

      // Act
      final json = input.toJsonString(indent: '  ');
      final decoded = jsonDecode(json);

      // Assert
      expect(json, contains('\n'));
      expect(decoded, isA<Map>());
      expect((decoded as Map)['a'], equals(1));
      expect(decoded['b'], equals('blue'));
    });

    test('Map.encodeWithIndent should return a pretty JSON string', () {
      // Arrange
      final input = <String, Object?>{'a': 1, 'b': 2};

      // Act
      final text = input.encodeWithIndent;

      // Assert
      expect(text, contains('\n'));
      expect(text, contains('  ')); // indentation
      expect(jsonDecode(text), equals(<String, dynamic>{'a': 1, 'b': 2}));
    });

    test('Iterable.toJsonList should produce JSON-safe list items', () {
      // Arrange
      final input = <Object?>[
        TestColor.red,
        DateTime.utc(2025, 1, 1),
        double.infinity,
      ];

      // Act
      final out = input.toJsonList();

      // Assert
      expect(out, isA<List<dynamic>>());
      expect(out[0], equals('red'));
      expect(out[1], equals(DateTime.utc(2025, 1, 1).toIso8601String()));
      expect(out[2], equals('Infinity'));
    });

    test('Iterable.toJsonString should encode to valid JSON', () {
      // Arrange
      final input = <Object?>[TestColor.red, 2, 'x'];

      // Act
      final text = input.toJsonString();
      final decoded = jsonDecode(text) as List<dynamic>;

      // Assert
      expect(decoded, equals(<dynamic>['red', 2, 'x']));
    });

    test('Iterable.toJsonString should honor indentation', () {
      // Arrange
      final input = <Object?>[TestColor.green, 2];

      // Act
      final text = input.toJsonString(indent: '  ');
      final decoded = jsonDecode(text) as List<dynamic>;

      // Assert
      expect(text, contains('\n'));
      expect(decoded, equals(<dynamic>['green', 2]));
    });

    test('Iterable.encodeWithIndent should return pretty JSON', () {
      // Arrange
      final input = <Object?>[1, TestColor.red];

      // Act
      final text = input.encodeWithIndent;

      // Assert
      expect(text, contains('\n'));
      expect(jsonDecode(text), equals(<dynamic>[1, 'red']));
    });

    test('Object.toJsonSafe should normalize values consistently', () {
      // Arrange
      final input = <String, Object?>{
        'enum': TestHttpMethod.post,
        'dur': const Duration(minutes: 1),
      };

      // Act
      final out = input.toJsonSafe();

      // Assert
      expect(out, isA<Map>());
      final map = out as Map;
      expect(map['enum'], equals('post'));
      expect(map['dur'], equals(const Duration(minutes: 1).inMilliseconds));
    });

    test('Object.toJsonString should encode values directly', () {
      // Arrange
      final Object input = <String, Object?>{'a': 1, 'b': TestColor.blue};

      // Act
      final text = input.toJsonString();
      final decoded = jsonDecode(text) as Map<String, dynamic>;

      // Assert
      expect(decoded['a'], equals(1));
      expect(decoded['b'], equals('blue'));
    });

    test('Object.toJsonString should honor indentation', () {
      // Arrange
      final Object input = <String, Object?>{'a': 1, 'b': TestColor.red};

      // Act
      final text = input.toJsonString(indent: '  ');
      final decoded = jsonDecode(text) as Map<String, dynamic>;

      // Assert
      expect(text, contains('\n'));
      expect(decoded['a'], equals(1));
      expect(decoded['b'], equals('red'));
    });
  });

  group('JsonOptions', () {
    test('copyWith should update selected fields only', () {
      // Arrange
      const options = JsonOptions();

      // Act
      final updated = options.copyWith(dropNulls: true, sortKeys: true);

      // Assert
      expect(updated.dropNulls, isTrue);
      expect(updated.sortKeys, isTrue);
      expect(updated.encodeEnumsAsName, isTrue);
      expect(updated.durationStrategy, equals(DurationStrategy.milliseconds));
      expect(updated.nonFiniteDoubles, equals(NonFiniteDoubleStrategy.string));
    });

    test('copyWith should honor dropNulls and sortKeys variables', () {
      // Arrange
      final initialDropNulls = false;
      final initialSortKeys = false;
      final options = JsonOptions(
        dropNulls: initialDropNulls,
        sortKeys: initialSortKeys,
      );
      final dropNulls = true;
      final sortKeys = true;

      // Act
      final updated = options.copyWith(
        dropNulls: dropNulls,
        sortKeys: sortKeys,
      );

      // Assert
      expect(updated.dropNulls, isTrue);
      expect(updated.sortKeys, isTrue);
    });
  });
}

class _Custom {
  const _Custom(this.x);
  final int x;
}

class _Unknown {
  @override
  String toString() => 'Unknown!';
}
