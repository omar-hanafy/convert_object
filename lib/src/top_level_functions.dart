import 'package:convert_object/src/core/convert_object.dart';

// Text

/// Top-level convenience alias for [ConvertObject.toText].
String toText(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? defaultValue,
  String Function(Object?)? converter,
}) =>
    ConvertObject.toText(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      defaultValue: defaultValue,
      converter: converter,
    );

/// Top-level convenience alias for [ConvertObject.tryToText].
String? tryToText(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? defaultValue,
  String Function(Object?)? converter,
}) =>
    ConvertObject.tryToText(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      defaultValue: defaultValue,
      converter: converter,
    );

// Numbers

/// Top-level convenience alias for [ConvertObject.toNum].
num toNum(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? format,
  String? locale,
  num? defaultValue,
  num Function(Object?)? converter,
}) =>
    ConvertObject.toNum(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      format: format,
      locale: locale,
      defaultValue: defaultValue,
      converter: converter,
    );

/// Top-level convenience alias for [ConvertObject.tryToNum].
num? tryToNum(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? format,
  String? locale,
  num? defaultValue,
  num Function(Object?)? converter,
}) =>
    ConvertObject.tryToNum(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      format: format,
      locale: locale,
      defaultValue: defaultValue,
      converter: converter,
    );

/// Top-level convenience alias for [ConvertObject.toInt].
int toInt(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? format,
  String? locale,
  int? defaultValue,
  int Function(Object?)? converter,
}) =>
    ConvertObject.toInt(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      format: format,
      locale: locale,
      defaultValue: defaultValue,
      converter: converter,
    );

/// Top-level convenience alias for [ConvertObject.tryToInt].
int? tryToInt(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? format,
  String? locale,
  int? defaultValue,
  int Function(Object?)? converter,
}) =>
    ConvertObject.tryToInt(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      format: format,
      locale: locale,
      defaultValue: defaultValue,
      converter: converter,
    );

/// Top-level convenience alias for [ConvertObject.toDouble].
double toDouble(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? format,
  String? locale,
  double? defaultValue,
  double Function(Object?)? converter,
}) =>
    ConvertObject.toDouble(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      format: format,
      locale: locale,
      defaultValue: defaultValue,
      converter: converter,
    );

/// Top-level convenience alias for [ConvertObject.tryToDouble].
double? tryToDouble(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  String? format,
  String? locale,
  double? defaultValue,
  double Function(Object?)? converter,
}) =>
    ConvertObject.tryToDouble(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      format: format,
      locale: locale,
      defaultValue: defaultValue,
      converter: converter,
    );

// BigInt

/// Top-level convenience alias for [ConvertObject.toBigInt].
BigInt toBigInt(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  BigInt? defaultValue,
  BigInt Function(Object?)? converter,
}) =>
    ConvertObject.toBigInt(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      defaultValue: defaultValue,
      converter: converter,
    );

/// Top-level convenience alias for [ConvertObject.tryToBigInt].
BigInt? tryToBigInt(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  BigInt? defaultValue,
  BigInt Function(Object?)? converter,
}) =>
    ConvertObject.tryToBigInt(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      defaultValue: defaultValue,
      converter: converter,
    );

// Bool

/// Top-level convenience alias for [ConvertObject.toBool].
bool toBool(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  bool? defaultValue,
  bool Function(Object?)? converter,
}) =>
    ConvertObject.toBool(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      defaultValue: defaultValue,
      converter: converter,
    );

/// Top-level convenience alias for [ConvertObject.tryToBool].
bool? tryToBool(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  bool? defaultValue,
  bool Function(Object?)? converter,
}) =>
    ConvertObject.tryToBool(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      defaultValue: defaultValue,
      converter: converter,
    );

// DateTime

/// Top-level convenience alias for [ConvertObject.toDateTime].
DateTime toDateTime(
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
}) =>
    ConvertObject.toDateTime(
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

/// Top-level convenience alias for [ConvertObject.tryToDateTime].
DateTime? tryToDateTime(
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
}) =>
    ConvertObject.tryToDateTime(
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

/// Top-level convenience alias for [ConvertObject.toUri].
Uri toUri(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  Uri? defaultValue,
  Uri Function(Object?)? converter,
}) =>
    ConvertObject.toUri(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      defaultValue: defaultValue,
      converter: converter,
    );

/// Top-level convenience alias for [ConvertObject.tryToUri].
Uri? tryToUri(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  Uri? defaultValue,
  Uri Function(Object?)? converter,
}) =>
    ConvertObject.tryToUri(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      defaultValue: defaultValue,
      converter: converter,
    );

// Collections

/// Top-level convenience alias for [ConvertObject.toMap].
Map<K, V> toMap<K, V>(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  Map<K, V>? defaultValue,
  K Function(Object?)? keyConverter,
  V Function(Object?)? valueConverter,
}) =>
    ConvertObject.toMap<K, V>(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      defaultValue: defaultValue,
      keyConverter: keyConverter,
      valueConverter: valueConverter,
    );

/// Top-level convenience alias for [ConvertObject.tryToMap].
Map<K, V>? tryToMap<K, V>(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  Map<K, V>? defaultValue,
  K Function(Object?)? keyConverter,
  V Function(Object?)? valueConverter,
}) =>
    ConvertObject.tryToMap<K, V>(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      defaultValue: defaultValue,
      keyConverter: keyConverter,
      valueConverter: valueConverter,
    );

/// Top-level convenience alias for [ConvertObject.toSet].
Set<T> toSet<T>(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  Set<T>? defaultValue,
  T Function(Object?)? elementConverter,
}) =>
    ConvertObject.toSet<T>(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      defaultValue: defaultValue,
      elementConverter: elementConverter,
    );

/// Top-level convenience alias for [ConvertObject.tryToSet].
Set<T>? tryToSet<T>(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  Set<T>? defaultValue,
  T Function(Object?)? elementConverter,
}) =>
    ConvertObject.tryToSet<T>(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      defaultValue: defaultValue,
      elementConverter: elementConverter,
    );

/// Top-level convenience alias for [ConvertObject.toList].
List<T> toList<T>(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  List<T>? defaultValue,
  T Function(Object?)? elementConverter,
}) =>
    ConvertObject.toList<T>(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      defaultValue: defaultValue,
      elementConverter: elementConverter,
    );

/// Top-level convenience alias for [ConvertObject.tryToList].
List<T>? tryToList<T>(
  dynamic object, {
  Object? mapKey,
  int? listIndex,
  List<T>? defaultValue,
  T Function(Object?)? elementConverter,
}) =>
    ConvertObject.tryToList<T>(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      defaultValue: defaultValue,
      elementConverter: elementConverter,
    );

// Generic

/// Top-level convenience alias for [ConvertObject.toType].
T toType<T>(dynamic object) => ConvertObject.toType<T>(object);

/// Top-level convenience alias for [ConvertObject.tryToType].
T? tryToType<T>(dynamic object) => ConvertObject.tryToType<T>(object);
