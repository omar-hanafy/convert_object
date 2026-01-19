import 'package:convert_object/src/core/converter.dart';

/// Adds a [convert] getter for fluent type conversions on any value.
///
/// This extension is the primary entry point for the fluent conversion API,
/// allowing chained operations like:
/// ```dart
/// final age = jsonMap.convert.fromMap('user').fromMap('age').toInt();
/// ```
///
/// See also: [Converter] for the full fluent API documentation.
extension ConvertObjectExtension on Object? {
  /// Wraps this value in a [Converter] for fluent chained conversions.
  ///
  /// The returned [Converter] provides methods for navigation ([Converter.fromMap],
  /// [Converter.fromList]) and type conversion ([Converter.toInt], [Converter.string], etc.).
  Converter get convert => Converter(this);
}
