/// Adds boolean parsing helpers to dynamic values.
///
/// This extension is used internally by `Convert.toBool` but can also be used
/// directly when you want a simple, non-throwing conversion with default rules.
///
/// See also: `BoolOptions` for configurable parsing via `ConvertConfig`.
extension BoolParsingX on Object? {
  /// Converts any value to a boolean with predictable, conservative semantics.
  ///
  /// ### Conversion Rules:
  /// * `null` returns `false`.
  /// * [bool] values pass through unchanged.
  /// * [num] values: positive numbers (`> 0`) are `true`, others `false`.
  /// * [String] values (case-insensitive after trimming):
  ///   - Truthy tokens: `'true'`, `'1'`, `'yes'`, `'y'`, `'on'`, `'ok'`, `'t'`
  ///   - Falsy tokens: `'false'`, `'0'`, `'no'`, `'n'`, `'off'`, `'f'`
  ///   - Numeric strings are parsed and treated as numbers.
  ///   - Unrecognized strings return `false` (conservative default).
  ///
  /// This getter never throws - unrecognized inputs silently return `false`.
  bool get asBool {
    final v = this;
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v > 0;

    final s = v.toString().trim().toLowerCase();
    if (s.isEmpty) return false;

    // Numeric `String` values
    final n = num.tryParse(s);
    if (n != null) return n > 0;

    const truthy = {'true', '1', 'yes', 'y', 'on', 'ok', 't'};
    const falsy = {'false', '0', 'no', 'n', 'off', 'f'};
    if (truthy.contains(s)) return true;
    if (falsy.contains(s)) return false;

    return false;
  }
}
