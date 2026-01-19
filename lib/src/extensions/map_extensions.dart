import 'package:convert_object/src/core/convert_object_impl.dart';

// Provides firstWhere without throwing StateError when no match is found.
extension _I<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

/// Type conversion helpers for non-nullable [Map] instances.
///
/// Provides key-based value extraction with automatic type conversion.
/// Each method looks up the value for [key] (with optional fallback to
/// [alternativeKeys]) and converts it to the target type.
///
/// ### Example
/// ```dart
/// final json = {'name': 'Alice', 'age': '25', 'active': 'true'};
/// final name = json.getString('name');      // 'Alice'
/// final age = json.getInt('age');           // 25
/// final active = json.getBool('active');    // true
/// ```
///
/// ### Alternative Keys
/// When APIs vary in naming conventions, use [alternativeKeys] for resilience:
/// ```dart
/// final id = json.getInt('id', alternativeKeys: ['ID', '_id', 'userId']);
/// ```
///
/// ### Nested Navigation
/// For complex structures, use [innerKey] and [innerListIndex]:
/// ```dart
/// final city = json.getString('address', innerKey: 'city');
/// ```
///
/// See also: [NullableMapConversionX] for nullable-safe `tryGetX` variants.
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
  String getString(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    String? defaultValue,
    ElementConverter<String>? converter,
  }) => ConvertObjectImpl.string(
    _firstValueForKeys(key, alternativeKeys: alternativeKeys),
    mapKey: innerKey,
    listIndex: innerListIndex,
    defaultValue: defaultValue,
    converter: converter,
    debugInfo: {
      'key': key,
      if (alternativeKeys != null && alternativeKeys.isNotEmpty)
        'altKeys': alternativeKeys,
    },
  );

  /// Converts the value at [key] (or [alternativeKeys]) to [int].
  int getInt(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    int? defaultValue,
    String? format,
    String? locale,
    ElementConverter<int>? converter,
  }) => ConvertObjectImpl.toInt(
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

  /// Converts the value at [key] (or [alternativeKeys]) to [double].
  double getDouble(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    double? defaultValue,
    String? format,
    String? locale,
    ElementConverter<double>? converter,
  }) => ConvertObjectImpl.toDouble(
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

  /// Converts the value at [key] (or [alternativeKeys]) to [num].
  num getNum(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    num? defaultValue,
    String? format,
    String? locale,
    ElementConverter<num>? converter,
  }) => ConvertObjectImpl.toNum(
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
  bool getBool(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    bool? defaultValue,
    ElementConverter<bool>? converter,
  }) => ConvertObjectImpl.toBool(
    _firstValueForKeys(key, alternativeKeys: alternativeKeys),
    mapKey: innerKey,
    listIndex: innerListIndex,
    defaultValue: defaultValue,
    converter: converter,
    debugInfo: {
      'key': key,
      if (alternativeKeys != null && alternativeKeys.isNotEmpty)
        'altKeys': alternativeKeys,
    },
  );

  /// Converts the value at [key] (or [alternativeKeys]) to a [List] of [T].
  List<T> getList<T>(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    List<T>? defaultValue,
    ElementConverter<T>? elementConverter,
  }) => ConvertObjectImpl.toList<T>(
    _firstValueForKeys(key, alternativeKeys: alternativeKeys),
    mapKey: innerKey,
    listIndex: innerListIndex,
    defaultValue: defaultValue,
    elementConverter: elementConverter,
    debugInfo: {
      'key': key,
      if (alternativeKeys != null && alternativeKeys.isNotEmpty)
        'altKeys': alternativeKeys,
    },
  );

  /// Converts the value at [key] (or [alternativeKeys]) to a [Set] of [T].
  Set<T> getSet<T>(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    Set<T>? defaultValue,
    ElementConverter<T>? elementConverter,
  }) => ConvertObjectImpl.toSet<T>(
    _firstValueForKeys(key, alternativeKeys: alternativeKeys),
    mapKey: innerKey,
    listIndex: innerListIndex,
    defaultValue: defaultValue,
    elementConverter: elementConverter,
    debugInfo: {
      'key': key,
      if (alternativeKeys != null && alternativeKeys.isNotEmpty)
        'altKeys': alternativeKeys,
    },
  );

  /// Converts the value at [key] (or [alternativeKeys]) to a [Map] of [K2] to [V2].
  Map<K2, V2> getMap<K2, V2>(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    Map<K2, V2>? defaultValue,
    ElementConverter<K2>? keyConverter,
    ElementConverter<V2>? valueConverter,
  }) => ConvertObjectImpl.toMap<K2, V2>(
    _firstValueForKeys(key, alternativeKeys: alternativeKeys),
    mapKey: innerKey,
    listIndex: innerListIndex,
    defaultValue: defaultValue,
    keyConverter: keyConverter,
    valueConverter: valueConverter,
    debugInfo: {
      'key': key,
      if (alternativeKeys != null && alternativeKeys.isNotEmpty)
        'altKeys': alternativeKeys,
    },
  );

  /// Converts the value at [key] (or [alternativeKeys]) to [BigInt].
  BigInt getBigInt(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    BigInt? defaultValue,
    ElementConverter<BigInt>? converter,
  }) => ConvertObjectImpl.toBigInt(
    _firstValueForKeys(key, alternativeKeys: alternativeKeys),
    mapKey: innerKey,
    listIndex: innerListIndex,
    defaultValue: defaultValue,
    converter: converter,
    debugInfo: {
      'key': key,
      if (alternativeKeys != null && alternativeKeys.isNotEmpty)
        'altKeys': alternativeKeys,
    },
  );

  /// Converts the value at [key] (or [alternativeKeys]) to [DateTime].
  DateTime getDateTime(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    String? format,
    String? locale,
    bool autoDetectFormat = false,
    bool useCurrentLocale = false,
    bool utc = false,
    DateTime? defaultValue,
    ElementConverter<DateTime>? converter,
  }) => ConvertObjectImpl.toDateTime(
    _firstValueForKeys(key, alternativeKeys: alternativeKeys),
    mapKey: innerKey,
    listIndex: innerListIndex,
    format: format,
    locale: locale,
    autoDetectFormat: autoDetectFormat,
    useCurrentLocale: useCurrentLocale,
    utc: utc,
    defaultValue: defaultValue,
    converter: converter,
    debugInfo: {
      'key': key,
      if (alternativeKeys != null && alternativeKeys.isNotEmpty)
        'altKeys': alternativeKeys,
    },
  );

  /// Converts the value at [key] (or [alternativeKeys]) to [Uri].
  Uri getUri(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    Uri? defaultValue,
    ElementConverter<Uri>? converter,
  }) => ConvertObjectImpl.toUri(
    _firstValueForKeys(key, alternativeKeys: alternativeKeys),
    mapKey: innerKey,
    listIndex: innerListIndex,
    defaultValue: defaultValue,
    converter: converter,
    debugInfo: {
      'key': key,
      if (alternativeKeys != null && alternativeKeys.isNotEmpty)
        'altKeys': alternativeKeys,
    },
  );

  /// Converts the value at [key] (or [alternativeKeys]) to an enum using [parser].
  T getEnum<T extends Enum>(
    K key, {
    required T Function(dynamic) parser,
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    T? defaultValue,
    Map<String, dynamic>? debugInfo,
  }) {
    final info = <String, dynamic>{};
    if (debugInfo != null && debugInfo.isNotEmpty) {
      info.addAll(debugInfo);
    }
    info['key'] = key;
    if (alternativeKeys != null && alternativeKeys.isNotEmpty) {
      info['altKeys'] = alternativeKeys;
    }
    return ConvertObjectImpl.toEnum<T>(
      _firstValueForKeys(key, alternativeKeys: alternativeKeys),
      parser: parser,
      mapKey: innerKey,
      listIndex: innerListIndex,
      defaultValue: defaultValue,
      debugInfo: info,
    );
  }

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
  String? tryGetString(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    String? defaultValue,
    ElementConverter<String>? converter,
  }) => ConvertObjectImpl.tryToString(
    _firstValueForKeys(key, alternativeKeys: alternativeKeys),
    mapKey: innerKey,
    listIndex: innerListIndex,
    defaultValue: defaultValue,
    converter: converter,
    debugInfo: {
      'key': key,
      if (alternativeKeys != null && alternativeKeys.isNotEmpty)
        'altKeys': alternativeKeys,
    },
  );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to [int].
  int? tryGetInt(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    int? defaultValue,
    String? format,
    String? locale,
    ElementConverter<int>? converter,
  }) => ConvertObjectImpl.tryToInt(
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

  /// Tries to convert the value at [key] (or [alternativeKeys]) to [double].
  double? tryGetDouble(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    double? defaultValue,
    String? format,
    String? locale,
    ElementConverter<double>? converter,
  }) => ConvertObjectImpl.tryToDouble(
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

  /// Tries to convert the value at [key] (or [alternativeKeys]) to [num].
  num? tryGetNum(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    num? defaultValue,
    String? format,
    String? locale,
    ElementConverter<num>? converter,
  }) => ConvertObjectImpl.tryToNum(
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
  bool? tryGetBool(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    bool? defaultValue,
    ElementConverter<bool>? converter,
  }) => ConvertObjectImpl.tryToBool(
    _firstValueForKeys(key, alternativeKeys: alternativeKeys),
    mapKey: innerKey,
    listIndex: innerListIndex,
    defaultValue: defaultValue,
    converter: converter,
    debugInfo: {
      'key': key,
      if (alternativeKeys != null && alternativeKeys.isNotEmpty)
        'altKeys': alternativeKeys,
    },
  );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to a [List] of [T].
  List<T>? tryGetList<T>(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    List<T>? defaultValue,
    ElementConverter<T>? elementConverter,
  }) => ConvertObjectImpl.tryToList<T>(
    _firstValueForKeys(key, alternativeKeys: alternativeKeys),
    mapKey: innerKey,
    listIndex: innerListIndex,
    defaultValue: defaultValue,
    elementConverter: elementConverter,
    debugInfo: {
      'key': key,
      if (alternativeKeys != null && alternativeKeys.isNotEmpty)
        'altKeys': alternativeKeys,
    },
  );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to a [Set] of [T].
  Set<T>? tryGetSet<T>(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    Set<T>? defaultValue,
    ElementConverter<T>? elementConverter,
  }) => ConvertObjectImpl.tryToSet<T>(
    _firstValueForKeys(key, alternativeKeys: alternativeKeys),
    mapKey: innerKey,
    listIndex: innerListIndex,
    defaultValue: defaultValue,
    elementConverter: elementConverter,
    debugInfo: {
      'key': key,
      if (alternativeKeys != null && alternativeKeys.isNotEmpty)
        'altKeys': alternativeKeys,
    },
  );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to a [Map] of [K2] to [V2].
  Map<K2, V2>? tryGetMap<K2, V2>(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    Map<K2, V2>? defaultValue,
    ElementConverter<K2>? keyConverter,
    ElementConverter<V2>? valueConverter,
  }) => ConvertObjectImpl.tryToMap<K2, V2>(
    _firstValueForKeys(key, alternativeKeys: alternativeKeys),
    mapKey: innerKey,
    listIndex: innerListIndex,
    defaultValue: defaultValue,
    keyConverter: keyConverter,
    valueConverter: valueConverter,
    debugInfo: {
      'key': key,
      if (alternativeKeys != null && alternativeKeys.isNotEmpty)
        'altKeys': alternativeKeys,
    },
  );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to [BigInt].
  BigInt? tryGetBigInt(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    BigInt? defaultValue,
    ElementConverter<BigInt>? converter,
  }) => ConvertObjectImpl.tryToBigInt(
    _firstValueForKeys(key, alternativeKeys: alternativeKeys),
    mapKey: innerKey,
    listIndex: innerListIndex,
    defaultValue: defaultValue,
    converter: converter,
    debugInfo: {
      'key': key,
      if (alternativeKeys != null && alternativeKeys.isNotEmpty)
        'altKeys': alternativeKeys,
    },
  );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to [DateTime].
  DateTime? tryGetDateTime(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    String? format,
    String? locale,
    bool autoDetectFormat = false,
    bool useCurrentLocale = false,
    bool utc = false,
    DateTime? defaultValue,
    ElementConverter<DateTime>? converter,
  }) => ConvertObjectImpl.tryToDateTime(
    _firstValueForKeys(key, alternativeKeys: alternativeKeys),
    mapKey: innerKey,
    listIndex: innerListIndex,
    format: format,
    locale: locale,
    autoDetectFormat: autoDetectFormat,
    useCurrentLocale: useCurrentLocale,
    utc: utc,
    defaultValue: defaultValue,
    converter: converter,
    debugInfo: {
      'key': key,
      if (alternativeKeys != null && alternativeKeys.isNotEmpty)
        'altKeys': alternativeKeys,
    },
  );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to [Uri].
  Uri? tryGetUri(
    K key, {
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    Uri? defaultValue,
    ElementConverter<Uri>? converter,
  }) => ConvertObjectImpl.tryToUri(
    _firstValueForKeys(key, alternativeKeys: alternativeKeys),
    mapKey: innerKey,
    listIndex: innerListIndex,
    defaultValue: defaultValue,
    converter: converter,
    debugInfo: {
      'key': key,
      if (alternativeKeys != null && alternativeKeys.isNotEmpty)
        'altKeys': alternativeKeys,
    },
  );

  /// Tries to convert the value at [key] (or [alternativeKeys]) to an enum using [parser].
  T? tryGetEnum<T extends Enum>(
    K key, {
    required T Function(dynamic) parser,
    List<K>? alternativeKeys,
    dynamic innerKey,
    int? innerListIndex,
    T? defaultValue,
    Map<String, dynamic>? debugInfo,
  }) {
    final info = <String, dynamic>{};
    if (debugInfo != null && debugInfo.isNotEmpty) {
      info.addAll(debugInfo);
    }
    info['key'] = key;
    if (alternativeKeys != null && alternativeKeys.isNotEmpty) {
      info['altKeys'] = alternativeKeys;
    }
    return ConvertObjectImpl.tryToEnum<T>(
      _firstValueForKeys(key, alternativeKeys: alternativeKeys),
      parser: parser,
      mapKey: innerKey,
      listIndex: innerListIndex,
      defaultValue: defaultValue,
      debugInfo: info,
    );
  }
}
