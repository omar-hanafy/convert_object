import 'dart:math';

import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

final _rnd = Random(0xDEADBEEF);

String _messyNumberString(num value) {
  // Base canonical string with '.' decimal (num.parse can handle it).
  var s = value.toString();

  // Randomly insert spaces/NBSPs/commas between digits (avoiding just after '-').
  String insertNoise(String input) {
    final run = input.split('');
    final out = StringBuffer();

    for (var i = 0; i < run.length; i++) {
      out.write(run[i]);
      final prev = i > 0 ? run[i - 1] : '';
      final curr = run[i];

      // After a digit, maybe inject a separator (space, NBSP, comma) 30% of the time.
      final isDigit = RegExp(r'\d').hasMatch(curr);
      if (isDigit && prev != '-' && _rnd.nextInt(10) < 3) {
        out.write([' ', '\u00A0', ','][_rnd.nextInt(3)]);
      }
    }
    return out.toString();
  }

  // Randomly prepend a sign
  if (_rnd.nextBool() && s[0] != '-') {
    if (_rnd.nextBool()) {
      s = '+$s';
    }
  }

  // Randomly add noise a few times
  final times = 1 + _rnd.nextInt(3);
  for (var i = 0; i < times; i++) {
    s = insertNoise(s);
  }
  return s;
}

double _randDouble() {
  // Keep magnitude moderate; include exponents occasionally
  final base = (_rnd.nextDouble() - 0.5) * 1e8;
  return base;
}

int _randInt() =>
    (_rnd.nextDouble() * 1e12).round() * (_rnd.nextBool() ? -1 : 1);

void main() {
  group('Fuzz (numbers): whitespace/nbsp/commas cleaning', () {
    test('doubles', () {
      for (var i = 0; i < 600; i++) {
        final v = _randDouble();
        final messy = _messyNumberString(v);
        final parsed = ConvertObject.toNum(messy);
        // toString for doubles can be lossy; allow small tolerance
        expect(parsed, closeTo(v, 1e-6), reason: 'Failed parsing "$messy"');
      }
    });

    test('ints', () {
      for (var i = 0; i < 600; i++) {
        final v = _randInt();
        final messy = _messyNumberString(v);
        final parsed = ConvertObject.toNum(messy);
        expect(parsed, v, reason: 'Failed parsing "$messy"');
      }
    });
  });
}
