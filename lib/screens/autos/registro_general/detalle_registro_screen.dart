import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/providers/autos/registro_detalle_provider.dart';
import 'package:stampcamera/widgets/autos/detalle_info_general.dart';
import 'package:stampcamera/widgets/autos/detalle_registros_vin.dart';
import 'package:stampcamera/widgets/autos/detalle_fotos_presentacion.dart';
import 'package:stampcamera/widgets/autos/detalle_danos.dart';

class DetalleRegistroScreen extends ConsumerWidget {
  final String vin;

  const DetalleRegistroScreen({super.key, required this.vin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleAsync = ref.watch(registroDetalleProvider(vin));

    return Scaffold(
      appBar: AppBar(title: Text('Detalle: $vin')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            registroDetalleProvider(vin),
          ); // limpia cache y fuerza fetch
        },
        child: detalleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (registro) => ListView(
            padding: const EdgeInsets.all(12),
            children: [
              DetalleInfoGeneral(r: registro),
              const SizedBox(height: 20),
              DetalleRegistrosVin(items: registro.registrosVin),
              const SizedBox(height: 20),
              DetalleFotosPresentacion(items: registro.fotosPresentacion),
              const SizedBox(height: 20),
              DetalleDanos(danos: registro.danos),
            ],
          ),
        ),
      ),
    );
  }
}
