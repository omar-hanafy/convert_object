import 'package:convert_object/convert_object.dart'; // exports the top-level toText/tryToText
import 'package:test/test.dart';

void main() {
  group('Top-level functions — toText / tryToText', () {
    test('basic conversions', () {
      expect(toText('s'), 's');
      expect(toText(10), '10');
      expect(toText(false), 'false');
    });

    test('null behavior', () {
      expect(() => toText(null), throwsA(isA<ConversionException>()));
      expect(toText(null, defaultValue: 'N/A'), 'N/A');

      expect(tryToText(null), isNull);
      expect(tryToText(null, defaultValue: 'fallback'), 'fallback');
    });

    test('mapKey / listIndex extraction', () {
      final obj = {
        'title': 'Convert',
        'items': ['a', 'b'],
      };
      expect(toText(obj, mapKey: 'title'), 'Convert');
      expect(toText(obj, mapKey: 'items', listIndex: 1), 'b');

      final list = [1, 2, 3];
      expect(toText(list, listIndex: 0), '1');
    });

    test('custom converter is honored for non-string input', () {
      final out = toText(99, converter: (o) => 'N=${o.toString()}');
      expect(out, 'N=99');
    });

    test('mapKey on already-String input is ignored (no decode)', () {
      const s = '{"k":"v"}';
      expect(toText(s, mapKey: 'k'), s);
      expect(tryToText(s, mapKey: 'k'), s);
    });
  });
}
