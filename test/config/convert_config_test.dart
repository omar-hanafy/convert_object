import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

void main() {
  late ConvertConfig previousConfig;

  setUp(() {
    previousConfig = Convert.configure(const ConvertConfig());
  });

  tearDown(() {
    Convert.configure(previousConfig);
  });

  test('number defaults from config are applied', () {
    Convert.configure(const ConvertConfig(
      numbers: NumberOptions(
        defaultFormat: '#,##0.##',
        defaultLocale: 'de_DE',
      ),
    ));

    final parsed = Convert.toNum('1.234,56');
    expect(parsed, closeTo(1234.56, 1e-9));
  });

  test('date defaults and UTC flag are read from config', () {
    Convert.configure(const ConvertConfig(
      dates: DateOptions(
        defaultFormat: 'dd/MM/yyyy',
        utc: true,
      ),
    ));

    final dt = Convert.toDateTime('31/12/2024');
    expect(dt.isUtc, isTrue);
    expect(dt.year, 2024);
    expect(dt.month, 12);
    expect(dt.day, 31);
  });

  test('bool literals can be customised via config', () {
    Convert.configure(const ConvertConfig(
      bools: BoolOptions(truthy: {'si'}, falsy: {'no'}),
    ));

    expect(Convert.toBool('si'), isTrue);
    expect(Convert.toBool('no'), isFalse);
    expect(Convert.tryToBool('maybe'), isNull);
  });

  test('exception hook is invoked whenever a conversion throws', () {
    var count = 0;
    Convert.configure(Convert.config.copyWith(
      onException: (ex) => count++,
    ));

    expect(() => Convert.toInt('oops'), throwsA(isA<ConversionException>()));
    expect(count, 1);
  });

  test('type registry powers custom conversions', () {
    Convert.configure(Convert.config.copyWith(
      registry: Convert.config.registry.register<Duration>(
        (value) => Duration(seconds: Convert.toInt(value)),
      ),
    ));

    final duration = Convert.toType<Duration>('5');
    expect(duration, const Duration(seconds: 5));
  });

  test('runScopedConfig applies overrides without touching global config', () {
    Convert.configure(const ConvertConfig(
      dates: DateOptions(defaultFormat: 'MM/dd/yyyy'),
    ));

    final outside = Convert.toDateTime('12/31/2024');
    expect(outside.isUtc, isFalse);

    final zoned = Convert.runScopedConfig(
      Convert.config.copyWith(
        dates: Convert.config.dates.copyWith(utc: true),
      ),
      () => Convert.toDateTime('12/31/2024'),
    );

    expect(zoned.isUtc, isTrue);
    // Verify global config remained unchanged.
    final after = Convert.toDateTime('12/31/2024');
    expect(after.isUtc, isFalse);
  });
}
