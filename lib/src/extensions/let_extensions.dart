/// Kotlin-style `let` helper for non-nullable types.
extension LetExtension<T extends Object> on T {
  /// Executes [block] with `this` and returns the result.
  R let<R>(R Function(T it) block) => block(this);

  /// Executes [block] with `this` and returns `this` for fluent side effects.
  T also(void Function(T it) block) {
    block(this);
    return this;
  }

  /// Returns `this` if it satisfies [predicate], otherwise returns `null`.
  T? takeIf(bool Function(T it) predicate) => predicate(this) ? this : null;

  /// Returns `this` if it does NOT satisfy [predicate], otherwise returns `null`.
  T? takeUnless(bool Function(T it) predicate) =>
      !predicate(this) ? this : null;
}

/// Kotlin-style `let` helpers for nullable types.
extension LetExtensionNullable<T extends Object> on T? {
  /// Executes [block] when the receiver is non-null, returning its result.
  R? let<R>(R Function(T it) block) => this == null ? null : block(this as T);

  /// Executes [block] when non-null, otherwise returns [defaultValue].
  R letOr<R>(R Function(T it) block, {required R defaultValue}) =>
      this == null ? defaultValue : block(this as T);

  /// Back-compat variant whose [block] accepts a nullable receiver.
  R? letNullable<R>(R? Function(T? it) block) =>
      this == null ? null : block(this);

  /// Executes [block] when non-null and returns the original receiver.
  T? also(void Function(T it) block) {
    final value = this;
    if (value == null) return null;
    block(value);
    return value;
  }

  /// Returns the receiver if non-null and it satisfies [predicate], else `null`.
  T? takeIf(bool Function(T it) predicate) {
    final value = this;
    if (value == null) return null;
    return predicate(value) ? value : null;
  }

  /// Returns the receiver if non-null and it does NOT satisfy [predicate], else `null`.
  T? takeUnless(bool Function(T it) predicate) {
    final value = this;
    if (value == null) return null;
    return !predicate(value) ? value : null;
  }
}
