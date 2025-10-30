import 'dart:math';

import 'package:convert_object/convert_object.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

final _rnd = Random(0xBEEFBEEF);

double _round(double x, int frac) {
  final p = pow(10, frac).toDouble();
  return (x * p).round() / p;
}

void main() {
  group('Property (numbers): formatted and plain parsing', () {
    test('plain strings from toString() round-trip via toNum', () {
      for (var i = 0; i < 600; i++) {
        // Mix ints and doubles
        final asDouble = _rnd.nextBool();
        if (asDouble) {
          final v = _round((_rnd.nextDouble() - 0.5) * 2e9, 6);
          final s = v.toString(); // includes scientific for large/small
          final parsed = ConvertObject.toNum(s);
          expect(parsed, closeTo(v, 1e-9),
              reason: 'Failed to parse plain double "$s"');
        } else {
          final v =
              (_rnd.nextDouble() * 1e12).round() * (_rnd.nextBool() ? -1 : 1);
          final s = v.toString();
          final parsed = ConvertObject.toNum(s);
          expect(parsed, v, reason: 'Failed to parse plain int "$s"');
        }
      }
    });

    test('formatted "en_US" #,##0.### with grouping', () {
      const pattern = '#,##0.###';
      const locale = 'en_US';
      final f = NumberFormat(pattern, locale);

      for (var i = 0; i < 400; i++) {
        final v = _round((_rnd.nextDouble() - 0.5) * 1e8, 3);
        final s = f.format(v);
        final parsed = ConvertObject.toNum(
          s,
          format: pattern,
          locale: locale,
        );
        expect(parsed, closeTo(v, 1e-9), reason: 'Failed to parse "$s"');
      }
    });

    test('NBSP and spaces are ignored by toNum()', () {
      for (var i = 0; i < 200; i++) {
        final v = _round((_rnd.nextDouble()) * 1e6, 3);
        var s = v.toString(); // e.g., 12345.678
        // Inject random spaces and NBSPs
        final insertions = 1 + _rnd.nextInt(5);
        for (var j = 0; j < insertions && s.length > 1; j++) {
          final pos = 1 + _rnd.nextInt(s.length - 1);
          final ch = _rnd.nextBool() ? ' ' : '\u00A0';
          s = s.substring(0, pos) + ch + s.substring(pos);
        }
        final parsed = ConvertObject.toNum(s);
        expect(parsed, closeTo(v, 1e-9), reason: 'Failed to parse "$s"');
      }
    });
  });
}
