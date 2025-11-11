import 'package:convert_object/convert_object.dart'; // for ConversionException
import 'package:convert_object/src/core/convert_object_impl.dart';
import 'package:test/test.dart';

import '../_setup/test_config.dart';

void main() {
  // Ensure a stable default locale for this suite.
  configureTests(defaultLocale: 'en_US');

  group('ConvertObjectImpl.string / tryToString', () {
    test('primitives → string', () {
      expect(ConvertObjectImpl.string('abc'), 'abc');
      expect(ConvertObjectImpl.string(42), '42');
      expect(ConvertObjectImpl.string(true), 'true');
      expect(ConvertObjectImpl.string(BigInt.from(7)), '7');
    });

    test('null → throws (string) and defaultValue is respected', () {
      expect(
        () => ConvertObjectImpl.string(null),
        throwsA(isA<ConversionException>()),
      );
      expect(
        ConvertObjectImpl.string(null, defaultValue: 'N/A'),
        'N/A',
      );
    });

    test('tryToString returns null or default', () {
      expect(ConvertObjectImpl.tryToString(null), isNull);
      expect(
        ConvertObjectImpl.tryToString(null, defaultValue: 'x'),
        'x',
      );
    });

    test('mapKey/listIndex extraction works', () {
      final data = {
        'name': 'Omar',
        'items': ['a', 'b', 'c'],
        'nested': {
          'list': [
            {'id': 10},
            {'id': 20}
          ]
        }
      };

      expect(ConvertObjectImpl.string(data, mapKey: 'name'), 'Omar');
      expect(
          ConvertObjectImpl.string(data, mapKey: 'items', listIndex: 2), 'c');
      expect(
        ConvertObjectImpl.string(
          data,
          mapKey: 'nested',
          // pull nested.list[1].id as string
          converter: (o) => ConvertObjectImpl.string(o,
              mapKey: 'list',
              listIndex: 1,
              converter: (e) => ConvertObjectImpl.string(e, mapKey: 'id')),
        ),
        '20',
      );
    });

    test('JSON strings are NOT auto-decoded for string primitives', () {
      const json = '{"a":"v"}';
      // Because input is already a String, _convertObject<T> returns it directly
      // and ignores mapKey/listIndex for text primitives.
      expect(ConvertObjectImpl.string(json, mapKey: 'a'), json);
      expect(ConvertObjectImpl.tryToString(json, mapKey: 'a'), json);
    });

    test('missing mapKey → string throws, tryToString uses default', () {
      final m = {'a': 1};
      expect(
        () => ConvertObjectImpl.string(m, mapKey: 'b'),
        throwsA(isA<ConversionException>()),
      );
      expect(
        ConvertObjectImpl.tryToString(m, mapKey: 'b', defaultValue: 'none'),
        'none',
      );
    });

    test('custom converter is used', () {
      final out =
          ConvertObjectImpl.string(7, converter: (o) => 'n=${o.toString()}');
      expect(out, 'n=7');
    });

    test('ConversionException context contains method and debug info', () {
      try {
        ConvertObjectImpl.string(
          {'k': 'v'},
          mapKey: 'missing',
          debugInfo: {'case': 'string-context'},
        );
        fail('Expected ConversionException');
      } on ConversionException catch (e) {
        expect(e.context['method'], 'string');
        expect(e.context['mapKey'], 'missing');
        expect(e.context['defaultValue'], isNull);
        expect(e.context['converter'], anyOf(isNull, isA<String>()));
        expect(e.context['objectType'], isNotNull);
        expect(e.context['case'], 'string-context');
      }
    });
  });
}
