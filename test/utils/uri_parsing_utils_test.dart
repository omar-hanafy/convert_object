import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('UriParsingX', () {
    group('isValidPhoneNumber', () {
      test('should return true for phone-like inputs', () {
        // Arrange
        const inputs = <String>[
          '123',
          '+15551234567',
          '+1 (555) 123-4567',
          '(555) 123 4567',
        ];

        for (final input in inputs) {
          // Act
          final result = input.isValidPhoneNumber;

          // Assert
          expect(result, isTrue, reason: 'Input: "$input"');
        }
      });

      test('should return false for non phone-like inputs', () {
        // Arrange
        const inputs = <String>[
          '',
          'ab',
          'hello world',
          'user@example.com',
          '123-abc',
        ];

        for (final input in inputs) {
          // Act
          final result = input.isValidPhoneNumber;

          // Assert
          expect(result, isFalse, reason: 'Input: "$input"');
        }
      });
    });

    group('isEmailAddress', () {
      test('should return true for simple email addresses', () {
        // Arrange
        const input = 'user@example.com';

        // Act
        final result = input.isEmailAddress;

        // Assert
        expect(result, isTrue);
      });

      test(
        'should return false when the string has leading or trailing whitespace',
        () {
          // Arrange
          const input = ' user@example.com ';

          // Act
          final result = input.isEmailAddress;

          // Assert
          expect(result, isFalse);
        },
      );

      test('should return false for invalid email strings', () {
        // Arrange
        const inputs = <String>[
          'user@',
          '@example.com',
          'user@example',
          'user example.com',
          'user@exa mple.com',
        ];

        for (final input in inputs) {
          // Act
          final result = input.isEmailAddress;

          // Assert
          expect(result, isFalse, reason: 'Input: "$input"');
        }
      });
    });

    group('toPhoneUri / toMailUri / toUri', () {
      test('should convert phone-like strings to tel: URIs', () {
        // Arrange
        const input = '+1 (555) 123-4567';

        // Act
        final uri = input.toPhoneUri;

        // Assert
        expect(uri, isA<Uri>());
        expect(uri.toString(), equals('tel:+15551234567'));
      });

      test('should convert email strings to mailto: URIs', () {
        // Arrange
        const input = 'user@example.com';

        // Act
        final uri = input.toMailUri;

        // Assert
        expect(uri, isA<Uri>());
        expect(uri.toString(), equals('mailto:user@example.com'));
      });

      test('toUri should parse using Uri.parse', () {
        // Arrange
        const input = 'https://example.com/path?q=1';

        // Act
        final uri = input.toUri;

        // Assert
        expect(uri, isA<Uri>());
        expect(uri.scheme, equals('https'));
        expect(uri.host, equals('example.com'));
        expect(uri.path, equals('/path'));
        expect(uri.queryParameters['q'], equals('1'));
      });
    });
  });
}
