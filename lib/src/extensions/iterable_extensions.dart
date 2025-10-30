import '../core/convert_object_impl.dart';

extension _IterableIndexing<E> on Iterable<E> {
  E? _elementAtOrNull(int index) {
    if (index < 0) return null;
    if (this is List) {
      final list = this as List;
      return index < list.length ? list[index] as E : null;
    }
    var i = 0;
    for (final element in this) {
      if (i == index) return element;
      i++;
    }
    return null;
  }
}

extension IterableConversionX<E> on Iterable<E> {
  E? _valueAt(int index) => _elementAtOrNull(index);

  // Get-as helpers with inner selection and defaults
  String getText(
    int index, {
    dynamic innerMapKey,
    int? innerIndex,
    String? defaultValue,
    ElementConverter<String>? converter,
  }) =>
      ConvertObjectImpl.toText(
        _valueAt(index),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        defaultValue: defaultValue,
        converter: converter,
        debugInfo: {'index': index},
      );

  int getInt(
    int index, {
    dynamic innerMapKey,
    int? innerIndex,
    String? format,
    String? locale,
    int? defaultValue,
    ElementConverter<int>? converter,
  }) =>
      ConvertObjectImpl.toInt(
        _valueAt(index),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        format: format,
        locale: locale,
        defaultValue: defaultValue,
        converter: converter,
        debugInfo: {'index': index},
      );

  double getDouble(
    int index, {
    dynamic innerMapKey,
    int? innerIndex,
    String? format,
    String? locale,
    double? defaultValue,
    ElementConverter<double>? converter,
  }) =>
      ConvertObjectImpl.toDouble(
        _valueAt(index),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        format: format,
        locale: locale,
        defaultValue: defaultValue,
        converter: converter,
        debugInfo: {'index': index},
      );

  num getNum(
    int index, {
    dynamic innerMapKey,
    int? innerIndex,
    String? format,
    String? locale,
    num? defaultValue,
    ElementConverter<num>? converter,
  }) =>
      ConvertObjectImpl.toNum(
        _valueAt(index),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        format: format,
        locale: locale,
        defaultValue: defaultValue,
        converter: converter,
        debugInfo: {'index': index},
      );

  bool getBool(
    int index, {
    dynamic innerMapKey,
    int? innerIndex,
    bool? defaultValue,
    ElementConverter<bool>? converter,
  }) =>
      ConvertObjectImpl.toBool(
        _valueAt(index),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        defaultValue: defaultValue,
        converter: converter,
        debugInfo: {'index': index},
      );

  BigInt getBigInt(
    int index, {
    dynamic innerMapKey,
    int? innerIndex,
    BigInt? defaultValue,
    ElementConverter<BigInt>? converter,
  }) =>
      ConvertObjectImpl.toBigInt(
        _valueAt(index),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        defaultValue: defaultValue,
        converter: converter,
        debugInfo: {'index': index},
      );

  DateTime getDateTime(
    int index, {
    dynamic innerMapKey,
    int? innerIndex,
    String? format,
    String? locale,
    bool autoDetectFormat = false,
    bool useCurrentLocale = false,
    bool utc = false,
    DateTime? defaultValue,
    ElementConverter<DateTime>? converter,
  }) =>
      ConvertObjectImpl.toDateTime(
        _valueAt(index),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        format: format,
        locale: locale,
        autoDetectFormat: autoDetectFormat,
        useCurrentLocale: useCurrentLocale,
        utc: utc,
        defaultValue: defaultValue,
        converter: converter,
        debugInfo: {'index': index},
      );

  Uri getUri(
    int index, {
    dynamic innerMapKey,
    int? innerIndex,
    Uri? defaultValue,
    ElementConverter<Uri>? converter,
  }) =>
      ConvertObjectImpl.toUri(
        _valueAt(index),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        defaultValue: defaultValue,
        converter: converter,
        debugInfo: {'index': index},
      );

  List<T> getList<T>(int index,
          {dynamic innerMapKey, int? innerIndex, List<T>? defaultValue}) =>
      ConvertObjectImpl.toList<T>(
        _valueAt(index),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        defaultValue: defaultValue,
        debugInfo: {'index': index},
      );

  Set<T> getSet<T>(int index,
          {dynamic innerMapKey, int? innerIndex, Set<T>? defaultValue}) =>
      ConvertObjectImpl.toSet<T>(
        _valueAt(index),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        defaultValue: defaultValue,
        debugInfo: {'index': index},
      );

  Map<K2, V2> getMap<K2, V2>(int index,
          {dynamic innerMapKey, int? innerIndex, Map<K2, V2>? defaultValue}) =>
      ConvertObjectImpl.toMap<K2, V2>(
        _valueAt(index),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        defaultValue: defaultValue,
        debugInfo: {'index': index},
      );

  T getEnum<T extends Enum>(int index,
          {required T Function(dynamic) parser,
          dynamic innerMapKey,
          int? innerIndex,
          T? defaultValue}) =>
      ConvertObjectImpl.toEnum<T>(
        _valueAt(index),
        parser: parser,
        mapKey: innerMapKey,
        listIndex: innerIndex,
        defaultValue: defaultValue,
        debugInfo: {'index': index},
      );

  // Convert all
  List<T> convertAll<T>() =>
      map((e) => ConvertObjectImpl.toType<T>(e)).toList();

  /// Returns this iterable as a mutable [Set] using the centralized conversion logic.
  Set<E> toMutableSet({ElementConverter<E>? converter}) =>
      ConvertObjectImpl.toSet<E>(
        this,
        elementConverter: converter,
        debugInfo: {'method': 'IterableConversionX.toMutableSet'},
      );

  /// Returns a union-like set combining this iterable and [other].
  ///
  /// Matches the historical behaviour from dart_helper_utils where the method
  /// name was `intersect` but it effectively merged the elements.
  Set<E> intersect(Iterable<dynamic> other, {ElementConverter<E>? converter}) {
    final base = toMutableSet(converter: converter);
    final otherSet = ConvertObjectImpl.toSet<E>(
      other,
      elementConverter: converter,
      debugInfo: {'method': 'IterableConversionX.intersect'},
    );
    base.addAll(otherSet);
    return base;
  }

  /// Maps the elements and eagerly materializes them into a [List] using convert_object.
  List<R> mapList<R>(R Function(E e) mapper,
          {ElementConverter<R>? converter}) =>
      ConvertObjectImpl.toList<R>(
        map(mapper),
        elementConverter: converter,
        debugInfo: {'method': 'IterableConversionX.mapList'},
      );

  /// Maps elements with their index and eagerly materializes the result into a [List].
  List<R> mapIndexedList<R>(R Function(int index, E element) mapper,
      {ElementConverter<R>? converter}) {
    var index = 0;
    final mapped = map((element) => mapper(index++, element));
    return ConvertObjectImpl.toList<R>(
      mapped,
      elementConverter: converter,
      debugInfo: {'method': 'IterableConversionX.mapIndexedList'},
    );
  }
}

extension NullableIterableConversionX<E> on Iterable<E>? {
  E? _firstForIndices(int index, {List<int>? alternativeIndices}) {
    final it = this;
    if (it == null) return null;
    final primary = it._elementAtOrNull(index);
    if (primary != null) return primary;
    if (alternativeIndices != null) {
      for (final i in alternativeIndices) {
        final candidate = it._elementAtOrNull(i);
        if (candidate != null) return candidate;
      }
    }
    return null;
  }

  String? tryGetText(
    int index, {
    List<int>? alternativeIndices,
    dynamic innerMapKey,
    int? innerIndex,
    String? defaultValue,
    ElementConverter<String>? converter,
  }) =>
      ConvertObjectImpl.tryToText(
        _firstForIndices(index, alternativeIndices: alternativeIndices),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        defaultValue: defaultValue,
        converter: converter,
        debugInfo: {
          'index': index,
          if (alternativeIndices != null && alternativeIndices.isNotEmpty)
            'altIndexes': alternativeIndices,
        },
      );

  int? tryGetInt(
    int index, {
    List<int>? alternativeIndices,
    dynamic innerMapKey,
    int? innerIndex,
    String? format,
    String? locale,
    int? defaultValue,
    ElementConverter<int>? converter,
  }) =>
      ConvertObjectImpl.tryToInt(
        _firstForIndices(index, alternativeIndices: alternativeIndices),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        format: format,
        locale: locale,
        defaultValue: defaultValue,
        converter: converter,
        debugInfo: {
          'index': index,
          if (alternativeIndices != null && alternativeIndices.isNotEmpty)
            'altIndexes': alternativeIndices,
        },
      );

  double? tryGetDouble(
    int index, {
    List<int>? alternativeIndices,
    dynamic innerMapKey,
    int? innerIndex,
    String? format,
    String? locale,
    double? defaultValue,
    ElementConverter<double>? converter,
  }) =>
      ConvertObjectImpl.tryToDouble(
        _firstForIndices(index, alternativeIndices: alternativeIndices),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        format: format,
        locale: locale,
        defaultValue: defaultValue,
        converter: converter,
        debugInfo: {
          'index': index,
          if (alternativeIndices != null && alternativeIndices.isNotEmpty)
            'altIndexes': alternativeIndices,
        },
      );

  bool? tryGetBool(
    int index, {
    List<int>? alternativeIndices,
    dynamic innerMapKey,
    int? innerIndex,
    bool? defaultValue,
    ElementConverter<bool>? converter,
  }) =>
      ConvertObjectImpl.tryToBool(
        _firstForIndices(index, alternativeIndices: alternativeIndices),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        defaultValue: defaultValue,
        converter: converter,
        debugInfo: {
          'index': index,
          if (alternativeIndices != null && alternativeIndices.isNotEmpty)
            'altIndexes': alternativeIndices,
        },
      );

  num? tryGetNum(
    int index, {
    List<int>? alternativeIndices,
    dynamic innerMapKey,
    int? innerIndex,
    String? format,
    String? locale,
    num? defaultValue,
    ElementConverter<num>? converter,
  }) =>
      ConvertObjectImpl.tryToNum(
        _firstForIndices(index, alternativeIndices: alternativeIndices),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        format: format,
        locale: locale,
        defaultValue: defaultValue,
        converter: converter,
        debugInfo: {
          'index': index,
          if (alternativeIndices != null && alternativeIndices.isNotEmpty)
            'altIndexes': alternativeIndices,
        },
      );

  BigInt? tryGetBigInt(
    int index, {
    List<int>? alternativeIndices,
    dynamic innerMapKey,
    int? innerIndex,
    BigInt? defaultValue,
    ElementConverter<BigInt>? converter,
  }) =>
      ConvertObjectImpl.tryToBigInt(
        _firstForIndices(index, alternativeIndices: alternativeIndices),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        defaultValue: defaultValue,
        converter: converter,
        debugInfo: {
          'index': index,
          if (alternativeIndices != null && alternativeIndices.isNotEmpty)
            'altIndexes': alternativeIndices,
        },
      );

  DateTime? tryGetDateTime(
    int index, {
    List<int>? alternativeIndices,
    dynamic innerMapKey,
    int? innerIndex,
    String? format,
    String? locale,
    bool autoDetectFormat = false,
    bool useCurrentLocale = false,
    bool utc = false,
    DateTime? defaultValue,
    ElementConverter<DateTime>? converter,
  }) =>
      ConvertObjectImpl.tryToDateTime(
        _firstForIndices(index, alternativeIndices: alternativeIndices),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        format: format,
        locale: locale,
        autoDetectFormat: autoDetectFormat,
        useCurrentLocale: useCurrentLocale,
        utc: utc,
        defaultValue: defaultValue,
        converter: converter,
        debugInfo: {
          'index': index,
          if (alternativeIndices != null && alternativeIndices.isNotEmpty)
            'altIndexes': alternativeIndices,
        },
      );

  Uri? tryGetUri(
    int index, {
    List<int>? alternativeIndices,
    dynamic innerMapKey,
    int? innerIndex,
    Uri? defaultValue,
    ElementConverter<Uri>? converter,
  }) =>
      ConvertObjectImpl.tryToUri(
        _firstForIndices(index, alternativeIndices: alternativeIndices),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        defaultValue: defaultValue,
        converter: converter,
        debugInfo: {
          'index': index,
          if (alternativeIndices != null && alternativeIndices.isNotEmpty)
            'altIndexes': alternativeIndices,
        },
      );

  List<T>? tryGetList<T>(int index,
          {List<int>? alternativeIndices,
          dynamic innerMapKey,
          int? innerIndex,
          List<T>? defaultValue}) =>
      ConvertObjectImpl.tryToList<T>(
        _firstForIndices(index, alternativeIndices: alternativeIndices),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'index': index,
          if (alternativeIndices != null && alternativeIndices.isNotEmpty)
            'altIndexes': alternativeIndices,
        },
      );

  Set<T>? tryGetSet<T>(int index,
          {List<int>? alternativeIndices,
          dynamic innerMapKey,
          int? innerIndex,
          Set<T>? defaultValue}) =>
      ConvertObjectImpl.tryToSet<T>(
        _firstForIndices(index, alternativeIndices: alternativeIndices),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'index': index,
          if (alternativeIndices != null && alternativeIndices.isNotEmpty)
            'altIndexes': alternativeIndices,
        },
      );

  Map<K2, V2>? tryGetMap<K2, V2>(int index,
          {List<int>? alternativeIndices,
          dynamic innerMapKey,
          int? innerIndex,
          Map<K2, V2>? defaultValue}) =>
      ConvertObjectImpl.tryToMap<K2, V2>(
        _firstForIndices(index, alternativeIndices: alternativeIndices),
        mapKey: innerMapKey,
        listIndex: innerIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'index': index,
          if (alternativeIndices != null && alternativeIndices.isNotEmpty)
            'altIndexes': alternativeIndices,
        },
      );

  T? tryGetEnum<T extends Enum>(int index,
          {required T Function(dynamic) parser,
          List<int>? alternativeIndices,
          dynamic innerMapKey,
          int? innerIndex,
          T? defaultValue}) =>
      ConvertObjectImpl.tryToEnum<T>(
        _firstForIndices(index, alternativeIndices: alternativeIndices),
        parser: parser,
        mapKey: innerMapKey,
        listIndex: innerIndex,
        defaultValue: defaultValue,
        debugInfo: {
          'index': index,
          if (alternativeIndices != null && alternativeIndices.isNotEmpty)
            'altIndexes': alternativeIndices,
        },
      );
}

extension SetConvertToX<E> on Set<E>? {
  Set<R> convertTo<R>() => ConvertObjectImpl.toSet<R>(this);
}
