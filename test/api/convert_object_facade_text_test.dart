import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('Convert facade — string / tryToString', () {
    test('passes through strings and converts common primitives', () {
      expect(Convert.string('hello'), 'hello');
      expect(Convert.string(123), '123');
      expect(Convert.string(1.5), '1.5');
      expect(Convert.string(true), 'true');
      expect(Convert.string(BigInt.parse('42')), '42');
      expect(Convert.string(Uri.parse('https://example.com')),
          'https://example.com');
    });

    test('null: string throws unless defaultValue is provided', () {
      expect(() => Convert.string(null), throwsA(isA<ConversionException>()));
      expect(Convert.string(null, defaultValue: 'N/A'), 'N/A');
    });

    test('null: tryToString returns null or defaultValue', () {
      expect(Convert.tryToString(null), isNull);
      expect(Convert.tryToString(null, defaultValue: 'fallback'), 'fallback');
    });

    test('mapKey / listIndex extraction from Map and List', () {
      final data = {
        'name': 'Omar',
        'tags': ['dart', 'utils'],
        'nested': {
          'inner': ['a', 'b', 'c'],
        },
      };

      expect(Convert.string(data, mapKey: 'name'), 'Omar');
      expect(Convert.string(data, mapKey: 'tags', listIndex: 1), 'utils');
      expect(Convert.string(data, mapKey: 'nested'), '{inner: [a, b, c]}');

      // Direct list access using listIndex (root object is a List)
      final list = ['x', 'y', 'z'];
      expect(Convert.string(list, listIndex: 2), 'z');
    });

    test('out-of-range listIndex: string throws, tryToString uses default', () {
      final list = ['x'];
      expect(() => Convert.string(list, listIndex: 10),
          throwsA(isA<ConversionException>()));
      expect(Convert.tryToString(list, listIndex: 10, defaultValue: 'none'),
          'none');
    });

    test('mapKey on a plain String is ignored (no decode for primitives)', () {
      const jsonLike = '{"a":"v"}';
      // Because the input is already a String (target type), _convertObject returns it directly.
      expect(Convert.string(jsonLike, mapKey: 'a'), jsonLike);
      expect(Convert.tryToString(jsonLike, mapKey: 'a'), jsonLike);
    });

    test('custom converter is used when input is not already a String', () {
      final out = Convert.string(7, converter: (o) => 'n=${o.toString()}');
      expect(out, 'n=7');
    });

    test('tryToString: converter throwing results in default (or null)', () {
      String throwing(Object? _) => throw StateError('boom');
      expect(Convert.tryToString(5, converter: throwing), isNull);
      expect(
          Convert.tryToString(5, converter: throwing, defaultValue: 'X'), 'X');
    });
  });
}
