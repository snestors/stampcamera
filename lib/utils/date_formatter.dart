import 'package:intl/intl.dart';

String formattedNow() {
  final now = DateTime.now();
  return DateFormat('dd/MM/yyyy HH:mm').format(now);
}
