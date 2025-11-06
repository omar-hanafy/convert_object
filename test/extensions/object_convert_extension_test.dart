import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('ConvertObjectExtension (.convert) – String shortcuts', () {
    test('toStringValue / tryToStringValue / toStringValueOr', () {
      expect('x'.convert.toStringValue(), 'x');
      expect(null.convert.tryToStringValue(), isNull);
      expect(null.convert.toStringValueOr('fallback'), 'fallback');
    });

    test('withDefault participates in toStringValue/tryToStringValue', () {
      expect(null.convert.withDefault('d').tryToStringValue(), 'd');
      expect(null.convert.withDefault('d').toStringValue(), 'd');
    });

    test('withConverter overrides conversion path', () {
      final c = 5.convert.withConverter((v) => 'N=${v.toString()}');
      expect(c.toStringValue(), '5');
    });

    test('fromMap/fromList chaining', () {
      final obj = {
        'users': [
          {'name': 'Omar'}
        ]
      };
      final name = obj.convert
          .fromMap('users')
          .fromList(0)
          .fromMap('name')
          .toStringValue();
      expect(name, 'Omar');
    });

    test('decoded loads JSON strings before navigation', () {
      const json = r'{"user":{"name":"Omar"}}';
      final name =
          json.convert.decoded.fromMap('user').fromMap('name').toStringValue();
      expect(name, 'Omar');
    });
  });
}
