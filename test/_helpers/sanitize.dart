/// Utilities to sanitize volatile output (paths, ANSI, stacks) for golden tests.
///
/// Typical usage:
///
///   import '../_helpers/sanitize.dart';
///
///   final raw = e.toString(); // from a ConversionException
///   final stable = sanitizeForGolden(raw);
///   expect(stable, contains('<List with 200 items>'));
///
/// If you want strict golden matching, read the file and compare after
/// sanitization to avoid OS-specific path/line-number diffs.

/// Remove ANSI color/style escape codes.
String stripAnsi(String input) {
  // Matches ESC[ ... m sequences.
  final ansi = RegExp(r'\x1B\[[0-9;]*m');
  return input.replaceAll(ansi, '');
}

/// Normalize Windows backslashes to Unix-style slashes for stability.
String normalizePaths(String input) {
  return input.replaceAll('\\', '/');
}

/// Normalize line endings to '\n'.
String normalizeLineEndings(String input) {
  return input.replaceAll('\r\n', '\n');
}

/// Coarsely sanitize stack traces: drop stack frame lines and file:line:col
/// occurrences which vary run-to-run.
///
/// This keeps the high-level error/context message stable while ignoring
/// volatile details.
String sanitizeStackTraces(String input) {
  var out = input;

  // Remove lines that look like stack frames beginning with "#<num>"
  out = out.replaceAll(RegExp(r'^\s*#\d+.*$', multiLine: true), '');

  // Remove file URLs with line/column suffixes.
  out = out.replaceAll(RegExp(r'file:///[^\s:]+:\d+:\d+'), '');

  // Remove absolute POSIX paths with line:col.
  out = out.replaceAll(RegExp(r'/(?:[^:\s])+:\\?\d+:\d+'), '');

  // Collapse multiple blank lines.
  out = out.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  return out.trimRight();
}

/// Compose all sanitizers for golden-friendly text.
String sanitizeForGolden(String input) {
  var out = input;
  out = stripAnsi(out);
  out = normalizePaths(out);
  out = normalizeLineEndings(out);
  out = sanitizeStackTraces(out);
  return out;
}
