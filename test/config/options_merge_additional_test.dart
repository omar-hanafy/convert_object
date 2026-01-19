// Additional tests for config merge logic covering gaps identified in audit.
//
// This file focuses on:
// - DateOptions extraAutoDetectPatterns merge behavior
// - BoolOptions empty set behavior
// - copyWith with all null arguments
// - _setEquals edge cases
import 'package:convert_object/convert_object.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';

void main() {
  late ConvertConfig prevConfig;
  late String? prevIntlLocale;

  setUpAll(() async {
    await initTestIntl();
  });

  setUp(() {
    prevIntlLocale = Intl.defaultLocale;
    Intl.defaultLocale = 'en_US';
    prevConfig = Convert.configure(makeTestConfig(locale: 'en_US'));
  });

  tearDown(() {
    Convert.configure(prevConfig);
    Intl.defaultLocale = prevIntlLocale;
  });

  group('DateOptions extraAutoDetectPatterns merge', () {
    test(
      'should prefer override patterns when both base and override have patterns',
      () {
        // Arrange
        final baseConfig = makeTestConfig(
          dates: const DateOptions(
            autoDetectFormat: true,
            extraAutoDetectPatterns: ['MM/dd/yyyy', 'dd-MM-yyyy'],
          ),
        );
        final overrideConfig = ConvertConfig.overrides(
          dates: const DateOptions(
            autoDetectFormat: true,
            extraAutoDetectPatterns: ['yyyy.MM.dd'],
          ),
        );

        // Act
        final merged = withGlobalConfig(
          baseConfig,
          () => Convert.runScopedConfig(
            overrideConfig,
            () => ConvertConfig.effective,
          ),
        );

        // Assert
        expect(merged.dates.extraAutoDetectPatterns, equals(['yyyy.MM.dd']));
      },
    );

    test('should keep base patterns when override patterns are empty', () {
      // Arrange
      final baseConfig = makeTestConfig(
        dates: const DateOptions(
          autoDetectFormat: true,
          extraAutoDetectPatterns: ['MM/dd/yyyy'],
        ),
      );
      final overrideConfig = ConvertConfig.overrides(
        dates: const DateOptions(
          autoDetectFormat: true,
          extraAutoDetectPatterns: [],
        ),
      );

      // Act
      final merged = withGlobalConfig(
        baseConfig,
        () => Convert.runScopedConfig(
          overrideConfig,
          () => ConvertConfig.effective,
        ),
      );

      // Assert
      expect(merged.dates.extraAutoDetectPatterns, equals(['MM/dd/yyyy']));
    });
  });

  group('BoolOptions empty set behavior', () {
    test('should preserve base truthy set when override truthy is empty', () {
      // Arrange
      final baseConfig = makeTestConfig(
        bools: const BoolOptions(truthy: {'yes', 'true', 'ok'}),
      );
      final overrideConfig = ConvertConfig.overrides(
        bools: const BoolOptions(truthy: {}),
      );

      // Act
      final merged = withGlobalConfig(
        baseConfig,
        () => Convert.runScopedConfig(
          overrideConfig,
          () => ConvertConfig.effective,
        ),
      );

      // Assert
      expect(merged.bools.truthy, equals({'yes', 'true', 'ok'}));
    });

    test('should preserve base falsy set when override falsy is empty', () {
      // Arrange
      final baseConfig = makeTestConfig(
        bools: const BoolOptions(falsy: {'no', 'false', 'off'}),
      );
      final overrideConfig = ConvertConfig.overrides(
        bools: const BoolOptions(falsy: {}),
      );

      // Act
      final merged = withGlobalConfig(
        baseConfig,
        () => Convert.runScopedConfig(
          overrideConfig,
          () => ConvertConfig.effective,
        ),
      );

      // Assert
      expect(merged.bools.falsy, equals({'no', 'false', 'off'}));
    });

    test('should use override truthy set when non-empty', () {
      // Arrange
      final baseConfig = makeTestConfig(
        bools: const BoolOptions(truthy: {'yes', 'true'}),
      );
      final overrideConfig = ConvertConfig.overrides(
        bools: const BoolOptions(truthy: {'oui'}),
      );

      // Act
      final merged = withGlobalConfig(
        baseConfig,
        () => Convert.runScopedConfig(
          overrideConfig,
          () => ConvertConfig.effective,
        ),
      );

      // Assert
      expect(merged.bools.truthy, equals({'oui'}));
    });
  });

  group('Options copyWith edge cases', () {
    test(
      'NumberOptions copyWith with all nulls returns equivalent options',
      () {
        // Arrange
        const original = NumberOptions(
          defaultFormat: '#,##0.00',
          defaultLocale: 'de_DE',
          tryFormattedFirst: false,
        );

        // Act
        final copied = original.copyWith();

        // Assert
        expect(copied.defaultFormat, equals('#,##0.00'));
        expect(copied.defaultLocale, equals('de_DE'));
        expect(copied.tryFormattedFirst, isFalse);
      },
    );

    test('DateOptions copyWith with all nulls returns equivalent options', () {
      // Arrange
      const original = DateOptions(
        defaultFormat: 'yyyy-MM-dd',
        locale: 'en_US',
        utc: true,
        autoDetectFormat: true,
        useCurrentLocale: true,
        extraAutoDetectPatterns: ['MM/dd/yyyy'],
      );

      // Act
      final copied = original.copyWith();

      // Assert
      expect(copied.defaultFormat, equals('yyyy-MM-dd'));
      expect(copied.locale, equals('en_US'));
      expect(copied.utc, isTrue);
      expect(copied.autoDetectFormat, isTrue);
      expect(copied.useCurrentLocale, isTrue);
      expect(copied.extraAutoDetectPatterns, equals(['MM/dd/yyyy']));
    });

    test('BoolOptions copyWith with all nulls returns equivalent options', () {
      // Arrange
      const original = BoolOptions(
        truthy: {'oui', 'si'},
        falsy: {'non', 'no'},
        numericPositiveIsTrue: false,
      );

      // Act
      final copied = original.copyWith();

      // Assert
      expect(copied.truthy, equals({'oui', 'si'}));
      expect(copied.falsy, equals({'non', 'no'}));
      expect(copied.numericPositiveIsTrue, isFalse);
    });

    test('UriOptions copyWith with all nulls returns equivalent options', () {
      // Arrange
      const original = UriOptions(
        defaultScheme: 'https',
        coerceBareDomainsToDefaultScheme: true,
        allowRelative: false,
      );

      // Act
      final copied = original.copyWith();

      // Assert
      expect(copied.defaultScheme, equals('https'));
      expect(copied.coerceBareDomainsToDefaultScheme, isTrue);
      expect(copied.allowRelative, isFalse);
    });

    test('ConvertConfig copyWith with all nulls returns equivalent config', () {
      // Arrange
      final original = makeTestConfig(
        locale: 'fr_FR',
        numbers: const NumberOptions(defaultFormat: '#.##'),
        dates: const DateOptions(utc: true),
        bools: const BoolOptions(numericPositiveIsTrue: false),
        uri: const UriOptions(allowRelative: false),
      );

      // Act
      final copied = original.copyWith();

      // Assert
      expect(copied.locale, equals('fr_FR'));
      expect(copied.numbers.defaultFormat, equals('#.##'));
      expect(copied.dates.utc, isTrue);
      expect(copied.bools.numericPositiveIsTrue, isFalse);
      expect(copied.uri.allowRelative, isFalse);
    });
  });

  group('ConvertConfig.overrides clearLocale and clearOnException', () {
    test('clearLocale should clear inherited locale', () {
      // Arrange
      final baseConfig = makeTestConfig(locale: 'de_DE');

      // Act
      final merged = withGlobalConfig(
        baseConfig,
        () => Convert.runScopedConfig(
          ConvertConfig.overrides(clearLocale: true),
          () => ConvertConfig.effective,
        ),
      );

      // Assert
      expect(merged.locale, isNull);
    });

    test('clearOnException should clear inherited exception hook', () {
      // Arrange
      final baseConfig = makeTestConfig(onException: (_) {});

      // Act
      final merged = withGlobalConfig(
        baseConfig,
        () => Convert.runScopedConfig(
          ConvertConfig.overrides(clearOnException: true),
          () => ConvertConfig.effective,
        ),
      );

      // Assert
      expect(merged.onException, isNull);
    });

    test('locale override should work alongside clearLocale=false', () {
      // Arrange
      final baseConfig = makeTestConfig(locale: 'de_DE');

      // Act
      final merged = withGlobalConfig(
        baseConfig,
        () => Convert.runScopedConfig(
          ConvertConfig.overrides(locale: 'fr_FR'),
          () => ConvertConfig.effective,
        ),
      );

      // Assert
      expect(merged.locale, equals('fr_FR'));
    });
  });

  group('Merge behavior with default options', () {
    test('runtime-default NumberOptions should not override base', () {
      // Arrange
      final baseConfig = makeTestConfig(
        numbers: const NumberOptions(defaultFormat: '#,##0.00'),
      );
      // Runtime-constructed default (same values as const default)
      const runtimeDefault = NumberOptions();

      // Act
      final merged = withGlobalConfig(
        baseConfig,
        () => Convert.runScopedConfig(
          const ConvertConfig(numbers: runtimeDefault),
          () => ConvertConfig.effective,
        ),
      );

      // Assert
      expect(merged.numbers.defaultFormat, equals('#,##0.00'));
    });

    test('runtime-default DateOptions should not override base', () {
      // Arrange
      final baseConfig = makeTestConfig(
        dates: const DateOptions(utc: true, autoDetectFormat: true),
      );
      const runtimeDefault = DateOptions();

      // Act
      final merged = withGlobalConfig(
        baseConfig,
        () => Convert.runScopedConfig(
          const ConvertConfig(dates: runtimeDefault),
          () => ConvertConfig.effective,
        ),
      );

      // Assert
      expect(merged.dates.utc, isTrue);
      expect(merged.dates.autoDetectFormat, isTrue);
    });
  });

  group('Options merge semantics', () {
    test('NumberOptions merge prefers other non-null values', () {
      // Arrange
      const base = NumberOptions(
        defaultFormat: 'base-format',
        defaultLocale: 'base-locale',
      );
      const other = NumberOptions(
        defaultFormat: 'other-format',
        // defaultLocale is null
      );

      // Act
      final merged = base.merge(other);

      // Assert
      expect(merged.defaultFormat, equals('other-format'));
      expect(merged.defaultLocale, equals('base-locale'));
    });

    test('DateOptions merge prefers other non-null values', () {
      // Arrange
      const base = DateOptions(
        defaultFormat: 'base-format',
        locale: 'base-locale',
      );
      const other = DateOptions(
        defaultFormat: 'other-format',
        // locale is null
      );

      // Act
      final merged = base.merge(other);

      // Assert
      expect(merged.defaultFormat, equals('other-format'));
      expect(merged.locale, equals('base-locale'));
    });

    test('UriOptions merge prefers other non-null scheme', () {
      // Arrange
      const base = UriOptions(defaultScheme: 'http');
      const other = UriOptions(defaultScheme: 'https');

      // Act
      final merged = base.merge(other);

      // Assert
      expect(merged.defaultScheme, equals('https'));
    });

    test('UriOptions merge uses boolean values from other', () {
      // Arrange
      const base = UriOptions(
        coerceBareDomainsToDefaultScheme: false,
        allowRelative: true,
      );
      const other = UriOptions(
        coerceBareDomainsToDefaultScheme: true,
        allowRelative: false,
      );

      // Act
      final merged = base.merge(other);

      // Assert
      expect(merged.coerceBareDomainsToDefaultScheme, isTrue);
      expect(merged.allowRelative, isFalse);
    });
  });
}
