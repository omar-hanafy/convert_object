// Additional tests for ConversionException covering gaps identified in audit.
//
// This file focuses on:
// - nullObject factory constructor
// - Stack trace default behavior
// - Various error type wrapping
// - Edge cases in context handling
import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/matchers.dart';

void main() {
  group('ConversionException.nullObject factory', () {
    test('should create exception with standard null object message', () {
      // Arrange
      final st = StackTrace.fromString('NULL_OBJECT_TRACE');

      // Act
      final ex = ConversionException.nullObject(
        context: <String, dynamic>{'method': 'toInt'},
        stackTrace: st,
      );

      // Assert
      expect(ex.error, equals('object is unsupported or null'));
      expect(ex.context['method'], equals('toInt'));
      expect(ex.stackTrace.toString(), contains('NULL_OBJECT_TRACE'));
    });

    test('should preserve full context in nullObject factory', () {
      // Arrange
      final st = StackTrace.fromString('TRACE');

      // Act
      final ex = ConversionException.nullObject(
        context: <String, dynamic>{
          'method': 'toDouble',
          'targetType': 'double',
          'objectType': 'Null',
          'mapKey': 'price',
          'listIndex': 0,
        },
        stackTrace: st,
      );

      // Assert
      expect(ex.context.length, equals(5));
      expect(ex.context['method'], equals('toDouble'));
      expect(ex.context['targetType'], equals('double'));
      expect(ex.context['mapKey'], equals('price'));
      expect(ex.context['listIndex'], equals(0));
    });

    test('should include null object message in toString output', () {
      // Arrange
      final st = StackTrace.fromString('TRACE');
      final ex = ConversionException.nullObject(
        context: <String, dynamic>{'method': 'toInt'},
        stackTrace: st,
      );

      // Act
      final text = ex.toString();

      // Assert
      expect(text, contains('object is unsupported or null'));
      expect(text, contains('method=toInt'));
    });
  });

  group('ConversionException stack trace default behavior', () {
    test('should capture current stack trace when not explicitly provided', () {
      // Arrange / Act
      final ex = ConversionException(
        error: 'test error',
        context: <String, dynamic>{'method': 'test'},
      );

      // Assert
      expect(ex.stackTrace, isNotNull);
      expect(ex.stackTrace.toString(), isNotEmpty);
      // The stack trace should contain the current file's name
      expect(
        ex.stackTrace.toString(),
        contains('conversion_exception_additional_test.dart'),
      );
    });

    test('should preserve custom stack trace when explicitly provided', () {
      // Arrange
      final customTrace = StackTrace.fromString('CUSTOM_TRACE_MARKER');

      // Act
      final ex = ConversionException(
        error: 'test error',
        context: <String, dynamic>{'method': 'test'},
        stackTrace: customTrace,
      );

      // Assert
      expect(ex.stackTrace.toString(), contains('CUSTOM_TRACE_MARKER'));
      expect(
        ex.stackTrace.toString(),
        isNot(contains('conversion_exception_additional_test.dart')),
      );
    });
  });

  group('ConversionException with various error types', () {
    test('should wrap StateError correctly', () {
      // Arrange
      final error = StateError('bad state');

      // Act
      final ex = ConversionException(
        error: error,
        context: <String, dynamic>{'method': 'test'},
      );

      // Assert
      expect(ex.errorType, equals('StateError'));
      expect(ex.toString(), contains('ConversionException(StateError)'));
      expect(ex.toString(), contains('bad state'));
    });

    test('should wrap RangeError correctly', () {
      // Arrange
      final error = RangeError.range(10, 0, 5);

      // Act
      final ex = ConversionException(
        error: error,
        context: <String, dynamic>{'method': 'getIndex'},
      );

      // Assert
      expect(ex.errorType, equals('RangeError'));
      expect(ex.toString(), contains('ConversionException(RangeError)'));
    });

    test('should wrap ArgumentError correctly', () {
      // Arrange
      final error = ArgumentError.value('bad', 'param', 'must be valid');

      // Act
      final ex = ConversionException(
        error: error,
        context: <String, dynamic>{'method': 'parse'},
      );

      // Assert
      expect(ex.errorType, equals('ArgumentError'));
      expect(ex.toString(), contains('ConversionException(ArgumentError)'));
    });

    test('should wrap TypeError correctly', () {
      // Arrange
      Object? error;
      try {
        // Force a type error by calling a method on null
        final dynamic nullValue = null;
        // ignore: avoid_dynamic_calls
        nullValue.nonExistentMethod();
      } catch (e) {
        error = e;
      }

      // Act
      final ex = ConversionException(
        error: error,
        context: <String, dynamic>{'method': 'cast'},
      );

      // Assert - in Dart, this throws NoSuchMethodError, not TypeError
      expect(ex.errorType, contains('NoSuchMethodError'));
      expect(ex.toString(), contains('ConversionException'));
    });

    test('should handle null error correctly', () {
      // Arrange / Act
      final ex = ConversionException(
        error: null,
        context: <String, dynamic>{'method': 'test'},
      );

      // Assert
      expect(ex.errorType, equals('null'));
      expect(ex.error, isNull);
      expect(ex.toString(), contains('ConversionException(null)'));
    });

    test('should handle string error correctly', () {
      // Arrange / Act
      final ex = ConversionException(
        error: 'simple string error',
        context: <String, dynamic>{'method': 'test'},
      );

      // Assert
      expect(ex.errorType, equals('String'));
      expect(ex.toString(), contains('ConversionException(String)'));
      expect(ex.toString(), contains('simple string error'));
    });
  });

  group('ConversionException context edge cases', () {
    test('should handle empty context map', () {
      // Arrange / Act
      final ex = ConversionException(
        error: 'error',
        context: <String, dynamic>{},
      );

      // Assert
      expect(ex.context, isEmpty);
      expect(ex.toString(), equals('ConversionException(String): error'));
    });

    test('should handle context with many fields', () {
      // Arrange
      final context = <String, dynamic>{
        'method': 'complexMethod',
        'targetType': 'ComplexType',
        'objectType': 'SourceType',
        'mapKey': 'key1',
        'listIndex': 42,
        'format': 'yyyy-MM-dd',
        'locale': 'en_US',
        'defaultValue': 0,
        'customField': 'custom',
        'nested': <String, dynamic>{'a': 1, 'b': 2},
      };

      // Act
      final ex = ConversionException(error: 'error', context: context);

      // Assert
      expect(ex.context.length, equals(10));
      // toString only includes specific fields
      expect(ex.toString(), contains('method=complexMethod'));
      expect(ex.toString(), contains('targetType=ComplexType'));
      expect(ex.toString(), isNot(contains('format=')));
      expect(ex.toString(), isNot(contains('customField=')));
    });

    test('should handle context with null values for key fields', () {
      // Arrange
      final context = <String, dynamic>{
        'method': null,
        'targetType': null,
        'objectType': 'String',
      };

      // Act
      final ex = ConversionException(error: 'error', context: context);

      // Assert
      // Null values should be omitted from toString suffix
      expect(ex.toString(), isNot(contains('method=')));
      expect(ex.toString(), isNot(contains('targetType=')));
      expect(ex.toString(), contains('objectType=String'));
    });
  });

  group('ConversionException fullReport edge cases', () {
    test('should handle empty context in fullReport', () {
      // Arrange
      final ex = ConversionException(
        error: 'error',
        context: <String, dynamic>{},
      );

      // Act
      final report = ex.fullReport();

      // Assert
      expect(report, contains('ConversionException (Full Report)'));
      expect(report, contains('error: error'));
      expect(report, contains('errorType: String'));
    });

    test('should handle deeply nested context in fullReport', () {
      // Arrange
      final context = <String, dynamic>{
        'method': 'test',
        'level1': <String, dynamic>{
          'level2': <String, dynamic>{
            'level3': <String, dynamic>{'value': 'deep'},
          },
        },
      };

      // Act
      final ex = ConversionException(error: 'error', context: context);
      final report = ex.fullReport();

      // Assert
      expect(report, contains('level1'));
      expect(report, contains('level2'));
      expect(report, contains('level3'));
      expect(report, contains('deep'));
    });

    test('should handle list values in context', () {
      // Arrange
      final context = <String, dynamic>{
        'method': 'test',
        'items': <int>[1, 2, 3],
        'strings': <String>['a', 'b', 'c'],
      };

      // Act
      final ex = ConversionException(error: 'error', context: context);
      final report = ex.fullReport();

      // Assert
      expect(report, contains('['));
      expect(report, contains('1'));
      expect(report, contains('"a"'));
    });
  });

  group('ConversionException integration with matchers', () {
    test('isConversionException should match with all criteria', () {
      // Arrange
      final ex = ConversionException(
        error: const FormatException('invalid format'),
        context: <String, dynamic>{'method': 'toInt', 'targetType': 'int'},
      );

      // Assert
      expect(
        ex,
        isConversionException(
          method: 'toInt',
          targetType: 'int',
          errorContains: 'invalid',
        ),
      );
    });

    test('isConversionException should fail on method mismatch', () {
      // Arrange
      final ex = ConversionException(
        error: 'error',
        context: <String, dynamic>{'method': 'toInt'},
      );

      // Assert
      expect(ex, isNot(isConversionException(method: 'toDouble')));
    });

    test(
      'isConversionException should fail on empty context when required',
      () {
        // Arrange
        final ex = ConversionException(
          error: 'error',
          context: <String, dynamic>{},
        );

        // Assert
        expect(ex, isNot(isConversionException(requireContext: true)));
      },
    );

    test(
      'isConversionException should pass on empty context when not required',
      () {
        // Arrange
        final ex = ConversionException(
          error: 'error',
          context: <String, dynamic>{},
        );

        // Assert
        expect(ex, isConversionException(requireContext: false));
      },
    );
  });
}
