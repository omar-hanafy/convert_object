import 'package:convert_object/convert_object.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

void main() {
  test(
    'uses newly initialized date symbols after a formatter fell back',
    () async {
      const format = 'MMMM d, yyyy';
      final expected = DateTime(2025, 3, 5);

      await Intl.withLocale('en_US', () async {
        expect('March 5, 2025'.toDateFormatted(format, 'fr_FR'), expected);
        await initializeDateFormatting();
        expect('mars 5, 2025'.toDateFormatted(format, 'fr_FR'), expected);
      });
    },
  );
}
