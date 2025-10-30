import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  group('ConversionResult<T>', () {
    test('success path basics', () {
      final r = ConversionResult.success(42);
      expect(r.isSuccess, isTrue);
      expect(r.isFailure, isFalse);
      expect(r.value, 42);
      expect(r.valueOrNull, 42);
      expect(r.valueOr(7), 42);
      expect(r.error, isNull);
    });

    test('failure path basics', () {
      final e = ConversionException(error: 'boom', context: {'k': 'v'});
      final r = ConversionResult<Object?>.failure(e);
      expect(r.isFailure, isTrue);
      expect(r.isSuccess, isFalse);
      expect(() => r.value, throwsA(isA<ConversionException>()));
      expect(r.valueOrNull, isNull);
      expect(r.valueOr(9), 9);
      expect(r.error, same(e)); // identity
    });

    test('map keeps success and transforms value', () {
      final r = ConversionResult.success(3).map((v) => v * 10);
      expect(r.isSuccess, isTrue);
      expect(r.value, 30);
    });

    test('map keeps failure as-is', () {
      final e = ConversionException(error: 'bad', context: {});
      final r = ConversionResult<int>.failure(e).map((v) => v * 10);
      expect(r.isFailure, isTrue);
      expect(r.error, same(e));
    });

    test('flatMap chains on success', () {
      final r = ConversionResult.success(2)
          .flatMap((v) => ConversionResult.success(v + 5))
          .flatMap((v) => ConversionResult.success(v * 3));
      expect(r.isSuccess, isTrue);
      expect(r.value, 21);
    });

    test('flatMap short-circuits on failure', () {
      final e = ConversionException(error: 'x', context: {});
      final r = ConversionResult.success(2)
          .flatMap((_) => ConversionResult<int>.failure(e))
          .flatMap((_) => ConversionResult.success(999)); // not executed
      expect(r.isFailure, isTrue);
      expect(r.error, same(e));
    });

    test('fold dispatches correctly', () {
      final ok = ConversionResult.success('ok').fold(
        onSuccess: (v) => 'S:$v',
        onFailure: (_) => 'F',
      );
      final fail = ConversionResult<String>.failure(
        ConversionException(error: 'no', context: {}),
      ).fold(
        onSuccess: (v) => 'S:$v',
        onFailure: (_) => 'F',
      );
      expect(ok, 'S:ok');
      expect(fail, 'F');
    });
  });
}
