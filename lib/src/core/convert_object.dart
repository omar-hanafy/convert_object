import 'package:convert_object/src/config/convert_config.dart';
import 'package:convert_object/src/core/convert_object_impl.dart';
import 'package:meta/meta.dart';

/// Signature for transforming a single element while converting collections.
typedef ElementConverter<T> = T Function(Object? element);

/// Backward-compatible static facade that mirrors the original ConvertObject API.
///
/// Use this class when you need stateless conversions that still honor the
/// current [ConvertConfig.effective] settings.
///
/// ### Shared Behavior
/// - `mapKey` and `listIndex` let you select nested data before conversion.
/// - `defaultValue` short-circuits failures for the `toX` methods.
/// - `tryToX` variants never throw and return `null` or `defaultValue`.
/// - Collection conversions decode JSON strings when possible and then
///   convert elements using the same conversion rules.
///
/// For fluent, stateful conversion chains, prefer `value.convert` from
/// `ConvertObjectExtension`.
abstract class Convert {
  /// Returns the effective configuration for the current zone.
  static ConvertConfig get config => ConvertConfig.effective;

  /// Replaces the global configuration and returns the previous instance.
  static ConvertConfig configure(ConvertConfig config) =>
      ConvertConfig.configure(config);

  /// Updates the global configuration using [updater].
  static void updateConfig(
    ConvertConfig Function(ConvertConfig current) updater,
  ) => ConvertConfig.update(updater);

  /// Runs [body] with [overrides] applied on top of the current effective config.
  static T runScopedConfig<T>(ConvertConfig overrides, T Function() body) =>
      ConvertConfig.runScoped(overrides, body);

  // Strings
  /// Converts [object] to [String], optionally selecting `mapKey` or
  /// `listIndex` first.
  ///
  /// Uses `converter` when provided, otherwise falls back to
  /// `Object.toString()`. Throws `ConversionException` when no value can be
  /// produced and `defaultValue` is `null`.
  static String string(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? defaultValue,
    ElementConverter<String>? converter,
  }) => ConvertObjectImpl.string(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue,
    converter: converter,
  );

  /// Converts [object] to [String] without throwing.
  ///
  /// Returns `defaultValue` when conversion fails, or `null` when both the
  /// input and `defaultValue` are `null`.
  static String? tryToString(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? defaultValue,
    ElementConverter<String>? converter,
  }) => ConvertObjectImpl.tryToString(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue,
    converter: converter,
  );

  // Numbers
  /// Converts [object] to [num], honoring [NumberOptions] defaults.
  ///
  /// If `format` is provided or [NumberOptions.defaultFormat] is set, formatted
  /// parsing is attempted in the order defined by
  /// [NumberOptions.tryFormattedFirst], then falls back to plain parsing.
  /// Throws `ConversionException` when parsing fails and `defaultValue` is
  /// `null`.
  static num toNum(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    num? defaultValue,
    ElementConverter<num>? converter,
  }) => ConvertObjectImpl.toNum(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    defaultValue: defaultValue,
    converter: converter,
  );

  /// Converts [object] to [num] without throwing.
  ///
  /// Returns `defaultValue` or `null` when parsing fails.
  static num? tryToNum(
    dynamic object, {
    dynamic mapKey,
    String? format,
    String? locale,
    int? listIndex,
    num? defaultValue,
    ElementConverter<num>? converter,
  }) => ConvertObjectImpl.tryToNum(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    defaultValue: defaultValue,
    converter: converter,
  );

  /// Converts [object] to [int], applying optional locale-aware formatting.
  ///
  /// Numeric inputs are truncated with `toInt()`. String inputs use
  /// [NumberOptions] defaults unless overridden by `format` or `locale`.
  /// Throws `ConversionException` when parsing fails and `defaultValue` is
  /// `null`.
  static int toInt(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    int? defaultValue,
    ElementConverter<int>? converter,
  }) => ConvertObjectImpl.toInt(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    defaultValue: defaultValue,
    converter: converter,
  );

  /// Converts [object] to [int] without throwing.
  ///
  /// Returns `defaultValue` or `null` if parsing cannot succeed.
  static int? tryToInt(
    dynamic object, {
    dynamic mapKey,
    String? format,
    String? locale,
    int? listIndex,
    int? defaultValue,
    ElementConverter<int>? converter,
  }) => ConvertObjectImpl.tryToInt(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    defaultValue: defaultValue,
    converter: converter,
  );

  /// Converts [object] to [double], supporting formatted numeric strings.
  ///
  /// Numeric inputs are converted with `toDouble()`. String inputs use
  /// [NumberOptions] defaults unless overridden by `format` or `locale`.
  /// Throws `ConversionException` when parsing fails and `defaultValue` is
  /// `null`.
  static double toDouble(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    double? defaultValue,
    ElementConverter<double>? converter,
  }) => ConvertObjectImpl.toDouble(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    defaultValue: defaultValue,
    converter: converter,
  );

  /// Converts [object] to [double] without throwing.
  ///
  /// Returns `defaultValue` or `null` on parsing failure.
  static double? tryToDouble(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    double? defaultValue,
    ElementConverter<double>? converter,
  }) => ConvertObjectImpl.tryToDouble(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    defaultValue: defaultValue,
    converter: converter,
  );

  /// Converts [object] to [BigInt], accepting [BigInt], [num], or numeric
  /// strings.
  ///
  /// Throws `ConversionException` when parsing fails and `defaultValue` is
  /// `null`.
  static BigInt toBigInt(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    BigInt? defaultValue,
    ElementConverter<BigInt>? converter,
  }) => ConvertObjectImpl.toBigInt(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue,
    converter: converter,
  );

  /// Converts [object] to [BigInt] without throwing.
  ///
  /// Returns `defaultValue` or `null` when conversion is not possible.
  static BigInt? tryToBigInt(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    BigInt? defaultValue,
    ElementConverter<BigInt>? converter,
  }) => ConvertObjectImpl.tryToBigInt(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue,
    converter: converter,
  );

  /// Converts [object] to [bool] using [BoolOptions] from [ConvertConfig].
  ///
  /// This conversion never throws. When parsing fails, it returns
  /// `defaultValue` or `false` when `defaultValue` is `null`.
  static bool toBool(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    bool? defaultValue,
    ElementConverter<bool>? converter,
  }) => ConvertObjectImpl.toBool(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue,
    converter: converter,
  );

  /// Converts [object] to [bool] without throwing.
  ///
  /// Returns `defaultValue` or `null` when coercion fails.
  static bool? tryToBool(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    bool? defaultValue,
    ElementConverter<bool>? converter,
  }) => ConvertObjectImpl.tryToBool(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue,
    converter: converter,
  );

  /// Converts [object] to a [DateTime], respecting [DateOptions] defaults.
  ///
  /// Calendar-like inputs (e.g. `yyyyMMdd`, `MM/dd/yyyy`, long month names)
  /// return a value in the local time zone unless `utc` is `true`. Instant
  /// inputs (ISO strings with offsets, HTTP dates, Unix epochs) preserve their
  /// UTC meaning but are converted back to local time if `utc` is `false`.
  ///
  /// `format`, `locale`, and flags override [DateOptions] for this call.
  /// Numeric inputs are treated as seconds or milliseconds since epoch.
  static DateTime toDateTime(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    bool autoDetectFormat = false,
    bool useCurrentLocale = false,
    bool utc = false,
    DateTime? defaultValue,
    ElementConverter<DateTime>? converter,
  }) => ConvertObjectImpl.toDateTime(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    autoDetectFormat: autoDetectFormat,
    useCurrentLocale: useCurrentLocale,
    utc: utc,
    defaultValue: defaultValue,
    converter: converter,
  );

  /// Like [toDateTime] but never throws.
  ///
  /// Returns `defaultValue` when provided, or `null` when conversion fails.
  static DateTime? tryToDateTime(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    bool autoDetectFormat = false,
    bool useCurrentLocale = false,
    bool utc = false,
    DateTime? defaultValue,
    ElementConverter<DateTime>? converter,
  }) => ConvertObjectImpl.tryToDateTime(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    autoDetectFormat: autoDetectFormat,
    useCurrentLocale: useCurrentLocale,
    utc: utc,
    defaultValue: defaultValue,
    converter: converter,
  );

  /// Converts [object] to [Uri], honoring [UriOptions] from [ConvertConfig].
  ///
  /// Email addresses and phone numbers are coerced to `mailto:` and `tel:`
  /// URIs. Throws `ConversionException` when parsing fails and `defaultValue`
  /// is `null`.
  static Uri toUri(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Uri? defaultValue,
    ElementConverter<Uri>? converter,
  }) => ConvertObjectImpl.toUri(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue,
    converter: converter,
  );

  /// Converts [object] to [Uri] without throwing.
  ///
  /// Returns `defaultValue` or `null` when parsing fails.
  static Uri? tryToUri(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Uri? defaultValue,
    ElementConverter<Uri>? converter,
  }) => ConvertObjectImpl.tryToUri(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue,
    converter: converter,
  );

  /// Converts [object] to a strongly-typed [Map], optionally transforming keys
  /// and values with `keyConverter` and `valueConverter`.
  ///
  /// JSON strings are decoded before conversion. Throws `ConversionException`
  /// when mapping fails and `defaultValue` is `null`.
  static Map<K, V> toMap<K, V>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Map<K, V>? defaultValue,
    ElementConverter<K>? keyConverter,
    ElementConverter<V>? valueConverter,
  }) => ConvertObjectImpl.toMap<K, V>(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue,
    keyConverter: keyConverter,
    valueConverter: valueConverter,
  );

  /// Converts [object] to [Map] without throwing.
  ///
  /// Returns `defaultValue` or `null` when conversion fails.
  static Map<K, V>? tryToMap<K, V>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Map<K, V>? defaultValue,
    ElementConverter<K>? keyConverter,
    ElementConverter<V>? valueConverter,
  }) => ConvertObjectImpl.tryToMap<K, V>(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue,
    keyConverter: keyConverter,
    valueConverter: valueConverter,
  );

  /// Converts [object] to [Set], applying `elementConverter` to each entry.
  ///
  /// JSON strings are decoded before conversion. Single values are wrapped
  /// into a one-element set, and map inputs use their values. Throws
  /// `ConversionException` with element context when conversion fails and
  /// `defaultValue` is `null`.
  static Set<T> toSet<T>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Set<T>? defaultValue,
    ElementConverter<T>? elementConverter,
  }) => ConvertObjectImpl.toSet<T>(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue,
    elementConverter: elementConverter,
  );

  /// Converts [object] to [Set] without throwing.
  ///
  /// Returns `defaultValue` or `null` when coercion is not possible.
  static Set<T>? tryToSet<T>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Set<T>? defaultValue,
    ElementConverter<T>? elementConverter,
  }) => ConvertObjectImpl.tryToSet<T>(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue,
    elementConverter: elementConverter,
  );

  /// Converts [object] to [List], optionally mapping each element through
  /// `elementConverter`.
  ///
  /// JSON strings are decoded before conversion. Single values are wrapped
  /// into a one-element list, and sets or maps are converted to their values.
  /// Throws `ConversionException` with element context when conversion fails
  /// and `defaultValue` is `null`.
  static List<T> toList<T>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    List<T>? defaultValue,
    ElementConverter<T>? elementConverter,
  }) => ConvertObjectImpl.toList<T>(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue,
    elementConverter: elementConverter,
  );

  /// Converts [object] to [List] without throwing.
  ///
  /// Returns `defaultValue` or `null` when conversion fails.
  static List<T>? tryToList<T>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    List<T>? defaultValue,
    ElementConverter<T>? elementConverter,
  }) => ConvertObjectImpl.tryToList<T>(
    object,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue,
    elementConverter: elementConverter,
  );

  /// Converts [object] to an enum using the supplied `parser`.
  ///
  /// `debugInfo` is merged into the failure context. Throws
  /// `ConversionException` when parsing fails and `defaultValue` is `null`.
  static T toEnum<T extends Enum>(
    dynamic object, {
    required T Function(dynamic) parser,
    dynamic mapKey,
    int? listIndex,
    T? defaultValue,
    Map<String, dynamic>? debugInfo,
  }) => ConvertObjectImpl.toEnum<T>(
    object,
    parser: parser,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue,
    debugInfo: debugInfo,
  );

  /// Converts [object] to an enum using `parser` without throwing.
  ///
  /// Returns `defaultValue` or `null` when parsing fails.
  static T? tryToEnum<T extends Enum>(
    dynamic object, {
    required T Function(dynamic) parser,
    dynamic mapKey,
    int? listIndex,
    T? defaultValue,
    Map<String, dynamic>? debugInfo,
  }) => ConvertObjectImpl.tryToEnum<T>(
    object,
    parser: parser,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue,
    debugInfo: debugInfo,
  );

  // Top-level generic

  /// Converts [object] to the requested type [T].
  ///
  /// Custom parsers from [TypeRegistry] in [ConvertConfig] are tried first,
  /// then built-in conversions. Throws `ConversionException` when conversion
  /// fails or when [T] is unsupported.
  static T toType<T>(dynamic object) => ConvertObjectImpl.toType<T>(object);

  /// Converts [object] to type [T] without throwing.
  ///
  /// Returns `null` when conversion is unsuccessful or [T] is unsupported.
  static T? tryToType<T>(dynamic object) =>
      ConvertObjectImpl.tryToType<T>(object);

  // Testing helper alias
  /// Builds a diagnostic map describing a conversion attempt; mainly used by
  /// tests and error reporting.
  @visibleForTesting
  static Map<String, dynamic> buildParsingInfo({
    required String method,
    dynamic object,
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    bool? autoDetectFormat,
    bool? useCurrentLocale,
    bool? utc,
    dynamic defaultValue,
    dynamic converter,
    Type? targetType,
    Map<String, dynamic>? debugInfo,
  }) => ConvertObjectImpl.buildContext(
    method: method,
    object: object,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    autoDetectFormat: autoDetectFormat,
    useCurrentLocale: useCurrentLocale,
    utc: utc,
    defaultValue: defaultValue,
    converter: converter,
    targetType: targetType,
    debugInfo: debugInfo,
  );
}
