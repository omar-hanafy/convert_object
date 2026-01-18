// Additional tests for TypeRegistry covering gaps identified in audit.
//
// This file focuses on:
// - Parser exception handling (non-ConversionException)
// - Multiple nested registry merges
// - Edge cases with empty sets and copyWith
import 'package:convert_object/convert_object.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_models.dart';

void main() {
  late ConvertConfig prevConfig;
  late String? prevIntlLocale;

  setUp(() {
    prevIntlLocale = Intl.defaultLocale;
    Intl.defaultLocale = 'en_US';
    prevConfig = Convert.configure(makeTestConfig(locale: 'en_US'));
  });

  tearDown(() {
    Convert.configure(prevConfig);
    Intl.defaultLocale = prevIntlLocale;
  });

  group('TypeRegistry parser exception handling', () {
    test('should propagate non-ConversionException from parser', () {
      // Arrange
      final registry = const TypeRegistry.empty().register<UserId>((v) {
        throw StateError('Parser failed');
      });
      final config = makeTestConfig(registry: registry);

      // Act / Assert
      expect(
        () => withGlobalConfig(config, () => Convert.toType<UserId>('42')),
        throwsA(isA<StateError>()),
      );
    });

    test('should propagate ArgumentError from parser', () {
      // Arrange
      final registry = const TypeRegistry.empty().register<UserId>((v) {
        throw ArgumentError.value(v, 'value', 'must be positive');
      });
      final config = makeTestConfig(registry: registry);

      // Act / Assert
      expect(
        () => withGlobalConfig(config, () => Convert.toType<UserId>('-1')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('tryParse should propagate parser exceptions (not catch them)', () {
      // Arrange
      final registry = const TypeRegistry.empty().register<UserId>((v) {
        throw StateError('Parser failed');
      });

      // Assert - tryParse does NOT catch exceptions, they propagate
      // This documents the actual behavior: only missing parser returns null
      expect(
        () => registry.tryParse<UserId>('42'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('TypeRegistry multiple nested merges', () {
    test('should support 3-level nested registry merges', () {
      // Arrange
      final level1 = const TypeRegistry.empty().register<int>((_) => 1);
      final level2 = const TypeRegistry.empty().register<double>((_) => 2.0);
      final level3 = const TypeRegistry.empty().register<String>((_) => 'three');

      // Act
      final merged = level1.merge(level2).merge(level3);

      // Assert
      expect(merged.tryParse<int>('x'), equals(1));
      expect(merged.tryParse<double>('x'), equals(2.0));
      expect(merged.tryParse<String>('x'), equals('three'));
    });

    test('should preserve all parsers through multiple merges', () {
      // Arrange
      final a = const TypeRegistry.empty()
          .register<int>((_) => 1)
          .register<double>((_) => 1.1);
      final b = const TypeRegistry.empty()
          .register<String>((_) => 'b')
          .register<bool>((_) => true);
      final c = const TypeRegistry.empty()
          .register<BigInt>((_) => BigInt.from(100))
          .register<Uri>((_) => Uri.parse('http://c.com'));

      // Act
      final merged = a.merge(b).merge(c);

      // Assert
      expect(merged.tryParse<int>('x'), equals(1));
      expect(merged.tryParse<double>('x'), equals(1.1));
      expect(merged.tryParse<String>('x'), equals('b'));
      expect(merged.tryParse<bool>('x'), isTrue);
      expect(merged.tryParse<BigInt>('x'), equals(BigInt.from(100)));
      expect(merged.tryParse<Uri>('x')?.toString(), equals('http://c.com'));
    });

    test('later merges should override earlier parsers', () {
      // Arrange
      final a = const TypeRegistry.empty().register<int>((_) => 1);
      final b = const TypeRegistry.empty().register<int>((_) => 2);
      final c = const TypeRegistry.empty().register<int>((_) => 3);

      // Act
      final merged = a.merge(b).merge(c);

      // Assert
      expect(merged.tryParse<int>('x'), equals(3));
    });
  });

  group('TypeRegistry with custom types', () {
    test('should support LatLng custom type parsing', () {
      // Arrange
      final registry = const TypeRegistry.empty().register<LatLng>(
        (v) => LatLng.tryParse(v) ?? const LatLng(0, 0),
      );
      final config = makeTestConfig(registry: registry);

      // Act
      final fromMap = withGlobalConfig(
        config,
        () => Convert.toType<LatLng>(<String, dynamic>{
          'lat': '30.0444',
          'lng': '31.2357',
        }),
      );
      final fromList = withGlobalConfig(
        config,
        () => Convert.toType<LatLng>(<dynamic>[30.0444, 31.2357]),
      );
      final fromString = withGlobalConfig(
        config,
        () => Convert.toType<LatLng>('30.0444,31.2357'),
      );

      // Assert
      expect(fromMap, equals(const LatLng(30.0444, 31.2357)));
      expect(fromList, equals(const LatLng(30.0444, 31.2357)));
      expect(fromString, equals(const LatLng(30.0444, 31.2357)));
    });

    test('should support Money custom type parsing', () {
      // Arrange
      final registry = const TypeRegistry.empty().register<Money>(
        (v) => Money.tryParse(v) ?? const Money(0, 'USD'),
      );
      final config = makeTestConfig(registry: registry);

      // Act
      final fromMap = withGlobalConfig(
        config,
        () => Convert.toType<Money>(<String, dynamic>{
          'amount': '99.99',
          'currency': 'EUR',
        }),
      );
      final fromStringCurrencyFirst = withGlobalConfig(
        config,
        () => Convert.toType<Money>('USD 25.50'),
      );
      final fromStringAmountFirst = withGlobalConfig(
        config,
        () => Convert.toType<Money>('25.50 GBP'),
      );

      // Assert
      expect(fromMap, equals(const Money(99.99, 'EUR')));
      expect(fromStringCurrencyFirst, equals(const Money(25.50, 'USD')));
      expect(fromStringAmountFirst, equals(const Money(25.50, 'GBP')));
    });
  });

  group('TypeRegistry edge cases', () {
    test('should handle parser that always returns null', () {
      // Arrange
      final registry = const TypeRegistry.empty().register<UserId?>((_) => null);

      // Act
      final result = registry.tryParse<UserId?>('42');

      // Assert
      expect(result, isNull);
    });

    test('should return null for unregistered type', () {
      // Arrange
      final registry = const TypeRegistry.empty().register<int>((_) => 42);

      // Act
      final result = registry.tryParse<String>('test');

      // Assert
      expect(result, isNull);
    });

    test('merge with self should return equivalent registry', () {
      // Arrange
      final registry = const TypeRegistry.empty()
          .register<int>((_) => 42)
          .register<String>((_) => 'hello');

      // Act
      final merged = registry.merge(registry);

      // Assert
      expect(merged.tryParse<int>('x'), equals(42));
      expect(merged.tryParse<String>('x'), equals('hello'));
    });
  });
}
