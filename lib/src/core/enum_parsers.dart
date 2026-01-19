import 'package:convert_object/src/core/convert_object_impl.dart';

/// Factory methods for building resilient enum parsing callbacks.
///
/// Use these parsers with `Convert.toEnum` to handle various input formats from
/// APIs that may return enum values as strings, integers, or mixed casing.
///
/// ### Example
/// ```dart
/// enum Status { pending, active, completed }
///
/// // Parse by name
/// final status = Convert.toEnum(
///   'active',
///   parser: EnumParsers.byName(Status.values),
/// );
///
/// // Parse by index
/// final status2 = Convert.toEnum(
///   1,
///   parser: EnumParsers.byIndex(Status.values),
/// );
/// ```
///
/// See also: [EnumValuesParsing] for convenient extension methods on enum lists.
class EnumParsers {
  /// Creates a parser that matches enum values by their [Enum.name] property.
  ///
  /// The input is stringified and trimmed. If the input contains a dot (e.g.,
  /// `Status.active`), only the part after the last dot is used for matching.
  ///
  /// Throws [StateError] if no matching enum value is found.
  static T Function(dynamic) byName<T extends Enum>(List<T> values) =>
      (dynamic obj) {
        if (obj is T) return obj;
        final raw = obj.toString().trim();
        final name = raw.contains('.') ? raw.split('.').last : raw;
        try {
          return values.firstWhere((e) => e.name == name);
        } on StateError {
          throw StateError('No enum value with that name: "$name"');
        }
      };

  /// Wraps a [String]-based parser to accept dynamic values.
  ///
  /// Useful for integrating with code generators that produce `fromString`
  /// methods, such as `json_serializable` or `freezed`.
  static T Function(dynamic) fromString<T>(T Function(String) fromString) =>
      (dynamic obj) => fromString(obj.toString());

  /// Creates a parser that returns [fallback] when no matching name is found.
  ///
  /// Use this for graceful degradation when the API may return unknown values
  /// (e.g., new enum cases added server-side before the client is updated).
  static T Function(dynamic) byNameOrFallback<T extends Enum>(
    List<T> values,
    T fallback,
  ) => (dynamic obj) {
    try {
      return values.byName(obj.toString());
    } catch (_) {
      return fallback;
    }
  };

  /// Creates a parser that matches names case-insensitively.
  ///
  /// Both the input and enum names are lowercased before comparison. Useful
  /// for APIs that inconsistently return `PENDING`, `Pending`, or `pending`.
  ///
  /// Throws [ArgumentError] if no matching enum value is found.
  static T Function(dynamic) byNameCaseInsensitive<T extends Enum>(
    List<T> values,
  ) => (dynamic obj) {
    final str = obj.toString().trim().toLowerCase();
    return values.firstWhere(
      (e) => e.name.toLowerCase() == str,
      orElse: () => throw ArgumentError('Invalid enum value: $obj'),
    );
  };

  /// Creates a parser that matches enum values by their numeric index.
  ///
  /// The input is converted to [int] using `ConvertObjectImpl.toInt`, which
  /// supports strings like `"1"` and numeric types.
  ///
  /// Throws [ArgumentError] if the index is out of bounds (must be `0` to
  /// `values.length - 1`).
  static T Function(dynamic) byIndex<T extends Enum>(List<T> values) =>
      (dynamic obj) {
        final index = ConvertObjectImpl.toInt(obj);
        if (index < 0 || index >= values.length) {
          throw ArgumentError(
            'Invalid enum index: $obj (valid range: 0-${values.length - 1})',
          );
        }
        return values[index];
      };
}

/// Convenience accessors for creating enum parsers directly from `Enum.values`.
///
/// These extension methods provide a fluent way to create parsers without
/// explicitly calling [EnumParsers] methods.
///
/// ### Example
/// ```dart
/// enum Priority { low, medium, high }
///
/// // Using extension methods
/// final parser = Priority.values.parser;
/// final priority = Convert.toEnum('high', parser: parser);
///
/// // Case-insensitive parsing
/// final p2 = Convert.toEnum('HIGH', parser: Priority.values.parserCaseInsensitive);
/// ```
extension EnumValuesParsing<T extends Enum> on List<T> {
  /// Returns a name-based parser using [EnumParsers.byName].
  ///
  /// Throws on unknown names. Use [parserWithFallback] for graceful handling.
  T Function(dynamic) get parser => EnumParsers.byName(this);

  /// Returns a name-based parser that returns [fallback] for unknown values.
  ///
  /// Useful when backward compatibility requires accepting unrecognized strings.
  T Function(dynamic) parserWithFallback(T fallback) =>
      EnumParsers.byNameOrFallback(this, fallback);

  /// Returns a case-insensitive name parser using [EnumParsers.byNameCaseInsensitive].
  ///
  /// Accepts `ACTIVE`, `Active`, or `active` for `MyEnum.active`.
  T Function(dynamic) get parserCaseInsensitive =>
      EnumParsers.byNameCaseInsensitive(this);

  /// Returns an index-based parser using [EnumParsers.byIndex].
  ///
  /// Accepts integers or numeric strings. Index `0` maps to the first enum value.
  T Function(dynamic) get parserByIndex => EnumParsers.byIndex(this);
}
