import 'package:convert_object/convert_object.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';

void main() {
  late ConvertConfig prevConfig;
  late ConvertConfig baselineConfig;
  late String? prevIntlLocale;

  setUp(() {
    // Arrange
    prevIntlLocale = Intl.defaultLocale;
    Intl.defaultLocale = 'en_US';

    baselineConfig = makeTestConfig(locale: 'en_US');
    prevConfig = Convert.configure(baselineConfig);
  });

  tearDown(() {
    // Arrange (cleanup)
    Convert.configure(prevConfig);
    Intl.defaultLocale = prevIntlLocale;
  });

  group('ConvertConfig.onException', () {
    test('should invoke hook when a conversion throws', () {
      // Arrange
      var calls = 0;
      ConversionException? captured;

      final config = makeTestConfig(
        onException: (e) {
          calls++;
          captured = e;
        },
      );

      // Act
      ConversionException? thrown;
      try {
        withGlobalConfig(config, () {
          Convert.toInt('abc'); // should throw ConversionException
        });
        fail('Expected Convert.toInt to throw');
      } catch (e) {
        thrown = e as ConversionException;
      }

      // Assert
      expect(calls, equals(1));
      expect(captured, isNotNull);
      expect(thrown, isNotNull);

      // Same instance is thrown after hook (ConvertObjectImpl._fail rethrows it).
      expect(identical(captured, thrown), isTrue);
      expect(thrown.context['method'], equals('toInt'));
    });

    test(
      'should not invoke hook for try APIs that return null instead of throwing',
      () {
        // Arrange
        var calls = 0;
        final config = makeTestConfig(
          onException: (_) {
            calls++;
          },
        );

        // Act
        final result = withGlobalConfig(config, () {
          return Convert.tryToInt('abc'); // should return null, not throw
        });

        // Assert
        expect(result, isNull);
        expect(calls, equals(0));
      },
    );

    test(
      'should swallow exceptions thrown by hook and still throw ConversionException',
      () {
        // Arrange
        var calls = 0;
        final config = makeTestConfig(
          onException: (_) {
            calls++;
            throw StateError('hook failed');
          },
        );

        // Act
        ConversionException? thrown;
        try {
          withGlobalConfig(config, () {
            Convert.toInt('abc');
          });
          fail('Expected Convert.toInt to throw');
        } catch (e) {
          thrown = e as ConversionException;
        }

        // Assert
        expect(calls, equals(1));
        expect(thrown, isNotNull);
        expect(thrown.context['method'], equals('toInt'));
      },
    );

    test('should invoke hook once per thrown ConversionException', () {
      // Arrange
      var calls = 0;
      final config = makeTestConfig(
        onException: (_) {
          calls++;
        },
      );

      // Act
      withGlobalConfig(config, () {
        for (var i = 0; i < 2; i++) {
          try {
            Convert.toInt('abc');
          } catch (_) {
            // swallow for this test
          }
        }
      });

      // Assert
      expect(calls, equals(2));
    });

    test('should invoke hook once when a ConversionException is rethrown', () {
      // Arrange
      var calls = 0;
      ConversionException? captured;
      final config = makeTestConfig(
        onException: (e) {
          calls++;
          captured = e;
        },
      );

      // Act
      ConversionException? thrown;
      try {
        withGlobalConfig(config, () {
          Convert.toType<int>('abc'); // toInt throws then rethrown in toType
        });
        fail('Expected Convert.toType to throw');
      } catch (e) {
        thrown = e as ConversionException;
      }

      // Assert
      expect(calls, equals(1));
      expect(captured, isNotNull);
      expect(thrown, isNotNull);
      expect(identical(captured, thrown), isTrue);
    });
  });
}
