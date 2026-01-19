import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';
import '../helpers/test_models.dart';

class UnsupportedThing {
  const UnsupportedThing();
}

class ThrowingDatesConfig extends ConvertConfig {
  ThrowingDatesConfig() : super();

  @override
  DateOptions get dates => throw StateError('boom');
}

class ThrowingUriConfig extends ConvertConfig {
  ThrowingUriConfig() : super();

  @override
  UriOptions get uri => throw ConversionException(
    error: 'boom',
    context: const {'method': 'tryToType<Uri>'},
    stackTrace: StackTrace.current,
  );
}

void main() {
  late ConvertConfig prev;

  setUp(() {
    prev = Convert.configure(makeTestConfig());
  });

  tearDown(() {
    Convert.configure(prev);
  });

  group('Convert.toType<T>', () {
    test('should route to int conversion when T == int', () {
      // Arrange
      const input = '5';

      // Act
      final result = Convert.toType<int>(input);

      // Assert
      expect(result, isA<int>());
      expect(result, equals(5));
    });

    test('should route to bool conversion when T == bool', () {
      // Arrange
      const input = 'true';

      // Act
      final result = Convert.toType<bool>(input);

      // Assert
      expect(result, isA<bool>());
      expect(result, isTrue);
    });

    test('should route to double conversion when T == double', () {
      // Arrange
      const input = '5.5';

      // Act
      final result = Convert.toType<double>(input);

      // Assert
      expect(result, isA<double>());
      expect(result, equals(5.5));
    });

    test('should route to num conversion when T == num', () {
      // Arrange
      const input = '5.5';

      // Act
      final result = Convert.toType<num>(input);

      // Assert
      expect(result, isA<num>());
      expect(result, equals(5.5));
    });

    test('should route to BigInt conversion when T == BigInt', () {
      // Arrange
      const input = '9007199254740993';

      // Act
      final result = Convert.toType<BigInt>(input);

      // Assert
      expect(result, isA<BigInt>());
      expect(result, equals(BigInt.parse(input)));
    });

    test('should route to String conversion when T == String', () {
      // Arrange
      const input = 123;

      // Act
      final result = Convert.toType<String>(input);

      // Assert
      expect(result, isA<String>());
      expect(result, equals('123'));
    });

    test('should route to DateTime conversion when T == DateTime', () {
      // Arrange
      const input = '2025-11-11T10:15:30Z';

      // Act
      final result = Convert.toType<DateTime>(input);

      // Assert
      expect(result, isA<DateTime>());
      expect(result, isUtcDateTime);
      expect(result, sameInstantAs(kKnownUtcInstant));
    });

    test('should route to Uri conversion when T == Uri', () {
      // Arrange
      const input = 'https://example.com';

      // Act
      final result = Convert.toType<Uri>(input);

      // Assert
      expect(result, isA<Uri>());
      expect(result, uriEquals(input));
    });

    test('should return the input when it is already of type T', () {
      // Arrange
      const input = 7;

      // Act
      final result = Convert.toType<int>(input);

      // Assert
      expect(result, equals(7));
    });

    test('should return same instance for matching collection types', () {
      // Arrange
      final input = <int>[1, 2, 3];

      // Act
      final result = Convert.toType<List<int>>(input);

      // Assert
      expect(identical(result, input), isTrue);
      expect(result, equals(input));
    });

    test('should throw for incompatible collection targets', () {
      // Arrange
      final input = <Object?>[1, '2'];

      // Act + Assert
      expect(
        () => Convert.toType<List<int>>(input),
        throwsConversionException(
          method: 'toType<List<int>>',
          targetType: 'List<int>',
        ),
      );
    });

    test('should throw ConversionException when input is null', () {
      // Arrange
      const Object? input = null;

      // Act + Assert
      expect(
        () => Convert.toType<int>(input),
        throwsConversionException(method: 'toType<int>', targetType: 'int'),
      );
    });

    test('should throw ConversionException for unsupported target types', () {
      // Arrange
      const input = 'x';

      // Act + Assert
      expect(
        () => Convert.toType<UnsupportedThing>(input),
        throwsConversionException(
          method: 'toType<UnsupportedThing>',
          errorContains: 'Unsupported type detected',
        ),
      );
    });

    test('should use TypeRegistry for custom target types when registered', () {
      // Arrange
      final registry = const TypeRegistry.empty().register<UserId>(
        (obj) => UserId(Convert.toInt(obj)),
      );
      final overrides = makeTestConfig(registry: registry);

      // Act
      final result = withScopedConfig(
        overrides,
        () => Convert.toType<UserId>('123'),
      );

      // Assert
      expect(result, isA<UserId>());
      expect(result, equals(const UserId(123)));
    });

    test(
      'should prefer TypeRegistry parser over built-in routing when registered',
      () {
        // Arrange
        final registry = const TypeRegistry.empty().register<int>((_) => 999);
        final overrides = makeTestConfig(registry: registry);

        // Act
        final globalResult = Convert.toType<int>('5');
        final scopedResult = withScopedConfig(
          overrides,
          () => Convert.toType<int>('5'),
        );

        // Assert
        expect(globalResult, equals(5));
        expect(scopedResult, equals(999));
      },
    );

    test('should prefer scoped TypeRegistry over a global TypeRegistry', () {
      // Arrange
      final globalRegistry = const TypeRegistry.empty().register<int>(
        (_) => 111,
      );
      final scopedRegistry = const TypeRegistry.empty().register<int>(
        (_) => 222,
      );

      // Act
      final result = withGlobalConfig(
        makeTestConfig(registry: globalRegistry),
        () {
          final usingGlobal = Convert.toType<int>('5');
          final usingScoped = withScopedConfig(
            makeTestConfig(registry: scopedRegistry),
            () => Convert.toType<int>('5'),
          );
          return (usingGlobal: usingGlobal, usingScoped: usingScoped);
        },
      );

      // Assert
      expect(result.usingGlobal, equals(111));
      expect(result.usingScoped, equals(222));
    });

    test('should wrap non-ConversionException thrown during routing', () {
      // Arrange
      final scopedPrev = Convert.configure(ThrowingDatesConfig());
      addTearDown(() => Convert.configure(scopedPrev));

      // Act + Assert
      expect(
        () => Convert.toType<DateTime>('2025-01-01'),
        throwsConversionException(method: 'toType<DateTime>'),
      );
    });
  });

  group('Convert.tryToType<T>', () {
    test('should return null when input is null', () {
      // Arrange
      const Object? input = null;

      // Act
      final result = Convert.tryToType<int>(input);

      // Assert
      expect(result, isNull);
    });

    test('should convert to String using tryToType', () {
      // Arrange
      const input = 123;

      // Act
      final result = Convert.tryToType<String>(input);

      // Assert
      expect(result, equals('123'));
    });

    test(
      'should return null when conversion fails for supported primitive types',
      () {
        // Arrange
        const input = 'abc';

        // Act
        final result = Convert.tryToType<int>(input);

        // Assert
        expect(result, isNull);
      },
    );

    test('should return null for unsupported target types', () {
      // Arrange
      const input = 'x';

      // Act
      final result = Convert.tryToType<UnsupportedThing>(input);

      // Assert
      expect(result, isNull);
    });

    test('should return null for incompatible collection targets', () {
      // Arrange
      final input = <Object?>[1, '2'];

      // Act
      final result = Convert.tryToType<List<int>>(input);

      // Assert
      expect(result, isNull);
    });

    test('should return null when ConversionException is thrown', () {
      // Arrange
      final scopedPrev = Convert.configure(ThrowingUriConfig());
      addTearDown(() => Convert.configure(scopedPrev));

      // Act
      final result = Convert.tryToType<Uri>('https://example.com');

      // Assert
      expect(result, isNull);
    });
  });
}
