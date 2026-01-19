import 'package:convert_object/src/core/convert_object_impl.dart';
import 'package:convert_object/src/exceptions/conversion_exception.dart';
import 'package:convert_object/src/utils/json.dart';

/// Signature for lazily transforming a stored value before conversion.
///
/// Used with `Converter.withConverter` to pre-process values before type
/// conversion (e.g., extracting a specific field or decoding custom formats).
typedef DynamicConverter<T> = T Function(Object? value);

/// Fluent wrapper for chained type conversions with navigation and fallbacks.
///
/// `Converter` provides a chainable API for extracting and converting values
/// from nested data structures. It is the primary way to convert values
/// fluently via the `value.convert.toInt()` syntax.
///
/// ### Basic Usage
/// ```dart
/// final json = {'user': {'age': '25'}};
/// final age = json.convert.fromMap('user').fromMap('age').toInt();
/// ```
///
/// ### With Defaults
/// ```dart
/// final value = data.convert.withDefault(0).toInt(); // Falls back to 0
/// ```
///
/// ### With Custom Pre-Processing
/// ```dart
/// final value = raw.convert.withConverter((v) => v?.trim()).string();
/// ```
///
/// Unlike `Convert`, which is stateless, `Converter` wraps a value and allows
/// incremental navigation through nested structures. Configuration set via
/// [withDefault] or [withConverter] persists through navigation methods.
///
/// See also:
/// * `Convert` for stateless conversion methods.
/// * `ConvertObjectExtension` for the `.convert` getter.
class Converter {
  /// Creates a converter wrapping [_value] with optional fallback and pre-processing.
  ///
  /// Typically you obtain a `Converter` via `value.convert` rather than
  /// constructing directly.
  const Converter(
    this._value, {
    Object? defaultValue,
    DynamicConverter<dynamic>? customConverter,
  }) : _defaultValue = defaultValue,
       _customConverter = customConverter;
  final Object? _value;
  final Object? _defaultValue;
  final DynamicConverter<dynamic>? _customConverter;

  // Applies the custom converter to pre-process values before type conversion.
  // Wraps any converter errors in [ConversionException] for debugging context.
  Object? _transformValue(String method) {
    if (_customConverter == null) return _value;
    try {
      return _customConverter(_value);
    } catch (e, s) {
      throw ConversionException(
        error: e,
        context: {
          'method': method,
          'object': _value,
          'converter': _customConverter.runtimeType.toString(),
        },
        stackTrace: s,
      );
    }
  }

  /// Configures a default value to be returned if the subsequent conversion operation fails.
  ///
  /// This allows the chain to recover gracefully from errors (e.g., parsing failures).
  Converter withDefault(Object? value) =>
      Converter(_value, defaultValue: value, customConverter: _customConverter);

  /// Applies a custom transformation to the value before any conversion attempt.
  ///
  /// The [converter] function is called with the current value, and its result
  /// is used for subsequent operations.
  Converter withConverter(DynamicConverter<dynamic> converter) => Converter(
    _value,
    defaultValue: _defaultValue,
    customConverter: converter,
  );

  /// Extracts a value from a [Map] using the specified [key].
  ///
  /// If the current value is a JSON string representing a map, it is automatically decoded.
  /// If the key is missing or the value is not a map, the result wraps `null`.
  Converter fromMap(Object? key) {
    final v = _value;
    if (v is Map) {
      return Converter(
        v[key],
        defaultValue: _defaultValue,
        customConverter: _customConverter,
      );
    }
    if (v is String) {
      final decoded = v.tryDecode();
      if (decoded is Map) {
        return Converter(
          decoded[key],
          defaultValue: _defaultValue,
          customConverter: _customConverter,
        );
      }
    }
    return Converter(
      null,
      defaultValue: _defaultValue,
      customConverter: _customConverter,
    );
  }

  /// Extracts a value from a [List] using the specified [index].
  ///
  /// If the current value is a JSON string representing a list, it is automatically decoded.
  /// If the index is out of bounds or the value is not a list, the result wraps `null`.
  Converter fromList(int index) {
    final v = _value;
    if (v is List) {
      return Converter(
        index >= 0 && index < v.length ? v[index] : null,
        defaultValue: _defaultValue,
        customConverter: _customConverter,
      );
    }
    if (v is String) {
      final decoded = v.tryDecode();
      if (decoded is List) {
        return Converter(
          index >= 0 && index < decoded.length ? decoded[index] : null,
          defaultValue: _defaultValue,
          customConverter: _customConverter,
        );
      }
    }
    return Converter(
      null,
      defaultValue: _defaultValue,
      customConverter: _customConverter,
    );
  }

  /// Explicitly decodes a JSON string into a Dart object (Map, List, etc.).
  ///
  /// If the current value is not a string or invalid JSON, the state remains unchanged.
  Converter get decoded {
    final v = _value;
    if (v is String) {
      final dv = v.tryDecode();
      return Converter(
        dv,
        defaultValue: _defaultValue,
        customConverter: _customConverter,
      );
    }
    return this;
  }

  /// Converts the wrapped value to type [T].
  ///
  /// Throws a [ConversionException] if the conversion fails.
  T to<T>() {
    final source = _transformValue('Converter.to<$T>');
    return ConvertObjectImpl.toType<T>(source);
  }

  /// Attempts to convert the wrapped value to type [T].
  ///
  /// Returns `null` if the conversion fails or if the value is `null`.
  T? tryTo<T>() {
    if (_value == null) return null;
    try {
      return to<T>();
    } on ConversionException {
      return null;
    }
  }

  /// Converts the wrapped value to type [T], falling back to [defaultValue] on failure.
  ///
  /// This is equivalent to calling [tryTo] and providing a default.
  T toOr<T>(T defaultValue) {
    try {
      final v = to<T>();
      return v;
    } on ConversionException {
      return defaultValue;
    }
  }

  /// Converts to [String], mirroring `Convert.string`.
  String string({
    dynamic mapKey,
    int? listIndex,
    String? defaultValue,
    DynamicConverter<String>? converter,
  }) => ConvertObjectImpl.string(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue ?? _defaultValue as String?,
    converter: converter,
  );

  /// Overrides [Object.toString] using the conversion logic.
  @override
  String toString() => string();

  /// Converts to [String] without throwing, mirroring `Convert.tryToString`.
  String? tryToString({
    dynamic mapKey,
    int? listIndex,
    String? defaultValue,
    DynamicConverter<String>? converter,
  }) => ConvertObjectImpl.tryToString(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue ?? _defaultValue as String?,
    converter: converter,
  );

  /// Converts to [String], falling back to [defaultValue] when conversion fails.
  String toStringOr(
    String defaultValue, {
    dynamic mapKey,
    int? listIndex,
    DynamicConverter<String>? converter,
  }) =>
      tryToString(
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        converter: converter,
      ) ??
      defaultValue;

  /// Converts to [num], mirroring `Convert.toNum`.
  num toNum({
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    num? defaultValue,
    DynamicConverter<num>? converter,
  }) => ConvertObjectImpl.toNum(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    defaultValue: defaultValue ?? _defaultValue as num?,
    converter: converter,
  );

  /// Converts to [num] without throwing, mirroring `Convert.tryToNum`.
  num? tryToNum({
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    num? defaultValue,
    DynamicConverter<num>? converter,
  }) => ConvertObjectImpl.tryToNum(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    defaultValue: defaultValue ?? _defaultValue as num?,
    converter: converter,
  );

  /// Converts to [num], falling back to [defaultValue] on conversion failure.
  num toNumOr(
    num defaultValue, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    DynamicConverter<num>? converter,
  }) =>
      tryToNum(
        mapKey: mapKey,
        listIndex: listIndex,
        format: format,
        locale: locale,
        defaultValue: defaultValue,
        converter: converter,
      ) ??
      defaultValue;

  /// Converts to [int], mirroring `Convert.toInt`.
  int toInt({
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    int? defaultValue,
    DynamicConverter<int>? converter,
  }) => ConvertObjectImpl.toInt(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    defaultValue: defaultValue ?? _defaultValue as int?,
    converter: converter,
  );

  /// Converts to [int] without throwing, mirroring `Convert.tryToInt`.
  int? tryToInt({
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    int? defaultValue,
    DynamicConverter<int>? converter,
  }) => ConvertObjectImpl.tryToInt(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    defaultValue: defaultValue ?? _defaultValue as int?,
    converter: converter,
  );

  /// Converts to [int], falling back to [defaultValue] when conversion fails.
  int toIntOr(
    int defaultValue, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    DynamicConverter<int>? converter,
  }) =>
      tryToInt(
        mapKey: mapKey,
        listIndex: listIndex,
        format: format,
        locale: locale,
        defaultValue: defaultValue,
        converter: converter,
      ) ??
      defaultValue;

  /// Converts to [double], mirroring `Convert.toDouble`.
  double toDouble({
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    double? defaultValue,
    DynamicConverter<double>? converter,
  }) => ConvertObjectImpl.toDouble(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    defaultValue: defaultValue ?? _defaultValue as double?,
    converter: converter,
  );

  /// Converts to [double] without throwing, mirroring
  /// `Convert.tryToDouble`.
  double? tryToDouble({
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    double? defaultValue,
    DynamicConverter<double>? converter,
  }) => ConvertObjectImpl.tryToDouble(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    defaultValue: defaultValue ?? _defaultValue as double?,
    converter: converter,
  );

  /// Converts to [double], falling back to [defaultValue] on failure.
  double toDoubleOr(
    double defaultValue, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    DynamicConverter<double>? converter,
  }) =>
      tryToDouble(
        mapKey: mapKey,
        listIndex: listIndex,
        format: format,
        locale: locale,
        defaultValue: defaultValue,
        converter: converter,
      ) ??
      defaultValue;

  /// Converts to [bool], mirroring `Convert.toBool`.
  bool toBool({
    dynamic mapKey,
    int? listIndex,
    bool? defaultValue,
    DynamicConverter<bool>? converter,
  }) => ConvertObjectImpl.toBool(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue ?? _defaultValue as bool?,
    converter: converter,
  );

  /// Converts to [bool] without throwing, mirroring `Convert.tryToBool`.
  bool? tryToBool({
    dynamic mapKey,
    int? listIndex,
    bool? defaultValue,
    DynamicConverter<bool>? converter,
  }) => ConvertObjectImpl.tryToBool(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue ?? _defaultValue as bool?,
    converter: converter,
  );

  /// Converts to [bool], falling back to [defaultValue] on failure.
  bool toBoolOr(
    bool defaultValue, {
    dynamic mapKey,
    int? listIndex,
    DynamicConverter<bool>? converter,
  }) =>
      tryToBool(
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        converter: converter,
      ) ??
      defaultValue;

  /// Converts to [BigInt], mirroring `Convert.toBigInt`.
  BigInt toBigInt({
    dynamic mapKey,
    int? listIndex,
    BigInt? defaultValue,
    DynamicConverter<BigInt>? converter,
  }) => ConvertObjectImpl.toBigInt(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue ?? _defaultValue as BigInt?,
    converter: converter,
  );

  /// Converts to [BigInt] without throwing, mirroring
  /// `Convert.tryToBigInt`.
  BigInt? tryToBigInt({
    dynamic mapKey,
    int? listIndex,
    BigInt? defaultValue,
    DynamicConverter<BigInt>? converter,
  }) => ConvertObjectImpl.tryToBigInt(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue ?? _defaultValue as BigInt?,
    converter: converter,
  );

  /// Converts to [BigInt], falling back to [defaultValue] on failure.
  BigInt toBigIntOr(
    BigInt defaultValue, {
    dynamic mapKey,
    int? listIndex,
    DynamicConverter<BigInt>? converter,
  }) =>
      tryToBigInt(
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        converter: converter,
      ) ??
      defaultValue;

  /// Converts to [DateTime], mirroring `Convert.toDateTime`.
  DateTime toDateTime({
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    bool autoDetectFormat = false,
    bool useCurrentLocale = false,
    bool utc = false,
    DateTime? defaultValue,
    DynamicConverter<DateTime>? converter,
  }) => ConvertObjectImpl.toDateTime(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    autoDetectFormat: autoDetectFormat,
    useCurrentLocale: useCurrentLocale,
    utc: utc,
    defaultValue: defaultValue ?? _defaultValue as DateTime?,
    converter: converter,
  );

  /// Converts to [DateTime] without throwing, mirroring
  /// `Convert.tryToDateTime`.
  DateTime? tryToDateTime({
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    bool autoDetectFormat = false,
    bool useCurrentLocale = false,
    bool utc = false,
    DateTime? defaultValue,
    DynamicConverter<DateTime>? converter,
  }) => ConvertObjectImpl.tryToDateTime(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    format: format,
    locale: locale,
    autoDetectFormat: autoDetectFormat,
    useCurrentLocale: useCurrentLocale,
    utc: utc,
    defaultValue: defaultValue ?? _defaultValue as DateTime?,
    converter: converter,
  );

  /// Converts to [DateTime], falling back to [defaultValue] on failure.
  DateTime toDateTimeOr(
    DateTime defaultValue, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    bool autoDetectFormat = false,
    bool useCurrentLocale = false,
    bool utc = false,
    DynamicConverter<DateTime>? converter,
  }) =>
      tryToDateTime(
        mapKey: mapKey,
        listIndex: listIndex,
        format: format,
        locale: locale,
        autoDetectFormat: autoDetectFormat,
        useCurrentLocale: useCurrentLocale,
        utc: utc,
        defaultValue: defaultValue,
        converter: converter,
      ) ??
      defaultValue;

  /// Converts to [Uri], mirroring `Convert.toUri`.
  Uri toUri({
    dynamic mapKey,
    int? listIndex,
    Uri? defaultValue,
    DynamicConverter<Uri>? converter,
  }) => ConvertObjectImpl.toUri(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue ?? _defaultValue as Uri?,
    converter: converter,
  );

  /// Converts to [Uri] without throwing, mirroring `Convert.tryToUri`.
  Uri? tryToUri({
    dynamic mapKey,
    int? listIndex,
    Uri? defaultValue,
    DynamicConverter<Uri>? converter,
  }) => ConvertObjectImpl.tryToUri(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue ?? _defaultValue as Uri?,
    converter: converter,
  );

  /// Converts to [Uri], falling back to [defaultValue] on failure.
  Uri toUriOr(
    Uri defaultValue, {
    dynamic mapKey,
    int? listIndex,
    DynamicConverter<Uri>? converter,
  }) =>
      tryToUri(
        mapKey: mapKey,
        listIndex: listIndex,
        defaultValue: defaultValue,
        converter: converter,
      ) ??
      defaultValue;

  /// Converts to [T] using [parser], mirroring `Convert.toEnum`.
  T toEnum<T extends Enum>({
    required T Function(dynamic) parser,
    dynamic mapKey,
    int? listIndex,
    T? defaultValue,
    Map<String, dynamic>? debugInfo,
  }) => ConvertObjectImpl.toEnum<T>(
    _value,
    parser: parser,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue ?? _defaultValue as T?,
    debugInfo: debugInfo,
  );

  /// Converts to [T] without throwing, mirroring `Convert.tryToEnum`.
  T? tryToEnum<T extends Enum>({
    required T Function(dynamic) parser,
    dynamic mapKey,
    int? listIndex,
    T? defaultValue,
    Map<String, dynamic>? debugInfo,
  }) => ConvertObjectImpl.tryToEnum<T>(
    _value,
    parser: parser,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue ?? _defaultValue as T?,
    debugInfo: debugInfo,
  );

  /// Converts to [List], optionally transforming each item.
  List<T> toList<T>({
    dynamic mapKey,
    int? listIndex,
    List<T>? defaultValue,
    DynamicConverter<T>? elementConverter,
  }) => ConvertObjectImpl.toList<T>(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue ?? _defaultValue as List<T>?,
    elementConverter: elementConverter,
  );

  /// Converts to [List] without throwing, returning `null` when conversion
  /// fails.
  List<T>? tryToList<T>({
    dynamic mapKey,
    int? listIndex,
    List<T>? defaultValue,
    DynamicConverter<T>? elementConverter,
  }) => ConvertObjectImpl.tryToList<T>(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue ?? _defaultValue as List<T>?,
    elementConverter: elementConverter,
  );

  /// Converts to [Set], optionally transforming each item.
  Set<T> toSet<T>({
    dynamic mapKey,
    int? listIndex,
    Set<T>? defaultValue,
    DynamicConverter<T>? elementConverter,
  }) => ConvertObjectImpl.toSet<T>(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue ?? _defaultValue as Set<T>?,
    elementConverter: elementConverter,
  );

  /// Converts to [Set] without throwing, returning `null` on failure.
  Set<T>? tryToSet<T>({
    dynamic mapKey,
    int? listIndex,
    Set<T>? defaultValue,
    DynamicConverter<T>? elementConverter,
  }) => ConvertObjectImpl.tryToSet<T>(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue ?? _defaultValue as Set<T>?,
    elementConverter: elementConverter,
  );

  /// Converts to [Map], allowing converters for keys and values.
  Map<K, V> toMap<K, V>({
    dynamic mapKey,
    int? listIndex,
    Map<K, V>? defaultValue,
    DynamicConverter<K>? keyConverter,
    DynamicConverter<V>? valueConverter,
  }) => ConvertObjectImpl.toMap<K, V>(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue ?? _defaultValue as Map<K, V>?,
    keyConverter: keyConverter,
    valueConverter: valueConverter,
  );

  /// Converts to [Map] without throwing, returning `null` on failure.
  Map<K, V>? tryToMap<K, V>({
    dynamic mapKey,
    int? listIndex,
    Map<K, V>? defaultValue,
    DynamicConverter<K>? keyConverter,
    DynamicConverter<V>? valueConverter,
  }) => ConvertObjectImpl.tryToMap<K, V>(
    _value,
    mapKey: mapKey,
    listIndex: listIndex,
    defaultValue: defaultValue ?? _defaultValue as Map<K, V>?,
    keyConverter: keyConverter,
    valueConverter: valueConverter,
  );
}
