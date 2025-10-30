import 'package:convert_object/src/core/convert_object_impl.dart';
import 'package:test/test.dart';

void main() {
  group('ConvertObjectImpl collections', () {
    group('toList<T> / tryToList<T>', () {
      test('single value → [T]', () {
        expect(ConvertObjectImpl.toList<int>(1), [1]);
        expect(ConvertObjectImpl.toList<String>('x'), ['x']);
      });

      test('Iterable with mixed element types converts via toType<T>', () {
        final out = ConvertObjectImpl.toList<int>(['1', 2, 3.0]);
        expect(out, [1, 2, 3]);
      });

      test('Set → List', () {
        // ignore: equal_elements_in_set
        final out = ConvertObjectImpl.toList<int>({1, 2, 2, 3});
        expect(out..sort(), [1, 2, 3]);
      });

      test('Map<String,int> → values List<int> (typed branch)', () {
        final m = {'a': 1, 'b': 2};
        final out = ConvertObjectImpl.toList<int>(m);
        out.sort();
        expect(out, [1, 2]);
      });

      test('JSON array string is auto-decoded for collections', () {
        const json = '["1","2","3"]';
        final out = ConvertObjectImpl.toList<int>(json);
        expect(out, [1, 2, 3]);
      });

      test('tryToList returns default on non-iterable', () {
        final def = <int>[9];
        expect(ConvertObjectImpl.tryToList<int>('x', defaultValue: def), def);
        expect(ConvertObjectImpl.tryToList<int>('x'), isNull);
      });

      test('mapKey/listIndex to reach nested lists', () {
        final obj = [
          {
            'numbers': ['1', '2']
          }
        ];
        final out = ConvertObjectImpl.toList<int>(
          obj,
          listIndex: 0,
          mapKey: 'numbers',
        );
        expect(out, [1, 2]);
      });
    });

    group('toSet<T> / tryToSet<T>', () {
      test('single element becomes {T}', () {
        final s = ConvertObjectImpl.toSet<String>('x');
        expect(s.length, 1);
        expect(s.contains('x'), isTrue);
      });

      test('Iterable → Set with conversion and uniqueness', () {
        final s = ConvertObjectImpl.toSet<int>(['1', '2', 2, 3.0]);
        expect(s.contains(1), isTrue);
        expect(s.contains(2), isTrue);
        expect(s.contains(3), isTrue);
        expect(s.length, 3);
      });

      test('JSON array string auto-decoded for Set', () {
        const json = '["a","a","b"]';
        final s = ConvertObjectImpl.toSet<String>(json);
        expect(s.length, 2);
        expect(s.containsAll(['a', 'b']), isTrue);
      });

      test('tryToSet default on non-iterable', () {
        final def = <int>{7};
        expect(ConvertObjectImpl.tryToSet<int>('x', defaultValue: def), def);
        expect(ConvertObjectImpl.tryToSet<int>('x'), isNull);
      });
    });

    group('toMap<K,V> / tryToMap<K,V>', () {
      test('typed map pass-through', () {
        final m = {'a': 1, 'b': 2};
        final out = ConvertObjectImpl.toMap<String, int>(m);
        expect(out, {'a': 1, 'b': 2});
      });

      test('keyConverter/valueConverter are applied', () {
        final raw = {'1': '2', '3': '4'};
        final out = ConvertObjectImpl.toMap<int, int>(
          raw,
          keyConverter: (k) => int.parse(k.toString()),
          valueConverter: (v) => int.parse(v.toString()),
        );
        expect(out, {1: 2, 3: 4});
      });

      test('JSON object string is auto-decoded for Map', () {
        const json = '{"x": "1", "y": "2"}';
        final out = ConvertObjectImpl.toMap<String, int>(
          json,
          valueConverter: (v) => int.parse(v.toString()),
        );
        expect(out, {'x': 1, 'y': 2});
      });

      test('tryToMap returns default on non-map', () {
        final def = <String, String>{'k': 'v'};
        expect(
            ConvertObjectImpl.tryToMap<String, String>('x', defaultValue: def),
            def);
        expect(ConvertObjectImpl.tryToMap<String, String>('x'), isNull);
      });
    });

    test('toList elementConverter overrides default conversion', () {
      final out = ConvertObjectImpl.toList<String>(
        [1, 2, 3],
        elementConverter: (e) => 'n=${e.toString()}',
      );
      expect(out, ['n=1', 'n=2', 'n=3']);
    });

    test('toSet elementConverter overrides default conversion', () {
      final out = ConvertObjectImpl.toSet<String>(
        [1, 1, 2],
        elementConverter: (e) => 'v${e.toString()}',
      );
      expect(out.length, 2);
      expect(out.containsAll(['v1', 'v2']), isTrue);
    });

    test('toMap with only valueConverter', () {
      final raw = {'a': '1', 'b': '2'};
      final out = ConvertObjectImpl.toMap<String, int>(
        raw,
        valueConverter: (v) => int.parse(v.toString()),
      );
      expect(out, {'a': 1, 'b': 2});
    });
  });
}
