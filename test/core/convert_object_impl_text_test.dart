import 'package:convert_object/convert_object.dart'; // for ConversionException
import 'package:convert_object/src/core/convert_object_impl.dart';
import 'package:test/test.dart';

import '../_setup/test_config.dart';

void main() {
  // Ensure a stable default locale for this suite.
  configureTests(defaultLocale: 'en_US');

  group('ConvertObjectImpl.toText / tryToText', () {
    test('primitives → text', () {
      expect(ConvertObjectImpl.toText('abc'), 'abc');
      expect(ConvertObjectImpl.toText(42), '42');
      expect(ConvertObjectImpl.toText(true), 'true');
      expect(ConvertObjectImpl.toText(BigInt.from(7)), '7');
    });

    test('null → throws (toText) and defaultValue is respected', () {
      expect(
        () => ConvertObjectImpl.toText(null),
        throwsA(isA<ConversionException>()),
      );
      expect(
        ConvertObjectImpl.toText(null, defaultValue: 'N/A'),
        'N/A',
      );
    });

    test('tryToText returns null or default', () {
      expect(ConvertObjectImpl.tryToText(null), isNull);
      expect(
        ConvertObjectImpl.tryToText(null, defaultValue: 'x'),
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

      expect(ConvertObjectImpl.toText(data, mapKey: 'name'), 'Omar');
      expect(
          ConvertObjectImpl.toText(data, mapKey: 'items', listIndex: 2), 'c');
      expect(
        ConvertObjectImpl.toText(
          data,
          mapKey: 'nested',
          listIndex: null,
          // pull nested.list[1].id as text
          converter: (o) => ConvertObjectImpl.toText(o,
              mapKey: 'list',
              listIndex: 1,
              converter: (e) => ConvertObjectImpl.toText(e, mapKey: 'id')),
        ),
        '20',
      );
    });

    test('JSON strings are NOT auto-decoded for text primitives', () {
      final json = '{"a":"v"}';
      // Because input is already a String, _convertObject<T> returns it directly
      // and ignores mapKey/listIndex for text primitives.
      expect(ConvertObjectImpl.toText(json, mapKey: 'a'), json);
      expect(ConvertObjectImpl.tryToText(json, mapKey: 'a'), json);
    });

    test('missing mapKey → toText throws, tryToText uses default', () {
      final m = {'a': 1};
      expect(
        () => ConvertObjectImpl.toText(m, mapKey: 'b'),
        throwsA(isA<ConversionException>()),
      );
      expect(
        ConvertObjectImpl.tryToText(m, mapKey: 'b', defaultValue: 'none'),
        'none',
      );
    });

    test('custom converter is used', () {
      final out =
          ConvertObjectImpl.toText(7, converter: (o) => 'n=${o.toString()}');
      expect(out, 'n=7');
    });

    test('ConversionException context contains method and debug info', () {
      try {
        ConvertObjectImpl.toText(
          {'k': 'v'},
          mapKey: 'missing',
          debugInfo: {'case': 'text-context'},
        );
        fail('Expected ConversionException');
      } on ConversionException catch (e) {
        expect(e.context['method'], 'toText');
        expect(e.context['mapKey'], 'missing');
        expect(e.context['defaultValue'], isNull);
        expect(e.context['converter'], anyOf(isNull, isA<String>()));
        expect(e.context['objectType'], isNotNull);
        expect(e.context['case'], 'text-context');
      }
    });
  });
}
