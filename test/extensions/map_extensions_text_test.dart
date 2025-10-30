import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('MapConversionX.getText / tryGetText', () {
    test('returns value for existing key', () {
      final m = {'name': 'Omar'};
      expect(m.getText('name'), 'Omar');
    });

    test('falls back to alternativeKeys (first existing)', () {
      final m = {'n': 'AltName', 'x': 'Nope'};
      expect(m.getText('name', alternativeKeys: ['n', 'x']), 'AltName');
    });

    test('supports innerKey and innerListIndex navigation', () {
      final m = {
        'post': {
          'tags': ['dart', 'utils', 'convert']
        }
      };
      expect(m.getText('post', innerKey: 'tags', innerListIndex: 1), 'utils');
    });

    test('missing key → getText throws ConversionException', () {
      final m = {'a': 1};
      expect(() => m.getText('missing'), throwsA(isA<ConversionException>()));
    });

    test('missing key → tryGetText returns defaultValue', () {
      final m = {'a': 1};
      expect(m.tryGetText('missing', defaultValue: 'none'), 'none');
    });

    test('out-of-range innerListIndex → getText throws', () {
      final m = {
        'arr': ['first']
      };
      expect(
        () => m.getText('arr', innerListIndex: 3),
        throwsA(isA<ConversionException>()),
      );
    });

    test('error context contains key and altKeys when failing', () {
      final m = {'k': 'v'};
      try {
        m.getText('missing', alternativeKeys: ['alt1', 'alt2']);
        fail('Expected ConversionException');
      } on ConversionException catch (e) {
        // The context should include method + our debug info from the extension.
        expect(e.context['method'], 'toText');
        expect(e.context['key'], 'missing');
        expect(e.context['altKeys'], ['alt1', 'alt2']);
      }
    });

    test('innerKey path missing → tryGetText returns defaultValue', () {
      final m = {
        'user': {'name': 'Omar'}
      };
      expect(
        m.tryGetText('user', innerKey: 'missing', defaultValue: 'fallback'),
        'fallback',
      );
    });
  });
}
