import 'dart:convert';

import 'package:convert_object/src/utils/map_pretty.dart';

/// Exception thrown when a type conversion fails.
///
/// [ConversionException] captures rich diagnostic context including:
/// * The original error or message that triggered the failure.
/// * A [context] map with method name, input/output types, and parameters.
/// * A [stackTrace] for debugging.
///
/// Use [fullReport] to generate detailed JSON output for logging or debugging.
///
/// ### Example
/// ```dart
/// try {
///   Convert.toInt('not-a-number');
/// } on ConversionException catch (e) {
///   print(e.fullReport()); // Detailed diagnostic output
/// }
/// ```
///
/// See also: `ConvertConfig.onException` for global error hooks.
class ConversionException implements Exception {
  /// Creates a conversion exception with the originating [error] and diagnostic [context].
  ///
  /// The [context] map is defensively copied and made unmodifiable.
  /// If [stackTrace] is not provided, the current stack trace is captured.
  ConversionException({
    required this.error,
    required Map<String, dynamic> context,
    StackTrace? stackTrace,
  }) : context = Map.unmodifiable(context),
       stackTrace = stackTrace ?? StackTrace.current;

  /// Creates an exception for `null` or unsupported source objects.
  ///
  /// Used internally when conversion receives a value that cannot be processed.
  factory ConversionException.nullObject({
    required Map<String, dynamic> context,
    required StackTrace stackTrace,
  }) => ConversionException(
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
