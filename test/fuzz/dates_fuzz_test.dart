import 'dart:math';

import 'package:convert_object/convert_object.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

final _rnd = Random(1234567);

int _randInt(int min, int max) => min + _rnd.nextInt(max - min + 1);

DateTime _randUtc() {
  final start = DateTime(1970, 1, 1);
  final end = DateTime(2100, 1, 1);
  final spanDays = end.difference(start).inDays;
  final localDate = start.add(Duration(days: _rnd.nextInt(spanDays)));
  return localDate.toUtc();
}

int _expectedMillisForPattern(String fmt, String text, {required String locale}) {
  switch (fmt) {
    case 'yyyyMMdd':
      return _dateFromDigits(text).millisecondsSinceEpoch;
    case 'yyyyMMdd_HHmm':
    case 'yyyyMMdd_HHmmss':
      final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
      return _dateFromDigits(digits).millisecondsSinceEpoch;
    case 'yyyyMMddHHmmss':
      return _dateFromDigits(text).millisecondsSinceEpoch;
    default:
      return DateFormat(fmt, locale).parse(text).millisecondsSinceEpoch;
  }
}

DateTime _dateFromDigits(String digits) {
  if (!(digits.length == 8 || digits.length == 12 || digits.length == 14)) {
    throw ArgumentError.value(digits, 'digits', 'Unexpected length for compact date');
  }
  final year = int.parse(digits.substring(0, 4));
  final month = int.parse(digits.substring(4, 6));
  final day = int.parse(digits.substring(6, 8));
  var hour = 0;
  var minute = 0;
  var second = 0;
  if (digits.length >= 12) {
    hour = int.parse(digits.substring(8, 10));
    minute = int.parse(digits.substring(10, 12));
  }
  if (digits.length == 14) {
    second = int.parse(digits.substring(12, 14));
  }
  return DateTime(year, month, day, hour, minute, second);
}

void main() {
  group('Fuzz (dates): auto-detect formats', () {
    test('unambiguous patterns (en_US)', () {
      final patterns = <String>[
        'yyyy-MM-dd HH:mm:ss',
        'yyyyMMdd_HHmm',
        'yyyyMMdd_HHmmss',
        'yyyyMMddHHmmss',
        'yyyyMMdd',
        "EEEE, MMMM d, yyyy 'at' h:mm a",
        'EEEE, MMMM d, yyyy',
        'MMMM d, yyyy h:mm a',
        'MMMM d, yyyy',
        'd MMMM yyyy HH:mm:ss',
        'd MMMM yyyy',
      ];

      for (final fmt in patterns) {
        final df = DateFormat(fmt, 'en_US');
        for (var i = 0; i < 40; i++) {
          final dt = _randUtc();
          final s = df.format(dt.toLocal()); // DateFormat defaults to local
          final parsed = ConvertObject.toDateTime(
            s,
            autoDetectFormat: true,
            locale: 'en_US',
          );
          final expectMs =
              _expectedMillisForPattern(fmt, s, locale: 'en_US');
          expect(parsed.millisecondsSinceEpoch, expectMs,
              reason: 'fmt=$fmt, s="$s"');
        }
      }
    });

    test('ambiguous numeric patterns resolved by locale (en_US)', () {
      final patterns = <String>[
        'MM/dd/yyyy',
        'MM/dd/yyyy HH:mm:ss',
      ];
      for (final fmt in patterns) {
        final df = DateFormat(fmt, 'en_US');
        for (var i = 0; i < 40; i++) {
          final dt = _randUtc().toLocal();
          final s = df.format(dt);
          final parsed = ConvertObject.toDateTime(
            s,
            autoDetectFormat: true,
            locale: 'en_US', // ensures MM/dd preference
          );
          final expectMs = df.parse(s).millisecondsSinceEpoch;
          expect(parsed.millisecondsSinceEpoch, expectMs,
              reason: 'fmt=$fmt, s="$s"');
        }
      }
    });

    test('HTTP-date (RFC7231 IMF-fixdate): "EEE, dd MMM yyyy HH:mm:ss GMT"',
        () {
      final df = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US');
      for (var i = 0; i < 80; i++) {
        final dtUtc = _randUtc();
        final s = df.format(dtUtc); // string is GMT (UTC)
        final parsed = ConvertObject.toDateTime(
          s,
          autoDetectFormat: true,
          locale: 'en_US',
        );
        // Parser returns a UTC instant; compare instants
        expect(parsed.millisecondsSinceEpoch, dtUtc.millisecondsSinceEpoch,
            reason: 's="$s"');
      }
    });

    test('Unix epoch strings (10 digits = sec, 13 digits = ms)', () {
      for (var i = 0; i < 100; i++) {
        // seconds in ~[2000..2030]
        final sec =
            946684800 + _rnd.nextInt(946684800); // 2000-01-01 .. 2030-ish
        final ms = sec * 1000;

        final sSec = sec.toString();
        final sMs = ms.toString();

        final pSec = ConvertObject.toDateTime(
          sSec,
          autoDetectFormat: true,
          locale: 'en_US',
        );
        final pMs = ConvertObject.toDateTime(
          sMs,
          autoDetectFormat: true,
          locale: 'en_US',
        );
        expect(pSec.millisecondsSinceEpoch, ms, reason: 'sec="$sSec"');
        expect(pMs.millisecondsSinceEpoch, ms, reason: 'ms="$sMs"');
      }
    });

    test('Numeric epoch (int) ms vs sec detection is plausible', () {
      for (var i = 0; i < 100; i++) {
        // around year 2000 in milliseconds, and the corresponding seconds
        final dt = DateTime.utc(
          _randInt(1995, 2005),
          _randInt(1, 12),
          _randInt(1, 28),
          _randInt(0, 23),
          _randInt(0, 59),
          _randInt(0, 59),
        );
        final ms = dt.millisecondsSinceEpoch;
        final sec = (ms ~/ 1000);

        final fromMs = ConvertObject.toDateTime(ms);
        final fromSec = ConvertObject.toDateTime(sec);

        expect(fromMs.millisecondsSinceEpoch, ms, reason: 'from ms failed');
        expect(fromSec.millisecondsSinceEpoch, ms, reason: 'from sec failed');
      }
    });
  });
}
