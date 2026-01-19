import 'package:convert_object/convert_object.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_models.dart';

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

  group('TypeRegistry.register', () {
    test('should return a new registry without mutating the original', () {
      // Arrange
      const empty = TypeRegistry.empty();
      final registered = empty.register<UserId>((v) {
        // Always return something to satisfy non-nullable UserId.
        return UserId.tryParse(v) ?? const UserId(-1);
      });

      // Act
      final fromEmpty = empty.tryParse<UserId>('42');
      final fromRegistered = registered.tryParse<UserId>('42');

      // Assert
      expect(fromEmpty, isNull);
      expect(fromRegistered, isNotNull);
      expect(fromRegistered, equals(const UserId(42)));
    });
  });

  group('TypeRegistry.tryParse', () {
    test('should return null when parser returns null for a nullable type', () {
      // Arrange
      final registry = const TypeRegistry.empty().register<UserId?>(
        (v) => UserId.tryParse(v),
      );

      // Act
      final parsed = registry.tryParse<UserId?>('not-an-int');

      // Assert
      expect(parsed, isNull);
    });
  });

  group('TypeRegistry.merge', () {
    test('should return this when merging with an empty registry', () {
      // Arrange
      final a = const TypeRegistry.empty().register<UserId>(
        (_) => const UserId(1),
      );

      // Act
      final merged = a.merge(const TypeRegistry.empty());

      // Assert
      expect(identical(merged, a), isTrue);
      expect(merged.tryParse<UserId>('x'), equals(const UserId(1)));
    });

    test('should prefer the other registry on key collisions', () {
      // Arrange
      final a = const TypeRegistry.empty().register<UserId>(
        (_) => const UserId(1),
      );
      final b = const TypeRegistry.empty().register<UserId>(
        (_) => const UserId(2),
      );

      // Act
      final merged = a.merge(b);

      // Assert
      expect(merged.tryParse<UserId>('x'), equals(const UserId(2)));
    });
  });

  group('Convert.toType with TypeRegistry', () {
    test('should use a registered parser for custom types', () {
      // Arrange
      final registry = const TypeRegistry.empty().register<UserId>(
        (v) => UserId.tryParse(v) ?? const UserId(-1),
      );
      final config = makeTestConfig(registry: registry);

      // Act
      final userId = withGlobalConfig(
        config,
        () => Convert.toType<UserId>('42'),
      );

      // Assert
      expect(userId, equals(const UserId(42)));
    });

    test(
      'should prefer TypeRegistry over built-in routing when registered',
      () {
        // Arrange
        final registry = const TypeRegistry.empty().register<int>((_) => 999);
        final config = makeTestConfig(registry: registry);

        // Act
        final value = withGlobalConfig(config, () => Convert.toType<int>('5'));

        // Assert
        expect(value, isA<int>());
        expect(value, equals(999));
      },
    );

    test('should surface registry parser errors without wrapping', () {
      // Arrange
      final registry = const TypeRegistry.empty().register<int>(
        (_) => throw StateError('boom'),
      );
      final config = makeTestConfig(registry: registry);

      // Act + Assert
      expect(
        () => withGlobalConfig(config, () => Convert.toType<int>('5')),
        throwsA(isA<StateError>()),
      );
    });

    test('should allow scoped registry to override global registry', () {
      // Arrange
      final globalRegistry = const TypeRegistry.empty().register<int>((_) => 1);
      final globalConfig = makeTestConfig(registry: globalRegistry);

      final scopedRegistry = const TypeRegistry.empty().register<int>((_) => 2);
      final scopedOverrides = makeTestConfig(registry: scopedRegistry);

      // Act
      withGlobalConfig(globalConfig, () {
        final before = Convert.toType<int>('x');

        late int inside;
        Convert.runScopedConfig(scopedOverrides, () {
          inside = Convert.toType<int>('x');
        });

        final after = Convert.toType<int>('x');

        // Assert
        expect(before, equals(1));
        expect(inside, equals(2));
        expect(after, equals(1));
      });
    });
  });
}
