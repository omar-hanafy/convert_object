import 'package:convert_object/src/exceptions/conversion_exception.dart';

/// A monadic wrapper representing the outcome of a type conversion operation.
///
/// Use [ConversionResult] when you need to capture both success and failure
/// states without immediately throwing exceptions. This is useful for:
/// * Batch processing where you want to collect all errors before reporting.
/// * Functional-style pipelines using [map] and [flatMap].
/// * Deferred error handling via [fold].
///
/// ### Example
/// ```dart
/// final result = ConversionResult.success(42);
/// final doubled = result.map((v) => v * 2);
/// print(doubled.value); // 84
/// ```
///
/// See also: [ConversionException] for the error type captured on failure.
class ConversionResult<T> {
  /// Internal constructor - use [ConversionResult.success] or
  /// [ConversionResult.failure] instead.
  const ConversionResult._(this._value, this._error);

  /// Creates a successful result containing [value].
  ///
  /// The resulting [isSuccess] will be `true` and [value] will return
  /// the wrapped value without throwing.
  factory ConversionResult.success(T value) => ConversionResult._(value, null);

  /// Creates a failed result containing [error].
  ///
  /// The resulting [isFailure] will be `true` and accessing [value] will
  /// rethrow the captured exception with its original stack trace.
  factory ConversionResult.failure(ConversionException error) =>
      ConversionResult._(null, error);

  final T? _value;
  final ConversionException? _error;

  /// Returns `true` if this result contains a successfully converted value.
  ///
  /// When `true`, [value] and [valueOrNull] are safe to access without throwing.
  bool get isSuccess => _error == null;

  /// Returns `true` if this result contains an error.
  ///
  /// When `true`, [error] contains the captured [ConversionException].
  bool get isFailure => _error != null;

  /// Returns the converted value, throwing [ConversionException] on failure.
  ///
  /// The exception is rethrown with its original stack trace preserved for
  /// accurate debugging. Prefer [valueOrNull] or [valueOr] for exception-free
  /// access, or [fold] for explicit handling of both cases.
  T get value {
    final error = _error;
    if (error != null) {
      Error.throwWithStackTrace(error, error.stackTrace);
    }
    return _value as T;
  }

  /// Returns the converted value when successful, or `null` on failure.
  ///
  /// This is a safe, exception-free accessor. Note that if [T] is nullable,
  /// a `null` return value is ambiguous - use [isSuccess] to distinguish.
  T? get valueOrNull => _error == null ? _value : null;

  /// Returns the converted value when successful, or [defaultValue] on failure.
  ///
  /// Useful for providing fallback values without exception handling overhead.
  T valueOr(T defaultValue) => _error == null ? (_value as T) : defaultValue;

  /// The captured [ConversionException] if this is a failure, otherwise `null`.
  ///
  /// Use [ConversionException.fullReport] to generate detailed diagnostic output.
  ConversionException? get error => _error;

  /// Transforms the contained value using [transform] when successful.
  ///
  /// Failures are forwarded unchanged. Use this for safe value transformations
  /// without manual success/failure checks.
  ConversionResult<R> map<R>(R Function(T value) transform) {
    if (isSuccess) {
      return ConversionResult.success(transform(_value as T));
    }
    return ConversionResult.failure(_error!);
  }

  /// Chains another conversion operation when this result is successful.
  ///
  /// Unlike [map], the [next] function returns a [ConversionResult], allowing
  /// composition of fallible operations. Failures short-circuit the chain.
  ConversionResult<R> flatMap<R>(ConversionResult<R> Function(T value) next) {
    if (isSuccess) {
      return next(_value as T);
    }
    return ConversionResult.failure(_error!);
  }

  /// Reduces this result to a single value by handling both outcomes explicitly.
  ///
  /// Both callbacks are required, ensuring exhaustive handling. This is the
  /// recommended way to consume results when you need to act on failures.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(ConversionException error) onFailure,
  }) {
    if (isSuccess) return onSuccess(_value as T);
    return onFailure(_error!);
  }
}
