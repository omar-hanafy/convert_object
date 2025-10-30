import 'dart:convert';

import 'package:convert_object/src/utils/map_pretty.dart';

/// Exception thrown when a conversion fails.
class ConversionException implements Exception {
  /// Creates a conversion error with the originating [error] and [context].
  ConversionException({
    required this.error,
    required Map<String, dynamic> context,
    StackTrace? stackTrace,
  })  : context = Map.unmodifiable(context),
        stackTrace = stackTrace ?? StackTrace.current;

  /// Convenience factory used when the source object is `null` or unsupported.
  factory ConversionException.nullObject({
    required Map<String, dynamic> context,
    required StackTrace stackTrace,
  }) =>
      ConversionException(
        error: 'object is unsupported or null',
        context: context,
        stackTrace: stackTrace,
      );

  /// Original error or message that triggered the failure.
  final Object? error;

  /// Context metadata captured at the time of the conversion attempt.
  final Map<String, dynamic> context;

  /// Stack trace captured when the exception was created.
  final StackTrace stackTrace;

  /// String representation of [error]'s runtime type.
  String get errorType => error?.runtimeType.toString() ?? 'null';

  bool _isHeavyValue(dynamic value) {
    if (value == null) return false;
    if (value is Map && value.length > 10) return true;
    if (value is List && value.length > 10) return true;
    if (value is Set && value.length > 10) return true;
    if (value is String && value.length > 500) return true;
    return false;
  }

  Map<String, dynamic> _filteredContext() {
    final filtered = <String, dynamic>{};
    context.forEach((key, value) {
      if (value == null) return;
      if (key == 'object' || _isHeavyValue(value)) {
        if (value is Map) {
          filtered[key] = '<Map with ${value.length} entries>';
        } else if (value is List) {
          filtered[key] = '<List with ${value.length} items>';
        } else if (value is Set) {
          filtered[key] = '<Set with ${value.length} items>';
        } else if (value is String && value.length > 500) {
          filtered[key] = '<String with ${value.length} characters>';
        } else {
          filtered[key] = '<${value.runtimeType}>';
        }
      } else if (value is Function) {
        filtered[key] = '<Function: ${value.runtimeType}>';
      } else {
        filtered[key] = value;
      }
    });

    try {
      if (_isHeavyValue(error)) {
        filtered['error'] = '<${error.runtimeType}>';
      }
    } catch (_) {}

    return filtered;
  }

  /// Generates an indented JSON report of the full conversion context.
  String fullReport() {
    final encodable = context.map((k, v) {
      if (v is Function) return MapEntry(k, 'Function: ${v.runtimeType}');
      return MapEntry(k, v);
    });
    final json = const JsonEncoder.withIndent('  ').convert(encodable);
    return 'ConversionException (Full Report) {\n'
        '  error: $error,\n'
        '  errorType: $errorType,\n'
        '  context:\n$json,\n'
        '  stackTrace: $stackTrace\n'
        '}';
  }

  /// Returns a concise summary of the conversion failure.
  @override
  String toString() {
    final filtered = _filteredContext();
    final json = filtered.encodedJsonText;
    return 'ConversionException {\n'
        '  error: $error,\n'
        '  errorType: $errorType,\n'
        '  context:\n$json,\n'
        '  stackTrace: $stackTrace\n'
        '}';
  }
}
