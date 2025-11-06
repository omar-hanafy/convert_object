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

  // Top-level
  final id = convertToInt(payload, mapKey: 'id');
  final price = convertToDouble(payload, mapKey: 'price');
  final when = convertToDateTime(payload, mapKey: 'when', utc: true);
  final uri = convertToUri(payload, mapKey: 'email');

  // Fluent
  final tags = Converter(
    payload,
  ).fromMap('meta').decoded.toMap<String, dynamic>().getList<String>('tags');

  print({'id': id, 'price': price, 'when': when.toIso8601String(), 'uri': uri});
  print(tags);
}
