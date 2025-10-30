/// Kotlin-style `let` helper for non-nullable types.
extension LetExtension<T extends Object> on T {
  /// Executes [block] with `this` and returns the result.
  R let<R>(R Function(T it) block) => block(this);
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
}
