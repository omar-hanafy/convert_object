import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';

void main() {
  late ConvertConfig _prev;

  setUp(() {
    // Arrange
    _prev = Convert.configure(makeTestConfig());
  });

  tearDown(() {
    // Arrange
    Convert.configure(_prev);
  });

  group('Convert.toUri', () {
    test('should convert phone-like strings into tel: URIs', () {
      // Arrange

      // Act
      final result = Convert.toUri(' +1 (555) 123-4567 ');

      // Assert
      expect(result, uriEquals('tel:+15551234567'));
    });

    test('should convert email strings into mailto: URIs', () {
      // Arrange

      // Act
      final result = Convert.toUri('user@example.com');

      // Assert
      expect(result, uriEquals('mailto:user@example.com'));
    });

    test('should not treat emails with surrounding whitespace as mailto:', () {
      // Arrange

      // Act
      final result = Convert.toUri(' user@example.com ');

      // Assert
      expect(result.scheme, isEmpty);
      expect(result.toString(), equals('user@example.com'));
    });

    test('should return a relative URI for bare domains when coercion is disabled', () {
      // Arrange

      // Act
      final result = Convert.toUri('example.com');

      // Assert
      expect(result.scheme, isEmpty);
      expect(result.toString(), equals('example.com'));
    });

    test('should coerce bare domains to default scheme when enabled', () {
      // Arrange
      const overrides = ConvertConfig(
        uri: UriOptions(
          defaultScheme: 'https',
          coerceBareDomainsToDefaultScheme: true,
          allowRelative: true,
        ),
      );

      // Act
      final result = withScopedConfig(overrides, () => Convert.toUri('example.com'));

      // Assert
      expect(result.toString(), equals('https://example.com'));
    });

    test('should reject relative URIs when allowRelative is false', () {
      // Arrange
      const overrides = ConvertConfig(
        uri: UriOptions(allowRelative: false),
      );

      // Act + Assert
      expect(
        () => withScopedConfig(overrides, () => Convert.toUri('/relative/path')),
        throwsConversionException(method: 'toUri'),
      );
    });

    test('should reject bare domains when allowRelative is false and coercion is disabled', () {
      // Arrange
      const overrides = ConvertConfig(
        uri: UriOptions(allowRelative: false),
      );

      // Act + Assert
      expect(
        () => withScopedConfig(overrides, () => Convert.toUri('example.com')),
        throwsConversionException(method: 'toUri'),
      );
    });

    test('should reject https URIs missing a host', () {
      // Arrange

      // Act + Assert
      expect(
        () => Convert.toUri('https://'),
        throwsConversionException(method: 'toUri'),
      );
    });

    test('should throw ConversionException on empty input when no defaultValue is provided', () {
      // Arrange

      // Act + Assert
      expect(
        () => Convert.toUri('   '),
        throwsConversionException(method: 'toUri'),
      );
    });

    test('should return defaultValue on invalid input when defaultValue is provided', () {
      // Arrange
      final fallback = Uri.parse('https://fallback.example');

      // Act
      final result = Convert.toUri('   ', defaultValue: fallback);

      // Assert
      expect(result, equals(fallback));
    });

    test('should support mapKey and listIndex selection', () {
      // Arrange
      final map = <String, dynamic>{'u': 'https://example.com'};
      final list = <dynamic>['https://example.com'];

      // Act
      final a = Convert.toUri(map, mapKey: 'u');
      final b = Convert.toUri(list, listIndex: 0);

      // Assert
      expect(a.toString(), equals('https://example.com'));
      expect(b.toString(), equals('https://example.com'));
    });
  });

  group('Convert.tryToUri', () {
    test('should return null on invalid input', () {
      // Arrange

      // Act
      final result = Convert.tryToUri('   ');

      // Assert
      expect(result, isNull);
    });

    test('should return defaultValue on invalid input when defaultValue is provided', () {
      // Arrange
      final fallback = Uri.parse('https://fallback.example');

      // Act
      final result = Convert.tryToUri('   ', defaultValue: fallback);

      // Assert
      expect(result, equals(fallback));
    });
  });
}
