// test/test.dart
//
// Master test aggregator.
//
// Usage:
//   dart test test/test.dart
//
// Env toggles:
//   INCLUDE_PROPERTY=0   -> skip property tests
//   INCLUDE_FUZZ=0       -> skip fuzz tests
//
// By default everything runs.

import 'dart:io' as io;

// --- API ---
import 'api/convert_object_facade_text_test.dart' as api_facade_text;
import 'api/converter_wrapper_text_test.dart' as api_converter_wrapper;
import 'api/top_level_functions_text_test.dart' as api_top_level;
import 'core/convert_object_impl_collections_test.dart' as core_collections;
import 'core/convert_object_impl_dates_test.dart' as core_dates;
import 'core/convert_object_impl_numbers_test.dart' as core_numbers;
// --- CORE ---
import 'core/convert_object_impl_text_test.dart' as core_text;
import 'core/convert_object_impl_uri_test.dart' as core_uri;
// --- ENUMS ---
import 'enums/enum_parsers_test.dart' as enums_suite;
import 'extensions/iterable_extensions_text_test.dart' as ext_iterable_text;
import 'extensions/let_extensions_test.dart' as ext_let;
// --- EXTENSIONS ---
import 'extensions/map_extensions_text_test.dart' as ext_map_text;
import 'extensions/object_convert_extension_test.dart' as ext_object_convert;
// --- FUZZ (optional/slow-ish) ---
import 'fuzz/dates_fuzz_test.dart' as fuzz_dates;
import 'fuzz/num_fuzz_test.dart' as fuzz_num;
// --- PROPERTY (optional/slow-ish) ---
import 'property/numbers_property_test.dart' as prop_numbers;
import 'property/text_roundtrip_property_test.dart' as prop_text;
// --- RESULT ---
import 'result/conversion_result_test.dart' as result_suite;
// --- UTILS ---
import 'utils/bools_test.dart' as utils_bools;
import 'utils/dates_test.dart' as utils_dates;
import 'utils/json_test.dart' as utils_json;
import 'utils/map_pretty_test.dart' as utils_map_pretty;
import 'utils/numbers_test.dart' as utils_numbers;
import 'utils/uri_test.dart' as utils_uri;

void main() {
  final includeProperty = _envFlag('INCLUDE_PROPERTY');
  final includeFuzz = _envFlag('INCLUDE_FUZZ');

  // API
  api_facade_text.main();
  api_converter_wrapper.main();
  api_top_level.main();

  // CORE
  core_text.main();
  core_numbers.main();
  core_dates.main();
  core_collections.main();
  core_uri.main();

  // EXTENSIONS
  ext_map_text.main();
  ext_iterable_text.main();
  ext_object_convert.main();
  ext_let.main();

  // ENUMS
  enums_suite.main();

  // RESULT
  result_suite.main();

  // UTILS
  utils_bools.main();
  utils_dates.main();
  utils_json.main();
  utils_map_pretty.main();
  utils_numbers.main();
  utils_uri.main();

  // OPTIONAL
  if (includeProperty) {
    prop_numbers.main();
    prop_text.main();
  }

  if (includeFuzz) {
    fuzz_dates.main();
    fuzz_num.main();
  }
}

bool _envFlag(String name, {bool defaultValue = true}) {
  final v = io.Platform.environment[name]?.toLowerCase();
  if (v == null) return defaultValue;
  return v == '1' || v == 'true' || v == 'yes' || v == 'on';
}
