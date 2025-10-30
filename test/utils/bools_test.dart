import 'package:convert_object/src/utils/bools.dart';
import 'package:test/test.dart';

void main() {
  group('BoolParsingX.asBool', () {
    test('null and booleans', () {
      Object? v;
      expect(v.asBool, isFalse);
      expect(true.asBool, isTrue);
      expect(false.asBool, isFalse);
    });

    test('numbers', () {
      expect(1.asBool, isTrue);
      expect(2.asBool, isTrue);
      expect(0.asBool, isFalse);
      expect((-1).asBool, isFalse);
      expect(2.5.asBool, isTrue);
      expect((-0.1).asBool, isFalse);
    });

    test('numeric strings', () {
      expect('1'.asBool, isTrue);
      expect('0'.asBool, isFalse);
      expect('  2.5 '.asBool, isTrue);
      expect('-5'.asBool, isFalse);
    });

    test('truthy strings', () {
      for (final s in ['true', 'True', ' TRUE ', 'yes', 'y', 'on', 'ok', 't']) {
        expect(s.asBool, isTrue, reason: 'Expected "$s" to be truthy');
      }
    });

    test('falsy strings', () {
      for (final s in ['false', 'False', ' FALSE ', 'no', 'n', 'off', 'f']) {
        expect(s.asBool, isFalse, reason: 'Expected "$s" to be falsy');
      }
    });

    test('other strings → false', () {
      expect('hello'.asBool, isFalse);
      expect(''.asBool, isFalse);
      expect('   '.asBool, isFalse);
    });
  });
}
