import 'package:convert_object/src/exceptions/conversion_exception.dart';

/// Represents the outcome of a conversion, capturing either a value or error.
class ConversionResult<T> {
  /// Internal base constructor used by the public factories.
  const ConversionResult._(this._value, this._error);

  /// Creates a successful result wrapping [value].
  factory ConversionResult.success(T value) => ConversionResult._(value, null);

  /// Creates a failed result wrapping [error].
  factory ConversionResult.failure(
    ConversionException error,
  ) =>
      ConversionResult._(null, error);
  final T? _value;
  final ConversionException? _error;

  /// Whether this result contains a value.
  bool get isSuccess => _error == null;

  /// Whether this result contains an error.
  bool get isFailure => _error != null;

  /// Returns the converted value or throws the stored [ConversionException].
  T get value {
    if (_error != null) {
      Error.throwWithStackTrace(_error!, _error!.stackTrace);
    }
    return _value as T;
  }

  /// Returns the converted value when successful, otherwise `null`.
  T? get valueOrNull => _error == null ? _value : null;

  /// Returns the converted value or [defaultValue] when a failure occurred.
  T valueOr(T defaultValue) => _error == null ? (_value as T) : defaultValue;

  /// The captured [ConversionException], if any.
  ConversionException? get error => _error;

  /// Transforms the contained value when successful.
  ConversionResult<R> map<R>(R Function(T value) transform) {
    if (isSuccess) {
      return ConversionResult.success(transform(_value as T));
    }
    return ConversionResult.failure(_error!);
  }

  /// Chains conversion results, forwarding failures automatically.
  ConversionResult<R> flatMap<R>(ConversionResult<R> Function(T value) next) {
    if (isSuccess) {
      return next(_value as T);
    }
    return ConversionResult.failure(_error!);
  }

  /// Folds the result into a single value using the supplied callbacks.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(ConversionException error) onFailure,
  }) {
    if (isSuccess) return onSuccess(_value as T);
    return onFailure(_error!);
  }
}
