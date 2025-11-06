import 'package:convert_object/src/core/convert_object_impl.dart';

/// Helpers for building resilient enum parsing callbacks.
class EnumParsers {
  /// Builds a parser that resolves enum values by their [Enum.name].
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

  /// Wraps a string parser so it can be used with dynamic values.
  static T Function(dynamic) fromString<T>(T Function(String) fromString) =>
      (dynamic obj) => fromString(obj.toString());

  /// Builds a parser that returns [fallback] when the name cannot be resolved.
  static T Function(dynamic) byNameOrFallback<T extends Enum>(
    List<T> values,
    T fallback,
  ) =>
      (dynamic obj) {
        try {
          return values.byName(obj.toString());
        } catch (_) {
          return fallback;
        }
      };

  /// Builds a parser that matches enum names ignoring case.
  static T Function(dynamic) byNameCaseInsensitive<T extends Enum>(
    List<T> values,
  ) =>
      (dynamic obj) {
        final str = obj.toString().trim().toLowerCase();
        return values.firstWhere(
          (e) => e.name.toLowerCase() == str,
          orElse: () => throw ArgumentError('Invalid enum value: $obj'),
        );
      };

  /// Builds a parser matching enum indices via [ConvertObjectImpl.toInt].
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

/// Convenience accessors for creating enum parsing callbacks from a list.
extension EnumValuesParsing<T extends Enum> on List<T> {
  /// Returns a parser that resolves names using [EnumParsers.byName].
  T Function(dynamic) get parser => EnumParsers.byName(this);

  /// Returns a parser that falls back to [fallback] when a name is unknown.
  T Function(dynamic) parserWithFallback(T fallback) =>
      EnumParsers.byNameOrFallback(this, fallback);

  /// Returns a parser that ignores case when matching names.
  T Function(dynamic) get parserCaseInsensitive =>
      EnumParsers.byNameCaseInsensitive(this);

  /// Returns a parser that matches enum indices.
  T Function(dynamic) get parserByIndex => EnumParsers.byIndex(this);
}
