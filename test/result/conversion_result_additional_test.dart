// Additional tests for ConversionResult covering gaps identified in audit.
//
// This file focuses on:
// - map with exception in transform function
// - flatMap chained failure scenarios
// - Stack trace preservation verification
// - Multiple chained operations
import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('ConversionResult map exception handling', () {
    test('map should propagate exception when transform throws', () {
      // Arrange
      final success = ConversionResult.success(5);

      // Act / Assert
      expect(
        () => success.map<int>((v) => throw StateError('Transform failed')),
        throwsA(isA<StateError>()),
      );
    });

    test('map should not call transform on failure', () {
      // Arrange
      final failure = ConversionResult<int>.failure(
        ConversionException(
          error: 'original error',
          context: <String, dynamic>{'method': 'test'},
        ),
      );
      var transformCalled = false;

      // Act
      final result = failure.map((v) {
        transformCalled = true;
        return v * 2;
      });

      // Assert
      expect(transformCalled, isFalse);
      expect(result.isFailure, isTrue);
    });
  });

  group('ConversionResult flatMap chained failure scenarios', () {
    test('flatMap should return failure from chained operation', () {
      // Arrange
      final success = ConversionResult.success(5);

      // Act
      final result = success.flatMap((v) {
        return ConversionResult<int>.failure(
          ConversionException(
            error: 'Chained failure',
            context: <String, dynamic>{'method': 'chained'},
          ),
        );
      });

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.error?.error, equals('Chained failure'));
    });

    test('flatMap chain should stop at first failure', () {
      // Arrange
      final success = ConversionResult.success(5);
      var secondCallCount = 0;

      // Act
      final result = success
          .flatMap(
            (v) => ConversionResult<int>.failure(
              ConversionException(
                error: 'First failure',
                context: <String, dynamic>{'step': 1},
              ),
            ),
          )
          .flatMap((v) {
            secondCallCount++;
            return ConversionResult.success(v * 2);
          });

      // Assert
      expect(result.isFailure, isTrue);
      expect(secondCallCount, equals(0));
      expect(result.error?.error, equals('First failure'));
    });

    test('flatMap chain should propagate through multiple successes', () {
      // Arrange
      final initial = ConversionResult.success(2);

      // Act
      final result = initial
          .flatMap((v) => ConversionResult.success(v * 2))
          .flatMap((v) => ConversionResult.success(v * 2))
          .flatMap((v) => ConversionResult.success(v * 2));

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.value, equals(16));
    });

    test('flatMap should preserve error from original failure', () {
      // Arrange
      final failure = ConversionResult<int>.failure(
        ConversionException(
          error: 'Original error',
          context: <String, dynamic>{'original': true},
        ),
      );

      // Act
      final result = failure.flatMap((v) => ConversionResult.success(v * 2));

      // Assert
      expect(result.error?.error, equals('Original error'));
      expect(result.error?.context['original'], isTrue);
    });
  });

  group('ConversionResult stack trace preservation', () {
    test('value getter should throw with preserved stack trace', () {
      // Arrange
      final customTrace = StackTrace.fromString('CUSTOM_STACK_TRACE_MARKER');
      final failure = ConversionResult<int>.failure(
        ConversionException(
          error: 'test error',
          context: <String, dynamic>{'method': 'test'},
          stackTrace: customTrace,
        ),
      );

      // Act / Assert
      try {
        failure.value;
        fail('Should have thrown');
      } catch (e, stackTrace) {
        expect(e, isA<ConversionException>());
        expect(stackTrace.toString(), contains('CUSTOM_STACK_TRACE_MARKER'));
      }
    });

    test('error should preserve original stack trace', () {
      // Arrange
      final customTrace = StackTrace.fromString('ORIGINAL_TRACE');
      final failure = ConversionResult<int>.failure(
        ConversionException(
          error: 'test',
          context: <String, dynamic>{},
          stackTrace: customTrace,
        ),
      );

      // Assert
      expect(failure.error?.stackTrace.toString(), contains('ORIGINAL_TRACE'));
    });
  });

  group('ConversionResult multiple chained operations', () {
    test('map -> flatMap -> map chain should work correctly', () {
      // Arrange
      final initial = ConversionResult.success(5);

      // Act
      final result = initial
          .map((v) => v.toString())
          .flatMap((v) => ConversionResult.success(int.parse(v) * 2))
          .map((v) => 'Result: $v');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.value, equals('Result: 10'));
    });

    test('map -> map -> map chain should accumulate transformations', () {
      // Arrange
      final initial = ConversionResult.success('hello');

      // Act
      final result = initial
          .map((v) => v.toUpperCase())
          .map((v) => v.length)
          .map((v) => v * 2);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.value, equals(10));
    });

    test('fold after chain should handle success path', () {
      // Arrange
      final initial = ConversionResult.success(10);

      // Act
      final text = initial
          .map((v) => v * 2)
          .flatMap((v) => ConversionResult.success(v + 5))
          .fold(
            onSuccess: (v) => 'Success: $v',
            onFailure: (e) => 'Error: ${e.error}',
          );

      // Assert
      expect(text, equals('Success: 25'));
    });

    test('fold after chain should handle failure path', () {
      // Arrange
      final initial = ConversionResult.success(10);

      // Act
      final text = initial
          .map((v) => v * 2)
          .flatMap<int>(
            (v) => ConversionResult.failure(
              ConversionException(
                error: 'Operation failed',
                context: <String, dynamic>{'value': v},
              ),
            ),
          )
          .fold(
            onSuccess: (v) => 'Success: $v',
            onFailure: (e) => 'Error: ${e.error}',
          );

      // Assert
      expect(text, equals('Error: Operation failed'));
    });
  });

  group('ConversionResult with nullable value types', () {
    test('success with null value when T is nullable', () {
      // Arrange
      final result = ConversionResult<int?>.success(null);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.value, isNull);
      expect(result.valueOrNull, isNull);
      expect(result.valueOr(42), isNull);
    });

    test('map should handle transformation to nullable type', () {
      // Arrange
      final success = ConversionResult.success(5);

      // Act
      final result = success.map<int?>((v) => v > 10 ? v : null);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.value, isNull);
    });

    test('flatMap should handle nullable result type', () {
      // Arrange
      final success = ConversionResult.success('test');

      // Act
      final result = success.flatMap<int?>((v) {
        return ConversionResult<int?>.success(null);
      });

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.value, isNull);
    });
  });

  group('ConversionResult fold edge cases', () {
    test('fold with exception in onSuccess callback should propagate', () {
      // Arrange
      final success = ConversionResult.success(5);

      // Act / Assert
      expect(
        () => success.fold(
          onSuccess: (v) => throw StateError('Callback failed'),
          onFailure: (e) => 'error',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('fold with exception in onFailure callback should propagate', () {
      // Arrange
      final failure = ConversionResult<int>.failure(
        ConversionException(error: 'original', context: <String, dynamic>{}),
      );

      // Act / Assert
      expect(
        () => failure.fold(
          onSuccess: (v) => 'success',
          onFailure: (e) => throw StateError('Callback failed'),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('fold should allow different return type than value type', () {
      // Arrange
      final success = ConversionResult.success(42);

      // Act
      final result = success.fold<Map<String, dynamic>>(
        onSuccess: (v) => {'value': v, 'status': 'ok'},
        onFailure: (e) => {'error': e.error, 'status': 'failed'},
      );

      // Assert
      expect(result, equals({'value': 42, 'status': 'ok'}));
    });
  });

  group('ConversionResult valueOr and valueOrNull', () {
    test(
      'valueOr should return value on success even when it equals default',
      () {
        // Arrange
        final result = ConversionResult.success(0);

        // Act
        final value = result.valueOr(999);

        // Assert
        expect(value, equals(0));
      },
    );

    test('valueOrNull should return value on success even when null-like', () {
      // Arrange
      final result = ConversionResult.success(0);

      // Act
      final value = result.valueOrNull;

      // Assert
      expect(value, equals(0));
    });

    test('valueOr with complex default should work correctly', () {
      // Arrange
      final failure = ConversionResult<Map<String, int>>.failure(
        ConversionException(error: 'failed', context: <String, dynamic>{}),
      );
      final defaultMap = <String, int>{'default': 1};

      // Act
      final value = failure.valueOr(defaultMap);

      // Assert
      expect(value, equals(defaultMap));
    });
  });

  group('ConversionResult type inference', () {
    test('success should infer type from value', () {
      // Arrange / Act
      final stringResult = ConversionResult.success('hello');
      final intResult = ConversionResult.success(42);
      final listResult = ConversionResult.success([1, 2, 3]);

      // Assert
      expect(stringResult, isA<ConversionResult<String>>());
      expect(intResult, isA<ConversionResult<int>>());
      expect(listResult, isA<ConversionResult<List<int>>>());
    });

    test('map should infer return type from transform', () {
      // Arrange
      final initial = ConversionResult.success(42);

      // Act
      final stringResult = initial.map((v) => v.toString());
      final doubleResult = initial.map((v) => v.toDouble());

      // Assert
      expect(stringResult, isA<ConversionResult<String>>());
      expect(doubleResult, isA<ConversionResult<double>>());
    });
  });
}
