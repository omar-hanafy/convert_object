import 'dart:convert';

dynamic makeValueEncodable(dynamic value) {
  if (value is String ||
      value is int ||
      value is double ||
      value is bool ||
      value == null) {
    return value;
  } else if (value is Enum) {
    return value.name;
  } else if (value is List) {
    return value.map(makeValueEncodable).toList();
  } else if (value is Set) {
    return value.map(makeValueEncodable).toList();
  } else if (value is Map) {
    return value.encodableCopy;
  } else {
    return value.toString();
  }
}

///  DHUMapExtension
extension PrettyJsonMap<K, V> on Map<K, V> {
  /// Returns a new map with converted dynamic keys and values to a map with `String` keys and JSON-encodable values.
  ///
  /// This is useful for preparing data for JSON serialization, where keys must be `String` values.
  Map<String, dynamic> get encodableCopy {
    final result = <String, dynamic>{};
    forEach((key, value) {
      result[key.toString()] = makeValueEncodable(value);
    });
    return result;
  }

  /// Converts a map with potentially complex data types to a formatted JSON text.
  ///
  /// The resulting JSON is indented for readability.
  String get encodedJsonText =>
      const JsonEncoder.withIndent('  ').convert(encodableCopy);
}

extension PrettyJsonIterable on Iterable<dynamic> {
  /// Returns a JSON-encodable representation of this iterable.
  List<dynamic> get encodableList =>
      map<dynamic>((element) => makeValueEncodable(element)).toList();

  /// Converts the iterable to a compact JSON text.
  String get encodedJson => const JsonEncoder().convert(encodableList);

  /// Converts the iterable to a pretty-printed JSON text.
  String encodedJsonWithIndent([String indent = '  ']) =>
      JsonEncoder.withIndent(indent).convert(encodableList);
}

extension PrettyJsonObject on Object? {
  /// Encodes this object into a JSON text.
  ///
  /// Provides a centralized entry point for JSON serialization, allowing callers
  /// to supply a [toEncodable] fallback for non-serializable objects.
  String encode({Object? Function(dynamic object)? toEncodable}) =>
      json.encode(this, toEncodable: toEncodable);
}
