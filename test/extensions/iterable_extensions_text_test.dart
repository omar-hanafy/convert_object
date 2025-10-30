import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('IterableConversionX.getText', () {
    test('returns element at index', () {
      final list = ['a', 'b', 'c'];
      expect(list.getText(1), 'b');
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
      expect(list.getText(0, innerMapKey: 'names', innerIndex: 1), 'bob');
      expect(list.getText(1, innerMapKey: 'names', innerIndex: 0), 'carol');
    });

    test('out-of-range index → getText throws ConversionException', () {
      final list = ['a'];
      expect(() => list.getText(3), throwsA(isA<ConversionException>()));
    });
  });

  group('NullableIterableConversionX.tryGetText (on Iterable<E>?)', () {
    test('falls back to alternativeIndices when primary missing', () {
      final List<String>? list = ['z'];
      // Ask for index 2 but allow fallback to 0
      expect(list.tryGetText(2, alternativeIndices: [0]), 'z');
    });

    test('returns defaultValue when all indices missing', () {
      final List<String>? list = ['only'];
      expect(
        list.tryGetText(5, alternativeIndices: [4, 3], defaultValue: 'd'),
        'd',
      );
    });

    test('null iterable → tryGetText returns defaultValue/null', () {
      final List<String>? list = null;
      expect(list.tryGetMap<dynamic, dynamic>(0), isNull);
      expect(list.tryGetText(0, defaultValue: 'x'), 'x');
    });

    test('inner navigation with alternativeIndices', () {
      final List<Map<String, dynamic>>? list = [
        {'name': 'first'},
      ];
      // index 3 doesn’t exist; fallback to 0
      expect(
        list.tryGetText(3, alternativeIndices: [0], innerMapKey: 'name'),
        'first',
      );
    });
  });
}
