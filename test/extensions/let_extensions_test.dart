import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('let extensions', () {
    test('non-null let', () {
      final out = 'omar'.let((it) => it.toUpperCase());
      expect(out, 'OMAR');
    });

    test('nullable let -> null input yields null', () {
      String? s;
      final out = s.let((it) => it.toUpperCase());
      expect(out, isNull);
    });

    test('letOr uses default when null', () {
      String? s;
      final out = s.letOr((it) => it.toUpperCase(), defaultValue: 'DEFAULT');
      expect(out, 'DEFAULT');
    });

    test('letOr uses block when non-null', () {
      String? s = 'abc';
      final out = s.letOr((it) => it.toUpperCase(), defaultValue: 'DEFAULT');
      expect(out, 'ABC');
    });

    test('letNullable passes through non-null and returns its result', () {
      String? s = 'x';
      final out = s.letNullable((it) => it?.toUpperCase());
      expect(out, 'X');
    });

    test('letNullable returns null when receiver is null', () {
      String? s;
      final out = s.letNullable((it) => it?.toUpperCase());
      expect(out, isNull);
    });
  });
}
