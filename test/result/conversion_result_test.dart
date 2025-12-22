import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('ConversionResult', () {
    test('success should expose value and success flags', () {
      // Arrange
      final result = ConversionResult.success(5);

      // Act
      final isSuccess = result.isSuccess;
      final isFailure = result.isFailure;
      final value = result.value;
      final valueOrNull = result.valueOrNull;
      final valueOr = result.valueOr(99);
      final error = result.error;

      // Assert
      expect(isSuccess, isTrue);
      expect(isFailure, isFalse);
      expect(value, equals(5));
      expect(valueOrNull, equals(5));
      expect(valueOr, equals(5));
      expect(error, isNull);
    });

    test('failure should expose error and failure flags', () {
      // Arrange
      final ex = ConversionException(
        error: 'bad',
        context: <String, dynamic>{'method': 'test'},
      );
      final result = ConversionResult<int>.failure(ex);

      // Act
      final isSuccess = result.isSuccess;
      final isFailure = result.isFailure;
      final valueOrNull = result.valueOrNull;
      final valueOr = result.valueOr(123);
      final error = result.error;

      // Assert
      expect(isSuccess, isFalse);
      expect(isFailure, isTrue);
      expect(valueOrNull, isNull);
      expect(valueOr, equals(123));
      expect(error, equals(ex));
    });

    test('value should throw when the result is a failure', () {
      // Arrange
      final ex = ConversionException(
        error: 'bad',
        context: <String, dynamic>{'method': 'test'},
      );
      final result = ConversionResult<int>.failure(ex);

      // Act / Assert
      expect(() => result.value, throwsA(isA<ConversionException>()));
    });

    test('map should transform success values and preserve failures', () {
      // Arrange
      final success = ConversionResult.success(5);
      final failure = ConversionResult<int>.failure(
        ConversionException(
            error: 'bad', context: <String, dynamic>{'method': 'test'}),
      );

      // Act
      final mappedSuccess = success.map((v) => 'v=$v');
      final mappedFailure = failure.map((v) => 'v=$v');

      // Assert
      expect(mappedSuccess.isSuccess, isTrue);
      expect(mappedSuccess.value, equals('v=5'));

      expect(mappedFailure.isFailure, isTrue);
      expect(mappedFailure.error, isNotNull);
    });

    test('flatMap should chain success values and short-circuit failures', () {
      // Arrange
      final success = ConversionResult.success(5);
      final failure = ConversionResult<int>.failure(
        ConversionException(
            error: 'bad', context: <String, dynamic>{'method': 'test'}),
      );

      // Act
      final chainedSuccess =
          success.flatMap((v) => ConversionResult.success(v * 2));
      final chainedFailure =
          failure.flatMap((v) => ConversionResult.success(v * 2));

      // Assert
      expect(chainedSuccess.isSuccess, isTrue);
      expect(chainedSuccess.value, equals(10));

      expect(chainedFailure.isFailure, isTrue);
      expect(chainedFailure.error, isNotNull);
    });

    test('fold should return onSuccess for success and onFailure for failure',
        () {
      // Arrange
      final success = ConversionResult.success(5);
      final ex = ConversionException(
          error: 'bad', context: <String, dynamic>{'method': 'test'});
      final failure = ConversionResult<int>.failure(ex);

      // Act
      final successOut = success.fold(
        onSuccess: (v) => 'ok:$v',
        onFailure: (e) => 'err:${e.error}',
      );
      final failureOut = failure.fold(
        onSuccess: (v) => 'ok:$v',
        onFailure: (e) => 'err:${e.error}',
      );

      // Assert
      expect(successOut, equals('ok:5'));
      expect(failureOut, equals('err:bad'));
    });
  });
}
