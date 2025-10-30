import 'package:convert_object/convert_object.dart'; // for ConversionException
import 'package:convert_object/src/core/convert_object_impl.dart';
import 'package:test/test.dart';

void main() {
  group('ConvertObjectImpl numbers', () {
    test('toInt basic parsing', () {
      expect(ConvertObjectImpl.toInt('42'), 42);
      expect(ConvertObjectImpl.toInt(41.9), 41); // truncation
      expect(ConvertObjectImpl.toInt(0), 0);
    });

    test('tryToInt returns default on failure', () {
      expect(ConvertObjectImpl.tryToInt('not a number'), isNull);
      expect(ConvertObjectImpl.tryToInt('nope', defaultValue: 7), 7);
    });

    test('toDouble / tryToDouble basic', () {
      expect(ConvertObjectImpl.toDouble('3.5'), closeTo(3.5, 1e-9));
      expect(ConvertObjectImpl.tryToDouble('x'), isNull);
      expect(ConvertObjectImpl.tryToDouble('x', defaultValue: 1.23),
          closeTo(1.23, 1e-9));
    });

    test('toNum with explicit format/locale (en_US thousand separators)', () {
      // parse "12,345.67" using a format string
      const s = '12,345.67';
      final n = ConvertObjectImpl.toNum(
        s,
        format: '#,##0.##',
        locale: 'en_US',
      );
      expect(n, closeTo(12345.67, 1e-9));
    });

    test('toInt with format/locale (en_US)', () {
      expect(
        ConvertObjectImpl.toInt('1,234', format: '#,##0', locale: 'en_US'),
        1234,
      );
    });

    test('toNum plain parsing', () {
      expect(ConvertObjectImpl.toNum('1234'), 1234);
      expect(ConvertObjectImpl.toNum(1234), 1234);
      expect(ConvertObjectImpl.toNum(12.75), closeTo(12.75, 1e-9));
    });

    test('BigInt conversions', () {
      expect(ConvertObjectImpl.toBigInt('9007199254740993').toString(),
          '9007199254740993');
      expect(ConvertObjectImpl.toBigInt(10.0), BigInt.from(10));
      expect(ConvertObjectImpl.tryToBigInt('x', defaultValue: BigInt.from(5)),
          BigInt.from(5));
    });

    test('toInt failure throws ConversionException when no default', () {
      expect(
        () => ConvertObjectImpl.toInt('not-an-int'),
        throwsA(isA<ConversionException>()),
      );
    });
  });
}
