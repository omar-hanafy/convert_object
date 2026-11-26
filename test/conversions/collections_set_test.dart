import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';
import '../helpers/matchers.dart';

void main() {
  late ConvertConfig prev;

  setUp(() {
    // Arrange
    prev = Convert.configure(makeTestConfig(locale: 'en_US'));
  });

  tearDown(() {
    // Arrange
    Convert.configure(prev);
  });

  group('Convert.toSet', () {
    test('should return the same set when input is already a Set<T>', () {
      // Arrange
      final input = <int>{1, 2};

      // Act
      final result = Convert.toSet<int>(input);

      // Assert
      expect(result, isA<Set<int>>());
      expect(result, equals(input));
      expect(identical(result, input), isTrue);
    });

    test('should convert iterable elements to T', () {
      // Arrange
      final input = <dynamic>['1', '2', '2'];

      // Act
      final result = Convert.toSet<int>(input);

      // Assert
      expect(result, equals(<int>{1, 2}));
    });

    test('should wrap a scalar input when it is already of type T', () {
      // Arrange
      const input = 7;

      // Act
      final result = Convert.toSet<int>(input);

      // Assert
      expect(result, equals(<int>{7}));
    });

    test(
      'should throw ConversionException when input is a scalar not iterable and not T',
      () {
        // Arrange
        const input = 'abc';

        // Act
        // Assert
        expect(
          () => Convert.toSet<int>(input),
          throwsConversionException(method: 'toSet<int>'),
        );
      },
    );

    test('should apply elementConverter to every element', () {
      // Arrange
      final input = <int>[1, 2];

      // Act
      final result = Convert.toSet<String>(
        input,
        elementConverter: (e) => 's$e',
      );

      // Assert
      expect(result, equals(<String>{'s1', 's2'}));
    });

    test(
      'should decode a JSON list string into a set and convert elements',
      () {
        // Arrange
        const input = '[1,2,2,3]';

        // Act
        final result = Convert.toSet<int>(input);

        // Assert
        expect(result, equals(<int>{1, 2, 3}));
      },
    );

    test(
      'converts map values before deduplicating, including JSON objects',
      () {
        final input = <String, Object?>{'first': '2', 'second': 1, 'third': 2};
        expect(convertToSet<int>(input), {2, 1});
        expect(
          [
            {'items': input},
          ].tryGetSet<int>(0, innerMapKey: 'items'),
          {2, 1},
        );
        expect('{"first":"2","second":1,"third":2}'.convert.tryToSet<int>(), {
          2,
          1,
        });
        expect(Convert.tryToSet<int>(<Object?, Object?>{}), isEmpty);
      },
    );

    test('converts each map value once before removing duplicates', () {
      final input = <String, int>{'a': 1, 'b': 3, 'c': 4};
      final seen = <Object?>[];
      final result = Convert.toSet<int>(
        input,
        elementConverter: (value) {
          seen.add(value);
          return (value as int).remainder(2);
        },
      );
      expect(seen, [1, 3, 4]);
      expect(result, {1, 0});
      expect(Convert.tryToSet<Object>(input)!.single, same(input));
      expect(Convert.toSet<Map<String, int>>(input).single, same(input));
    });

    test('keeps the failed map value index and discards partial results', () {
      final input = <String, Object?>{
        'first': '2',
        'second': 'bad',
        'third': 1,
      };
      expect(
        () => [input].getSet<int>(0),
        throwsA(
          isA<ConversionException>()
              .having((e) => e.context['index'], 'selected index', 0)
              .having((e) => e.context['elementIndex'], 'failed value index', 1)
              .having((e) => e.error, 'parse error', isA<FormatException>()),
        ),
      );
      final fallback = <int>{42};
      expect(Convert.toSet<int>(input, defaultValue: fallback), same(fallback));
      expect(Convert.tryToSet<int>(input), isNull);
    });

    test('should convert from map.values (Iterable) into a Set<T>', () {
      // Arrange
      final map = <String, String>{'a': '1', 'b': '2'};

      // Act
      final result = Convert.toSet<int>(map.values);

      // Assert
      expect(result, equals(<int>{1, 2}));
    });

    test('should convert a Map<K, V> directly to a Set<V>', () {
      // Arrange
      final map = <String, int>{'a': 1, 'b': 2};

      // Act
      final result = Convert.toSet<int>(map);

      // Assert
      expect(result, equals(<int>{1, 2}));
    });

    test(
      'should return defaultValue when conversion fails and defaultValue is provided',
      () {
        // Arrange
        const input = 'not-a-set';
        final fallback = <int>{9};

        // Act
        final result = Convert.toSet<int>(input, defaultValue: fallback);

        // Assert
        expect(result, equals(fallback));
      },
    );

    test('should include elementIndex in ConversionException context', () {
      // Arrange
      final input = <dynamic>['1', 'x', '3'];
      ConversionException? thrown;

      // Act
      try {
        Convert.toSet<int>(input);
      } catch (e) {
        thrown = e as ConversionException;
      }

      // Assert
      expect(thrown, isNotNull);
      expect(thrown!.context['elementIndex'], equals(1));
    });
  });

  group('Convert.tryToSet', () {
    test(
      'should return null when conversion fails and no defaultValue is provided',
      () {
        // Arrange
        const input = 'abc';

        // Act
        final result = Convert.tryToSet<int>(input);

        // Assert
        expect(result, isNull);
      },
    );

    test('should return a one-element set when input is already of type T', () {
      // Arrange
      const input = 5;

      // Act
      final result = Convert.tryToSet<int>(input);

      // Assert
      expect(result, equals(<int>{5}));
    });

    test('should return defaultValue when conversion fails', () {
      // Arrange
      const input = 'abc';
      final fallback = <int>{1};

      // Act
      final result = Convert.tryToSet<int>(input, defaultValue: fallback);

      // Assert
      expect(result, equals(fallback));
    });

    test('should return null when element conversion fails', () {
      // Arrange
      final input = <dynamic>['a'];

      // Act
      final result = Convert.tryToSet<int>(input);

      // Assert
      expect(result, isNull);
    });

    test('should return an empty set when input is an empty iterable', () {
      // Arrange
      final input = <dynamic>[];

      // Act
      final result = Convert.tryToSet<int>(input);

      // Assert
      expect(result, isA<Set<int>>());
      expect(result, equals(<int>{}));
    });

    test('should apply elementConverter when provided', () {
      // Arrange
      final input = <dynamic>['1', '2'];

      // Act
      final result = Convert.tryToSet<int>(
        input,
        elementConverter: (e) => int.parse(e as String),
      );

      // Assert
      expect(result, equals(<int>{1, 2}));
    });
  });
}
