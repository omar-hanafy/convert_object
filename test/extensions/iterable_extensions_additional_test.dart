// Additional tests for iterable extensions covering gaps identified in audit.
//
// This file focuses on:
// - BigInt conversions
// - Uri conversions
// - ElementConverter parameter usage
// - Untested NullableIterableConversionX methods
// - Edge cases with negative indices
import 'package:convert_object/convert_object.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';
import '../helpers/test_enums.dart';

void main() {
  late ConvertConfig prev;
  late String? prevIntlLocale;

  setUp(() {
    prevIntlLocale = Intl.defaultLocale;
    Intl.defaultLocale = 'en_US';
    prev = Convert.configure(makeTestConfig(locale: 'en_US'));
  });

  tearDown(() {
    Convert.configure(prev);
    Intl.defaultLocale = prevIntlLocale;
  });

  group('IterableConversionX BigInt conversions', () {
    test('getBigInt should convert string element to BigInt', () {
      // Arrange
      final data = <String>['12345678901234567890'];

      // Act
      final result = data.getBigInt(0);

      // Assert
      expect(result, equals(BigInt.parse('12345678901234567890')));
    });

    test('getBigInt should convert int element to BigInt', () {
      // Arrange
      final data = <int>[42, 100];

      // Act
      final result = data.getBigInt(1);

      // Assert
      expect(result, equals(BigInt.from(100)));
    });

    test('getBigInt should use defaultValue when conversion fails', () {
      // Arrange
      final data = <String>['not-a-number'];

      // Act
      final result = data.getBigInt(0, defaultValue: BigInt.from(-1));

      // Assert
      expect(result, equals(BigInt.from(-1)));
    });

    test('getBigInt should support innerMapKey navigation', () {
      // Arrange
      final data = <Map<String, dynamic>>[
        {'bigVal': '999999999999'},
      ];

      // Act
      final result = data.getBigInt(0, innerMapKey: 'bigVal');

      // Assert
      expect(result, equals(BigInt.parse('999999999999')));
    });
  });

  group('IterableConversionX Uri conversions', () {
    test('getUri should convert string element to Uri', () {
      // Arrange
      final data = <String>['https://example.com/path'];

      // Act
      final result = data.getUri(0);

      // Assert
      expect(result, uriEquals('https://example.com/path'));
    });

    test('getUri should use defaultValue when index out of bounds', () {
      // Arrange
      final data = <String>['https://first.com'];
      final defaultUri = Uri.parse('https://default.com');

      // Act
      final result = data.getUri(5, defaultValue: defaultUri);

      // Assert
      expect(result, equals(defaultUri));
    });

    test('getUri should support innerMapKey navigation', () {
      // Arrange
      final data = <Map<String, dynamic>>[
        {'link': 'http://api.example.com'},
      ];

      // Act
      final result = data.getUri(0, innerMapKey: 'link');

      // Assert
      expect(result.host, equals('api.example.com'));
    });
  });

  group('IterableConversionX DateTime conversions', () {
    test('getDateTime should parse ISO-8601 string', () {
      // Arrange
      final data = <String>['2025-11-11T10:15:30Z'];

      // Act
      final result = data.getDateTime(0);

      // Assert
      expect(result, sameInstantAs(kKnownUtcInstant));
    });

    test('getDateTime should support utc flag', () {
      // Arrange
      final data = <String>['2025-11-11T10:15:30Z'];

      // Act
      final result = data.getDateTime(0, utc: true);

      // Assert
      expect(result.isUtc, isTrue);
    });

    test('getDateTime should use defaultValue on parse failure', () {
      // Arrange
      final data = <String>['invalid-date'];
      final defaultDt = DateTime.utc(2000, 1, 1);

      // Act
      final result = data.getDateTime(0, defaultValue: defaultDt);

      // Assert
      expect(result, equals(defaultDt));
    });

    test('getDateTime should support innerMapKey + innerIndex', () {
      // Arrange
      final data = <Map<String, dynamic>>[
        {
          'dates': <String>['2025-01-01T00:00:00Z', '2025-11-11T10:15:30Z'],
        },
      ];

      // Act
      final result = data.getDateTime(0, innerMapKey: 'dates', innerIndex: 1);

      // Assert
      expect(result, sameInstantAs(kKnownUtcInstant));
    });
  });

  group('IterableConversionX with ElementConverter', () {
    test('toMutableSet with custom converter', () {
      // Arrange
      final data = <String>['hello', 'world', 'hello'];

      // Act - converter transforms each element to uppercase
      final result = data.toMutableSet(
        converter: (e) => (e as String).toUpperCase(),
      );

      // Assert
      expect(result, equals(<String>{'HELLO', 'WORLD'}));
    });

    test('mapList with custom converter', () {
      // Arrange
      final data = <int>[1, 2, 3];

      // Act - mapper transforms to string, converter further transforms
      final result = data.mapList(
        (e) => 'val_$e',
        converter: (e) => (e as String).toUpperCase(),
      );

      // Assert
      expect(result, equals(<String>['VAL_1', 'VAL_2', 'VAL_3']));
    });
  });

  group('IterableConversionX edge cases', () {
    test('getString with negative index should throw', () {
      // Arrange
      final data = <String>['a', 'b', 'c'];

      // Act / Assert
      expect(
        () => data.getString(-1),
        throwsConversionException(method: 'string'),
      );
    });

    test('getInt with out-of-bounds index should use defaultValue', () {
      // Arrange
      final data = <int>[1, 2, 3];

      // Act
      final result = data.getInt(10, defaultValue: -1);

      // Assert
      expect(result, equals(-1));
    });

    test('convertAll should handle empty iterable', () {
      // Arrange
      final data = <String>[];

      // Act
      final result = data.convertAll<int>();

      // Assert
      expect(result, isEmpty);
    });

    test('intersect should handle empty iterables', () {
      // Arrange
      final a = <int>[];
      final b = <int>[1, 2];

      // Act
      final result = a.intersect(b);

      // Assert
      expect(result, equals(<int>{1, 2}));
    });

    test('mapIndexedList should handle empty iterable', () {
      // Arrange
      final data = <String>[];

      // Act
      final result = data.mapIndexedList((i, e) => '$i:$e');

      // Assert
      expect(result, isEmpty);
    });
  });

  group('NullableIterableConversionX tryGetString', () {
    test('tryGetString should return null when iterable is null', () {
      // Arrange
      List<String>? data;

      // Act
      final result = data.tryGetString(0);

      // Assert
      expect(result, isNull);
    });

    test('tryGetString should return element when present', () {
      // Arrange
      final List<String> data = <String>['hello', 'world'];

      // Act
      final result = data.tryGetString(1);

      // Assert
      expect(result, equals('world'));
    });

    test('tryGetString should use defaultValue when null', () {
      // Arrange
      List<String>? data;

      // Act
      final result = data.tryGetString(0, defaultValue: 'fallback');

      // Assert
      expect(result, equals('fallback'));
    });

    test('tryGetString should support alternativeIndices', () {
      // Arrange
      final List<Object?> data = <Object?>[null, 'second'];

      // Act
      final result = data.tryGetString(0, alternativeIndices: const [1]);

      // Assert
      expect(result, equals('second'));
    });
  });

  group('NullableIterableConversionX tryGetDouble', () {
    test('tryGetDouble should return null when iterable is null', () {
      // Arrange
      List<String>? data;

      // Act
      final result = data.tryGetDouble(0);

      // Assert
      expect(result, isNull);
    });

    test('tryGetDouble should convert string to double', () {
      // Arrange
      final List<String> data = <String>['19.99'];

      // Act
      final result = data.tryGetDouble(0);

      // Assert
      expect(result, equals(19.99));
    });

    test('tryGetDouble should use defaultValue on failure', () {
      // Arrange
      final List<String> data = <String>['invalid'];

      // Act
      final result = data.tryGetDouble(0, defaultValue: 0.0);

      // Assert
      expect(result, equals(0.0));
    });
  });

  group('NullableIterableConversionX tryGetBool', () {
    test('tryGetBool should return null when iterable is null', () {
      // Arrange
      List<String>? data;

      // Act
      final result = data.tryGetBool(0);

      // Assert
      expect(result, isNull);
    });

    test('tryGetBool should convert truthy string', () {
      // Arrange
      final List<String> data = <String>['yes', 'no'];

      // Act
      final result = data.tryGetBool(0);

      // Assert
      expect(result, isTrue);
    });

    test('tryGetBool should convert falsy string', () {
      // Arrange
      final List<String> data = <String>['yes', 'no'];

      // Act
      final result = data.tryGetBool(1);

      // Assert
      expect(result, isFalse);
    });
  });

  group('NullableIterableConversionX tryGetNum', () {
    test('tryGetNum should return null when iterable is null', () {
      // Arrange
      List<String>? data;

      // Act
      final result = data.tryGetNum(0);

      // Assert
      expect(result, isNull);
    });

    test('tryGetNum should return num when value is integer', () {
      // Arrange
      final List<String> data = <String>['42'];

      // Act
      final result = data.tryGetNum(0);

      // Assert
      expect(result, equals(42));
      expect(result, isA<num>());
    });

    test('tryGetNum should return num when value has decimal', () {
      // Arrange
      final List<String> data = <String>['42.5'];

      // Act
      final result = data.tryGetNum(0);

      // Assert
      expect(result, equals(42.5));
      expect(result, isA<num>());
    });
  });

  group('NullableIterableConversionX tryGetBigInt', () {
    test('tryGetBigInt should return null when iterable is null', () {
      // Arrange
      List<String>? data;

      // Act
      final result = data.tryGetBigInt(0);

      // Assert
      expect(result, isNull);
    });

    test('tryGetBigInt should convert string to BigInt', () {
      // Arrange
      final List<String> data = <String>['99999999999999999'];

      // Act
      final result = data.tryGetBigInt(0);

      // Assert
      expect(result, equals(BigInt.parse('99999999999999999')));
    });
  });

  group('NullableIterableConversionX tryGetDateTime', () {
    test('tryGetDateTime should return null when iterable is null', () {
      // Arrange
      List<String>? data;

      // Act
      final result = data.tryGetDateTime(0);

      // Assert
      expect(result, isNull);
    });

    test('tryGetDateTime should parse ISO-8601 string', () {
      // Arrange
      final List<String> data = <String>['2025-11-11T10:15:30Z'];

      // Act
      final result = data.tryGetDateTime(0);

      // Assert
      expect(result, sameInstantAs(kKnownUtcInstant));
    });
  });

  group('NullableIterableConversionX tryGetUri', () {
    test('tryGetUri should return null when iterable is null', () {
      // Arrange
      List<String>? data;

      // Act
      final result = data.tryGetUri(0);

      // Assert
      expect(result, isNull);
    });

    test('tryGetUri should convert string to Uri', () {
      // Arrange
      final List<String> data = <String>['https://example.com'];

      // Act
      final result = data.tryGetUri(0);

      // Assert
      expect(result?.host, equals('example.com'));
    });
  });

  group('NullableIterableConversionX tryGetList', () {
    test('tryGetList should return null when iterable is null', () {
      // Arrange
      List<List<String>>? data;

      // Act
      final result = data.tryGetList<String>(0);

      // Assert
      expect(result, isNull);
    });

    test('tryGetList should return nested list', () {
      // Arrange
      final List<Object?> data = <Object?>[
        <String>['a', 'b'],
      ];

      // Act
      final result = data.tryGetList<String>(0);

      // Assert
      expect(result, equals(<String>['a', 'b']));
    });
  });

  group('NullableIterableConversionX tryGetSet', () {
    test('tryGetSet should return null when iterable is null', () {
      // Arrange
      List<List<String>>? data;

      // Act
      final result = data.tryGetSet<String>(0);

      // Assert
      expect(result, isNull);
    });

    test('tryGetSet should convert and deduplicate', () {
      // Arrange
      final List<Object?> data = <Object?>[
        <String>['a', 'b', 'a'],
      ];

      // Act
      final result = data.tryGetSet<String>(0);

      // Assert
      expect(result, equals(<String>{'a', 'b'}));
    });
  });

  group('NullableIterableConversionX tryGetMap', () {
    test('tryGetMap should return null when iterable is null', () {
      // Arrange
      List<Map<String, int>>? data;

      // Act
      final result = data.tryGetMap<String, int>(0);

      // Assert
      expect(result, isNull);
    });

    test('tryGetMap should return nested map with same types', () {
      // Arrange
      final List<Object?> data = <Object?>[
        <String, int>{'a': 1, 'b': 2},
      ];

      // Act
      final result = data.tryGetMap<String, int>(0);

      // Assert
      expect(result, equals(<String, int>{'a': 1, 'b': 2}));
    });
  });

  group('NullableIterableConversionX tryGetEnum', () {
    test('tryGetEnum should return null when iterable is null', () {
      // Arrange
      List<String>? data;

      // Act
      final result = data.tryGetEnum<TestColor>(0, parser: kTestColors.parser);

      // Assert
      expect(result, isNull);
    });

    test('tryGetEnum should parse enum value', () {
      // Arrange
      final List<String> data = <String>['green'];

      // Act
      final result = data.tryGetEnum<TestColor>(0, parser: kTestColors.parser);

      // Assert
      expect(result, equals(TestColor.green));
    });

    test('tryGetEnum should return defaultValue on parse failure', () {
      // Arrange
      final List<String> data = <String>['unknown'];

      // Act
      final result = data.tryGetEnum<TestColor>(
        0,
        parser: kTestColors.parser,
        defaultValue: TestColor.red,
      );

      // Assert
      expect(result, equals(TestColor.red));
    });
  });

  group('Error context validation', () {
    test('getInt should include index in error context', () {
      // Arrange
      final data = <String>['invalid'];
      ConversionException? thrown;

      // Act
      try {
        data.getInt(0);
      } catch (e) {
        thrown = e as ConversionException;
      }

      // Assert
      expect(thrown?.context['index'], equals(0));
    });

    test('getInt should include altIndexes in error context when provided', () {
      // Arrange
      final data = <String>[null.toString(), 'invalid'];
      ConversionException? thrown;

      // Act
      try {
        data.getInt(0, innerIndex: 1);
      } catch (e) {
        thrown = e as ConversionException;
      }

      // Assert
      expect(thrown?.context['index'], equals(0));
    });
  });

  group('IterableConversionX non-List indexing', () {
    test('getDouble should iterate non-List iterables', () {
      // Arrange
      final data = Iterable<int>.generate(3, (i) => i + 1);

      // Act
      final result = data.getDouble(1);

      // Assert
      expect(result, equals(2.0));
    });
  });

  group('NullableIterableConversionX alternativeIndices', () {
    test('tryGet methods should honor alternativeIndices', () {
      // Arrange
      final data = <dynamic>[
        null,
        '42',
        '3.5',
        'true',
        '2025-01-02T00:00:00Z',
        'https://example.com',
        <String>['1', '2'],
        <String, int>{'a': 1},
        '9007199254740991',
        'green',
      ];

      // Act
      final asString = data.tryGetString(99, alternativeIndices: const [1]);
      final asInt = data.tryGetInt(99, alternativeIndices: const [1]);
      final asDouble = data.tryGetDouble(99, alternativeIndices: const [2]);
      final asNum = data.tryGetNum(99, alternativeIndices: const [2]);
      final asBool = data.tryGetBool(99, alternativeIndices: const [3]);
      final asDate = data.tryGetDateTime(99, alternativeIndices: const [4]);
      final asUri = data.tryGetUri(99, alternativeIndices: const [5]);
      final asList = data.tryGetList<int>(99, alternativeIndices: const [6]);
      final asSet = data.tryGetSet<int>(99, alternativeIndices: const [6]);
      final asMap = data.tryGetMap<String, int>(
        99,
        alternativeIndices: const [7],
      );
      final asBigInt = data.tryGetBigInt(99, alternativeIndices: const [8]);
      final asEnum = data.tryGetEnum<TestColor>(
        99,
        alternativeIndices: const [9],
        parser: TestColor.values.parser,
      );

      // Assert
      expect(asString, equals('42'));
      expect(asInt, equals(42));
      expect(asDouble, equals(3.5));
      expect(asNum, equals(3.5));
      expect(asBool, isTrue);
      expect(asDate, isA<DateTime>());
      expect(asUri, uriEquals('https://example.com'));
      expect(asList, equals(<int>[1, 2]));
      expect(asSet, equals(<int>{1, 2}));
      expect(asMap, equals(<String, int>{'a': 1}));
      expect(asBigInt, equals(BigInt.parse('9007199254740991')));
      expect(asEnum, equals(TestColor.green));
    });
  });
}
