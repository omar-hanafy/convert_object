import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('Converter wrapper — .Convert.string / tryToString / stringOr', () {
    test('string / tryToString basics', () {
      expect('x'.convert.toString(), 'x');
      expect(5.convert.toString(), '5');
      expect(null.convert.tryToString(), isNull);
      expect(null.convert.toStringOr('fallback'), 'fallback');
    });

    test('withDefault applies to string / tryToString', () {
      expect(null.convert.withDefault('d').toString(), 'd');
      expect(null.convert.withDefault('d').tryToString(), 'd');
    });

    test('fromMap / fromList chaining', () {
      final data = {
        'users': [
          {'name': 'Omar'},
          {'name': 'Sara'},
        ],
      };

      final firstName =
          data.convert.fromMap('users').fromList(0).fromMap('name').toString();
      final secondName =
          data.convert.fromMap('users').fromList(1).fromMap('name').toString();

      expect(firstName, 'Omar');
      expect(secondName, 'Sara');
    });

    test('decoded → navigate into JSON string content', () {
      const json = '{"a":{"b":["zero","one","two"]}}';
      final v0 =
          json.convert.decoded.fromMap('a').fromMap('b').fromList(0).toString();
      final v2 =
          json.convert.decoded.fromMap('a').fromMap('b').fromList(2).toString();

      expect(v0, 'zero');
      expect(v2, 'two');
    });

    test('tryToString with missing path returns null or default', () {
      const json = '{"a":{"b":["zero"]}}';
      final missing =
          json.convert.decoded.fromMap('a').fromMap('missing').tryToString();
      final withDefault = json.convert.decoded
          .fromMap('a')
          .fromMap('missing')
          .toStringOr('N/A');

      expect(missing, isNull);
      expect(withDefault, 'N/A');
    });

    test('withConverter affects .to<T>() (not .string())', () {
      // Demonstrate that custom conversion pipeline works via to<T>() calls.
      final c = 5.convert.withConverter((v) => 'N=${v.toString()}');
      expect(c.to<String>(), 'N=5');

      // And .tryToString ignores the custom converter (uses toString path)
      expect(c.tryToString(), '5');
    });
  });
}
