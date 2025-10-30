import 'dart:math';

import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

/// Deterministic RNG for property-like tests.
final _rnd = Random(0xC0FFEE);

String _randAscii([int min = 1, int max = 24]) {
  final len = min + _rnd.nextInt(max - min + 1);
  final sb = StringBuffer();
  for (var i = 0; i < len; i++) {
    // Letters, digits, and a few common punctuation chars:
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_- .@';
    sb.write(chars[_rnd.nextInt(chars.length)]);
  }
  return sb.toString();
}

BigInt _randBigInt() {
  final digits = 1 + _rnd.nextInt(40); // up to ~40 digits
  final sb = StringBuffer();
  if (_rnd.nextBool()) sb.write('-');
  sb.write(1 + _rnd.nextInt(9));
  for (var i = 1; i < digits; i++) {
    sb.write(_rnd.nextInt(10));
  }
  return BigInt.parse(sb.toString());
}

DateTime _randDateTime() {
  // Between 1970-01-01 and 2100-01-01
  final startSec = DateTime.utc(1970).millisecondsSinceEpoch ~/ 1000;
  final endSec = DateTime.utc(2100).millisecondsSinceEpoch ~/ 1000;
  final spanSec = endSec - startSec;
  final secOffset = _rnd.nextInt(spanSec);
  final ms = (startSec + secOffset) * 1000;
  // Randomly UTC or local
  return _rnd.nextBool()
      ? DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true)
      : DateTime.fromMillisecondsSinceEpoch(ms);
}

Uri _randUri() {
  final host = '${_randAscii(3, 8).toLowerCase()}.example.com';
  final path = '/${_randAscii(3, 10)}';
  final q = 'q=${_randAscii(2, 6)}&n=${_rnd.nextInt(1000)}';
  return Uri.parse('https://$host$path?$q');
}

List<dynamic> _randList() => List.generate(
      1 + _rnd.nextInt(6),
      (_) => switch (_rnd.nextInt(6)) {
        0 => _rnd.nextInt(1 << 20),
        1 => _rnd.nextDouble() * (_rnd.nextBool() ? -1 : 1),
        2 => _rnd.nextBool(),
        3 => _randAscii(),
        4 => _randUri(),
        _ => _randDateTime(),
      },
    );

Map<String, dynamic> _randMap() {
  final m = <String, dynamic>{};
  final n = 1 + _rnd.nextInt(6);
  for (var i = 0; i < n; i++) {
    m[_randAscii(1, 6)] = switch (_rnd.nextInt(6)) {
      0 => _rnd.nextInt(1 << 20),
      1 => _rnd.nextDouble() * (_rnd.nextBool() ? -1 : 1),
      2 => _rnd.nextBool(),
      3 => _randAscii(),
      4 => _randList(),
      _ => _randMap(), // shallow-ish
    };
  }
  return m;
}

void main() {
  group('Property (text roundtrip): toText/tryToText reflect .toString()', () {
    test('random non-null values', () {
      for (var i = 0; i < 500; i++) {
        final value = switch (_rnd.nextInt(9)) {
          0 => _rnd.nextInt(1 << 31),
          1 => _rnd.nextDouble() * (_rnd.nextBool() ? -1 : 1),
          2 => _rnd.nextBool(),
          3 => _randBigInt(),
          4 => _randAscii(),
          5 => _randDateTime(),
          6 => _randUri(),
          7 => _randList(),
          _ => _randMap(),
        };

        final expected = value.toString();
        // toText must equal .toString()
        expect(ConvertObject.toText(value), expected,
            reason: 'Mismatch for value: $value (${value.runtimeType})');

        // tryToText must not throw and matches .toString()
        expect(ConvertObject.tryToText(value), expected);
      }
    });

    test('null behavior', () {
      expect(ConvertObject.tryToText(null), isNull);
      expect(ConvertObject.toText(null, defaultValue: 'd'), 'd');
      expect(() => ConvertObject.toText(null),
          throwsA(isA<ConversionException>()));
    });
  });
}
