import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

/// Strategy for encoding [DateTime] values to JSON.
///
/// Used by [JsonOptions.dateTimeStrategy] to control how dates are serialized.
enum DateTimeStrategy {
  /// ISO 8601 string format (e.g., `"2025-11-11T10:15:30.123Z"`).
  ///
  /// This is the most portable format and preserves timezone information.
  iso8601String,

  /// Milliseconds since Unix epoch (1970-01-01T00:00:00Z) as an integer.
  ///
  /// Compact but loses sub-millisecond precision.
  millisecondsSinceEpoch,

  /// Microseconds since Unix epoch as an integer.
  ///
  /// Preserves full [DateTime] precision but produces large numbers.
  microsecondsSinceEpoch,
}

/// Strategy for encoding [Duration] values to JSON.
///
/// Used by [JsonOptions.durationStrategy] to control how durations are serialized.
enum DurationStrategy {
  /// Integer milliseconds.
  milliseconds,

  /// Integer microseconds (preserves full precision).
  microseconds,

  /// ISO 8601 duration format (e.g., `"PT1H2M3.5S"` for 1 hour, 2 minutes, 3.5 seconds).
  iso8601,
}

/// Strategy for handling non-finite doubles (`NaN`, `Infinity`, `-Infinity`) in JSON.
///
/// Standard JSON does not support non-finite values. This enum controls the fallback behavior.
enum NonFiniteDoubleStrategy {
  /// Encode as strings: `"NaN"`, `"Infinity"`, `"-Infinity"`.
  ///
  /// Preserves information but requires special handling on the receiving end.
  string,

  /// Replace non-finite values with `null`.
  nullValue,

  /// Throw [UnsupportedError] when a non-finite value is encountered.
  error,
}

/// Configuration for JSON normalization via [jsonSafe] and related helpers.
///
/// Controls how Dart-specific types like [DateTime], [Duration], [Enum], and
/// non-finite doubles are converted to JSON-compatible representations.
///
/// ### Example
/// ```dart
/// final options = JsonOptions(
///   dropNulls: true,
///   sortKeys: true,
///   dateTimeStrategy: DateTimeStrategy.millisecondsSinceEpoch,
/// );
/// final json = myMap.toJsonString(options: options);
/// ```
class JsonOptions {
  /// Creates a new configuration bundle for JSON normalization.
  const JsonOptions({
    this.encodeEnumsAsName = true,
    this.dateTimeStrategy = DateTimeStrategy.iso8601String,
    this.durationStrategy = DurationStrategy.milliseconds,
    this.nonFiniteDoubles = NonFiniteDoubleStrategy.string,
    this.stringifyUnknown = true,
    this.setsAsLists = true,
    this.dropNulls = false,
    this.sortKeys = false,
    this.detectCycles = false,
    this.cyclePlaceholder = '<cycle>',
  });

  /// Encode enums by `.name` (true) or `.index` (false).
  final bool encodeEnumsAsName;

  /// How to encode DateTime values.
  final DateTimeStrategy dateTimeStrategy;

  /// How to encode Duration values.
  final DurationStrategy durationStrategy;

  /// What to do with non-finite doubles (NaN/±Infinity).
  final NonFiniteDoubleStrategy nonFiniteDoubles;

  /// If true, unknown objects fall back to `toString()`. If false, throw.
  final bool stringifyUnknown;

  /// If true, encode Sets as Lists.
  final bool setsAsLists;

  /// If true, drop `null` map values at all nesting levels.
  final bool dropNulls;

  /// If true, sort map keys lexicographically (all levels).
  final bool sortKeys;

  /// If true, detect reference cycles to avoid infinite recursion.
  final bool detectCycles;

  /// Placeholder emitted when a cycle is detected.
  final String cyclePlaceholder;

  /// Returns a copy of these options with the provided fields replaced.
  JsonOptions copyWith({
    bool? encodeEnumsAsName,
    DateTimeStrategy? dateTimeStrategy,
    DurationStrategy? durationStrategy,
    NonFiniteDoubleStrategy? nonFiniteDoubles,
    bool? stringifyUnknown,
    bool? setsAsLists,
    bool? dropNulls,
    bool? sortKeys,
    bool? detectCycles,
    String? cyclePlaceholder,
  }) {
    return JsonOptions(
      encodeEnumsAsName: encodeEnumsAsName ?? this.encodeEnumsAsName,
      dateTimeStrategy: dateTimeStrategy ?? this.dateTimeStrategy,
      durationStrategy: durationStrategy ?? this.durationStrategy,
      nonFiniteDoubles: nonFiniteDoubles ?? this.nonFiniteDoubles,
      stringifyUnknown: stringifyUnknown ?? this.stringifyUnknown,
      setsAsLists: setsAsLists ?? this.setsAsLists,
      dropNulls: dropNulls ?? this.dropNulls,
      sortKeys: sortKeys ?? this.sortKeys,
      detectCycles: detectCycles ?? this.detectCycles,
      cyclePlaceholder: cyclePlaceholder ?? this.cyclePlaceholder,
    );
  }
}

/// Returns a JSON-encodable form of [value], honoring [options].
///
/// Use [toEncodable] to transform application-specific objects before
/// built-in conversions apply.
dynamic jsonSafe(
  dynamic value, {
  JsonOptions options = const JsonOptions(),
  Object? Function(dynamic object)? toEncodable,
}) => _createJsonWalker(options, toEncodable)(value);

dynamic Function(Object?) _createJsonWalker(
  JsonOptions options,
  Object? Function(dynamic object)? toEncodable, {
  Object? rootContainer,
}) {
  final ancestors = options.detectCycles ? HashSet<Object>.identity() : null;
  if (rootContainer != null) ancestors?.add(rootContainer);

  dynamic walk(Object? v) {
    // Handle null, bool, and string early.
    if (v == null || v is bool || v is String) return v;

    // Numbers with special-casing for non-finite doubles.
    if (v is num) {
      if (v is double && (v.isNaN || v.isInfinite)) {
        switch (options.nonFiniteDoubles) {
          case NonFiniteDoubleStrategy.string:
            if (v.isNaN) return 'NaN';
            return v.isNegative ? '-Infinity' : 'Infinity';
          case NonFiniteDoubleStrategy.nullValue:
            return null;
          case NonFiniteDoubleStrategy.error:
            throw UnsupportedError('Non-finite double not allowed in JSON: $v');
        }
      }
      return v; // finite number
    }

    if (ancestors != null && !ancestors.add(v)) {
      return options.cyclePlaceholder;
    }

    try {
      if (toEncodable != null) {
        final transformed = toEncodable(v);
        if (transformed != null && !identical(transformed, v)) {
          return walk(transformed);
        }
      }

      if (v is Enum) return options.encodeEnumsAsName ? v.name : v.index;
      if (v is DateTime) {
        return switch (options.dateTimeStrategy) {
          DateTimeStrategy.iso8601String => v.toIso8601String(),
          DateTimeStrategy.millisecondsSinceEpoch => v.millisecondsSinceEpoch,
          DateTimeStrategy.microsecondsSinceEpoch => v.microsecondsSinceEpoch,
        };
      }
      if (v is Duration) {
        return switch (options.durationStrategy) {
          DurationStrategy.milliseconds => v.inMilliseconds,
          DurationStrategy.microseconds => v.inMicroseconds,
          DurationStrategy.iso8601 => _durationToIso8601(v),
        };
      }
      if (v is Uri || v is BigInt) return v.toString();
      if (v is Uint8List) return base64Encode(v);
      if (v is ByteBuffer) return base64Encode(v.asUint8List());
      if (v is ByteData) return base64Encode(Uint8List.sublistView(v));

      if (v is Map<Object?, Object?>) return _encodeJsonMap(v, options, walk);
      if (v is Set<Object?> && options.setsAsLists) return v.map(walk).toList();
      if (v is Iterable<Object?>) return v.map(walk).toList();

      if (options.stringifyUnknown) return v.toString();
      throw UnsupportedError(
        'Value of type ${v.runtimeType} is not JSON encodable. '
        'Provide JsonOptions.stringifyUnknown=true or a toEncodable handler.',
      );
    } finally {
      ancestors?.remove(v);
    }
  }

  return walk;
}

Map<String, dynamic> _encodeJsonMap(
  Map<Object?, Object?> input,
  JsonOptions options,
  dynamic Function(Object?) walk,
) {
  final out = <String, dynamic>{};
  input.forEach((key, value) {
    if (options.dropNulls && value == null) return;
    out[key.toString()] = walk(value);
  });
  return options.sortKeys
      ? SplayTreeMap<String, dynamic>.from(out, (a, b) => a.compareTo(b))
      : out;
}

String _durationToIso8601(Duration d) {
  // Taking the magnitude of each component also handles the minimum Duration.
  final days = d.inDays.abs();
  final hours = d.inHours.remainder(24).abs();
  final minutes = d.inMinutes.remainder(60).abs();
  final seconds = d.inSeconds.remainder(60).abs();
  final micros = d.inMicroseconds.remainder(1000000).abs();

  final b = StringBuffer(d.isNegative ? '-P' : 'P');
  if (days != 0) {
    b
      ..write(days)
      ..write('D');
  }

  if (hours != 0 || minutes != 0 || seconds != 0 || micros != 0) {
    b.write('T');
    if (hours != 0) {
      b
        ..write(hours)
        ..write('H');
    }
    if (minutes != 0) {
      b
        ..write(minutes)
        ..write('M');
    }
    if (micros != 0) {
      final s = seconds + micros / 1e6;
      final trimmed = s
          .toStringAsFixed(6)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
      b
        ..write(trimmed)
        ..write('S');
    } else if (seconds != 0) {
      b
        ..write(seconds)
        ..write('S');
    }
  }

  if (b.length == 1) {
    b.write('T0S'); // Exactly zero.
  }
  return b.toString();
}

/// ----------------------
/// Map helpers
/// ----------------------

/// Convenience JSON encoding helpers for `Map` implementations.
extension JsonMapX<K, V> on Map<K, V> {
  /// Converts this map to a `Map<String, dynamic>` with JSON-encodable values.
  ///
  /// - Non-string keys are stringified with `toString()`.
  /// - Honors [options] for null filtering, key sorting, etc.
  /// - [toEncodable] can transform app-specific objects.
  Map<String, dynamic> toJsonMap({
    JsonOptions options = const JsonOptions(),
    Object? Function(dynamic object)? toEncodable,
  }) => _encodeJsonMap(
    this,
    options,
    _createJsonWalker(options, toEncodable, rootContainer: this),
  );

  /// Converts this map to a JSON string (pretty if [indent] is provided).
  String toJsonString({
    String? indent,
    JsonOptions options = const JsonOptions(),
    Object? Function(dynamic object)? toEncodable,
  }) {
    final data = toJsonMap(options: options, toEncodable: toEncodable);
    final encoder = indent == null
        ? const JsonEncoder()
        : JsonEncoder.withIndent(indent);
    return encoder.convert(data);
  }

  /// Convenience getter used by `ConversionException.toString()`.
  ///
  /// Produces 2-space pretty JSON via [toJsonString].
  String get encodeWithIndent => toJsonString(indent: '  ');
}

/// ----------------------
/// Iterable helpers
/// ----------------------

/// Convenience JSON encoding helpers for `Iterable` implementations.
extension JsonIterableX<T> on Iterable<T> {
  /// Converts this iterable to a JSON-encodable `List`.
  List<dynamic> toJsonList({
    JsonOptions options = const JsonOptions(),
    Object? Function(dynamic object)? toEncodable,
  }) => map<dynamic>(
    _createJsonWalker(options, toEncodable, rootContainer: this),
  ).toList();

  /// Converts this iterable to a JSON string (pretty if [indent] is provided).
  String toJsonString({
    String? indent,
    JsonOptions options = const JsonOptions(),
    Object? Function(dynamic object)? toEncodable,
  }) {
    final data = toJsonList(options: options, toEncodable: toEncodable);
    final encoder = indent == null
        ? const JsonEncoder()
        : JsonEncoder.withIndent(indent);
    return encoder.convert(data);
  }

  /// Convenience getter mirroring the Map variant for parity.
  String get encodeWithIndent => toJsonString(indent: '  ');
}

/// ----------------------
/// Object helpers
/// ----------------------

/// Convenience JSON encoding helpers for any value.
extension JsonAnyX on Object? {
  /// Returns a JSON-encodable form of this value.
  dynamic toJsonSafe({
    JsonOptions options = const JsonOptions(),
    Object? Function(dynamic object)? toEncodable,
  }) => jsonSafe(this, options: options, toEncodable: toEncodable);

  /// Encodes this value directly to JSON text (pretty if [indent] is provided).
  String toJsonString({
    String? indent,
    JsonOptions options = const JsonOptions(),
    Object? Function(dynamic object)? toEncodable,
  }) {
    final safe = toJsonSafe(options: options, toEncodable: toEncodable);
    final encoder = indent == null
        ? const JsonEncoder()
        : JsonEncoder.withIndent(indent);
    return encoder.convert(safe);
  }
}
