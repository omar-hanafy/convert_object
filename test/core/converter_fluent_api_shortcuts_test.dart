import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';
import '../helpers/test_enums.dart';

void main() {
  late ConvertConfig prev;

  setUp(() {
    prev = Convert.configure(makeTestConfig(locale: 'en_US'));
  });

  tearDown(() {
    Convert.configure(prev);
  });

  group('Converter shortcut primitives', () {
    test('toNum / tryToNum / toNumOr', () {
      expect(const Converter('123').toNum(), equals(123));
      expect(const Converter('abc').tryToNum(), isNull);
      expect(const Converter('abc').toNumOr(0), equals(0));
      expect(
        () => const Converter('abc').toNum(),
        throwsConversionException(method: 'toNum'),
      );
    });

    test('toInt / tryToInt / toIntOr', () {
      expect(const Converter('42').toInt(), equals(42));
      expect(const Converter('abc').tryToInt(), isNull);
      expect(const Converter('abc').toIntOr(-1), equals(-1));
      expect(
        () => const Converter('abc').toInt(),
        throwsConversionException(method: 'toInt'),
      );
    });

    test('toInt should support mapKey, listIndex, and defaultValue', () {
      final map = <String, Object?>{'v': '7'};
      expect(Converter(map).toInt(mapKey: 'v'), equals(7));
      final list = <Object?>['1', '2'];
      expect(Converter(list).toInt(listIndex: 1), equals(2));
      expect(const Converter('abc').toInt(defaultValue: 9), equals(9));
    });

    test('toDouble / tryToDouble / toDoubleOr', () {
      expect(const Converter('12.5').toDouble(), equals(12.5));
      expect(const Converter('abc').tryToDouble(), isNull);
      expect(const Converter('abc').toDoubleOr(0.0), equals(0.0));
      expect(
        () => const Converter('abc').toDouble(),
        throwsConversionException(method: 'toDouble'),
      );
    });

    test('toBigInt / tryToBigInt / toBigIntOr', () {
      final big = BigInt.parse('9007199254740993');
      expect(Converter(big.toString()).toBigInt(), equals(big));
      expect(const Converter('abc').tryToBigInt(), isNull);
      expect(const Converter('abc').toBigIntOr(BigInt.zero), BigInt.zero);
      expect(
        () => const Converter('abc').toBigInt(),
        throwsConversionException(method: 'toBigInt'),
      );
    });

    test('toBool / tryToBool / toBoolOr', () {
      expect(const Converter('true').toBool(), isTrue);
      expect(const Converter('false').toBool(), isFalse);
      expect(const Converter('random').tryToBool(), isNull);
      expect(const Converter('random').toBool(), isFalse);
      expect(const Converter('random').toBoolOr(true), isTrue);
    });

    test('toString / tryToString / toStringOr', () {
      expect(const Converter(123).toString(), equals('123'));
      expect(const Converter(null).tryToString(), isNull);
      expect(const Converter(null).toStringOr('fallback'), equals('fallback'));
      final map = <String, Object?>{'v': 5};
      expect(Converter(map).string(mapKey: 'v'), equals('5'));
      expect(
        () => const Converter(null).toString(),
        throwsConversionException(method: 'string'),
      );
    });
  });

  group('Converter shortcut complex types', () {
    test('toDateTime / tryToDateTime / toDateTimeOr', () {
      const dateStr = '2025-01-01';
      expect(const Converter(dateStr).tryToDateTime(), isNotNull);
      expect(const Converter('not-date').tryToDateTime(), isNull);
      final fallback = DateTime.utc(2000, 1, 1);
      expect(const Converter('not-date').toDateTimeOr(fallback), fallback);
      expect(
        () => const Converter('not-date').toDateTime(),
        throwsConversionException(method: 'toDateTime'),
      );
    });

    test('toUri / tryToUri / toUriOr', () {
      const uriStr = 'https://example.com';
      expect(const Converter(uriStr).toUri(), equals(Uri.parse(uriStr)));
      expect(const Converter('::invalid::').tryToUri(), isNull);
      final fallback = Uri.parse('https://fallback.example');
      expect(const Converter('::invalid::').toUriOr(fallback), fallback);
      expect(
        () => const Converter('::invalid::').toUri(),
        throwsConversionException(method: 'toUri'),
      );
    });
  });

  group('Converter shortcut enums', () {
    test('toEnum / tryToEnum', () {
      final map = <String, Object?>{'status': 'active'};
      final parser = TestStatus.values.parser;
      expect(
        Converter(map).toEnum<TestStatus>(parser: parser, mapKey: 'status'),
        equals(TestStatus.active),
      );
      expect(
        const Converter('unknown').tryToEnum<TestStatus>(parser: parser),
        isNull,
      );
    });
  });

  group('Converter shortcut collections', () {
    test('toList / tryToList', () {
      final input = <dynamic>['1', '2', '3'];
      expect(Converter(input).toList<int>(), equals(<int>[1, 2, 3]));
      expect(const Converter('not-list').tryToList<int>(), isNull);
      expect(
        const Converter('not-list').toList<int>(defaultValue: <int>[7]),
        equals(<int>[7]),
      );
      expect(
        Converter(
          input,
        ).toList<int>(elementConverter: (e) => Convert.toInt(e) * 2),
        equals(<int>[2, 4, 6]),
      );
    });

    test('toSet / tryToSet', () {
      final input = <dynamic>['1', '2', '2'];
      expect(Converter(input).toSet<int>(), equals(<int>{1, 2}));
      expect(const Converter('not-set').tryToSet<int>(), isNull);
      expect(
        Converter(
          input,
        ).toSet<int>(elementConverter: (e) => Convert.toInt(e) + 1),
        equals(<int>{2, 3}),
      );
    });

    test('toMap / tryToMap', () {
      final input = <String, String>{'1': '10', '2': '20'};
      final map = Converter(input).toMap<int, int>(
        keyConverter: (k) => Convert.toInt(k),
        valueConverter: (v) => Convert.toInt(v),
      );
      expect(map, equals(<int, int>{1: 10, 2: 20}));
      expect(const Converter('not-map').tryToMap<String, int>(), isNull);
    });
  });
}
