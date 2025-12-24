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

  /// Generates an indented JSON report of the full conversion context.
  String fullReport() {
    final encodable = jsonSafe(context);
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
    final method = context['method'];
    final targetType = context['targetType'];
    final objectType = context['objectType'];
    final mapKey = context['mapKey'];
    final listIndex = context['listIndex'];
    final details = <String>[
      if (method != null) 'method=$method',
      if (targetType != null) 'targetType=$targetType',
      if (objectType != null) 'objectType=$objectType',
      if (mapKey != null) 'mapKey=$mapKey',
      if (listIndex != null) 'listIndex=$listIndex',
    ];
    final suffix = details.isEmpty ? '' : ' (${details.join(', ')})';
    return 'ConversionException($errorType): $error$suffix';
  }
}
