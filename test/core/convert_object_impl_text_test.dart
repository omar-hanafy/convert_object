import 'package:convert_object/convert_object.dart'; // for ConversionException
import 'package:convert_object/src/core/convert_object_impl.dart';
import 'package:test/test.dart';

import '../_setup/test_config.dart';

void main() {
  // Ensure a stable default locale for this suite.
  configureTests(defaultLocale: 'en_US');

  group('ConvertObjectImpl.toStringValue / tryToStringValue', () {
    test('primitives → string', () {
      expect(ConvertObjectImpl.toStringValue('abc'), 'abc');
      expect(ConvertObjectImpl.toStringValue(42), '42');
      expect(ConvertObjectImpl.toStringValue(true), 'true');
      expect(ConvertObjectImpl.toStringValue(BigInt.from(7)), '7');
    });

    test('null → throws (toStringValue) and defaultValue is respected', () {
      expect(
        () => ConvertObjectImpl.toStringValue(null),
        throwsA(isA<ConversionException>()),
      );
      expect(
        ConvertObjectImpl.toStringValue(null, defaultValue: 'N/A'),
        'N/A',
      );
    });

    test('tryToStringValue returns null or default', () {
      expect(ConvertObjectImpl.tryToStringValue(null), isNull);
      expect(
        ConvertObjectImpl.tryToStringValue(null, defaultValue: 'x'),
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

      expect(ConvertObjectImpl.toStringValue(data, mapKey: 'name'), 'Omar');
      expect(
          ConvertObjectImpl.toStringValue(data, mapKey: 'items', listIndex: 2),
          'c');
      expect(
        ConvertObjectImpl.toStringValue(
          data,
          mapKey: 'nested',
          // pull nested.list[1].id as string
          converter: (o) => ConvertObjectImpl.toStringValue(o,
              mapKey: 'list',
              listIndex: 1,
              converter: (e) =>
                  ConvertObjectImpl.toStringValue(e, mapKey: 'id')),
        ),
        '20',
      );
    });

    test('JSON strings are NOT auto-decoded for string primitives', () {
      const json = '{"a":"v"}';
      // Because input is already a String, _convertObject<T> returns it directly
      // and ignores mapKey/listIndex for text primitives.
      expect(ConvertObjectImpl.toStringValue(json, mapKey: 'a'), json);
      expect(ConvertObjectImpl.tryToStringValue(json, mapKey: 'a'), json);
    });

    test('missing mapKey → toStringValue throws, tryToStringValue uses default',
        () {
      final m = {'a': 1};
      expect(
        () => ConvertObjectImpl.toStringValue(m, mapKey: 'b'),
        throwsA(isA<ConversionException>()),
      );
      expect(
        ConvertObjectImpl.tryToStringValue(m,
            mapKey: 'b', defaultValue: 'none'),
        'none',
      );
    });

    test('custom converter is used', () {
      final out = ConvertObjectImpl.toStringValue(7,
          converter: (o) => 'n=${o.toString()}');
      expect(out, 'n=7');
    });

    test('ConversionException context contains method and debug info', () {
      try {
        ConvertObjectImpl.toStringValue(
          {'k': 'v'},
          mapKey: 'missing',
          debugInfo: {'case': 'string-context'},
        );
        fail('Expected ConversionException');
      } on ConversionException catch (e) {
        expect(e.context['method'], 'toStringValue');
        expect(e.context['mapKey'], 'missing');
        expect(e.context['defaultValue'], isNull);
        expect(e.context['converter'], anyOf(isNull, isA<String>()));
        expect(e.context['objectType'], isNotNull);
        expect(e.context['case'], 'string-context');
      }
    });
  });
}
