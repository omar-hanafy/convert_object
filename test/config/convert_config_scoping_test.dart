import 'package:convert_object/convert_object.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';

void main() {
  late ConvertConfig _prevConfig;
  late ConvertConfig _baselineConfig;
  late String? _prevIntlLocale;

  setUp(() {
    // Arrange
    _prevIntlLocale = Intl.defaultLocale;
    Intl.defaultLocale = 'en_US';

    _baselineConfig = makeTestConfig(locale: 'en_US');
    _prevConfig = Convert.configure(_baselineConfig);
  });

  tearDown(() {
    // Arrange (cleanup)
    Convert.configure(_prevConfig);
    Intl.defaultLocale = _prevIntlLocale;
  });

  group('Convert.configure', () {
    test('should return previous config and apply new config globally', () {
      // Arrange
      final newConfig = makeTestConfig(locale: 'fr_FR');

      // Act
      final returnedPrev = Convert.configure(newConfig);

      // Assert
      expect(identical(returnedPrev, _baselineConfig), isTrue);
      expect(Convert.config.locale, equals('fr_FR'));
    });
  });

  group('Convert.updateConfig', () {
    test('should update the global config immutably', () {
      // Arrange
      expect(Convert.config.locale, equals('en_US'));

      // Act
      Convert.updateConfig((current) => current.copyWith(locale: 'de_DE'));

      // Assert
      expect(Convert.config.locale, equals('de_DE'));
      expect(Convert.config.numbers, isA<NumberOptions>());
      expect(Convert.config.dates, isA<DateOptions>());
      expect(Convert.config.bools, isA<BoolOptions>());
      expect(Convert.config.uri, isA<UriOptions>());
      expect(Convert.config.registry, isA<TypeRegistry>());
    });
  });

  group('Convert.runScopedConfig', () {
    test('should apply scoped overrides only inside the body and not leak globally',
        () {
      // Arrange
      final globalBefore = Convert.config;
      final overrides = makeTestConfig(locale: 'ar_EG');

      // Act
      final insideLocale = Convert.runScopedConfig(overrides, () {
        return Convert.config.locale;
      });

      // Assert
      expect(insideLocale, equals('ar_EG'));
      expect(Convert.config.locale, equals(globalBefore.locale));
      expect(identical(Convert.config, globalBefore), isTrue);
    });

    test('should expose the zone-effective config via Convert.config inside scope',
        () {
      // Arrange
      final global = Convert.config;
      final overrides = makeTestConfig(locale: 'it_IT');

      // Act
      Convert.runScopedConfig(overrides, () {
        // Assert (inside scope)
        expect(Convert.config.locale, equals('it_IT'));
        expect(identical(Convert.config, global), isFalse);
      });

      // Assert (after scope)
      expect(Convert.config.locale, equals(global.locale));
      expect(identical(Convert.config, global), isTrue);
    });

    test('should support nested scopes with inner overrides taking precedence',
        () {
      // Arrange
      final outer = makeTestConfig(locale: 'de_DE');
      final inner = makeTestConfig(locale: 'fr_FR');

      // Act
      final observed = <String?>[];
      Convert.runScopedConfig(outer, () {
        observed.add(Convert.config.locale); // outer
        Convert.runScopedConfig(inner, () {
          observed.add(Convert.config.locale); // inner
        });
        observed.add(Convert.config.locale); // back to outer
      });

      // Assert
      expect(observed, equals(<String?>['de_DE', 'fr_FR', 'de_DE']));
      expect(Convert.config.locale, equals('en_US'));
    });

    test('should return the body result unchanged', () {
      // Arrange
      const expected = 123;
      final overrides = makeTestConfig(locale: 'es_ES');

      // Act
      final result = Convert.runScopedConfig(overrides, () => expected);

      // Assert
      expect(result, equals(expected));
      expect(Convert.config.locale, equals('en_US'));
    });
  });
}
