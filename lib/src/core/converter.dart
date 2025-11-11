import 'package:convert_object/src/core/convert_object_impl.dart';
import 'package:convert_object/src/exceptions/conversion_exception.dart';
import 'package:convert_object/src/utils/json.dart';

/// Signature for lazily transforming a stored value before conversion.
typedef DynamicConverter<T> = T Function(Object? value);

/// Fluent wrapper that offers composable access to conversion helpers.
class Converter {
  /// Creates a converter around [_value] with optional fallbacks or custom
  /// pre-processing.
  const Converter(
    this._value, {
    Object? defaultValue,
    DynamicConverter<dynamic>? customConverter,
  })  : _defaultValue = defaultValue,
        _customConverter = customConverter;
  final Object? _value;
  final Object? _defaultValue;
  final DynamicConverter<dynamic>? _customConverter;

  Object? _transformValue(String method) {
    if (_customConverter == null) return _value;
    try {
      return _customConverter!(_value);
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

  // Options -----------------------------------------------------------
  /// Returns a new [Converter] that uses [value] whenever a conversion fails.
  Converter withDefault(Object? value) =>
      Converter(_value, defaultValue: value, customConverter: _customConverter);

  /// Returns a new [Converter] that applies [converter] before any lookup.
  Converter withConverter(DynamicConverter<dynamic> converter) =>
      Converter(_value,
          defaultValue: _defaultValue, customConverter: converter);

  // Navigation --------------------------------------------------------
  /// Reads a nested value from a map (or JSON string map) using [key].
  Converter fromMap(Object? key) {
    final v = _value;
    if (v is Map) {
      return Converter(v[key],
          defaultValue: _defaultValue, customConverter: _customConverter);
    }
    if (v is String) {
      final decoded = v.tryDecode();
      if (decoded is Map) {
        return Converter(decoded[key],
            defaultValue: _defaultValue, customConverter: _customConverter);
      }
    }
    return Converter(null,
        defaultValue: _defaultValue, customConverter: _customConverter);
  }

  /// Reads a nested value from a list (or JSON string list) using [index].
  Converter fromList(int index) {
    final v = _value;
    if (v is List) {
      return Converter(index >= 0 && index < v.length ? v[index] : null,
          defaultValue: _defaultValue, customConverter: _customConverter);
    }
    if (v is String) {
      final decoded = v.tryDecode();
      if (decoded is List) {
        return Converter(
            index >= 0 && index < decoded.length ? decoded[index] : null,
            defaultValue: _defaultValue,
            customConverter: _customConverter);
      }
    }
    return Converter(null,
        defaultValue: _defaultValue, customConverter: _customConverter);
  }

  /// Decodes JSON string input before continuing conversions.
  Converter get decoded {
    final v = _value;
    if (v is String) {
      final dv = v.tryDecode();
      return Converter(dv,
          defaultValue: _defaultValue, customConverter: _customConverter);
    }
    return this;
  }

  // Generic -----------------------------------------------------------
  /// Converts the wrapped value to [T], throwing when conversion fails.
  T to<T>() {
    final source = _transformValue('Converter.to<$T>');
    return ConvertObjectImpl.toType<T>(source);
  }

  /// Attempts to convert to [T], returning `null` on failure.
  T? tryTo<T>() {
    if (_value == null) return null;
    try {
      return to<T>();
    } catch (_) {
      return null;
    }
  }

  /// Converts to [T], returning [defaultValue] when conversion throws.
  T toOr<T>(T defaultValue) {
    try {
      final v = to<T>();
      return v;
    } catch (_) {
      return defaultValue;
    }
  }

  // Primitive shortcuts ----------------------------------------------
  /// Converts to [String], mirroring [Convert.toString].
  @override
  String toString() =>
      ConvertObjectImpl.string(_value, defaultValue: _defaultValue as String?);

  /// Converts to [String] without throwing, mirroring [Convert.tryToString].
  String? tryToString() => ConvertObjectImpl.tryToString(_value,
      defaultValue: _defaultValue as String?);

  /// Converts to [String], falling back to [defaultValue] when conversion fails.
  String toStringOr(String defaultValue) => tryToString() ?? defaultValue;

  /// Converts to [num], mirroring [Convert.toNum].
  num toNum() =>
      ConvertObjectImpl.toNum(_value, defaultValue: _defaultValue as num?);

  /// Converts to [num] without throwing, mirroring [Convert.tryToNum].
  num? tryToNum() =>
      ConvertObjectImpl.tryToNum(_value, defaultValue: _defaultValue as num?);

  /// Converts to [num], falling back to [defaultValue] on conversion failure.
  num toNumOr(num defaultValue) => tryToNum() ?? defaultValue;

  /// Converts to [int], mirroring [Convert.toInt].
  int toInt() =>
      ConvertObjectImpl.toInt(_value, defaultValue: _defaultValue as int?);

  /// Converts to [int] without throwing, mirroring [Convert.tryToInt].
  int? tryToInt() =>
      ConvertObjectImpl.tryToInt(_value, defaultValue: _defaultValue as int?);

  /// Converts to [int], falling back to [defaultValue] when conversion fails.
  int toIntOr(int defaultValue) => tryToInt() ?? defaultValue;

  /// Converts to [double], mirroring [Convert.toDouble].
  double toDouble() => ConvertObjectImpl.toDouble(_value,
      defaultValue: _defaultValue as double?);

  /// Converts to [double] without throwing, mirroring
  /// [Convert.tryToDouble].
  double? tryToDouble() => ConvertObjectImpl.tryToDouble(_value,
      defaultValue: _defaultValue as double?);

  /// Converts to [double], falling back to [defaultValue] on failure.
  double toDoubleOr(double defaultValue) => tryToDouble() ?? defaultValue;

  /// Converts to [bool], mirroring [Convert.toBool].
  bool toBool() =>
      ConvertObjectImpl.toBool(_value, defaultValue: _defaultValue as bool?);

  /// Converts to [bool] without throwing, mirroring [Convert.tryToBool].
  bool? tryToBool() =>
      ConvertObjectImpl.tryToBool(_value, defaultValue: _defaultValue as bool?);

  /// Converts to [bool], falling back to [defaultValue] on failure.
  bool toBoolOr(bool defaultValue) => tryToBool() ?? defaultValue;

  /// Converts to [BigInt], mirroring [Convert.toBigInt].
  BigInt toBigInt() => ConvertObjectImpl.toBigInt(_value,
      defaultValue: _defaultValue as BigInt?);

  /// Converts to [BigInt] without throwing, mirroring
  /// [Convert.tryToBigInt].
  BigInt? tryToBigInt() => ConvertObjectImpl.tryToBigInt(_value,
      defaultValue: _defaultValue as BigInt?);

  /// Converts to [BigInt], falling back to [defaultValue] on failure.
  BigInt toBigIntOr(BigInt defaultValue) => tryToBigInt() ?? defaultValue;

  /// Converts to [DateTime], mirroring [Convert.toDateTime].
  DateTime toDateTime() => ConvertObjectImpl.toDateTime(_value,
      defaultValue: _defaultValue as DateTime?);

  /// Converts to [DateTime] without throwing, mirroring
  /// [Convert.tryToDateTime].
  DateTime? tryToDateTime() => ConvertObjectImpl.tryToDateTime(_value,
      defaultValue: _defaultValue as DateTime?);

  /// Converts to [DateTime], falling back to [defaultValue] on failure.
  DateTime toDateTimeOr(DateTime defaultValue) =>
      tryToDateTime() ?? defaultValue;

  /// Converts to [Uri], mirroring [Convert.toUri].
  Uri toUri() =>
      ConvertObjectImpl.toUri(_value, defaultValue: _defaultValue as Uri?);

  /// Converts to [Uri] without throwing, mirroring [Convert.tryToUri].
  Uri? tryToUri() =>
      ConvertObjectImpl.tryToUri(_value, defaultValue: _defaultValue as Uri?);

  /// Converts to [Uri], falling back to [defaultValue] on failure.
  Uri toUriOr(Uri defaultValue) => tryToUri() ?? defaultValue;

  // Collections -------------------------------------------------------
  /// Converts to [List], optionally transforming each item.
  List<T> toList<T>({DynamicConverter<T>? elementConverter}) =>
      ConvertObjectImpl.toList<T>(_value, elementConverter: elementConverter);

  /// Converts to [List] without throwing, returning `null` when conversion
  /// fails.
  List<T>? tryToList<T>({DynamicConverter<T>? elementConverter}) =>
      ConvertObjectImpl.tryToList<T>(_value,
          elementConverter: elementConverter);

  /// Converts to [Set], optionally transforming each item.
  Set<T> toSet<T>({DynamicConverter<T>? elementConverter}) =>
      ConvertObjectImpl.toSet<T>(_value, elementConverter: elementConverter);

  /// Converts to [Set] without throwing, returning `null` on failure.
  Set<T>? tryToSet<T>({DynamicConverter<T>? elementConverter}) =>
      ConvertObjectImpl.tryToSet<T>(_value, elementConverter: elementConverter);

  /// Converts to [Map], allowing converters for keys and values.
  Map<K, V> toMap<K, V>(
          {DynamicConverter<K>? keyConverter,
          DynamicConverter<V>? valueConverter}) =>
      ConvertObjectImpl.toMap<K, V>(_value,
          keyConverter: keyConverter, valueConverter: valueConverter);

  /// Converts to [Map] without throwing, returning `null` on failure.
  Map<K, V>? tryToMap<K, V>(
          {DynamicConverter<K>? keyConverter,
          DynamicConverter<V>? valueConverter}) =>
      ConvertObjectImpl.tryToMap<K, V>(_value,
          keyConverter: keyConverter, valueConverter: valueConverter);
}
