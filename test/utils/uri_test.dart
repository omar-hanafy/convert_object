import 'package:convert_object/src/utils/uri.dart';
import 'package:test/test.dart';

void main() {
  group('UriParsingX', () {
    test('isValidPhoneNumber', () {
      expect('+1 (415) 555-1212'.isValidPhoneNumber, isTrue);
      expect('415-555-1212'.isValidPhoneNumber, isTrue);
      expect('12'.isValidPhoneNumber, isFalse); // too short
      expect('abc'.isValidPhoneNumber, isFalse);
    });

    test('isEmailAddress', () {
      expect('test@example.com'.isEmailAddress, isTrue);
      expect('user.name+tag@sub.domain.co'.isEmailAddress, isTrue);
      expect('not-an-email'.isEmailAddress, isFalse);
      expect('bad@@example.com'.isEmailAddress, isFalse);
      expect(' name@example.com'.isEmailAddress, isFalse); // leading space
    });

    test('toPhoneUri strips non-digits but keeps +', () {
      expect(' (415) 555-1212 '.toPhoneUri.toString(), 'tel:4155551212');
      expect('+1 (415) 555-1212'.toPhoneUri.toString(), 'tel:+14155551212');
    });

    test('toMailUri trims and prefixes mailto', () {
      final u = '  user@example.com  '.toMailUri;
      expect(u.scheme, 'mailto');
      expect(u.path, 'user@example.com');
      expect(u.toString(), 'mailto:user@example.com');
    });

    test('toUri parses generic URIs', () {
      final u = 'https://dart.dev/path?x=1'.toUri;
      expect(u.scheme, 'https');
      expect(u.host, 'dart.dev');
      expect(u.path, '/path');
      expect(u.queryParameters['x'], '1');
    });
  });
}
