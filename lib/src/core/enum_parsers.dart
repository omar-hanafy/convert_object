import 'convert_object_impl.dart';

class EnumParsers {
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

  static T Function(dynamic) fromText<T>(T Function(String) fromText) =>
      (dynamic obj) => fromText(obj.toString());

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

extension EnumValuesParsing<T extends Enum> on List<T> {
  T Function(dynamic) get parser => EnumParsers.byName(this);

  T Function(dynamic) parserWithFallback(T fallback) =>
      EnumParsers.byNameOrFallback(this, fallback);

  T Function(dynamic) get parserCaseInsensitive =>
      EnumParsers.byNameCaseInsensitive(this);

  T Function(dynamic) get parserByIndex => EnumParsers.byIndex(this);
}
