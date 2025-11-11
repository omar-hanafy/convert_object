import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('ConvertObjectExtension (.convert) – String shortcuts', () {
    test('string / tryToString / stringOr', () {
      expect('x'.convert.toString(), 'x');
      expect(null.convert.tryToString(), isNull);
      expect(null.convert.toStringOr('fallback'), 'fallback');
    });

    test('withDefault participates in string/tryToString', () {
      expect(null.convert.withDefault('d').tryToString(), 'd');
      expect(null.convert.withDefault('d').toString(), 'd');
    });

    test('withConverter overrides conversion path', () {
      final c = 5.convert.withConverter((v) => 'N=${v.toString()}');
      expect(c.toString(), '5');
    });

    test('fromMap/fromList chaining', () {
      final obj = {
        'users': [
          {'name': 'Omar'}
        ]
      };
      final name =
          obj.convert.fromMap('users').fromList(0).fromMap('name').toString();
      expect(name, 'Omar');
    });

    test('decoded loads JSON strings before navigation', () {
      const json = r'{"user":{"name":"Omar"}}';
      final name =
          json.convert.decoded.fromMap('user').fromMap('name').toString();
      expect(name, 'Omar');
    });
  });
}
