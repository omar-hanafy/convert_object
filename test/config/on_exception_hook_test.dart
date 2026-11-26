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

    test('try and defaulted collections handle routed failures silently', () {
      final seen = <ConversionException>[];
      final input = <Object?>[1, 'bad'];
      final listDefault = <int>[9];
      final setDefault = <int>{9};

      withScopedConfig(makeTestConfig(onException: seen.add), () {
        expect(Convert.tryToList<int>(input), isNull);
        expect(Convert.tryToSet<int>(input), isNull);
        expect(
          Convert.toList<int>(input, defaultValue: listDefault),
          same(listDefault),
        );
        expect(
          Convert.toSet<int>(input, defaultValue: setDefault),
          same(setDefault),
        );
        expect(
          Convert.toList<int>('bad', defaultValue: listDefault),
          same(listDefault),
        );
        expect(seen, isEmpty);
      });
    });

    test(
      'reports the indexed collection failure once with its original cause',
      () {
        final seen = <ConversionException>[];
        final error = StateError('original cause');
        final trace = StackTrace.current;
        final registry = const TypeRegistry.empty().register<int>(
          (value) => Convert.toInt(
            value,
            converter: (_) => Error.throwWithStackTrace(error, trace),
          ),
        );
        final config = makeTestConfig(
          registry: registry,
          onException: seen.add,
        );
        late ConversionException thrown;

        withScopedConfig(config, () {
          try {
            final input = {
              'items': <Object?>[1, 'bad'],
            };
            input.getList<int>('items');
            fail('Expected an indexed conversion failure');
          } on ConversionException catch (e) {
            thrown = e;
          }
        });

        expect(seen.map((e) => e.context['method']), ['toList<int>']);
        expect(seen.single, same(thrown));
        expect(thrown.context['elementIndex'], 1);
        expect(thrown.context['key'], 'items');
        expect(thrown.error, same(error));
        expect(thrown.stackTrace.toString(), trace.toString());
      },
    );

    test('lazy iterator failures stay silent for try and defaults', () {
      final seen = <ConversionException>[];
      final fallback = <int>{9};
      Iterable<int> values() => ['1', 'bad'].map((s) => Convert.toInt(s));

      withScopedConfig(makeTestConfig(onException: seen.add), () {
        expect(Convert.tryToSet<int>(values()), isNull);
        expect(
          Convert.toSet<int>(values(), defaultValue: fallback),
          same(fallback),
        );
        expect(
          Convert.tryToSet<int>(values(), defaultValue: fallback),
          same(fallback),
        );
        expect(seen, isEmpty);
      });
    });

    test(
      'lazy iterator failures report the collection and attempted index',
      () {
        final seen = <ConversionException>[];
        final error = const FormatException('lazy source');
        final trace = StackTrace.current;

        final attempts = <String>[];
        int parse(String s) {
          attempts.add(s);
          if (s == '1') return 1;
          return Convert.toInt(
            s,
            converter: (_) => Error.throwWithStackTrace(error, trace),
          );
        }

        Iterable<int> generate(List<String> source) sync* {
          for (final item in source) {
            yield parse(item);
          }
        }

        withScopedConfig(makeTestConfig(onException: seen.add), () {
          for (final source in [
            ['1', 'bad'],
            ['bad'],
          ]) {
            for (final input in [source.map(parse), generate(source)]) {
              attempts.clear();
              seen.clear();
              late ConversionException thrown;
              try {
                Convert.toSet<int>(input);
                fail('Expected the source to fail on the invalid element');
              } on ConversionException catch (e) {
                thrown = e;
              }
              expect(seen, [same(thrown)]);
              expect(thrown.context['method'], 'toSet<int>');
              expect(thrown.context['elementIndex'], source.length - 1);
              expect(attempts, source);
              expect(thrown.error, same(error));
              expect(thrown.stackTrace.toString(), trace.toString());
            }
          }
        });
      },
    );

    test('reports a handled error before its nested collection returns', () {
      final seen = <ConversionException>[];
      late int seenAtInnerReturn;
      final values = withScopedConfig(
        makeTestConfig(onException: seen.add),
        () {
          return Convert.toList<int>(
            ['outer'],
            elementConverter: (_) {
              final inner = Convert.toList<int>(
                ['inner'],
                elementConverter: (_) {
                  try {
                    return Convert.toInt('bad');
                  } on ConversionException {
                    return 7;
                  }
                },
              );
              seenAtInnerReturn = seen.length;
              return inner.single;
            },
          );
        },
      );
      expect(values, [7]);
      expect(seenAtInnerReturn, 1);
      expect(seen.single.context['object'], 'bad');
    });

    test('keeps independent failures caught inside a successful converter', () {
      final seen = <(String?, Object?)>[];
      final config = makeTestConfig(
        onException: (e) {
          seen.add((Convert.config.locale, e.context['object']));
        },
      );

      final result = withScopedConfig(
        config,
        () => Convert.tryToList<int>(
          <Object?>['item'],
          elementConverter: (_) {
            Convert.runScopedConfig(
              ConvertConfig.overrides(locale: 'de_DE'),
              () {
                try {
                  Convert.toInt('independent');
                } on ConversionException {
                  // The caller handles this failure without failing the element.
                }
              },
            );
            return 9;
          },
        ),
      );
      expect(result, [9]);
      expect(seen, [('de_DE', 'independent')]);
    });

    test(
      'later conversions scheduled by a registry parser still report',
      () async {
        final seen = <ConversionException>[];
        late Future<void> later;
        final registry = const TypeRegistry.empty().register<int>((value) {
          later = Future<void>.microtask(() {
            expect(
              () => Convert.toInt('later'),
              throwsA(isA<ConversionException>()),
            );
          });
          return Convert.toInt(value);
        });
        final config = makeTestConfig(
          registry: registry,
          onException: seen.add,
        );
        await withScopedConfig(config, () async {
          expect(Convert.tryToSet<int>(['bad']), isNull);
          await later;
        });
        expect(seen.map((e) => e.context['object']), ['later']);
      },
    );

    test(
      'try collections retain strict boolean and registered element parsing',
      () {
        final registry = const TypeRegistry.empty().register<Duration>(
          (value) => Duration(seconds: Convert.toInt(value)),
        );
        withScopedConfig(makeTestConfig(registry: registry), () {
          expect(Convert.tryToList<bool>(['invalid']), [false]);
          expect(Convert.tryToSet<Duration>(['2']), {
            const Duration(seconds: 2),
          });
        });
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
