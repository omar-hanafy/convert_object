import 'package:meta/meta.dart';
import 'package:convert_object/src/core/convert_object_impl.dart';

/// Signature for transforming a single element while converting collections.
typedef ElementConverter<T> = T Function(Object? element);

/// Backward-compatible static facade that mirrors the original ConvertObject API.
abstract class ConvertObject {
  // Text

  /// Converts [object] to [String], throwing if the value cannot be coerced.
  static String toText(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? defaultValue,
    ElementConverter<String>? converter,
  }) =>
      ConvertObjectImpl.toText(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        converter: converter,
      );

  /// Converts [object] to [String] and returns `null` or [defaultValue] on
  /// failure instead of throwing.
  static String? tryToText(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? defaultValue,
    ElementConverter<String>? converter,
  }) =>
      ConvertObjectImpl.tryToText(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        converter: converter,
      );

  // Numbers
  /// Converts [object] to [num], using optional formatting hints for parsing
  /// textual input.
  static num toNum(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    num? defaultValue,
    ElementConverter<num>? converter,
  }) =>
      ConvertObjectImpl.toNum(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        format: format,
        locale: locale,
        defaultValue: defaultValue,
        converter: converter,
      );

  /// Converts [object] to [num] returning `null` or [defaultValue] when
  /// conversion fails.
  static num? tryToNum(
    dynamic object, {
    dynamic mapKey,
    String? format,
    String? locale,
    int? listIndex,
    num? defaultValue,
    ElementConverter<num>? converter,
  }) =>
      ConvertObjectImpl.tryToNum(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        format: format,
        locale: locale,
        defaultValue: defaultValue,
        converter: converter,
      );

  /// Converts [object] to [int], applying optional locale-aware formatting.
  static int toInt(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    int? defaultValue,
    ElementConverter<int>? converter,
  }) =>
      ConvertObjectImpl.toInt(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        format: format,
        locale: locale,
        defaultValue: defaultValue,
        converter: converter,
      );

  /// Converts [object] to [int] while suppressing errors and returning
  /// [defaultValue] or `null` if parsing cannot succeed.
  static int? tryToInt(
    dynamic object, {
    dynamic mapKey,
    String? format,
    String? locale,
    int? listIndex,
    int? defaultValue,
    ElementConverter<int>? converter,
  }) =>
      ConvertObjectImpl.tryToInt(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        format: format,
        locale: locale,
        defaultValue: defaultValue,
        converter: converter,
      );

  /// Converts [object] to [double], supporting formatted numeric strings.
  static double toDouble(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    double? defaultValue,
    ElementConverter<double>? converter,
  }) =>
      ConvertObjectImpl.toDouble(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        format: format,
        locale: locale,
        defaultValue: defaultValue,
        converter: converter,
      );

  /// Converts [object] to [double] returning [defaultValue] or `null` on
  /// parsing failure.
  static double? tryToDouble(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    double? defaultValue,
    ElementConverter<double>? converter,
  }) =>
      ConvertObjectImpl.tryToDouble(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        format: format,
        locale: locale,
        defaultValue: defaultValue,
        converter: converter,
      );

  /// Converts [object] to [BigInt], optionally falling back to
  /// [defaultValue].
  static BigInt toBigInt(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    BigInt? defaultValue,
    ElementConverter<BigInt>? converter,
  }) =>
      ConvertObjectImpl.toBigInt(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        converter: converter,
      );

  /// Converts [object] to [BigInt] suppressing errors; returns `null` when
  /// conversion is not possible.
  static BigInt? tryToBigInt(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    BigInt? defaultValue,
    ElementConverter<BigInt>? converter,
  }) =>
      ConvertObjectImpl.tryToBigInt(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        converter: converter,
      );

  /// Converts [object] to [bool], accepting common textual truthy/falsy
  /// representations.
  static bool toBool(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    bool? defaultValue,
    ElementConverter<bool>? converter,
  }) =>
      ConvertObjectImpl.toBool(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        converter: converter,
      );

  /// Converts [object] to [bool] and returns [defaultValue] or `null` when
  /// coercion fails.
  static bool? tryToBool(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    bool? defaultValue,
    ElementConverter<bool>? converter,
  }) =>
      ConvertObjectImpl.tryToBool(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        converter: converter,
      );

  /// Converts [object] to a [DateTime], respecting [format] or automatic
  /// detection rules. Calendar-like inputs (e.g. `yyyyMMdd`, `MM/dd/yyyy`,
  /// long month names) return a value in the local time zone unless [utc] is
  /// `true`. Instant-style inputs (ISO strings with offsets, HTTP dates, Unix
  /// epochs) preserve their UTC meaning but are converted back to local time if
  /// [utc] is `false`.
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
  }) =>
      ConvertObjectImpl.toDateTime(
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

  /// Like [toDateTime] but never throws, returning [defaultValue] (if
  /// provided) or `null` when conversion fails.
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
  }) =>
      ConvertObjectImpl.tryToDateTime(
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

  /// Converts [object] to [Uri], allowing custom parsing via [converter].
  static Uri toUri(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Uri? defaultValue,
    ElementConverter<Uri>? converter,
  }) =>
      ConvertObjectImpl.toUri(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        converter: converter,
      );

  /// Converts [object] to [Uri] returning `null` or [defaultValue] when parsing
  /// fails.
  static Uri? tryToUri(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Uri? defaultValue,
    ElementConverter<Uri>? converter,
  }) =>
      ConvertObjectImpl.tryToUri(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        converter: converter,
      );

  /// Converts [object] to a strongly-typed [Map], optionally transforming keys
  /// and values with [keyConverter] and [valueConverter].
  static Map<K, V> toMap<K, V>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Map<K, V>? defaultValue,
    ElementConverter<K>? keyConverter,
    ElementConverter<V>? valueConverter,
  }) =>
      ConvertObjectImpl.toMap<K, V>(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        keyConverter: keyConverter,
        valueConverter: valueConverter,
      );

  /// Converts [object] to [Map] while returning `null` or [defaultValue] when
  /// conversion fails.
  static Map<K, V>? tryToMap<K, V>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Map<K, V>? defaultValue,
    ElementConverter<K>? keyConverter,
    ElementConverter<V>? valueConverter,
  }) =>
      ConvertObjectImpl.tryToMap<K, V>(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        keyConverter: keyConverter,
        valueConverter: valueConverter,
      );

  /// Converts [object] to [Set], applying [elementConverter] to every entry.
  static Set<T> toSet<T>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Set<T>? defaultValue,
    ElementConverter<T>? elementConverter,
  }) =>
      ConvertObjectImpl.toSet<T>(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        elementConverter: elementConverter,
      );

  /// Converts [object] to [Set] returning `null` or [defaultValue] when
  /// coercion is not possible.
  static Set<T>? tryToSet<T>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Set<T>? defaultValue,
    ElementConverter<T>? elementConverter,
  }) =>
      ConvertObjectImpl.tryToSet<T>(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        elementConverter: elementConverter,
      );

  /// Converts [object] to [List], optionally mapping each element through
  /// [elementConverter].
  static List<T> toList<T>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    List<T>? defaultValue,
    ElementConverter<T>? elementConverter,
  }) =>
      ConvertObjectImpl.toList<T>(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        elementConverter: elementConverter,
      );

  /// Converts [object] to [List] returning [defaultValue] or `null` when
  /// conversion fails.
  static List<T>? tryToList<T>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    List<T>? defaultValue,
    ElementConverter<T>? elementConverter,
  }) =>
      ConvertObjectImpl.tryToList<T>(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        elementConverter: elementConverter,
      );

  /// Converts [object] to an enum using the supplied [parser].
  static T toEnum<T extends Enum>(
    dynamic object, {
    required T Function(dynamic) parser,
    dynamic mapKey,
    int? listIndex,
    T? defaultValue,
    Map<String, dynamic>? debugInfo,
  }) =>
      ConvertObjectImpl.toEnum<T>(
        object,
        parser: parser,
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        debugInfo: debugInfo,
      );

  /// Converts [object] to an enum using [parser] and returns `null` or
  /// [defaultValue] when parsing fails.
  static T? tryToEnum<T extends Enum>(
    dynamic object, {
    required T Function(dynamic) parser,
    dynamic mapKey,
    int? listIndex,
    T? defaultValue,
    Map<String, dynamic>? debugInfo,
  }) =>
      ConvertObjectImpl.tryToEnum<T>(
        object,
        parser: parser,
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        debugInfo: debugInfo,
      );

  // Top-level generic

  /// Converts [object] to the requested type [T], throwing if conversion fails.
  static T toType<T>(dynamic object) => ConvertObjectImpl.toType<T>(object);

  /// Converts [object] to type [T] returning `null` when conversion is
  /// unsuccessful.
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
  }) =>
      ConvertObjectImpl.buildContext(
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
