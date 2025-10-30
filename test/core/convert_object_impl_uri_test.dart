import 'package:convert_object/convert_object.dart'; // for ConversionException
import 'package:convert_object/src/core/convert_object_impl.dart';
import 'package:test/test.dart';

void main() {
  group('ConvertObjectImpl URIs', () {
    test('http/https URIs', () {
      final u1 = ConvertObjectImpl.toUri('https://dart.dev');
      expect(u1.scheme, 'https');
      expect(u1.host, 'dart.dev');

      final u2 = ConvertObjectImpl.tryToUri('https://example.com');
      expect(u2?.scheme, 'https');
      expect(u2?.host, 'example.com');
    });

    test('email string → mailto:', () {
      final u = ConvertObjectImpl.toUri('alice@example.com');
      expect(u.scheme, 'mailto');
      expect(u.path, 'alice@example.com');
    });

    test('phone string → tel:', () {
      final u = ConvertObjectImpl.toUri('+1 (415) 555-0100');
      expect(u.scheme, 'tel');
      // path keeps digits (and leading +)
      expect(u.path, '+14155550100');
    });

    test('invalid URI → tryToUri returns default, toUri throws', () {
      final fallback = Uri.parse('https://fallback.example');
      expect(
        ConvertObjectImpl.tryToUri('http://', defaultValue: fallback),
        fallback,
      );
      expect(
        () => ConvertObjectImpl.toUri('http://'),
        throwsA(isA<ConversionException>()),
      );
    });

    test('mapKey/listIndex pathing', () {
      final obj = {
        'links': ['https://a.com', 'https://b.com']
      };
      final u = ConvertObjectImpl.toUri(obj, mapKey: 'links', listIndex: 1);
      expect(u.scheme, 'https');
      expect(u.host, 'b.com');
    });
  });
}
