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
    // Arrange
    prevIntlLocale = Intl.defaultLocale;
    Intl.defaultLocale = 'en_US';
    prev = Convert.configure(makeTestConfig(locale: 'en_US'));
  });

  tearDown(() {
    // Arrange
    Convert.configure(prev);
    Intl.defaultLocale = prevIntlLocale;
  });

  group('IterableConversionX', () {
    test('getString should convert the element at index using innerMapKey', () {
      // Arrange
      final data = <Map<String, dynamic>>[
        {'id': '1'},
        {'id': '2'},
      ];

      // Act
      final result = data.getString(0, innerMapKey: 'id');

      // Assert
      expect(result, equals('1'));
    });

    test('getInt should support innerMapKey + innerIndex navigation', () {
      // Arrange
      final data = <Map<String, dynamic>>[
        {
          'nums': <dynamic>['1', '2'],
        },
        {
          'nums': <dynamic>['3', '4'],
        },
      ];

      // Act
      final result = data.getInt(0, innerMapKey: 'nums', innerIndex: 1);

      // Assert
      expect(result, equals(2));
    });

    test('getInt should include index in error context', () {
      // Arrange
      final data = <String>['abc'];
      ConversionException? thrown;

      // Act
      try {
        data.getInt(0);
      } catch (e) {
        thrown = e as ConversionException;
      }

      // Assert
      expect(thrown, isNotNull);
      expect(thrown!.error, isA<FormatException>());
      expect(thrown.context['index'], equals(0));
    });

    test('getBool should convert truthy/falsy strings using innerMapKey', () {
      // Arrange
      final data = <Map<String, dynamic>>[
        {'flag': 'true'},
        {'flag': 'false'},
      ];

      // Act
      final a = data.getBool(0, innerMapKey: 'flag');
      final b = data.getBool(1, innerMapKey: 'flag');

      // Assert
      expect(a, isTrue);
      expect(b, isFalse);
    });

    test('getNum should convert numeric strings', () {
      // Arrange
      final data = <String>['1,234.5'];

      // Act
      final result = data.getNum(0);

      // Assert
      expect(result, equals(1234.5));
    });

    test('getBigInt should convert large integer strings', () {
      // Arrange
      final data = <String>['9007199254740993'];

      // Act
      final result = data.getBigInt(0);

      // Assert
      expect(result, equals(BigInt.parse('9007199254740993')));
    });

    test('getList should convert a nested list using innerMapKey', () {
      // Arrange
      final data = <Map<String, dynamic>>[
        {
          'nums': <dynamic>['1', '2'],
        },
      ];

      // Act
      final result = data.getList<int>(0, innerMapKey: 'nums');

      // Assert
      expect(result, equals(<int>[1, 2]));
    });

    test('getSet should convert a nested list into a Set', () {
      // Arrange
      final data = <Map<String, dynamic>>[
        {
          'tags': <dynamic>['a', 'b', 'c'],
        },
      ];

      // Act
      final result = data.getSet<String>(0, innerMapKey: 'tags');

      // Assert
      expect(result, equals(<String>{'a', 'b', 'c'}));
    });

    test('getMap should return a nested typed map using innerMapKey', () {
      // Arrange
      final data = <Map<String, dynamic>>[
        {
          'map': <String, int>{'a': 1},
        },
      ];

      // Act
      final result = data.getMap<String, int>(0, innerMapKey: 'map');

      // Assert
      expect(result, equals(<String, int>{'a': 1}));
    });

    test('getEnum should parse enum values using the provided parser', () {
      // Arrange
      final data = <Map<String, dynamic>>[
        {'color': 'red'},
        {'color': 'green'},
      ];

      // Act
      final c1 = data.getEnum<TestColor>(
        0,
        innerMapKey: 'color',
        parser: kTestColors.parser,
      );
      final c2 = data.getEnum<TestColor>(
        1,
        innerMapKey: 'color',
        parser: kTestColors.parser,
      );

      // Assert
      expect(c1, equals(TestColor.red));
      expect(c2, equals(TestColor.green));
    });

    test('getUri should convert string values to Uri', () {
      // Arrange
      final data = <String>['https://example.com'];

      // Act
      final result = data.getUri(0);

      // Assert
      expect(result, uriEquals('https://example.com'));
    });

    test('convertAll should convert every element to the requested type', () {
      // Arrange
      final data = <String>['1', '2', '3'];

      // Act
      final result = data.convertAll<int>();

      // Assert
      expect(result, equals(<int>[1, 2, 3]));
    });

    test('toMutableSet should create a Set from the iterable', () {
      // Arrange
      final data = <int>[1, 2, 2];

      // Act
      final result = data.toMutableSet();

      // Assert
      expect(result, equals(<int>{1, 2}));
    });

    test(
      'intersect should behave like a union between this iterable and the other',
      () {
        // Arrange
        final a = <int>[1, 2];
        final b = <int>[2, 3];

        // Act
        final result = a.intersect(b);

        // Assert
        expect(result, equals(<int>{1, 2, 3}));
      },
    );

    test('mapList should map elements and materialize them into a List', () {
      // Arrange
      final data = <int>[1, 2, 3];

      // Act
      final result = data.mapList((e) => e * 2);

      // Assert
      expect(result, equals(<int>[2, 4, 6]));
    });

    test(
      'mapIndexedList should map elements with index and materialize into a List',
      () {
        // Arrange
        final data = <String>['a', 'b'];

        // Act
        final result = data.mapIndexedList(
          (index, element) => '$index:$element',
        );

        // Assert
        expect(result, equals(<String>['0:a', '1:b']));
      },
    );
  });

  group('NullableIterableConversionX', () {
    test('tryGetInt should return null when the iterable is null', () {
      // Arrange
      List<Object?>? data;

      // Act
      final result = data.tryGetInt(0);

      // Assert
      expect(result, isNull);
    });

    test('tryGetInt should return defaultValue when the iterable is null', () {
      // Arrange
      List<Object?>? data;

      // Act
      final result = data.tryGetInt(0, defaultValue: 7);

      // Assert
      expect(result, equals(7));
    });

    test(
      'tryGetInt should use alternativeIndices when the primary index is null',
      () {
        // Arrange
        final List<Object?> data = <Object?>[
          null,
          <String, dynamic>{'age': '30'},
        ];

        // Act
        final result = data.tryGetInt(
          0,
          alternativeIndices: const [1],
          innerMapKey: 'age',
        );

        // Assert
      expect(result, equals(30));
    },
    );

    test('tryGetNum should return null when iterable is null', () {
      // Arrange
      List<Object?>? data;

      // Act
      final result = data.tryGetNum(0);

      // Assert
      expect(result, isNull);
    });

    test('tryGetBigInt should convert when value is present', () {
      // Arrange
      final List<Object?> data = <Object?>['9007199254740993'];

      // Act
      final result = data.tryGetBigInt(0);

      // Assert
      expect(result, equals(BigInt.parse('9007199254740993')));
    });

    test('tryGetUri should convert string values to Uri', () {
      // Arrange
      final List<Object?> data = <Object?>['https://example.com'];

      // Act
      final result = data.tryGetUri(0);

      // Assert
      expect(result, uriEquals('https://example.com'));
    });

    test('tryGetSet should convert list values into a Set', () {
      // Arrange
      final List<Object?> data = <Object?>[
        <dynamic>['a', 'b', 'c'],
      ];

      // Act
      final result = data.tryGetSet<String>(0);

      // Assert
      expect(result, equals(<String>{'a', 'b', 'c'}));
    });
  });

  group('SetConvertToX', () {
    test(
      'convertTo should convert a Set<E> into a Set<R> using convert_object',
      () {
        // Arrange
        final Set<String> input = <String>{'1', '2'};

        // Act
        final result = input.convertTo<int>();

        // Assert
        expect(result, equals(<int>{1, 2}));
      },
    );

    test('convertTo should throw when the receiver set is null', () {
      // Arrange
      Set<String>? input;

      // Act
      // Assert
      expect(
        () => input.convertTo<int>(),
        throwsConversionException(method: 'toSet<int>'),
      );
    });
  });
}
