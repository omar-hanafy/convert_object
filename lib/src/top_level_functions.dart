import 'package:convert_object/src/core/convert_object.dart';

// --------------------------------------------------------------------------
// Top-Level Convenience Functions
// --------------------------------------------------------------------------
//
// These functions provide a functional programming style alternative to
// the static [Convert] methods. They have identical signatures and behavior.
//
// Use these when you prefer top-level function syntax:
//   final age = convertToInt(json['age']);
//
// Instead of:
//   final age = Convert.toInt(json['age']);
//
// See [Convert] for detailed documentation of each method's behavior.
// --------------------------------------------------------------------------

// Strings

/// Top-level convenience alias for [Convert.string].
///
/// See [Convert.string] for full documentation.
String convertToString(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? defaultValue,
  String Function(Object?)? converter,
}) => Convert.string(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  defaultValue: defaultValue,
  converter: converter,
);

/// Top-level convenience alias for [Convert.tryToString].
String? tryConvertToString(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? defaultValue,
  String Function(Object?)? converter,
}) => Convert.tryToString(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  defaultValue: defaultValue,
  converter: converter,
);

// Numbers

/// Top-level convenience alias for [Convert.toNum].
num convertToNum(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? format,
  String? locale,
  num? defaultValue,
  num Function(Object?)? converter,
}) => Convert.toNum(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  format: format,
  locale: locale,
  defaultValue: defaultValue,
  converter: converter,
);

/// Top-level convenience alias for [Convert.tryToNum].
num? tryConvertToNum(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? format,
  String? locale,
  num? defaultValue,
  num Function(Object?)? converter,
}) => Convert.tryToNum(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  format: format,
  locale: locale,
  defaultValue: defaultValue,
  converter: converter,
);

/// Top-level convenience alias for [Convert.toInt].
int convertToInt(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? format,
  String? locale,
  int? defaultValue,
  int Function(Object?)? converter,
}) => Convert.toInt(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  format: format,
  locale: locale,
  defaultValue: defaultValue,
  converter: converter,
);

/// Top-level convenience alias for [Convert.tryToInt].
int? tryConvertToInt(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? format,
  String? locale,
  int? defaultValue,
  int Function(Object?)? converter,
}) => Convert.tryToInt(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  format: format,
  locale: locale,
  defaultValue: defaultValue,
  converter: converter,
);

/// Top-level convenience alias for [Convert.toDouble].
double convertToDouble(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? format,
  String? locale,
  double? defaultValue,
  double Function(Object?)? converter,
}) => Convert.toDouble(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  format: format,
  locale: locale,
  defaultValue: defaultValue,
  converter: converter,
);

/// Top-level convenience alias for [Convert.tryToDouble].
double? tryConvertToDouble(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? format,
  String? locale,
  double? defaultValue,
  double Function(Object?)? converter,
}) => Convert.tryToDouble(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  format: format,
  locale: locale,
  defaultValue: defaultValue,
  converter: converter,
);

// BigInt

/// Top-level convenience alias for [Convert.toBigInt].
BigInt convertToBigInt(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  BigInt? defaultValue,
  BigInt Function(Object?)? converter,
}) => Convert.toBigInt(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  defaultValue: defaultValue,
  converter: converter,
);

/// Top-level convenience alias for [Convert.tryToBigInt].
BigInt? tryConvertToBigInt(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  BigInt? defaultValue,
  BigInt Function(Object?)? converter,
}) => Convert.tryToBigInt(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  defaultValue: defaultValue,
  converter: converter,
);

// Bool

/// Top-level convenience alias for [Convert.toBool].
bool convertToBool(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  bool? defaultValue,
  bool Function(Object?)? converter,
}) => Convert.toBool(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  defaultValue: defaultValue,
  converter: converter,
);

/// Top-level convenience alias for [Convert.tryToBool].
bool? tryConvertToBool(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  bool? defaultValue,
  bool Function(Object?)? converter,
}) => Convert.tryToBool(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  defaultValue: defaultValue,
  converter: converter,
);

// DateTime

/// Top-level convenience alias for [Convert.toDateTime].
DateTime convertToDateTime(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? format,
  String? locale,
  bool autoDetectFormat = false,
  bool useCurrentLocale = false,
  bool utc = false,
  DateTime? defaultValue,
  DateTime Function(Object?)? converter,
}) => Convert.toDateTime(
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

/// Top-level convenience alias for [Convert.tryToDateTime].
DateTime? tryConvertToDateTime(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? format,
  String? locale,
  bool autoDetectFormat = false,
  bool useCurrentLocale = false,
  bool utc = false,
  DateTime? defaultValue,
  DateTime Function(Object?)? converter,
}) => Convert.tryToDateTime(
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

// Uri

/// Top-level convenience alias for [Convert.toUri].
Uri convertToUri(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  Uri? defaultValue,
  Uri Function(Object?)? converter,
}) => Convert.toUri(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  defaultValue: defaultValue,
  converter: converter,
);

/// Top-level convenience alias for [Convert.tryToUri].
Uri? tryConvertToUri(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  Uri? defaultValue,
  Uri Function(Object?)? converter,
}) => Convert.tryToUri(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  defaultValue: defaultValue,
  converter: converter,
);

// Collections

/// Top-level convenience alias for [Convert.toMap].
Map<K, V> convertToMap<K, V>(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  Map<K, V>? defaultValue,
  K Function(Object?)? keyConverter,
  V Function(Object?)? valueConverter,
}) => Convert.toMap<K, V>(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  defaultValue: defaultValue,
  keyConverter: keyConverter,
  valueConverter: valueConverter,
);

/// Top-level convenience alias for [Convert.tryToMap].
Map<K, V>? tryConvertToMap<K, V>(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  Map<K, V>? defaultValue,
  K Function(Object?)? keyConverter,
  V Function(Object?)? valueConverter,
}) => Convert.tryToMap<K, V>(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  defaultValue: defaultValue,
  keyConverter: keyConverter,
  valueConverter: valueConverter,
);

/// Top-level convenience alias for [Convert.toSet].
Set<T> convertToSet<T>(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  Set<T>? defaultValue,
  T Function(Object?)? elementConverter,
}) => Convert.toSet<T>(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  defaultValue: defaultValue,
  elementConverter: elementConverter,
);

/// Top-level convenience alias for [Convert.tryToSet].
Set<T>? tryConvertToSet<T>(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  Set<T>? defaultValue,
  T Function(Object?)? elementConverter,
}) => Convert.tryToSet<T>(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  defaultValue: defaultValue,
  elementConverter: elementConverter,
);

/// Top-level convenience alias for [Convert.toList].
List<T> convertToList<T>(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  List<T>? defaultValue,
  T Function(Object?)? elementConverter,
}) => Convert.toList<T>(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  defaultValue: defaultValue,
  elementConverter: elementConverter,
);

/// Top-level convenience alias for [Convert.tryToList].
List<T>? tryConvertToList<T>(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  List<T>? defaultValue,
  T Function(Object?)? elementConverter,
}) => Convert.tryToList<T>(
  object,
  mapKey: mapKey,
  listIndex: listIndex,
  defaultValue: defaultValue,
  elementConverter: elementConverter,
);

// Enum

/// Top-level convenience alias for [Convert.toEnum].
T convertToEnum<T extends Enum>(
  dynamic object, {
  required T Function(dynamic) parser,
  Object? mapKey,
  int? listIndex,
  T? defaultValue,
  Map<String, dynamic>? debugInfo,
}) => Convert.toEnum<T>(
  object,
  parser: parser,
  mapKey: mapKey,
  listIndex: listIndex,
  defaultValue: defaultValue,
  debugInfo: debugInfo,
);

/// Top-level convenience alias for [Convert.tryToEnum].
T? tryConvertToEnum<T extends Enum>(
  dynamic object, {
  required T Function(dynamic) parser,
  Object? mapKey,
  int? listIndex,
  T? defaultValue,
  Map<String, dynamic>? debugInfo,
}) => Convert.tryToEnum<T>(
  object,
  parser: parser,
  mapKey: mapKey,
  listIndex: listIndex,
  defaultValue: defaultValue,
  debugInfo: debugInfo,
);

// Generic

/// Top-level convenience alias for [Convert.toType].
T convertToType<T>(dynamic object) => Convert.toType<T>(object);

/// Top-level convenience alias for [Convert.tryToType].
T? tryConvertToType<T>(dynamic object) => Convert.tryToType<T>(object);
