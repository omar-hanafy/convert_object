import 'package:convert_object/convert_object.dart'; // exports the top-level convertToString/tryConvertToString
import 'package:test/test.dart';

void main() {
  group('Top-level functions — convertToString / tryConvertToString', () {
    test('basic conversions', () {
      expect(convertToString('s'), 's');
      expect(convertToString(10), '10');
      expect(convertToString(false), 'false');
    });

    test('null behavior', () {
      expect(() => convertToString(null), throwsA(isA<ConversionException>()));
      expect(convertToString(null, defaultValue: 'N/A'), 'N/A');

      expect(tryConvertToString(null), isNull);
      expect(tryConvertToString(null, defaultValue: 'fallback'), 'fallback');
    });

    test('mapKey / listIndex extraction', () {
      final obj = {
        'title': 'Convert',
        'items': ['a', 'b'],
      };
      expect(convertToString(obj, mapKey: 'title'), 'Convert');
      expect(convertToString(obj, mapKey: 'items', listIndex: 1), 'b');

      final list = [1, 2, 3];
      expect(convertToString(list, listIndex: 0), '1');
    });

    test('custom converter is honored for non-string input', () {
      final out = convertToString(99, converter: (o) => 'N=${o.toString()}');
      expect(out, 'N=99');
    });

    test('mapKey on already-String input is ignored (no decode)', () {
      const s = '{"k":"v"}';
      expect(convertToString(s, mapKey: 'k'), s);
      expect(tryConvertToString(s, mapKey: 'k'), s);
    });
  });
}
