import 'dart:collection';

import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';

class ThrowingMap<K, V> extends MapBase<K, V> {
  ThrowingMap(this._inner);

  final Map<K, V> _inner;

  @override
  V? operator [](Object? key) => throw StateError('boom');

  @override
  void operator []=(K key, V value) => _inner[key] = value;

  @override
  void clear() => _inner.clear();

  @override
  Iterable<K> get keys => _inner.keys;

  @override
  V? remove(Object? key) => _inner.remove(key);
}

ConversionException _testException(String method) {
  return ConversionException(
    error: 'boom',
    context: {'method': method},
    stackTrace: StackTrace.current,
  );
}

void main() {
  late ConvertConfig prev;

  setUpAll(() async {
    await initTestIntl(defaultLocale: 'en_US');
  });

  setUp(() {
    prev = Convert.configure(makeTestConfig(locale: 'en_US'));
  });

  tearDown(() {
    Convert.configure(prev);
  });

  group('Convert internal selection safeguards', () {
    test('should return defaultValue when listIndex is out of range', () {
      final list = <dynamic>['1', '2'];

      final result = Convert.toInt(list, listIndex: -1, defaultValue: 9);

      expect(result, equals(9));
    });

    test('should throw when listIndex is out of range and no defaultValue', () {
      final list = <dynamic>['1', '2'];

      expect(
        () => Convert.toInt(list, listIndex: -1),
        throwsConversionException(method: 'toInt'),
      );
    });

    test('should treat mapKey access errors as null selections', () {
      final map = ThrowingMap<String, dynamic>({'a': '1'});

      expect(
        () => Convert.string(map, mapKey: 'a'),
        throwsConversionException(method: 'string'),
      );

      final result = Convert.tryToString(
        map,
        mapKey: 'a',
        defaultValue: 'fallback',
      );

      expect(result, equals('fallback'));
    });
  });

  group('Convert.toDateTime numeric threshold', () {
    test('should treat values at or above 100000000000 as milliseconds', () {
      const millis = 100000000000;
      final expected =
          DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);

      final result = Convert.toDateTime(millis, utc: true);

      expect(result, isUtcDateTime);
      expect(result, sameInstantAs(expected));
    });

    test('should treat values below 100000000000 as seconds', () {
      const seconds = 99999999999;
      final expected = DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000,
        isUtc: true,
      );

      final result = Convert.toDateTime(seconds, utc: true);

      expect(result, isUtcDateTime);
      expect(result, sameInstantAs(expected));
    });
  });

  group('Convert.toDateTime converter error handling', () {
    test('should wrap non-ConversionException converter errors', () {
      expect(
        () => Convert.toDateTime(
          '2025-01-01',
          converter: (_) => throw StateError('boom'),
        ),
        throwsConversionException(method: 'toDateTime'),
      );
    });

    test('tryToDateTime should return defaultValue on converter errors', () {
      final fallback = DateTime.utc(2000, 1, 1);

      final result = Convert.tryToDateTime(
        '2025-01-01',
        converter: (_) => throw StateError('boom'),
        defaultValue: fallback,
      );

      expect(result, equals(fallback));
    });
  });

  group('Convert.string error handling', () {
    test('should wrap non-ConversionException converter errors', () {
      expect(
        () => Convert.string(123, converter: (_) => throw StateError('boom')),
        throwsConversionException(method: 'string'),
      );
    });

    test('should rethrow ConversionException from converter', () {
      expect(
        () => Convert.string(
          123,
          converter: (_) => throw _testException('string'),
        ),
        throwsConversionException(method: 'string'),
      );
    });
  });

  group('Convert.toNum formatted fallbacks', () {
    test('should fall back to formatted parse when plain parse fails', () {
      final overrides = makeTestConfig(
        numbers: const NumberOptions(tryFormattedFirst: false),
      );

      final result = withScopedConfig(
        overrides,
        () => Convert.toNum('12%', format: '0%'),
      );

      expect(result, closeTo(0.12, 0.0001));
    });

    test('should rethrow ConversionException from converter', () {
      expect(
        () => Convert.toNum(
          '1',
          converter: (_) => throw _testException('toNum'),
        ),
        throwsConversionException(method: 'toNum'),
      );
    });

    test('should throw null object when input is null', () {
      expect(
        () => Convert.toNum(null),
        throwsConversionException(method: 'toNum'),
      );
    });
  });

  group('Convert.tryToNum formatted branches', () {
    test('should try formatted first when configured', () {
      final overrides = makeTestConfig(
        numbers: const NumberOptions(tryFormattedFirst: true),
      );

      final result = withScopedConfig(
        overrides,
        () => Convert.tryToNum('1,234', format: '#,##0'),
      );

      expect(result, equals(1234));
    });

    test('should attempt formatted after plain parse when configured', () {
      final overrides = makeTestConfig(
        numbers: const NumberOptions(tryFormattedFirst: false),
      );

      final result = withScopedConfig(
        overrides,
        () => Convert.tryToNum('1,234', format: '#,##0'),
      );

      expect(result, equals(1234));
    });

    test('should attempt formatted when plain parse returns null', () {
      final overrides = makeTestConfig(
        numbers: const NumberOptions(tryFormattedFirst: false),
      );

      final result = withScopedConfig(
        overrides,
        () => Convert.tryToNum('12%', format: '0%'),
      );

      expect(result, closeTo(0.12, 0.0001));
    });
  });

  group('Convert.toInt formatted fallbacks', () {
    test('should use formatted parse when plain parse fails', () {
      final overrides = makeTestConfig(
        numbers: const NumberOptions(tryFormattedFirst: false),
      );

      final result = withScopedConfig(
        overrides,
        () => Convert.toInt('12%', format: '0%'),
      );

      expect(result, equals(0));
    });

    test('should rethrow ConversionException from converter', () {
      expect(
        () => Convert.toInt(
          '1',
          converter: (_) => throw _testException('toInt'),
        ),
        throwsConversionException(method: 'toInt'),
      );
    });
  });

  group('Convert.tryToInt formatted branches', () {
    test('should convert numbers directly', () {
      final result = Convert.tryToInt(3.6);

      expect(result, equals(3));
    });

    test('should try formatted first when configured', () {
      final overrides = makeTestConfig(
        numbers: const NumberOptions(tryFormattedFirst: true),
      );

      final result = withScopedConfig(
        overrides,
        () => Convert.tryToInt('12%', format: '0%'),
      );

      expect(result, equals(0));
    });

    test('should attempt formatted after plain parse when configured', () {
      final overrides = makeTestConfig(
        numbers: const NumberOptions(tryFormattedFirst: false),
      );

      final result = withScopedConfig(
        overrides,
        () => Convert.tryToInt('1,234', format: '#,##0'),
      );

      expect(result, equals(1234));
    });

    test('should attempt formatted when plain parse returns null', () {
      final overrides = makeTestConfig(
        numbers: const NumberOptions(tryFormattedFirst: false),
      );

      final result = withScopedConfig(
        overrides,
        () => Convert.tryToInt('12%', format: '0%'),
      );

      expect(result, equals(0));
    });
  });

  group('Convert.toBigInt error paths', () {
    test('should rethrow ConversionException from converter', () {
      expect(
        () => Convert.toBigInt(
          '1',
          converter: (_) => throw _testException('toBigInt'),
        ),
        throwsA(isA<ConversionException>()),
      );
    });

    test('should throw null object when input is null', () {
      expect(
        () => Convert.toBigInt(null),
        throwsConversionException(method: 'toBigInt'),
      );
    });
  });

  group('Convert.toDouble formatted fallbacks', () {
    test('should convert numbers directly', () {
      final result = Convert.toDouble(2);

      expect(result, equals(2.0));
    });

    test('should use formatted parse when plain parse fails', () {
      final overrides = makeTestConfig(
        numbers: const NumberOptions(tryFormattedFirst: false),
      );

      final result = withScopedConfig(
        overrides,
        () => Convert.toDouble('12%', format: '0%'),
      );

      expect(result, closeTo(0.12, 0.0001));
    });

    test('should rethrow ConversionException from converter', () {
      expect(
        () => Convert.toDouble(
          '1',
          converter: (_) => throw _testException('toDouble'),
        ),
        throwsConversionException(method: 'toDouble'),
      );
    });

    test('should throw null object when input is null', () {
      expect(
        () => Convert.toDouble(null),
        throwsConversionException(method: 'toDouble'),
      );
    });
  });

  group('Convert.tryToDouble formatted branches', () {
    test('should convert numbers directly', () {
      final result = Convert.tryToDouble(2);

      expect(result, equals(2.0));
    });

    test('should try formatted first when configured', () {
      final overrides = makeTestConfig(
        numbers: const NumberOptions(tryFormattedFirst: true),
      );

      final result = withScopedConfig(
        overrides,
        () => Convert.tryToDouble('12%', format: '0%'),
      );

      expect(result, closeTo(0.12, 0.0001));
    });

    test('should attempt formatted after plain parse when configured', () {
      final overrides = makeTestConfig(
        numbers: const NumberOptions(tryFormattedFirst: false),
      );

      final result = withScopedConfig(
        overrides,
        () => Convert.tryToDouble('1,234', format: '#,##0'),
      );

      expect(result, equals(1234.0));
    });

    test('should attempt formatted when plain parse returns null', () {
      final overrides = makeTestConfig(
        numbers: const NumberOptions(tryFormattedFirst: false),
      );

      final result = withScopedConfig(
        overrides,
        () => Convert.tryToDouble('12%', format: '0%'),
      );

      expect(result, closeTo(0.12, 0.0001));
    });
  });

  group('Convert.toDateTime auto-detect patterns', () {
    test('should parse extra auto-detect patterns', () {
      final overrides = makeTestConfig(
        dates: const DateOptions(
          autoDetectFormat: true,
          extraAutoDetectPatterns: ['yyyy/MM/dd'],
        ),
      );

      final result = withScopedConfig(
        overrides,
        () => Convert.toDateTime('2025/01/02'),
      );

      expect(result.year, equals(2025));
      expect(result.month, equals(1));
      expect(result.day, equals(2));
    });

    test('should parse extra patterns and return utc when requested', () {
      final overrides = makeTestConfig(
        dates: const DateOptions(
          autoDetectFormat: true,
          extraAutoDetectPatterns: ['yyyy/MM/dd'],
        ),
      );

      final result = withScopedConfig(
        overrides,
        () => Convert.toDateTime('2025/01/02', utc: true),
      );

      expect(result.isUtc, isTrue);
    });

    test('should rethrow ConversionException from converter', () {
      expect(
        () => Convert.toDateTime(
          '2025-01-01',
          converter: (_) => throw _testException('toDateTime'),
        ),
        throwsConversionException(method: 'toDateTime'),
      );
    });
  });

  group('Convert.tryToDateTime numeric and format branches', () {
    test('should interpret numeric seconds as epoch seconds', () {
      const seconds = 1700000000;
      final expected = DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000,
        isUtc: true,
      );

      final result = Convert.tryToDateTime(seconds, utc: true);

      expect(result, sameInstantAs(expected));
    });

    test('should interpret numeric milliseconds as epoch milliseconds', () {
      const millis = 1700000000000;
      final expected = DateTime.fromMillisecondsSinceEpoch(
        millis,
        isUtc: true,
      );

      final result = Convert.tryToDateTime(millis, utc: true);

      expect(result, sameInstantAs(expected));
    });

    test('should parse using explicit format when provided', () {
      final result = Convert.tryToDateTime(
        '2025-01-31',
        format: 'yyyy-MM-dd',
      );

      expect(result, isA<DateTime>());
      expect(result!.year, equals(2025));
    });

    test('should parse auto-detect patterns in local time', () {
      final overrides = makeTestConfig(
        dates: const DateOptions(
          autoDetectFormat: true,
          extraAutoDetectPatterns: ['yyyy/MM/dd'],
        ),
      );

      final result = withScopedConfig(
        overrides,
        () => Convert.tryToDateTime('2025/01/02', utc: false),
      );

      expect(result, isA<DateTime>());
      expect(result!.year, equals(2025));
    });

    test('should parse auto-detect patterns in utc', () {
      final overrides = makeTestConfig(
        dates: const DateOptions(
          autoDetectFormat: true,
          extraAutoDetectPatterns: ['yyyy/MM/dd'],
        ),
      );

      final result = withScopedConfig(
        overrides,
        () => Convert.tryToDateTime('2025/01/02', utc: true),
      );

      expect(result, isA<DateTime>());
      expect(result!.isUtc, isTrue);
    });
  });
}
