// Additional tests for map extensions covering gaps identified in audit.
//
// This file focuses on:
// - BigInt conversions
// - Uri conversions
// - ElementConverter parameter usage
// - Untested NullableMapConversionX methods
// - Combined parameters (alternativeKeys + innerKey + innerListIndex)
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

  group('MapConversionX BigInt conversions', () {
    test('getBigInt should convert string to BigInt', () {
      // Arrange
      final map = <String, dynamic>{'value': '12345678901234567890'};

      // Act
      final result = map.getBigInt('value');

      // Assert
      expect(result, equals(BigInt.parse('12345678901234567890')));
    });

    test('getBigInt should convert int to BigInt', () {
      // Arrange
      final map = <String, dynamic>{'value': 42};

      // Act
      final result = map.getBigInt('value');

      // Assert
      expect(result, equals(BigInt.from(42)));
    });

    test('getBigInt should use alternativeKeys', () {
      // Arrange
      final map = <String, dynamic>{'bigNum': '99999999999999'};

      // Act
      final result = map.getBigInt(
        'missing',
        alternativeKeys: const ['bigNum'],
      );

      // Assert
      expect(result, equals(BigInt.parse('99999999999999')));
    });

    test('getBigInt should use defaultValue when conversion fails', () {
      // Arrange
      final map = <String, dynamic>{'value': 'not-a-number'};

      // Act
      final result = map.getBigInt('value', defaultValue: BigInt.from(-1));

      // Assert
      expect(result, equals(BigInt.from(-1)));
    });

    test('getBigInt should support innerKey navigation', () {
      // Arrange
      final map = <String, dynamic>{
        'data': <String, dynamic>{'bigValue': '123456789'},
      };

      // Act
      final result = map.getBigInt('data', innerKey: 'bigValue');

      // Assert
      expect(result, equals(BigInt.parse('123456789')));
    });
  });

  group('MapConversionX Uri conversions', () {
    test('getUri should convert string to Uri', () {
      // Arrange
      final map = <String, dynamic>{'url': 'https://example.com/path?q=1'};

      // Act
      final result = map.getUri('url');

      // Assert
      expect(result, uriEquals('https://example.com/path?q=1'));
    });

    test('getUri should handle relative paths', () {
      // Arrange
      final map = <String, dynamic>{'path': '/api/v1/users'};

      // Act
      final result = map.getUri('path');

      // Assert
      expect(result.path, equals('/api/v1/users'));
      expect(result.hasScheme, isFalse);
    });

    test('getUri should use alternativeKeys', () {
      // Arrange
      final map = <String, dynamic>{'link': 'http://alt.com'};

      // Act
      final result = map.getUri('url', alternativeKeys: const ['link']);

      // Assert
      expect(result.host, equals('alt.com'));
    });

    test('getUri should use defaultValue when key missing', () {
      // Arrange
      final map = <String, dynamic>{};
      final defaultUri = Uri.parse('https://default.com');

      // Act
      final result = map.getUri('missing', defaultValue: defaultUri);

      // Assert
      expect(result, equals(defaultUri));
    });

    test('getUri should support innerKey navigation', () {
      // Arrange
      final map = <String, dynamic>{
        'config': <String, dynamic>{'endpoint': 'https://api.example.com'},
      };

      // Act
      final result = map.getUri('config', innerKey: 'endpoint');

      // Assert
      expect(result.host, equals('api.example.com'));
    });
  });

  group('MapConversionX combined parameters', () {
    test('getInt with alternativeKeys + innerKey', () {
      // Arrange
      final map = <String, dynamic>{
        'alt': <String, dynamic>{'count': '42'},
      };

      // Act
      final result = map.getInt(
        'missing',
        alternativeKeys: const ['alt'],
        innerKey: 'count',
      );

      // Assert
      expect(result, equals(42));
    });

    test('getString with alternativeKeys + innerKey + innerListIndex', () {
      // Arrange
      final map = <String, dynamic>{
        'backup': <String, dynamic>{
          'items': <String>['a', 'b', 'c'],
        },
      };

      // Act
      final result = map.getString(
        'primary',
        alternativeKeys: const ['backup'],
        innerKey: 'items',
        innerListIndex: 1,
      );

      // Assert
      expect(result, equals('b'));
    });

    test('getDouble with innerKey + innerListIndex', () {
      // Arrange
      final map = <String, dynamic>{
        'data': <String, dynamic>{
          'prices': <dynamic>['10.5', '20.75', '30.0'],
        },
      };

      // Act
      final result = map.getDouble(
        'data',
        innerKey: 'prices',
        innerListIndex: 1,
      );

      // Assert
      expect(result, equals(20.75));
    });
  });

  group('MapConversionX with defaultValue', () {
    test('getBool should use defaultValue when value is null', () {
      // Arrange
      final map = <String, dynamic>{'flag': null};

      // Act
      final result = map.getBool('flag', defaultValue: true);

      // Assert
      expect(result, isTrue);
    });

    test('getString should use defaultValue when value is null', () {
      // Arrange
      final map = <String, dynamic>{'name': null};

      // Act
      final result = map.getString('name', defaultValue: 'default');

      // Assert
      expect(result, equals('default'));
    });

    test('getInt should use defaultValue when parsing fails', () {
      // Arrange
      final map = <String, dynamic>{'num': 'not-a-number'};

      // Act
      final result = map.getInt('num', defaultValue: -999);

      // Assert
      expect(result, equals(-999));
    });
  });

  group('NullableMapConversionX tryGetString', () {
    test('tryGetString should return null when map is null', () {
      // Arrange
      Map<String, dynamic>? map;

      // Act
      final result = map.tryGetString('key');

      // Assert
      expect(result, isNull);
    });

    test('tryGetString should return value when present', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{'name': 'Omar'};

      // Act
      final result = map.tryGetString('name');

      // Assert
      expect(result, equals('Omar'));
    });

    test('tryGetString should use defaultValue when map is null', () {
      // Arrange
      Map<String, dynamic>? map;

      // Act
      final result = map.tryGetString('key', defaultValue: 'fallback');

      // Assert
      expect(result, equals('fallback'));
    });

    test('tryGetString should support alternativeKeys', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{'fullName': 'John'};

      // Act
      final result = map.tryGetString(
        'name',
        alternativeKeys: const ['fullName'],
      );

      // Assert
      expect(result, equals('John'));
    });
  });

  group('NullableMapConversionX tryGetDouble', () {
    test('tryGetDouble should return null when map is null', () {
      // Arrange
      Map<String, dynamic>? map;

      // Act
      final result = map.tryGetDouble('price');

      // Assert
      expect(result, isNull);
    });

    test('tryGetDouble should convert string to double', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{'price': '19.99'};

      // Act
      final result = map.tryGetDouble('price');

      // Assert
      expect(result, equals(19.99));
    });

    test('tryGetDouble should return defaultValue on parse failure', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{'price': 'invalid'};

      // Act
      final result = map.tryGetDouble('price', defaultValue: 0.0);

      // Assert
      expect(result, equals(0.0));
    });
  });

  group('NullableMapConversionX tryGetBool', () {
    test('tryGetBool should return null when map is null', () {
      // Arrange
      Map<String, dynamic>? map;

      // Act
      final result = map.tryGetBool('active');

      // Assert
      expect(result, isNull);
    });

    test('tryGetBool should convert truthy strings', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{'active': 'yes'};

      // Act
      final result = map.tryGetBool('active');

      // Assert
      expect(result, isTrue);
    });

    test('tryGetBool should convert falsy strings', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{'active': 'no'};

      // Act
      final result = map.tryGetBool('active');

      // Assert
      expect(result, isFalse);
    });

    test('tryGetBool should use defaultValue when key missing', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{};

      // Act
      final result = map.tryGetBool('missing', defaultValue: true);

      // Assert
      expect(result, isTrue);
    });
  });

  group('NullableMapConversionX tryGetBigInt', () {
    test('tryGetBigInt should return null when map is null', () {
      // Arrange
      Map<String, dynamic>? map;

      // Act
      final result = map.tryGetBigInt('value');

      // Assert
      expect(result, isNull);
    });

    test('tryGetBigInt should convert string to BigInt', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{
        'value': '99999999999999999999',
      };

      // Act
      final result = map.tryGetBigInt('value');

      // Assert
      expect(result, equals(BigInt.parse('99999999999999999999')));
    });

    test('tryGetBigInt should return defaultValue on failure', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{'value': 'abc'};

      // Act
      final result = map.tryGetBigInt('value', defaultValue: BigInt.zero);

      // Assert
      expect(result, equals(BigInt.zero));
    });
  });

  group('NullableMapConversionX tryGetUri', () {
    test('tryGetUri should return null when map is null', () {
      // Arrange
      Map<String, dynamic>? map;

      // Act
      final result = map.tryGetUri('url');

      // Assert
      expect(result, isNull);
    });

    test('tryGetUri should convert string to Uri', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{
        'url': 'https://example.com',
      };

      // Act
      final result = map.tryGetUri('url');

      // Assert
      expect(result?.host, equals('example.com'));
    });

    test('tryGetUri should return defaultValue when key missing', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{};
      final defaultUri = Uri.parse('https://fallback.com');

      // Act
      final result = map.tryGetUri('missing', defaultValue: defaultUri);

      // Assert
      expect(result, equals(defaultUri));
    });
  });

  group('NullableMapConversionX tryGetDateTime', () {
    test('tryGetDateTime should return null when map is null', () {
      // Arrange
      Map<String, dynamic>? map;

      // Act
      final result = map.tryGetDateTime('created');

      // Assert
      expect(result, isNull);
    });

    test('tryGetDateTime should parse ISO-8601 string', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{
        'created': '2025-11-11T10:15:30Z',
      };

      // Act
      final result = map.tryGetDateTime('created');

      // Assert
      expect(result, sameInstantAs(kKnownUtcInstant));
    });

    test('tryGetDateTime should return defaultValue on failure', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{'created': 'invalid'};
      final defaultDt = DateTime.utc(2000, 1, 1);

      // Act
      final result = map.tryGetDateTime('created', defaultValue: defaultDt);

      // Assert
      expect(result, equals(defaultDt));
    });

    test('tryGetDateTime should support utc flag', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{
        'created': '2025-11-11T10:15:30Z',
      };

      // Act
      final result = map.tryGetDateTime('created', utc: true);

      // Assert
      expect(result?.isUtc, isTrue);
    });
  });

  group('NullableMapConversionX tryGetList', () {
    test('tryGetList should return null when map is null', () {
      // Arrange
      Map<String, dynamic>? map;

      // Act
      final result = map.tryGetList<int>('items');

      // Assert
      expect(result, isNull);
    });

    test('tryGetList should convert and return list', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{
        'items': <dynamic>['1', '2', '3'],
      };

      // Act
      final result = map.tryGetList<int>('items');

      // Assert
      expect(result, equals(<int>[1, 2, 3]));
    });

    test('tryGetList should return defaultValue when key missing', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{};

      // Act
      final result = map.tryGetList<int>('missing', defaultValue: <int>[0]);

      // Assert
      expect(result, equals(<int>[0]));
    });
  });

  group('NullableMapConversionX tryGetSet', () {
    test('tryGetSet should return null when map is null', () {
      // Arrange
      Map<String, dynamic>? map;

      // Act
      final result = map.tryGetSet<String>('tags');

      // Assert
      expect(result, isNull);
    });

    test('tryGetSet should convert and deduplicate', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{
        'tags': <String>['a', 'b', 'a'],
      };

      // Act
      final result = map.tryGetSet<String>('tags');

      // Assert
      expect(result, equals(<String>{'a', 'b'}));
    });
  });

  group('NullableMapConversionX tryGetMap', () {
    test('tryGetMap should return null when map is null', () {
      // Arrange
      Map<String, dynamic>? map;

      // Act
      final result = map.tryGetMap<String, int>('config');

      // Assert
      expect(result, isNull);
    });

    test('tryGetMap should return nested map with same types', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{
        'config': <String, dynamic>{'a': 1, 'b': 2},
      };

      // Act
      final result = map.tryGetMap<String, int>('config');

      // Assert
      expect(result, equals(<String, int>{'a': 1, 'b': 2}));
    });

    test('tryGetMap should return null when values cannot be cast', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{
        'config': <String, dynamic>{'a': '1', 'b': '2'},
      };

      // Act
      final result = map.tryGetMap<String, int>('config');

      // Assert
      expect(result, isNull);
    });

    test('tryGetMap should support innerKey navigation', () {
      // Arrange
      final Map<String, dynamic> map = <String, dynamic>{
        'data': <String, dynamic>{
          'nested': <String, int>{'x': 10},
        },
      };

      // Act
      final result = map.tryGetMap<String, int>('data', innerKey: 'nested');

      // Assert
      expect(result, equals(<String, int>{'x': 10}));
    });
  });

  group('Error context validation', () {
    test('getInt should include key in error context', () {
      // Arrange
      final map = <String, dynamic>{'value': 'invalid'};
      ConversionException? thrown;

      // Act
      try {
        map.getInt('value');
      } catch (e) {
        thrown = e as ConversionException;
      }

      // Assert
      expect(thrown?.context['key'], equals('value'));
    });

    test('getInt should include altKeys in error context when provided', () {
      // Arrange
      final map = <String, dynamic>{'alt': 'invalid'};
      ConversionException? thrown;

      // Act
      try {
        map.getInt('primary', alternativeKeys: const ['alt']);
      } catch (e) {
        thrown = e as ConversionException;
      }

      // Assert
      expect(thrown?.context['key'], equals('primary'));
      expect(thrown?.context['altKeys'], equals(const ['alt']));
    });

    test('getUri should throw with proper context on invalid URI', () {
      // Arrange
      final map = <String, dynamic>{'url': ':::invalid:::'};

      // Act / Assert
      expect(
        () => map.getUri('url'),
        throwsConversionException(method: 'toUri'),
      );
    });
  });

  group('alternativeKeys coverage', () {
    test('MapConversionX should populate altKeys for all getters', () {
      // Arrange
      final map = <String, dynamic>{
        'altString': 'hello',
        'altInt': '42',
        'altDouble': '3.5',
        'altNum': '9.5',
        'altBool': 'true',
        'altList': <int>[1, 2],
        'altSet': <int>[1, 2],
        'altMap': <String, int>{'a': 1},
        'altBigInt': '123456789',
        'altDate': '2025-01-02T00:00:00Z',
        'altUri': 'https://example.com',
        'altEnum': 'green',
      };

      // Act
      final asString = map.getString(
        'missing',
        alternativeKeys: const ['altString'],
      );
      final asInt = map.getInt('missing', alternativeKeys: const ['altInt']);
      final asDouble = map.getDouble(
        'missing',
        alternativeKeys: const ['altDouble'],
      );
      final asNum = map.getNum('missing', alternativeKeys: const ['altNum']);
      final asBool = map.getBool('missing', alternativeKeys: const ['altBool']);
      final asList = map.getList<int>(
        'missing',
        alternativeKeys: const ['altList'],
      );
      final asSet = map.getSet<int>(
        'missing',
        alternativeKeys: const ['altSet'],
      );
      final asMap = map.getMap<String, int>(
        'missing',
        alternativeKeys: const ['altMap'],
      );
      final asBigInt = map.getBigInt(
        'missing',
        alternativeKeys: const ['altBigInt'],
      );
      final asDate = map.getDateTime(
        'missing',
        alternativeKeys: const ['altDate'],
      );
      final asUri = map.getUri('missing', alternativeKeys: const ['altUri']);
      final asEnum = map.getEnum<TestColor>(
        'missing',
        alternativeKeys: const ['altEnum'],
        parser: TestColor.values.parser,
      );

      // Assert
      expect(asString, equals('hello'));
      expect(asInt, equals(42));
      expect(asDouble, equals(3.5));
      expect(asNum, equals(9.5));
      expect(asBool, isTrue);
      expect(asList, equals(<int>[1, 2]));
      expect(asSet, equals(<int>{1, 2}));
      expect(asMap, equals(<String, int>{'a': 1}));
      expect(asBigInt, equals(BigInt.parse('123456789')));
      expect(asDate, isA<DateTime>());
      expect(asUri, uriEquals('https://example.com'));
      expect(asEnum, equals(TestColor.green));
    });

    test('tryParse should convert nested map and invoke converter', () {
      // Arrange
      final map = <String, dynamic>{
        'payload': <String, int>{'a': 1},
      };

      // Act
      final parsed = map.tryParse<int, String, int>(
        'payload',
        (json) => json['a'] ?? 0,
      );

      // Assert
      expect(parsed, equals(1));
    });

    test('NullableMapConversionX should honor altKeys for tryGet methods', () {
      // Arrange
      final map = <String, dynamic>{
        'altString': 'hello',
        'altInt': '42',
        'altDouble': '3.5',
        'altNum': '9.5',
        'altBool': 'true',
        'altList': <int>[1, 2],
        'altSet': <int>[1, 2],
        'altMap': <String, int>{'a': 1},
        'altBigInt': '123456789',
        'altDate': '2025-01-02T00:00:00Z',
        'altUri': 'https://example.com',
        'altEnum': 'green',
      };

      // Act
      final asString = map.tryGetString(
        'missing',
        alternativeKeys: const ['altString'],
      );
      final asInt = map.tryGetInt('missing', alternativeKeys: const ['altInt']);
      final asDouble = map.tryGetDouble(
        'missing',
        alternativeKeys: const ['altDouble'],
      );
      final asNum = map.tryGetNum('missing', alternativeKeys: const ['altNum']);
      final asBool = map.tryGetBool(
        'missing',
        alternativeKeys: const ['altBool'],
      );
      final asList = map.tryGetList<int>(
        'missing',
        alternativeKeys: const ['altList'],
      );
      final asSet = map.tryGetSet<int>(
        'missing',
        alternativeKeys: const ['altSet'],
      );
      final asMap = map.tryGetMap<String, int>(
        'missing',
        alternativeKeys: const ['altMap'],
      );
      final asBigInt = map.tryGetBigInt(
        'missing',
        alternativeKeys: const ['altBigInt'],
      );
      final asDate = map.tryGetDateTime(
        'missing',
        alternativeKeys: const ['altDate'],
      );
      final asUri = map.tryGetUri('missing', alternativeKeys: const ['altUri']);
      final asEnum = map.tryGetEnum<TestColor>(
        'missing',
        alternativeKeys: const ['altEnum'],
        parser: TestColor.values.parser,
      );

      // Assert
      expect(asString, equals('hello'));
      expect(asInt, equals(42));
      expect(asDouble, equals(3.5));
      expect(asNum, equals(9.5));
      expect(asBool, isTrue);
      expect(asList, equals(<int>[1, 2]));
      expect(asSet, equals(<int>{1, 2}));
      expect(asMap, equals(<String, int>{'a': 1}));
      expect(asBigInt, equals(BigInt.parse('123456789')));
      expect(asDate, isA<DateTime>());
      expect(asUri, uriEquals('https://example.com'));
      expect(asEnum, equals(TestColor.green));
    });
  });
}
