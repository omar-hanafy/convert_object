/// Kotlin-style scope functions for non-nullable types.
///
/// These extensions bring Kotlin's popular scope functions to Dart, enabling
/// concise transformations and side effects without intermediate variables.
///
/// ### Example
/// ```dart
/// final formatted = getUserName()
///   .let((name) => name.toUpperCase())
///   .also((name) => print('Processing: $name'));
/// ```
extension LetExtension<T extends Object> on T {
  /// Executes [block] with `this` as the argument and returns the result.
  ///
  /// Useful for inline transformations without intermediate variables:
  /// ```dart
  /// final length = fetchValue().let((v) => v.toString().length);
  /// ```
  R let<R>(R Function(T it) block) => block(this);

  /// Executes [block] with `this` for side effects, then returns `this`.
  ///
  /// Useful for logging or debugging in a fluent chain:
  /// ```dart
  /// fetchData().also((d) => print('Got: $d')).process();
  /// ```
  T also(void Function(T it) block) {
    block(this);
    return this;
  }

  /// Returns `this` if it satisfies [predicate], otherwise `null`.
  ///
  /// Useful for conditional filtering in a chain:
  /// ```dart
  /// value.takeIf((v) => v > 0)?.let((v) => process(v));
  /// ```
  T? takeIf(bool Function(T it) predicate) => predicate(this) ? this : null;

  /// Returns `this` if it does NOT satisfy [predicate], otherwise `null`.
  ///
  /// The inverse of [takeIf].
  T? takeUnless(bool Function(T it) predicate) =>
      !predicate(this) ? this : null;
}

/// Kotlin-style scope functions for nullable types.
///
/// These extensions safely handle `null` values, executing blocks only when
/// the receiver is non-null.
///
/// ### Example
/// ```dart
/// final result = maybeNull?.let((v) => v * 2) ?? 0;
/// ```
extension LetExtensionNullable<T extends Object> on T? {
  /// Executes [block] when non-null, returning its result or `null` if the receiver is `null`.
  R? let<R>(R Function(T it) block) => this == null ? null : block(this as T);

  /// Executes [block] when non-null, returning [defaultValue] if the receiver is `null`.
  ///
  /// Unlike [let], this always returns a non-null result.
  R letOr<R>(R Function(T it) block, {required R defaultValue}) =>
      this == null ? defaultValue : block(this as T);

  /// Backwards-compatible variant that passes the nullable receiver to [block].
  ///
  /// Prefer [let] for cleaner null handling.
  R? letNullable<R>(R? Function(T? it) block) =>
      this == null ? null : block(this);

  /// Executes [block] for side effects when non-null, returning the original receiver.
  T? also(void Function(T it) block) {
    final value = this;
    if (value == null) return null;
    block(value);
    return value;
  }

  /// Returns the receiver if non-null and satisfies [predicate], otherwise `null`.
  T? takeIf(bool Function(T it) predicate) {
    final value = this;
    if (value == null) return null;
    return predicate(value) ? value : null;
  }

  /// Returns the receiver if non-null and does NOT satisfy [predicate], otherwise `null`.
  T? takeUnless(bool Function(T it) predicate) {
    final value = this;
    if (value == null) return null;
    return !predicate(value) ? value : null;
  }
}
