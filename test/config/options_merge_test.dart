import 'package:convert_object/convert_object.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';
import '../helpers/test_models.dart';

void main() {
  late ConvertConfig _prevConfig;
  late ConvertConfig _baselineConfig;
  late String? _prevIntlLocale;

  setUpAll(() async {
    // Arrange
    await initTestIntl(defaultLocale: 'en_US');
  });

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

  group('ConvertConfig merge behavior', () {
    group('NumberOptions', () {
      test(
          'should not override base numbers when overrides.numbers is the default const instance',
          () {
        // Arrange
        final baseNumbers = NumberOptions(
          defaultFormat: '#,##0.###',
          defaultLocale: 'de_DE',
          tryFormattedFirst: false,
        );

        final baseConfig = makeTestConfig(
          locale: 'en_US',
          numbers: baseNumbers,
        );

        // Act
        withGlobalConfig(baseConfig, () {
          final overrides = makeTestConfig(
            locale: 'fr_FR',
            // numbers is default const -> should NOT override base numbers (guarded)
          );

          Convert.runScopedConfig(overrides, () {
            // Assert (inside scope)
            expect(Convert.config.locale, equals('fr_FR'));
            expect(Convert.config.numbers.defaultFormat, equals('#,##0.###'));
            expect(Convert.config.numbers.defaultLocale, equals('de_DE'));
            expect(Convert.config.numbers.tryFormattedFirst, isFalse);
          });

          // Assert (after scope)
          expect(Convert.config.locale, equals('en_US'));
          expect(Convert.config.numbers.defaultFormat, equals('#,##0.###'));
          expect(Convert.config.numbers.tryFormattedFirst, isFalse);
        });
      });

      test(
          'should merge runtime-default numbers object and override booleans but keep null fields',
          () {
        // Arrange
        final baseNumbers = NumberOptions(
          defaultFormat: '#,##0.###',
          defaultLocale: 'de_DE',
          tryFormattedFirst: false,
        );

        final baseConfig = makeTestConfig(
          locale: 'en_US',
          numbers: baseNumbers,
        );

        // Act
        withGlobalConfig(baseConfig, () {
          final overrides = makeTestConfig(
            locale: 'fr_FR',
            numbers: NumberOptions(), // runtime default (NOT identical to const)
          );

          Convert.runScopedConfig(overrides, () {
            // Assert (inside scope)
            expect(Convert.config.locale, equals('fr_FR'));

            // Null fields should not override base values.
            expect(Convert.config.numbers.defaultFormat, equals('#,##0.###'));
            expect(Convert.config.numbers.defaultLocale, equals('de_DE'));

            // Boolean should override because merge uses other.tryFormattedFirst.
            expect(Convert.config.numbers.tryFormattedFirst, isTrue);
          });

          // Assert (after scope)
          expect(Convert.config.locale, equals('en_US'));
          expect(Convert.config.numbers.tryFormattedFirst, isFalse);
        });
      });

      test(
          'should apply numbers.defaultFormat/defaultLocale from config when format/locale are not provided',
          () {
        // Arrange
        final baseNumbers = NumberOptions(
          defaultFormat: '#,##0.###',
          defaultLocale: 'de_DE',
          tryFormattedFirst: true,
        );
        final baseConfig = makeTestConfig(
          locale: 'en_US',
          numbers: baseNumbers,
        );

        // Act
        final parsed = withGlobalConfig(baseConfig, () {
          return Convert.toNum('1.234,5'); // de_DE formatted: 1234.5
        });

        // Assert
        expect(parsed, isA<num>());
        expect(parsed, equals(1234.5));
      });
    });

    group('BoolOptions', () {
      test(
          'should not override base bools when overrides.bools is the default const instance',
          () {
        // Arrange
        final baseBools = BoolOptions(
          truthy: {'sure'},
          falsy: {'nah'},
          numericPositiveIsTrue: false,
        );
        final baseConfig = makeTestConfig(bools: baseBools);

        // Act
        withGlobalConfig(baseConfig, () {
          final overrides = makeTestConfig(
            locale: 'fr_FR',
            // bools is default const -> should NOT override base bools (guarded)
          );

          Convert.runScopedConfig(overrides, () {
            // Assert (inside scope)
            expect(Convert.config.locale, equals('fr_FR'));
            expect(Convert.config.bools.numericPositiveIsTrue, isFalse);
            expect(Convert.config.bools.truthy.contains('sure'), isTrue);
            expect(Convert.config.bools.truthy.contains('true'), isFalse);
          });

          // Assert (after scope)
          expect(Convert.config.bools.numericPositiveIsTrue, isFalse);
          expect(Convert.config.bools.truthy.contains('sure'), isTrue);
        });
      });

      test(
          'should override base bools when overrides.bools is a runtime default instance',
          () {
        // Arrange
        final baseBools = BoolOptions(
          truthy: {'sure'},
          falsy: {'nah'},
          numericPositiveIsTrue: false,
        );
        final baseConfig = makeTestConfig(bools: baseBools);

        // Act
        withGlobalConfig(baseConfig, () {
          final overrides = makeTestConfig(
            bools: BoolOptions(), // runtime default -> merge applies
          );

          Convert.runScopedConfig(overrides, () {
            // Assert (inside scope)
            expect(Convert.config.bools.numericPositiveIsTrue, isTrue);
            expect(Convert.config.bools.truthy.contains('true'), isTrue);
            expect(Convert.config.bools.truthy.contains('sure'), isFalse);
          });

          // Assert (after scope)
          expect(Convert.config.bools.numericPositiveIsTrue, isFalse);
          expect(Convert.config.bools.truthy.contains('sure'), isTrue);
        });
      });

      test('should respect numericPositiveIsTrue from config for numeric inputs',
          () {
        // Arrange
        final baseConfig = makeTestConfig(
          bools: const BoolOptions(numericPositiveIsTrue: false),
        );

        // Act
        final results = withGlobalConfig(baseConfig, () {
          final a = Convert.toBool(-1);
          final b = Convert.toBool(0);
          final c = Convert.toBool(2);
          return <bool>[a, b, c];
        });

        // Assert
        expect(results, equals(<bool>[true, false, true]));
      });
    });

    group('DateOptions', () {
      test(
          'should not override base dates when overrides.dates is the default const instance',
          () {
        // Arrange
        final baseDates = DateOptions(
          utc: true,
          autoDetectFormat: true,
          useCurrentLocale: true,
          extraAutoDetectPatterns: const ['yyyyMMdd'],
        );
        final baseConfig = makeTestConfig(dates: baseDates);

        // Act
        withGlobalConfig(baseConfig, () {
          final overrides = makeTestConfig(
            locale: 'fr_FR',
            // dates is default const -> should NOT override base dates (guarded)
          );

          Convert.runScopedConfig(overrides, () {
            // Assert (inside scope)
            expect(Convert.config.locale, equals('fr_FR'));
            expect(Convert.config.dates.utc, isTrue);
            expect(Convert.config.dates.autoDetectFormat, isTrue);
            expect(Convert.config.dates.useCurrentLocale, isTrue);
            expect(Convert.config.dates.extraAutoDetectPatterns, isNotEmpty);
          });

          // Assert (after scope)
          expect(Convert.config.dates.utc, isTrue);
          expect(Convert.config.dates.autoDetectFormat, isTrue);
        });
      });

      test(
          'should override base dates when overrides.dates is a runtime default instance',
          () {
        // Arrange
        final baseDates = DateOptions(
          utc: true,
          autoDetectFormat: true,
          useCurrentLocale: true,
          extraAutoDetectPatterns: const ['yyyyMMdd'],
        );
        final baseConfig = makeTestConfig(dates: baseDates);

        // Act
        withGlobalConfig(baseConfig, () {
          final overrides = makeTestConfig(dates: DateOptions()); // runtime default

          Convert.runScopedConfig(overrides, () {
            // Assert (inside scope)
            expect(Convert.config.dates.utc, isFalse);
            expect(Convert.config.dates.autoDetectFormat, isFalse);
            expect(Convert.config.dates.useCurrentLocale, isFalse);
          });

          // Assert (after scope)
          expect(Convert.config.dates.utc, isTrue);
          expect(Convert.config.dates.autoDetectFormat, isTrue);
        });
      });

      test(
          'should allow parsing non-ISO dates when DateOptions.autoDetectFormat is enabled in config',
          () {
        // Arrange
        final baseConfig = makeTestConfig(
          dates: const DateOptions(autoDetectFormat: true),
        );

        // Act
        final dt = withGlobalConfig(baseConfig, () {
          // "01/31/2025" is not ISO; DateTime.parse should reject in many runtimes,
          // but auto-detect should accept via MM/dd/yyyy parsing for en_US.
          return Convert.toDateTime('01/31/2025');
        });

        // Assert
        expect(dt, isA<DateTime>());
        expect(dt.year, equals(2025));
        expect(dt.month, equals(1));
        expect(dt.day, equals(31));
      });

      test(
          'should throw when auto-detect is disabled and no explicit format is provided for a non-ISO date',
          () {
        // Arrange
        final baseConfig = makeTestConfig(
          dates: const DateOptions(autoDetectFormat: false),
        );

        // Act & Assert
        withGlobalConfig(baseConfig, () {
          expect(
            () => Convert.toDateTime('01/31/2025'),
            throwsConversionException(method: 'toDateTime'),
          );
        });
      });

      test('should respect DateOptions.utc from config for epoch numbers', () {
        // Arrange
        final utcConfig = makeTestConfig(dates: const DateOptions(utc: true));
        final localConfig = makeTestConfig(dates: const DateOptions(utc: false));

        // Act
        final utcDt = withGlobalConfig(utcConfig, () => Convert.toDateTime(0));
        final localDt =
            withGlobalConfig(localConfig, () => Convert.toDateTime(0));

        // Assert
        expect(utcDt.isUtc, isTrue);
        expect(localDt.isUtc, isFalse);

        // Both should represent the same instant.
        expect(utcDt, sameInstantAs(DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)));
        expect(localDt, sameInstantAs(DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)));
      });
    });

    group('UriOptions', () {
      test(
          'should not override base uri policy when overrides.uri is the default const instance',
          () {
        // Arrange
        final baseUri = UriOptions(
          defaultScheme: 'https',
          coerceBareDomainsToDefaultScheme: true,
          allowRelative: false,
        );
        final baseConfig = makeTestConfig(uri: baseUri);

        // Act
        withGlobalConfig(baseConfig, () {
          final overrides = makeTestConfig(
            locale: 'fr_FR',
            // uri is default const -> should NOT override base uri policy (guarded)
          );

          Convert.runScopedConfig(overrides, () {
            // Assert (inside scope)
            expect(Convert.config.locale, equals('fr_FR'));
            expect(Convert.config.uri.allowRelative, isFalse);
            expect(Convert.config.uri.coerceBareDomainsToDefaultScheme, isTrue);
            expect(Convert.config.uri.defaultScheme, equals('https'));
          });

          // Assert (after scope)
          expect(Convert.config.uri.allowRelative, isFalse);
        });
      });

      test(
          'should override base uri policy when overrides.uri is a runtime default instance',
          () {
        // Arrange
        final baseUri = UriOptions(
          defaultScheme: 'https',
          coerceBareDomainsToDefaultScheme: true,
          allowRelative: false,
        );
        final baseConfig = makeTestConfig(uri: baseUri);

        // Act
        withGlobalConfig(baseConfig, () {
          final overrides = makeTestConfig(uri: UriOptions()); // runtime default

          Convert.runScopedConfig(overrides, () {
            // Assert (inside scope)
            expect(Convert.config.uri.allowRelative, isTrue);
            expect(Convert.config.uri.coerceBareDomainsToDefaultScheme, isFalse);
            expect(Convert.config.uri.defaultScheme, equals('https'));
          });

          // Assert (after scope)
          expect(Convert.config.uri.allowRelative, isFalse);
          expect(Convert.config.uri.coerceBareDomainsToDefaultScheme, isTrue);
        });
      });

      test('should enforce allowRelative=false policy during URI conversion', () {
        // Arrange
        final baseConfig = makeTestConfig(
          uri: const UriOptions(allowRelative: false),
        );

        // Act & Assert
        withGlobalConfig(baseConfig, () {
          expect(
            () => Convert.toUri('/relative/path'),
            throwsConversionException(method: 'toUri'),
          );
          expect(Convert.tryToUri('/relative/path'), isNull);
        });
      });

      test(
          'should coerce bare domains to defaultScheme when coercion is enabled',
          () {
        // Arrange
        final baseConfig = makeTestConfig(
          uri: const UriOptions(
            defaultScheme: 'https',
            coerceBareDomainsToDefaultScheme: true,
            allowRelative: true,
          ),
        );

        // Act
        final uri = withGlobalConfig(baseConfig, () => Convert.toUri('example.com'));

        // Assert
        expect(uri, uriEquals('https://example.com'));
      });
    });

    group('TypeRegistry (merge via Convert.runScopedConfig)', () {
      test('should merge registries with scoped registry taking precedence', () {
        // Arrange
        final baseRegistry = const TypeRegistry.empty().register<UserId>(
          (_) => const UserId(1),
        );
        final baseConfig = makeTestConfig(registry: baseRegistry);

        final overrideRegistry = const TypeRegistry.empty().register<UserId>(
          (_) => const UserId(2),
        );
        final overrides = makeTestConfig(registry: overrideRegistry);

        // Act
        withGlobalConfig(baseConfig, () {
          final before = Convert.toType<UserId>('anything');

          late UserId inside;
          Convert.runScopedConfig(overrides, () {
            inside = Convert.toType<UserId>('anything');
          });

          final after = Convert.toType<UserId>('anything');

          // Assert
          expect(before, equals(const UserId(1)));
          expect(inside, equals(const UserId(2)));
          expect(after, equals(const UserId(1)));
        });
      });
    });
  });
}
