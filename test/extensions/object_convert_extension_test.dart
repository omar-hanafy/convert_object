import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('ConvertObjectExtension (.convert) – Text shortcuts', () {
    test('toText / tryToText / toTextOr', () {
      expect('x'.convert.toText(), 'x');
      expect(null.convert.tryToText(), isNull);
      expect(null.convert.toTextOr('fallback'), 'fallback');
    });

    test('withDefault participates in toText/tryToText', () {
      expect(null.convert.withDefault('d').tryToText(), 'd');
      expect(null.convert.withDefault('d').toText(), 'd');
    });

    test('withConverter overrides conversion path', () {
      final c = 5.convert.withConverter((v) => 'N=${v.toString()}');
      expect(c.toText(), '5');
    });

    test('fromMap/fromList chaining', () {
      final obj = {
        'users': [
          {'name': 'Omar'}
        ]
      };
      final name =
          obj.convert.fromMap('users').fromList(0).fromMap('name').toText();
      expect(name, 'Omar');
    });

    test('decoded loads JSON strings before navigation', () {
      final json = r'{"user":{"name":"Omar"}}';
      final name =
          json.convert.decoded.fromMap('user').fromMap('name').toText();
      expect(name, 'Omar');
    });
  });
}
