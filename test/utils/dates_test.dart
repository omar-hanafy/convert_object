import 'package:convert_object/src/utils/dates.dart';
import 'package:test/test.dart';

void main() {
  group('DateParsingStringX', () {
    test('toDateTime parses ISO8601 Zulu', () {
      final dt = '2024-06-11T14:15:00Z'.toDateTime();
      expect(dt.isUtc, isTrue);
      expect(dt, DateTime.utc(2024, 6, 11, 14, 15));
    });

    test('tryToDateTime returns null on invalid', () {
      expect('not a date'.tryToDateTime(), isNull);
    });

    test('toDateFormatted parses with format and utc:true', () {
      const s = '11/06/2024 14:15:00';
      final dt = s.toDateFormatted('dd/MM/yyyy HH:mm:ss', null, utc: true);
      expect(dt.isUtc, isTrue);
      expect(dt, DateTime.utc(2024, 6, 11, 14, 15));
    });

    test('tryToDateFormatted returns null on mismatch', () {
      final dt = '11-06-2024'.tryToDateFormatted('yyyy/MM/dd', null);
      expect(dt, isNull);
    });

    test('toDateAutoFormat parses HTTP-date (IMF-fixdate)', () {
      final s = 'Tue, 11 Jun 2024 14:15:00 GMT';
      final dt = s.toDateAutoFormat(utc: true);
      expect(dt.isUtc, isTrue);
      expect(dt, DateTime.utc(2024, 6, 11, 14, 15));
    });

    test('toDateAutoFormat parses Unix epoch seconds', () {
      const secs = '1700000000'; // seconds
      final expected =
          DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000, isUtc: true);
      final dt = secs.toDateAutoFormat(utc: true);
      expect(dt.isUtc, isTrue);
      expect(dt, expected);
    });

    test('toDateAutoFormat parses Unix epoch milliseconds', () {
      const ms = '1700000000000'; // milliseconds
      final expected =
          DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);
      final dt = ms.toDateAutoFormat(utc: true);
      expect(dt.isUtc, isTrue);
      expect(dt, expected);
    });

    test(
        'toDateAutoFormat parses unambiguous yyyy-MM-dd HH:mm:ss as local time',
        () {
      final dt = '2024-06-11 14:15:00'.toDateAutoFormat();
      // Parsed as local time (by design); we check components.
      expect(dt.isUtc, isFalse);
      expect([dt.year, dt.month, dt.day, dt.hour, dt.minute],
          [2024, 6, 11, 14, 15]);
    });

    test('tryToDateAutoFormat returns null on invalid', () {
      final dt = ''.tryToDateAutoFormat();
      expect(dt, isNull);
    });
  });
}
