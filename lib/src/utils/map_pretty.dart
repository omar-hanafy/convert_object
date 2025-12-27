import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

/// Strategy for encoding DateTime values.
enum DateTimeStrategy {
  /// Example: "2025-11-11T10:15:30.123Z"
  iso8601String,

  /// Milliseconds since Unix epoch (UTC).
  millisecondsSinceEpoch,

  /// Microseconds since Unix epoch (UTC).
  microsecondsSinceEpoch,
}

/// Strategy for encoding Duration values.
enum DurationStrategy {
  /// Integer milliseconds.
  milliseconds,

  /// Integer microseconds.
  microseconds,

  /// ISO-8601 duration, e.g. "PT1H2M3.5S"
  iso8601,
}

/// Strategy for non-finite doubles (`NaN`, `Infinity`, `-Infinity`).
enum NonFiniteDoubleStrategy {
  /// Encode as strings: "NaN", "Infinity", "-Infinity".
  string,

  /// Replace with `null`.
  nullValue,

  /// Throw during encoding.
  error,
}

/// Options controlling how values are normalized into JSON-safe forms.
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
}) {
  final seen = options.detectCycles ? <int>{} : null;

  dynamic walk(dynamic v) {
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

    // Optional cycle detection.
    if (options.detectCycles) {
      final id = identityHashCode(v);
      if (seen!.contains(id)) return options.cyclePlaceholder;
      seen.add(id);
    }

    // Allow a caller-provided encoder to run first.
    if (toEncodable != null) {
      final transformed = toEncodable(v);
      if (transformed != null && !identical(transformed, v)) {
        final out = walk(transformed);
        if (options.detectCycles) seen!.remove(identityHashCode(v));
        return out;
      }
    }

    // Common helpful encodings.
    if (v is Enum) {
      final out = options.encodeEnumsAsName ? v.name : v.index;
      if (options.detectCycles) seen!.remove(identityHashCode(v));
      return out;
    }
    if (v is DateTime) {
      final out = switch (options.dateTimeStrategy) {
        DateTimeStrategy.iso8601String => v.toIso8601String(),
        DateTimeStrategy.millisecondsSinceEpoch => v.millisecondsSinceEpoch,
        DateTimeStrategy.microsecondsSinceEpoch => v.microsecondsSinceEpoch,
      };
      if (options.detectCycles) seen!.remove(identityHashCode(v));
      return out;
    }
    if (v is Duration) {
      final out = switch (options.durationStrategy) {
        DurationStrategy.milliseconds => v.inMilliseconds,
        DurationStrategy.microseconds => v.inMicroseconds,
        DurationStrategy.iso8601 => _durationToIso8601(v),
      };
      if (options.detectCycles) seen!.remove(identityHashCode(v));
      return out;
    }
    if (v is Uri) {
      if (options.detectCycles) seen!.remove(identityHashCode(v));
      return v.toString();
    }
    if (v is BigInt) {
      if (options.detectCycles) seen!.remove(identityHashCode(v));
      return v.toString();
    }
    if (v is Uint8List) {
      if (options.detectCycles) seen!.remove(identityHashCode(v));
      return base64Encode(v);
    }
    if (v is ByteBuffer) {
      if (options.detectCycles) seen!.remove(identityHashCode(v));
      return base64Encode(v.asUint8List());
    }
    if (v is ByteData) {
      if (options.detectCycles) seen!.remove(identityHashCode(v));
      return base64Encode(v.buffer.asUint8List());
    }

    // Collections.
    if (v is Map) {
      final map = <String, dynamic>{};
      v.forEach((key, val) {
        if (options.dropNulls && val == null) return;
        map[key.toString()] = walk(val);
      });
      final result = options.sortKeys
          ? SplayTreeMap<String, dynamic>.from(map, (a, b) => a.compareTo(b))
          : map;
      if (options.detectCycles) seen!.remove(identityHashCode(v));
      return result;
    }
    if (v is Set && options.setsAsLists) {
      final list = v.map(walk).toList();
      if (options.detectCycles) seen!.remove(identityHashCode(v));
      return list;
    }
    if (v is Iterable) {
      final list = v.map(walk).toList();
      if (options.detectCycles) seen!.remove(identityHashCode(v));
      return list;
    }

    // Fallback.
    if (options.detectCycles) seen!.remove(identityHashCode(v));
    if (options.stringifyUnknown) {
      return v.toString();
    }
    throw UnsupportedError(
      'Value of type ${v.runtimeType} is not JSON encodable. '
      'Provide JsonOptions.stringifyUnknown=true or a toEncodable handler.',
    );
  }

  return walk(value);
}

String _durationToIso8601(Duration d) {
  // PnDTnHnMnS with fractional seconds if needed.
  final days = d.inDays;
  final hours = d.inHours.remainder(24);
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  final micros = d.inMicroseconds.remainder(1000000);

  final b = StringBuffer('P');
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
  }) {
    final out = <String, dynamic>{};
    forEach((key, value) {
      if (options.dropNulls && value == null) return;
      out[key.toString()] = jsonSafe(
        value,
        options: options,
        toEncodable: toEncodable,
      );
    });
    return options.sortKeys
        ? SplayTreeMap<String, dynamic>.from(out, (a, b) => a.compareTo(b))
        : out;
  }

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
    (e) => jsonSafe(e, options: options, toEncodable: toEncodable),
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
