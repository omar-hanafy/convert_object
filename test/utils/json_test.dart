import 'package:convert_object/src/utils/json.dart';
import 'package:test/test.dart';

void main() {
  group('StringJsonX', () {
    test('tryDecode returns decoded object on valid JSON', () {
      final obj = '{"a":1,"b":[1,2]}'.tryDecode();
      expect(obj, isA<Map<String, dynamic>>());
      final map = obj as Map<String, dynamic>;
      expect(map['a'], 1);
      expect(map['b'], [1, 2]);
    });

    test('tryDecode returns original string on invalid JSON', () {
      const s = 'not json';
      final out = s.tryDecode();
      expect(out, same(s));
    });

    test('decode throws on invalid JSON', () {
      expect(() => 'oops'.decode(), throwsA(isA<FormatException>()));
    });

    test('decode parses valid JSON with surrounding whitespace', () {
      final obj = '  { "x": 42 }  '.decode();
      expect((obj as Map)['x'], 42);
    });

    test('tryDecode preserves type when string is empty or whitespace', () {
      expect(''.tryDecode(), '');
      expect('   '.tryDecode(), '   ');
    });
  });
}
