import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('ConversionException', () {
    const marker = 'ReportMarker';

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

    test('toString() should be concise and include key context fields', () {
      // Arrange
      final ex = ConversionException(
        error: const FormatException('bad'),
        context: <String, dynamic>{
          'method': 'toInt',
          'objectType': 'String',
          'targetType': 'int',
          'mapKey': 'id',
          'listIndex': 0,
        },
      );

      // Act
      final text = ex.toString();

      // Assert
      expect(text, contains('ConversionException(FormatException)'));
      expect(text, contains('method=toInt'));
      expect(text, contains('targetType=int'));
      expect(text, isNot(contains('stackTrace')));
      expect(text, isNot(contains('\n')));
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

    test('fullReport() should be JSON-safe for non-JSON values', () {
      // Arrange
      final ex = ConversionException(
        error: StateError(marker),
        context: <String, dynamic>{
          'method': 'test',
          'when': DateTime.utc(2025, 1, 1, 0, 0, 0),
          'uri': Uri.parse('https://example.com'),
          'custom': const _CustomThing(marker),
        },
      );

      // Act + Assert
      expect(() => ex.fullReport(), returnsNormally);
      final report = ex.fullReport();
      expect(report, contains('ConversionException (Full Report)'));
      expect(report, contains('https://example.com'));
      expect(report, contains(marker));
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

class _CustomThing {
  const _CustomThing(this.label);

  final String label;

  @override
  String toString() => 'CustomThing($label)';
}
