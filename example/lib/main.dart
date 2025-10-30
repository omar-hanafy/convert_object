import 'package:intl/intl.dart';

void main() {
  final dt = DateFormat('d MMMM yyyy HH:mm:ss', 'en_US').parse('12 May 1987 01:00:00');
  print(dt);
  print(dt.millisecondsSinceEpoch);
}
