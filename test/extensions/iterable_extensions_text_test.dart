import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('IterableConversionX.getString', () {
    test('returns element at index', () {
      final list = ['a', 'b', 'c'];
      expect(list.getString(1), 'b');
    });

    test('supports innerMapKey / innerIndex navigation', () {
      final list = [
        {
          'names': ['alice', 'bob']
        },
        {
          'names': ['carol', 'dave']
        },
      ];
      expect(list.getString(0, innerMapKey: 'names', innerIndex: 1), 'bob');
      expect(list.getString(1, innerMapKey: 'names', innerIndex: 0), 'carol');
    });

    test('out-of-range index → getString throws ConversionException', () {
      final list = ['a'];
      expect(() => list.getString(3), throwsA(isA<ConversionException>()));
    });
  });

  group('NullableIterableConversionX.tryGetString (on Iterable<E>?)', () {
    test('falls back to alternativeIndices when primary missing', () {
      final List<String> list = ['z'];
      // Ask for index 2 but allow fallback to 0
      expect(list.tryGetString(2, alternativeIndices: [0]), 'z');
    });

    test('returns defaultValue when all indices missing', () {
      final List<String> list = ['only'];
      expect(
        list.tryGetString(5, alternativeIndices: [4, 3], defaultValue: 'd'),
        'd',
      );
    });

    test('null iterable → tryGetString returns defaultValue/null', () {
      const List<String>? list = null;
      expect(list.tryGetMap<dynamic, dynamic>(0), isNull);
      expect(list.tryGetString(0, defaultValue: 'x'), 'x');
    });

    test('inner navigation with alternativeIndices', () {
      final List<Map<String, dynamic>> list = [
        {'name': 'first'},
      ];
      // index 3 doesn’t exist; fallback to 0
      expect(
        list.tryGetString(3, alternativeIndices: [0], innerMapKey: 'name'),
        'first',
      );
    });
  });
}
