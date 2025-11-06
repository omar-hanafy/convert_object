import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group(
      'Converter wrapper — .convert.toStringValue / tryToStringValue / toStringValueOr',
      () {
    test('toStringValue / tryToStringValue basics', () {
      expect('x'.convert.toStringValue(), 'x');
      expect(5.convert.toStringValue(), '5');
      expect(null.convert.tryToStringValue(), isNull);
      expect(null.convert.toStringValueOr('fallback'), 'fallback');
    });

    test('withDefault applies to toStringValue / tryToStringValue', () {
      expect(null.convert.withDefault('d').toStringValue(), 'd');
      expect(null.convert.withDefault('d').tryToStringValue(), 'd');
    });

    test('fromMap / fromList chaining', () {
      final data = {
        'users': [
          {'name': 'Omar'},
          {'name': 'Sara'},
        ],
      };

      final firstName = data.convert
          .fromMap('users')
          .fromList(0)
          .fromMap('name')
          .toStringValue();
      final secondName = data.convert
          .fromMap('users')
          .fromList(1)
          .fromMap('name')
          .toStringValue();

      expect(firstName, 'Omar');
      expect(secondName, 'Sara');
    });

    test('decoded → navigate into JSON string content', () {
      const json = '{"a":{"b":["zero","one","two"]}}';
      final v0 = json.convert.decoded
          .fromMap('a')
          .fromMap('b')
          .fromList(0)
          .toStringValue();
      final v2 = json.convert.decoded
          .fromMap('a')
          .fromMap('b')
          .fromList(2)
          .toStringValue();

      expect(v0, 'zero');
      expect(v2, 'two');
    });

    test('tryToStringValue with missing path returns null or default', () {
      const json = '{"a":{"b":["zero"]}}';
      final missing = json.convert.decoded
          .fromMap('a')
          .fromMap('missing')
          .tryToStringValue();
      final withDefault = json.convert.decoded
          .fromMap('a')
          .fromMap('missing')
          .toStringValueOr('N/A');

      expect(missing, isNull);
      expect(withDefault, 'N/A');
    });

    test('withConverter affects .to<T>() (not .toStringValue())', () {
      // Demonstrate that custom conversion pipeline works via to<T>() calls.
      final c = 5.convert.withConverter((v) => 'N=${v.toString()}');
      expect(c.to<String>(), 'N=5');

      // And .tryToStringValue ignores the custom converter (uses toString path)
      expect(c.tryToStringValue(), '5');
    });
  });
}
