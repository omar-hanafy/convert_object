/// Test-only model types used to validate:
/// - TypeRegistry custom parsing
/// - Map/List/String parsing via Convert.toType / Converter
/// - Equality + toString behavior
library;

import 'package:convert_object/convert_object.dart';

/// A simple custom type to test TypeRegistry registration + routing.
class UserId {
  const UserId(this.value);
  final int value;

  /// Returns null when parsing fails (ideal for TypeRegistry.tryParse patterns).
  static UserId? tryParse(Object? input) {
    if (input == null) return null;
    if (input is UserId) return input;
    if (input is int) return UserId(input);

    final asInt = Convert.tryToInt(input);
    if (asInt == null) return null;
    return UserId(asInt);
  }

  @override
  String toString() => 'UserId($value)';

  @override
  bool operator ==(Object other) => other is UserId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// A small geo type to test conversion from:
/// - Map: { "lat": "...", "lng": "..." }
/// - List: [lat, lng]
/// - String: "lat,lng"
class LatLng {
  const LatLng(this.lat, this.lng);
  final double lat;
  final double lng;

  static LatLng? tryParse(Object? input) {
    if (input == null) return null;
    if (input is LatLng) return input;

    // Map form: {"lat": 1, "lng": 2}
    if (input is Map) {
      final lat = Convert.tryToDouble(input['lat']);
      final lng = Convert.tryToDouble(input['lng']);
      if (lat == null || lng == null) return null;
      return LatLng(lat, lng);
    }

    // List/iterable form: [lat, lng]
    if (input is Iterable) {
      final list = input.toList(growable: false);
      if (list.length < 2) return null;
      final lat = Convert.tryToDouble(list[0]);
      final lng = Convert.tryToDouble(list[1]);
      if (lat == null || lng == null) return null;
      return LatLng(lat, lng);
    }

    // String form: "lat,lng"
    final text = input.toString().trim();
    final parts = text.split(',');
    if (parts.length != 2) return null;
    final lat = Convert.tryToDouble(parts[0].trim());
    final lng = Convert.tryToDouble(parts[1].trim());
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  @override
  String toString() => 'LatLng(lat: $lat, lng: $lng)';

  @override
  bool operator ==(Object other) =>
      other is LatLng && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}

/// A basic Money type to test custom parsing rules.
class Money {
  const Money(this.amount, this.currency);
  final double amount;
  final String currency;

  static Money? tryParse(Object? input) {
    if (input == null) return null;
    if (input is Money) return input;

    // Map form: {"amount": "12.34", "currency": "USD"}
    if (input is Map) {
      final amount = Convert.tryToDouble(input['amount']);
      final currency = Convert.tryToString(input['currency']);
      if (amount == null || currency == null || currency.trim().isEmpty) {
        return null;
      }
      return Money(amount, currency.trim().toUpperCase());
    }

    // String form: "USD 12.34" or "12.34 USD"
    final text = input.toString().trim();
    if (text.isEmpty) return null;

    final parts = text.split(RegExp(r'\s+'));
    if (parts.length != 2) return null;

    // Try "USD 12.34"
    final c1 = parts[0].trim();
    final a1 = Convert.tryToDouble(parts[1].trim());
    if (a1 != null && _looksLikeCurrency(c1)) {
      return Money(a1, c1.toUpperCase());
    }

    // Try "12.34 USD"
    final a2 = Convert.tryToDouble(parts[0].trim());
    final c2 = parts[1].trim();
    if (a2 != null && _looksLikeCurrency(c2)) {
      return Money(a2, c2.toUpperCase());
    }

    return null;
  }

  static bool _looksLikeCurrency(String s) =>
      RegExp(r'^[A-Za-z]{3}$').hasMatch(s);

  @override
  String toString() => '$currency $amount';

  @override
  bool operator ==(Object other) =>
      other is Money && other.amount == amount && other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);
}