import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('ConversionException', () {
    test('should expose an unmodifiable context map', () {
      // Arrange
      final ex = ConversionException(
        error: 'oops',
        context: <String, dynamic>{'a': 1},
      );

      // Act / Assert
      expect(() {
        // ignore: avoid_dynamic_calls
        (ex.context as dynamic)['b'] = 2;
      }, throwsA(isA<UnsupportedError>()));
    });

    test('should expose errorType as the runtime type of the error', () {
      // Arrange
      final ex = ConversionException(
        error: const FormatException('bad'),
        context: <String, dynamic>{'method': 'test'},
      );

      // Act
      final type = ex.errorType;

      // Assert
      expect(type, equals('FormatException'));
    });

    test('toString() should filter heavy context values and function values',
        () {
      // Arrange
      final heavyMap = <int, int>{
        for (var i = 0; i < 11; i++) i: i,
      };
      final heavyList = List<int>.generate(11, (i) => i);
      final heavySet = heavyList.toSet();
      final heavyString = List<String>.filled(501, 'x').join();

      final ex = ConversionException(
        error: 'boom',
        context: <String, dynamic>{
          'method': 'test',
          'object': heavyMap, // key 'object' is always filtered
          'bigList': heavyList,
          'bigSet': heavySet,
          'bigString': heavyString,
          'fn': () => 1,
        },
      );

      // Act
      final text = ex.toString();

      // Assert
      expect(text, contains('<Map with 11 entries>'));
      expect(text, contains('<List with 11 items>'));
      expect(text, contains('<Set with 11 items>'));
      expect(text, contains('<String with 501 characters>'));
      expect(text, contains('<Function:'));
    });

    test('fullReport() should include the full (unfiltered) context as JSON',
        () {
      // Arrange
      final ex = ConversionException(
        error: 'boom',
        context: <String, dynamic>{
          'method': 'test',
          'object': <String, dynamic>{'a': 1},
        },
      );

      // Act
      final report = ex.fullReport();

      // Assert
      expect(report, contains('ConversionException (Full Report)'));
      expect(report, contains('"method": "test"'));
      expect(report, contains('"object"'));
      expect(report, contains('"a": 1'));
    });

    test('should store and expose the provided stack trace', () {
      // Arrange
      final st = StackTrace.fromString('STACK_TRACE_TEST');
      final ex = ConversionException(
        error: 'boom',
        context: <String, dynamic>{'method': 'test'},
        stackTrace: st,
      );

      // Act
      final stored = ex.stackTrace.toString();

      // Assert
      expect(stored, contains('STACK_TRACE_TEST'));
    });
  });
}
