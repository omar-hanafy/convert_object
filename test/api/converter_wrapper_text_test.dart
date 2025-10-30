import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('Converter wrapper — .convert.toText / tryToText / toTextOr', () {
    test('toText / tryToText basics', () {
      expect('x'.convert.toText(), 'x');
      expect(5.convert.toText(), '5');
      expect(null.convert.tryToText(), isNull);
      expect(null.convert.toTextOr('fallback'), 'fallback');
    });

    test('withDefault applies to toText / tryToText', () {
      expect(null.convert.withDefault('d').toText(), 'd');
      expect(null.convert.withDefault('d').tryToText(), 'd');
    });

    test('fromMap / fromList chaining', () {
      final data = {
        'users': [
          {'name': 'Omar'},
          {'name': 'Sara'},
        ],
      };

      final firstName =
          data.convert.fromMap('users').fromList(0).fromMap('name').toText();
      final secondName =
          data.convert.fromMap('users').fromList(1).fromMap('name').toText();

      expect(firstName, 'Omar');
      expect(secondName, 'Sara');
    });

    test('decoded → navigate into JSON string content', () {
      final json = '{"a":{"b":["zero","one","two"]}}';
      final v0 =
          json.convert.decoded.fromMap('a').fromMap('b').fromList(0).toText();
      final v2 =
          json.convert.decoded.fromMap('a').fromMap('b').fromList(2).toText();

      expect(v0, 'zero');
      expect(v2, 'two');
    });

    test('tryToText with missing path returns null or default', () {
      final json = '{"a":{"b":["zero"]}}';
      final missing =
          json.convert.decoded.fromMap('a').fromMap('missing').tryToText();
      final withDefault =
          json.convert.decoded.fromMap('a').fromMap('missing').toTextOr('N/A');

      expect(missing, isNull);
      expect(withDefault, 'N/A');
    });

    test('withConverter affects .to<T>() (not .toText())', () {
      // Demonstrate that custom conversion pipeline works via to<T>() calls.
      final c = 5.convert.withConverter((v) => 'N=${v.toString()}');
      expect(c.to<String>(), 'N=5');

      // And .tryToText ignores the custom converter (uses toString path)
      expect(c.tryToText(), '5');
    });
  });
}
