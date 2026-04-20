import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/naves/berthing_model.dart';
import 'package:stampcamera/services/naves/berthings_service.dart';

final berthingsServiceProvider = Provider<BerthingsService>((ref) {
  return BerthingsService();
});

/// Form options (estados + transiciones). Cacheado por toda la app.
final berthingsFormOptionsProvider = FutureProvider<BerthingsFormOptions>((
  ref,
) async {
  final service = ref.watch(berthingsServiceProvider);
  return service.getFormOptions();
});
