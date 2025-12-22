/// Test-only enums used across the suite.
///
/// Keep these small, stable, and descriptive. Prefer adding a new enum rather
/// than reusing one with unclear semantics.
library;

enum TestColor { red, green, blue }

enum TestStatus { pending, active, disabled }

enum TestHttpMethod { get, post, put, delete }

/// Convenience lists (useful in table-driven tests).
const List<TestColor> kTestColors = TestColor.values;
const List<TestStatus> kTestStatuses = TestStatus.values;
const List<TestHttpMethod> kTestHttpMethods = TestHttpMethod.values;
