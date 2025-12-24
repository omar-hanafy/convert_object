import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';
import '../helpers/test_enums.dart';
import '../helpers/test_models.dart';

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

  group('MapConversionX', () {
    test('getString should convert the value at a key', () {
      // Arrange
      final map = kNestedMap;

      // Act
      final result = map.getString('name');

      // Assert
      expect(result, equals('Omar'));
    });

    test(
        'getString should fallback to alternativeKeys when primary key is missing',
        () {
      // Arrange
      final map = kNestedMap;

      // Act
      final result = map.getString('missing', alternativeKeys: const ['name']);

      // Assert
      expect(result, equals('Omar'));
    });

    test(
        'getString should fallback to alternativeKeys when primary value is null',
        () {
      // Arrange
      final map = <String, dynamic>{'a': null, 'b': 'x'};

      // Act
      final result = map.getString('a', alternativeKeys: const ['b']);

      // Assert
      expect(result, equals('x'));
    });

    test('getInt should include altKeys in error context', () {
      // Arrange
      final map = <String, dynamic>{'a': null, 'b': 'abc'};
      ConversionException? thrown;

      // Act
      try {
        map.getInt('a', alternativeKeys: const ['b']);
      } catch (e) {
        thrown = e as ConversionException;
      }

      // Assert
      expect(thrown, isNotNull);
      expect(thrown!.error, isA<FormatException>());
      expect(thrown.context['key'], equals('a'));
      expect(thrown.context['altKeys'], equals(const ['b']));
    });

    test('getInt should support nested selection via innerKey', () {
      // Arrange
      final map = kNestedMap;

      // Act
      final result = map.getInt('meta', innerKey: 'age');

      // Assert
      expect(result, equals(30));
    });

    test('getDouble should support list index selection + innerKey', () {
      // Arrange
      final map = kNestedMap;

      // Act
      final result =
          map.getDouble('items', innerListIndex: 1, innerKey: 'price');

      // Assert
      expect(result, equals(5.5));
    });

    test('getBool should convert truthy strings', () {
      // Arrange
      final map = kNestedMap;

      // Act
      final result = map.getBool('active');

      // Assert
      expect(result, isTrue);
    });

    test('getDateTime should parse ISO-8601 Z strings into the same instant',
        () {
      // Arrange
      final map = kNestedMap;

      // Act
      final dt = map.getDateTime('meta', innerKey: 'created');

      // Assert
      expect(dt, sameInstantAs(kKnownUtcInstant));
      expect(dt.isUtc, isTrue);
    });

    test('getList should read and convert a nested list', () {
      // Arrange
      final map = kNestedMap;

      // Act
      final tags = map.getList<String>('meta', innerKey: 'tags');

      // Assert
      expect(tags, equals(<String>['a', 'b', 'c']));
    });

    test('getList should respect innerListIndex on a list value', () {
      // Arrange
      final map = <String, dynamic>{
        'nums': <int>[1, 2, 3],
      };

      // Act
      final result = map.getList<int>('nums', innerListIndex: 1);

      // Assert
      expect(result, equals(<int>[2]));
    });

    test('getEnum should parse an enum using the provided parser', () {
      // Arrange
      final map = <String, dynamic>{'color': 'red'};

      // Act
      final result =
          map.getEnum<TestColor>('color', parser: kTestColors.parser);

      // Assert
      expect(result, equals(TestColor.red));
    });

    test('getMap should respect innerKey when the value is already a map', () {
      // Arrange
      final map = <String, dynamic>{
        'mainOrganizer': <String, dynamic>{
          'id': 4028,
          'user': <String, dynamic>{'id': 8357, 'name': 'John'},
        },
      };

      // Act
      final result = map.getMap<String, dynamic>(
        'mainOrganizer',
        innerKey: 'user',
      );

      // Assert
      expect(result, equals(<String, dynamic>{'id': 8357, 'name': 'John'}));
    });

    test('getEnum should return defaultValue when parsing fails', () {
      // Arrange
      final map = <String, dynamic>{'color': 'unknown'};

      // Act
      final result = map.getEnum<TestColor>(
        'color',
        parser: kTestColors.parser,
        defaultValue: TestColor.blue,
      );

      // Assert
      expect(result, equals(TestColor.blue));
    });

    test('keysList/valuesList should return materialized lists of keys/values',
        () {
      // Arrange
      final map = <String, int>{'a': 1, 'b': 2};

      // Act
      final keys = map.keysList;
      final values = map.valuesList;

      // Assert
      expect(keys, equals(<String>['a', 'b']));
      expect(values, equals(<int>[1, 2]));
    });

    test('keysSet/valuesSet should return materialized sets of keys/values',
        () {
      // Arrange
      final map = <String, int>{'a': 1, 'b': 2};

      // Act
      final keys = map.keysSet;
      final values = map.valuesSet;

      // Assert
      expect(keys, equals(<String>{'a', 'b'}));
      expect(values, equals(<int>{1, 2}));
    });

    test('parse should parse a nested map using a provided converter', () {
      // Arrange
      final map = <String, dynamic>{
        'coords': <String, dynamic>{'lat': '30.0444', 'lng': '31.2357'},
      };

      // Act
      final result = map.parse<LatLng, String, dynamic>(
        'coords',
        (json) => LatLng.tryParse(json)!,
      );

      // Assert
      expect(result, equals(const LatLng(30.0444, 31.2357)));
    });

    test('tryParse should return null when the key is missing', () {
      // Arrange
      final map = <String, dynamic>{};

      // Act
      final result = map.tryParse<LatLng, String, dynamic>(
        'coords',
        (json) => LatLng.tryParse(json)!,
      );

      // Assert
      expect(result, isNull);
    });

    test('parse should throw when the nested map cannot be converted', () {
      // Arrange
      final map = <String, dynamic>{'coords': 'not-a-map'};

      // Act
      // Assert
      expect(
        () => map.parse<LatLng, String, dynamic>(
          'coords',
          (json) => LatLng.tryParse(json)!,
        ),
        throwsA(isA<ConversionException>()),
      );
    });
  });

  group('NullableMapConversionX', () {
    test('tryGetInt should return null when the map is null', () {
      // Arrange
      Map<String, dynamic>? map;

      // Act
      final result = map.tryGetInt('x');

      // Assert
      expect(result, isNull);
    });

    test('tryGetInt should return defaultValue when the map is null', () {
      // Arrange
      Map<String, dynamic>? map;

      // Act
      final result = map.tryGetInt('x', defaultValue: 7);

      // Assert
      expect(result, equals(7));
    });

    test('tryGetInt should fallback to alternativeKeys when primary is missing',
        () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{'b': '5'};

      // Act
      final result = map.tryGetInt('a', alternativeKeys: const ['b']);

      // Assert
      expect(result, equals(5));
    });

    test('tryGetInt should support nested selection via innerKey', () {
      // Arrange
      final Map<String, dynamic> map = kNestedMap;

      // Act
      final result = map.tryGetInt('meta', innerKey: 'age');

      // Assert
      expect(result, equals(30));
    });

    test('tryGetEnum should return defaultValue when parsing fails', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{'color': 'unknown'};

      // Act
      final result = map.tryGetEnum<TestColor>(
        'color',
        parser: kTestColors.parser,
        defaultValue: TestColor.green,
      );

      // Assert
      expect(result, equals(TestColor.green));
    });
  });
}
