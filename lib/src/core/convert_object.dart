import 'package:meta/meta.dart';
import 'convert_object_impl.dart';

typedef ElementConverter<T> = T Function(Object? element);

/// Backward-compatible static facade that mirrors the original ConvertObject API.
abstract class ConvertObject {
  // Text
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
  static T toType<T>(dynamic object) => ConvertObjectImpl.toType<T>(object);
  static T? tryToType<T>(dynamic object) =>
      ConvertObjectImpl.tryToType<T>(object);

  // Testing helper alias
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
