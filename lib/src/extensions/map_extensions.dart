import 'package:convert_object/src/core/convert_object_impl.dart';

extension _I<E> on Iterable<E> {
  /// The first element satisfying [test], or `null` if there are none.
  E? firstWhereOrNull(bool Function(E element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

/// Conversion helpers for non-nullable maps.
extension MapConversionX<K, V> on Map<K, V> {
  V? _firstValueForKeys(K key, {List<K>? alternativeKeys}) {
    var value = this[key];
    if (value == null &&
        alternativeKeys != null &&
        alternativeKeys.isNotEmpty) {
      final altKey = alternativeKeys.firstWhereOrNull(containsKey);
      if (altKey != null) value = this[altKey];
    }
    return value;
  }

  /// Converts the value at [key] (or [alternativeKeys]) to [String].
  String getString(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          String? defaultValue}) =>
      ConvertObjectImpl.string(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Converts the value at [key] (or [alternativeKeys]) to [int].
  int getInt(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          int? defaultValue,
          String? format,
          String? locale}) =>
      ConvertObjectImpl.toInt(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        format: format,
        locale: locale,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Converts the value at [key] (or [alternativeKeys]) to [double].
  double getDouble(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          double? defaultValue,
          String? format,
          String? locale}) =>
      ConvertObjectImpl.toDouble(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        format: format,
        locale: locale,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Converts the value at [key] (or [alternativeKeys]) to [num].
  num getNum(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          num? defaultValue,
          String? format,
          String? locale,
          ElementConverter<num>? converter}) =>
      ConvertObjectImpl.toNum(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        format: format,
        locale: locale,
        converter: converter,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Converts the value at [key] (or [alternativeKeys]) to [bool].
  bool getBool(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          bool? defaultValue}) =>
      ConvertObjectImpl.toBool(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Converts the value at [key] (or [alternativeKeys]) to a [List] of [T].
  List<T> getList<T>(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          List<T>? defaultValue}) =>
      ConvertObjectImpl.toList<T>(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Converts the value at [key] (or [alternativeKeys]) to a [Set] of [T].
  Set<T> getSet<T>(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          Set<T>? defaultValue}) =>
      ConvertObjectImpl.toSet<T>(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Converts the value at [key] (or [alternativeKeys]) to a [Map] of [K2] to [V2].
  Map<K2, V2> getMap<K2, V2>(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          Map<K2, V2>? defaultValue}) =>
      ConvertObjectImpl.toMap<K2, V2>(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Converts the value at [key] (or [alternativeKeys]) to [BigInt].
  BigInt getBigInt(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          BigInt? defaultValue}) =>
      ConvertObjectImpl.toBigInt(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Converts the value at [key] (or [alternativeKeys]) to [DateTime].
  DateTime getDateTime(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          String? format,
          String? locale,
          bool autoDetectFormat = false,
          bool useCurrentLocale = false,
          bool utc = false,
          DateTime? defaultValue}) =>
      ConvertObjectImpl.toDateTime(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        format: format,
        locale: locale,
        autoDetectFormat: autoDetectFormat,
        useCurrentLocale: useCurrentLocale,
        utc: utc,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Converts the value at [key] (or [alternativeKeys]) to [Uri].
  Uri getUri(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          Uri? defaultValue}) =>
      ConvertObjectImpl.toUri(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Converts the value at [key] (or [alternativeKeys]) to an enum using [parser].
  T getEnum<T extends Enum>(K key,
          {required T Function(dynamic) parser,
          List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          T? defaultValue}) =>
      ConvertObjectImpl.toEnum<T>(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        parser: parser,
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Returns a list containing all the values in the map.
  List<V> get valuesList => ConvertObjectImpl.toList<V>(
        values,
        debugInfo: {'method': 'MapConversionX.valuesList'},
      );

  /// Returns a list containing all the keys in the map.
  List<K> get keysList => ConvertObjectImpl.toList<K>(
        keys,
        debugInfo: {'method': 'MapConversionX.keysList'},
      );

  /// Returns a set containing all the values in the map.
  Set<V> get valuesSet => ConvertObjectImpl.toSet<V>(
        values,
        debugInfo: {'method': 'MapConversionX.valuesSet'},
      );

  /// Returns a set containing all the keys in the map.
  Set<K> get keysSet => ConvertObjectImpl.toSet<K>(
        keys,
        debugInfo: {'method': 'MapConversionX.keysSet'},
      );

  // Parsing helpers (non-nullable map)

  /// Parses the nested map at [key] using the provided [converter].
  T parse<T, K2, V2>(K key, T Function(Map<K2, V2> json) converter) {
    final raw = this[key];
    final map = ConvertObjectImpl.toMap<K2, V2>(raw);
    return converter.call(map);
  }

  /// Tries to parse the nested map at [key] using the provided [converter].
  T? tryParse<T, K2, V2>(K key, T Function(Map<K2, V2> json) converter) {
    final raw = this[key];
    final map = ConvertObjectImpl.tryToMap<K2, V2>(raw);
    if (map == null) return null;
    return converter.call(map);
  }
}

/// Conversion helpers for nullable maps.
extension NullableMapConversionX<K, V> on Map<K, V>? {
  V? _firstValueForKeys(K key, {List<K>? alternativeKeys}) {
    final map = this;
    if (map == null) return null;
    var value = map[key];
    if (value == null &&
        alternativeKeys != null &&
        alternativeKeys.isNotEmpty) {
      final altKey = alternativeKeys.firstWhereOrNull(map.containsKey);
      if (altKey != null) value = map[altKey];
    }
    return value;
  }

  /// Tries to convert the value at [key] (or [alternativeKeys]) to [String].
  String? tryGetString(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          String? defaultValue}) =>
      ConvertObjectImpl.tryToString(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to [int].
  int? tryGetInt(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          int? defaultValue,
          String? format,
          String? locale}) =>
      ConvertObjectImpl.tryToInt(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        format: format,
        locale: locale,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to [double].
  double? tryGetDouble(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          double? defaultValue,
          String? format,
          String? locale}) =>
      ConvertObjectImpl.tryToDouble(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        format: format,
        locale: locale,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to [num].
  num? tryGetNum(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          num? defaultValue,
          String? format,
          String? locale,
          ElementConverter<num>? converter}) =>
      ConvertObjectImpl.tryToNum(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        format: format,
        locale: locale,
        converter: converter,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to [bool].
  bool? tryGetBool(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          bool? defaultValue}) =>
      ConvertObjectImpl.tryToBool(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to a [List] of [T].
  List<T>? tryGetList<T>(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          List<T>? defaultValue}) =>
      ConvertObjectImpl.tryToList<T>(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to a [Set] of [T].
  Set<T>? tryGetSet<T>(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          Set<T>? defaultValue}) =>
      ConvertObjectImpl.tryToSet<T>(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to a [Map] of [K2] to [V2].
  Map<K2, V2>? tryGetMap<K2, V2>(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          Map<K2, V2>? defaultValue}) =>
      ConvertObjectImpl.tryToMap<K2, V2>(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to [BigInt].
  BigInt? tryGetBigInt(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          BigInt? defaultValue}) =>
      ConvertObjectImpl.tryToBigInt(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to [DateTime].
  DateTime? tryGetDateTime(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          String? format,
          String? locale,
          bool autoDetectFormat = false,
          bool useCurrentLocale = false,
          bool utc = false,
          DateTime? defaultValue}) =>
      ConvertObjectImpl.tryToDateTime(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        format: format,
        locale: locale,
        autoDetectFormat: autoDetectFormat,
        useCurrentLocale: useCurrentLocale,
        utc: utc,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to [Uri].
  Uri? tryGetUri(K key,
          {List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          Uri? defaultValue}) =>
      ConvertObjectImpl.tryToUri(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to an enum using [parser].
  T? tryGetEnum<T extends Enum>(K key,
          {required T Function(dynamic) parser,
          List<K>? alternativeKeys,
          dynamic innerKey,
          int? innerListIndex,
          T? defaultValue}) =>
      ConvertObjectImpl.tryToEnum<T>(
        _firstValueForKeys(key, alternativeKeys: alternativeKeys),
        parser: parser,
        mapKey: innerKey,
        listIndex: innerListIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'key': key,
          if (alternativeKeys != null && alternativeKeys.isNotEmpty)
            'altKeys': alternativeKeys,
        },
      );
}
