LLM-README: convert_object

Purpose
Provide deterministic, composable conversions from dynamic/loosely-typed input to Dart primitives, dates, URIs, enums, and collections, with try/throw variants, JSON-aware collection parsing, and fluent wrappers.

Architecture
core/convert_object.dart: public static facade (Convert) mirroring legacy API.
core/convert_object_impl.dart: centralized conversion engine and diagnostics.
core/converter.dart: fluent Converter wrapper with navigation, defaults, and pre-transform.
core/enum_parsers.dart: helpers to build robust enum parsers; List<T>.extensions.
exceptions/conversion_exception.dart: structured failure with context and reports.
result/conversion_result.dart: success/failure container.
extensions/*.dart: iterable/map/object/let conversion helpers.
utils/*.dart: parsing helpers (bool/number/date/json/uri) and pretty JSON.
src/top_level_functions.dart: top-level aliases for Convert methods.

Public API
Class ConversionException: ctor(error,context,stackTrace?); factory nullObject(context,stackTrace); props: error,errorType,context,stackTrace; methods: fullReport()->String, toString()->String.
Class ConversionResult<T>: success(value), failure(ConversionException); props: isSuccess,isFailure,value,valueOrNull,error; methods: valueOr(default), map(f), flatMap(f), fold(onSuccess,onFailure).
Class Convert: toStringValue/tryToStringValue(object,mapKey?,listIndex?,defaultValue?,converter?) -> String|String?; toNum/tryToNum(object,mapKey?,listIndex?,format?,locale?,defaultValue?,converter?) -> num|num?; toInt/tryToInt(...format?,locale?) -> int|int?; toDouble/tryToDouble(...format?,locale?) -> double|double?; toBigInt/tryToBigInt(...defaultValue?,converter?) -> BigInt|BigInt?; toBool/tryToBool(...defaultValue?,converter?) -> bool|bool?; toDateTime/tryToDateTime(object,mapKey?,listIndex?,format?,locale?,autoDetectFormat=false,useCurrentLocale=false,utc=false,defaultValue?,converter?) -> DateTime|DateTime?; toUri/tryToUri(object,mapKey?,listIndex?,defaultValue?,converter?) -> Uri|Uri?; toMap/tryToMap<K,V>(object,mapKey?,listIndex?,defaultValue?,keyConverter?,valueConverter?) -> Map<K,V>|Map<K,V>?; toSet/tryToSet<T>(...elementConverter?) -> Set<T>|Set<T>?; toList/tryToList<T>(...elementConverter?) -> List<T>|List<T>?; toEnum/tryToEnum<T extends Enum>(object,parser,{mapKey?,listIndex?,defaultValue?,debugInfo?}) -> T|T?; toType<T>(object)->T; tryToType<T>(object)->T?; buildParsingInfo({...})->Map<String,dynamic>.
Class Converter: ctor(value,{defaultValue?,customConverter?}); withDefault(v)->Converter; withConverter(f)->Converter; fromMap(key)->Converter; fromList(index)->Converter; decoded->Converter; to<T>()->T; tryTo<T>()->T?; toOr<T>(default)->T; primitives to*/try*/*Or mirror Convert; collections toList/tryToList,toSet/tryToSet,toMap/tryToMap.
Class EnumParsers: byName(values)->(dynamic)->T; fromString(f:String->T)->(dynamic)->T; byNameOrFallback(values,fallback)->(dynamic)->T; byNameCaseInsensitive(values)->(dynamic)->T; byIndex(values)->(dynamic)->T.
Extension EnumValuesParsing<T extends Enum> on List<T>: parser, parserWithFallback(fallback), parserCaseInsensitive, parserByIndex.
Extensions IterableConversionX<E>: getString/getInt/getDouble/getNum/getBool/getBigInt/getDateTime/getUri/getList/getSet/getMap/getEnum; convertAll<T>(); toMutableSet(converter?); intersect(other,converter?); mapList(mapper,converter?); mapIndexedList(mapper,converter?).
Extensions NullableIterableConversionX<E>: tryGetString/Int/Double/Num/Bool/BigInt/DateTime/Uri/List/Set/Map/Enum with alternativeIndices?.
Extensions MapConversionX<K,V>: getString/Int/Double/Num/Bool/List/Set/Map/BigInt/DateTime/Uri/Enum; valuesList,keysList,valuesSet,keysSet; parse<T,K2,V2>(key,converter)->T; tryParse<T,K2,V2>(key,converter)->T?.
Extensions NullableMapConversionX<K,V>: tryGetString/Int/Double/Num/Bool/List/Set/Map/BigInt/DateTime/Uri/Enum.
Extension ConvertExtension on Object?: convert->Converter.
Utilities BoolParsingX.asBool->bool; NumParsingTextX: toNum/try,toInt/try,toDouble/try,toNumFormatted/try,toIntFormatted/try,toDoubleFormatted/try; DateParsingTextX: toDateTime/try,toDateFormatted/try,toDateAutoFormat/try; TextJsonX.tryDecode/decode; UriParsingX: isValidPhoneNumber,isEmailAddress,toPhoneUri,toMailUri,toUri; PrettyJsonMap.encodableCopy/encodedJsonText; PrettyJsonIterable.encodableList/encodedJson/encodedJsonWithIndent; PrettyJsonObject.encode.

Configuration / Flags / Env
format:String; locale:String; utc:bool; autoDetectFormat:bool; useCurrentLocale:bool; mapKey:any; listIndex:int; defaultValue:T; converter/elementConverter/keyConverter/valueConverter: functions; parser:(dynamic)->Enum.

Data Models
ConversionResult<T>: value:T?; error:ConversionException?; semantics: success XOR failure; serialization: not provided.

Errors / Exceptions → Failures
Null/unsupported/unparsable without defaultValue -> ConversionException.nullObject; retryable: no.
ConvertImpl.toType(null) -> ConversionException.nullObject; unsupported T -> ConversionException(error:String).
Enum parse failure -> ConversionException with context{reason:'enum parse failed',enumType}.
Custom converters throwing -> wrapped in ConversionException with captured stackTrace.
URI invalid host/path/empty -> logged in engine; results in ConversionException.nullObject at toUri.
try* methods return defaultValue or null instead of throwing.

Execution Flow
_convertObject: null short-circuit; exact-type return; as-cast; optional JSON tryDecode; listIndex selection; mapKey selection; apply converter; catch/log and return null.
Numbers: String cleaned (NBSP, commas, spaces, underscores; parentheses→negative); NumberFormat when format provided.
Dates: numeric epoch seconds(9–10) vs ms(12–13, guarded for yyyyMMddHHmm); ISO/RFC3339; HTTP-date(GMT); locale-slashed; compact yyyyMMdd[HHmm[ss]]; long names; time-only→today; utc flag converts result.
Collections: decodeInput for JSON text; accept Map/Iterable/singletons; element/key/value converters applied.

State & Observability
Logging: dart:developer.log on converter failures; no metrics, no persistence.

Validation & Limits
Phone/email regex lenient; http/https require host; mailto/tel require path.
Date bounds: year 1800–2500; hh 0–23; mm/ss 0–59; slashed ambiguity resolved by locale (en_US prefers MM/dd).
toBool: numeric>0 truthy; fixed truthy/falsy sets; else false.
Heavy objects elided in ConversionException.toString(); fullReport emits full JSON.

Security / Footguns
tryToType<T>() can still throw for unsupported T.
auto-detected date formats can misinterpret ambiguous slashed inputs if locale is wrong.
decodeInput on collections will JSON-decode untrusted strings; validate upstream.

Extensibility
Inject converters via converter/elementConverter/keyConverter/valueConverter or Converter.withConverter.
EnumParsers builders compose resilient parsers; List<T>.parser* shortcuts.
Debug info thread: buildParsingInfo/debugInfo accepted by impl and extensions.

Minimal Usage Sketch
Wrap input in Converter via obj.convert or call Convert/top-level toX directly.
Optionally pass mapKey/listIndex to select nested values; for JSON strings use decoded or collection to* which auto-decode.
Choose tryToX for null/default on failure; otherwise handle ConversionException.
For enums, supply a parser (e.g., MyEnum.values.parser).

Output Shape
Success: T (primitive/collection/DateTime/Uri/enum). Failure: throws ConversionException unless using try*; ConversionResult<T> available for explicit success/failure pipelines.

Edge Cases / Ambiguities
Epoch with 12 digits disambiguated against yyyyMMddHHmm; compact parser handles calendar forms.
Single non-iterable value toList/toSet becomes [toType<T>(value)]/{toType<T>(value)}.
HTTP/HTTPS URIs without host are rejected even if Uri.parse would accept them.
