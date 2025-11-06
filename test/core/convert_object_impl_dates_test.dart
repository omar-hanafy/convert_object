import 'package:convert_object/convert_object.dart'; // for ConversionException
import 'package:convert_object/src/core/convert_object_impl.dart';
import 'package:test/test.dart';

void main() {
  group('ConvertObjectImpl dates', () {
    test('ISO-8601 (UTC "Z") string input parses via toDateTime', () {
      final dt = ConvertObjectImpl.toDateTime('2024-06-11T14:15:00Z');
      expect(dt.isUtc, isTrue);
      expect(dt.toUtc().year, 2024);
      expect(dt.toUtc().month, 6);
      expect(dt.toUtc().day, 11);
      expect(dt.toUtc().hour, 14);
      expect(dt.toUtc().minute, 15);
      expect(dt.toUtc().second, 0);
    });

    test('HTTP-date via autoDetectFormat', () {
      const s = 'Tue, 11 Jun 2024 14:15:00 GMT';
      final dt = ConvertObjectImpl.toDateTime(
        s,
        autoDetectFormat: true,
        utc: true,
      );
      expect(dt.isUtc, isTrue);
      expect(dt.year, 2024);
      expect(dt.month, 6);
      expect(dt.day, 11);
      expect(dt.hour, 14);
      expect(dt.minute, 15);
    });

    test('Unix epoch seconds (numeric)', () {
      const secs = 1700000000; // 2023-11-14T22:13:20Z
      final dt = ConvertObjectImpl.toDateTime(secs, utc: true);
      expect(dt.isUtc, isTrue);
      expect(dt.year >= 2020, isTrue); // sanity
      // Exact check:
      final expected =
          DateTime.fromMillisecondsSinceEpoch(secs * 1000, isUtc: true);
      expect(dt, expected);
    });

    test('Unix epoch milliseconds (numeric)', () {
      const ms = 1700000000000; // 2023-11-14T22:13:20Z
      final dt = ConvertObjectImpl.toDateTime(ms, utc: true);
      expect(dt.isUtc, isTrue);
      final expected = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
      expect(dt, expected);
    });

    test('Explicit format parsing (dd/MM/yyyy HH:mm:ss)', () {
      const s = '11/06/2024 14:15:00';
      final dt = ConvertObjectImpl.toDateTime(
        s,
        format: 'dd/MM/yyyy HH:mm:ss',
        locale: 'en_GB',
        utc: true,
      );
      expect(dt.isUtc, isTrue);
      expect(dt.year, 2024);
      expect(dt.month, 6);
      expect(dt.day, 11);
      expect(dt.hour, 14);
      expect(dt.minute, 15);
    });

    test('Auto-detect ambiguous numeric by locale preference', () {
      const raw = '06/11/2024';
      // US prefers MM/dd → June 11, 2024
      final us = ConvertObjectImpl.toDateTime(
        raw,
        autoDetectFormat: true,
        locale: 'en_US',
      );
      expect(us.month, 6);
      expect(us.day, 11);

      // Non-US prefers dd/MM → 06 Nov 2024
      final gb = ConvertObjectImpl.toDateTime(
        raw,
        autoDetectFormat: true,
        locale: 'en_GB',
      );
      expect(gb.day, 6);
      expect(gb.month, 11);
    });

    test('Auto-detect time-only → today (local) with hour/minute preserved',
        () {
      final t = ConvertObjectImpl.toDateTime(
        '14:30',
        autoDetectFormat: true,
      );
      expect(t.hour, anyOf(14, 14)); // same hour in local
      expect(t.minute, 30);
      // Day is "today" (local) — we assert it's within +-1 day to avoid DST edges.
      final now = DateTime.now();
      final deltaDays =
          t.difference(DateTime(now.year, now.month, now.day)).inDays;
      expect(deltaDays.abs() <= 1, isTrue);
    });

    test(
        'Invalid string → tryToDateTime returns default or null; toDateTime throws',
        () {
      expect(ConvertObjectImpl.tryToDateTime('not-a-date'), isNull);
      final fallback = DateTime(2000);
      expect(ConvertObjectImpl.tryToDateTime('nope', defaultValue: fallback),
          fallback);
      expect(() => ConvertObjectImpl.toDateTime('nope'),
          throwsA(isA<ConversionException>()));
    });
  });
}
