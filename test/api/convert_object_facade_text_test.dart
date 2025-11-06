import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('Convert facade — toStringValue / tryToStringValue', () {
    test('passes through strings and converts common primitives', () {
      expect(Convert.toStringValue('hello'), 'hello');
      expect(Convert.toStringValue(123), '123');
      expect(Convert.toStringValue(1.5), '1.5');
      expect(Convert.toStringValue(true), 'true');
      expect(Convert.toStringValue(BigInt.parse('42')), '42');
      expect(Convert.toStringValue(Uri.parse('https://example.com')),
          'https://example.com');
    });

    test('null: toStringValue throws unless defaultValue is provided', () {
      expect(() => Convert.toStringValue(null),
          throwsA(isA<ConversionException>()));
      expect(Convert.toStringValue(null, defaultValue: 'N/A'), 'N/A');
    });

    test('null: tryToStringValue returns null or defaultValue', () {
      expect(Convert.tryToStringValue(null), isNull);
      expect(
          Convert.tryToStringValue(null, defaultValue: 'fallback'), 'fallback');
    });

    test('mapKey / listIndex extraction from Map and List', () {
      final data = {
        'name': 'Omar',
        'tags': ['dart', 'utils'],
        'nested': {
          'inner': ['a', 'b', 'c'],
        },
      };

      expect(Convert.toStringValue(data, mapKey: 'name'), 'Omar');
      expect(
          Convert.toStringValue(data, mapKey: 'tags', listIndex: 1), 'utils');
      expect(
          Convert.toStringValue(data, mapKey: 'nested'), '{inner: [a, b, c]}');

      // Direct list access using listIndex (root object is a List)
      final list = ['x', 'y', 'z'];
      expect(Convert.toStringValue(list, listIndex: 2), 'z');
    });

    test(
        'out-of-range listIndex: toStringValue throws, tryToStringValue uses default',
        () {
      final list = ['x'];
      expect(() => Convert.toStringValue(list, listIndex: 10),
          throwsA(isA<ConversionException>()));
      expect(
          Convert.tryToStringValue(list, listIndex: 10, defaultValue: 'none'),
          'none');
    });

    test('mapKey on a plain String is ignored (no decode for primitives)', () {
      const jsonLike = '{"a":"v"}';
      // Because the input is already a String (target type), _convertObject returns it directly.
      expect(Convert.toStringValue(jsonLike, mapKey: 'a'), jsonLike);
      expect(Convert.tryToStringValue(jsonLike, mapKey: 'a'), jsonLike);
    });

    test('custom converter is used when input is not already a String', () {
      final out =
          Convert.toStringValue(7, converter: (o) => 'n=${o.toString()}');
      expect(out, 'n=7');
    });

    test('tryToStringValue: converter throwing results in default (or null)',
        () {
      String throwing(Object? _) => throw StateError('boom');
      expect(Convert.tryToStringValue(5, converter: throwing), isNull);
      expect(
          Convert.tryToStringValue(5, converter: throwing, defaultValue: 'X'),
          'X');
    });
  });
}
