import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('ConvertObject facade — toText / tryToText', () {
    test('passes through strings and converts common primitives', () {
      expect(ConvertObject.toText('hello'), 'hello');
      expect(ConvertObject.toText(123), '123');
      expect(ConvertObject.toText(1.5), '1.5');
      expect(ConvertObject.toText(true), 'true');
      expect(ConvertObject.toText(BigInt.parse('42')), '42');
      expect(ConvertObject.toText(Uri.parse('https://example.com')),
          'https://example.com');
    });

    test('null: toText throws unless defaultValue is provided', () {
      expect(() => ConvertObject.toText(null),
          throwsA(isA<ConversionException>()));
      expect(ConvertObject.toText(null, defaultValue: 'N/A'), 'N/A');
    });

    test('null: tryToText returns null or defaultValue', () {
      expect(ConvertObject.tryToText(null), isNull);
      expect(
          ConvertObject.tryToText(null, defaultValue: 'fallback'), 'fallback');
    });

    test('mapKey / listIndex extraction from Map and List', () {
      final data = {
        'name': 'Omar',
        'tags': ['dart', 'utils'],
        'nested': {
          'inner': ['a', 'b', 'c'],
        },
      };

      expect(ConvertObject.toText(data, mapKey: 'name'), 'Omar');
      expect(ConvertObject.toText(data, mapKey: 'tags', listIndex: 1), 'utils');
      expect(
          ConvertObject.toText(data, mapKey: 'nested'), '{inner: [a, b, c]}');

      // Direct list access using listIndex (root object is a List)
      final list = ['x', 'y', 'z'];
      expect(ConvertObject.toText(list, listIndex: 2), 'z');
    });

    test('out-of-range listIndex: toText throws, tryToText uses default', () {
      final list = ['x'];
      expect(() => ConvertObject.toText(list, listIndex: 10),
          throwsA(isA<ConversionException>()));
      expect(ConvertObject.tryToText(list, listIndex: 10, defaultValue: 'none'),
          'none');
    });

    test('mapKey on a plain String is ignored (no decode for primitives)', () {
      const jsonLike = '{"a":"v"}';
      // Because the input is already a String (target type), _convertObject returns it directly.
      expect(ConvertObject.toText(jsonLike, mapKey: 'a'), jsonLike);
      expect(ConvertObject.tryToText(jsonLike, mapKey: 'a'), jsonLike);
    });

    test('custom converter is used when input is not already a String', () {
      final out =
          ConvertObject.toText(7, converter: (o) => 'n=${o.toString()}');
      expect(out, 'n=7');
    });

    test('tryToText: converter throwing results in default (or null)', () {
      String throwing(Object? _) => throw StateError('boom');
      expect(ConvertObject.tryToText(5, converter: throwing), isNull);
      expect(ConvertObject.tryToText(5, converter: throwing, defaultValue: 'X'),
          'X');
    });
  });
}
