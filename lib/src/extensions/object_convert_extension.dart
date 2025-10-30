import 'package:convert_object/src/core/converter.dart';

/// Adds a [convert] getter that exposes the fluent [Converter] API.
extension ConvertObjectExtension on Object? {
  /// Wraps the receiver in a [Converter] for chained lookups.
  Converter get convert => Converter(this);
}
