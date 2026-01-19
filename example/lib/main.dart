import 'package:convert_object/convert_object.dart';

enum Status { active, inactive }

void main() {
  final payload = {
    'id': '42',
    'ok': 'true',
    'price': '1,234.56',
    'when': '2024-01-20T00:00:00Z',
    'meta': '{"tags":["a","b"],"active":true}',
    'email': 'dev@example.com',
  };

  // Extension
  final id = payload.getInt('id');
  final price = payload.getDouble('price');
  final when = payload.getDateTime('when', utc: true);
  final uri = payload.getUri('email');
  print({'id': id, 'price': price, 'when': when.toIso8601String(), 'uri': uri});

  // Top-level
  final id1 = convertToInt(payload, mapKey: 'id');
  final price1 = convertToDouble(payload, mapKey: 'price');
  final when1 = convertToDateTime(payload, mapKey: 'when', utc: true);
  final uri1 = convertToUri(payload, mapKey: 'email');
  print({
    'id': id1,
    'price': price1,
    'when': when1.toIso8601String(),
    'uri': uri1,
  });

  // Fluent
  final tags = Converter(
    payload,
  ).fromMap('meta').decoded.toMap<String, dynamic>().getList<String>('tags');

  print(tags);
}
