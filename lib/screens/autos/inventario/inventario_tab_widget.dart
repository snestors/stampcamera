import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/inventario_model.dart';
import 'package:stampcamera/providers/autos/inventario_provider.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/widgets/autos/forms/inventario_form.dart';

class InventarioTabWidget extends ConsumerWidget {
  final InventarioBaseResponse response;
  final int informacionUnidadId;

  const InventarioTabWidget({
    super.key,
    required this.response,
    required this.informacionUnidadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!response.hasInventario) {
      return _buildEmptyState(context, ref);
    }

    return _buildInventarioContent(context, ref);
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spaceXXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(DesignTokens.spaceXXL),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: DesignTokens.iconGiant,
                color: AppColors.textLight,
              ),
            ),

            SizedBox(height: DesignTokens.spaceXXL),

            Text(
              'No hay inventario registrado',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: DesignTokens.spaceS),

            Text(
              'Esta unidad aún no tiene un inventario creado.\nPuedes crear uno ahora.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () => _showInventarioForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Crear Inventario'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventarioContent(BuildContext context, WidgetRef ref) {
    final inventario = response.inventario!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Secciones de inventario con cantidades siempre visibles
        _buildInventarioSection('Llaves y Accesorios', Icons.vpn_key, [
          _buildInventarioItem('Llave Simple', inventario.llaveSimple),
          _buildInventarioItem('Llave Comando', inventario.llaveComando),
          _buildInventarioItem(
            'Llave Inteligente',
            inventario.llaveInteligente,
          ),
        ]),

        const SizedBox(height: 16),

        _buildInventarioSection('Interior', Icons.airline_seat_recline_normal, [
          _buildInventarioItem('Encendedor', inventario.encendedor),
          _buildInventarioItem('Cenicero', inventario.cenicero),
          _buildInventarioItem('Cable USB/AUX', inventario.cableUsbOAux),
          _buildInventarioItem('Retrovisor', inventario.retrovisor),
          _buildInventarioItem('Pisos', inventario.pisos),
          _buildInventarioItem('Logos', inventario.logos),
        ]),

        const SizedBox(height: 16),

        _buildInventarioSection('Documentación', Icons.description, [
          _buildInventarioItem('Estuche Manual', inventario.estucheManual),
          _buildInventarioItem(
            'Manuales en Estuche',
            inventario.manualesEstuche,
          ),
        ]),

        const SizedBox(height: 16),

        _buildInventarioSection('Exterior y Carrocería', Icons.directions_car, [
          _buildInventarioItem('Pin de Remolque', inventario.pinDeRemolque),
          _buildInventarioItem(
            'Tapa Pin Remolque',
            inventario.tapaPinDeRemolque,
          ),
          _buildInventarioItem('Portaplaca', inventario.portaplaca),
          _buildInventarioItem(
            'Copas/Tapas de Aros',
            inventario.copasTapasDeAros,
          ),
          _buildInventarioItem('Tapones Chasis', inventario.taponesChasis),
          _buildInventarioItem('Cobertor', inventario.cobertor),
          _buildInventarioItem('Antena', inventario.antena),
        ]),

        const SizedBox(height: 16),

        _buildInventarioSection('Herramientas y Emergencia', Icons.build, [
          _buildInventarioItem(
            'Estuche Herramienta',
            inventario.estucheHerramienta,
          ),
          _buildInventarioItem('Desarmador', inventario.desarmador),
          _buildInventarioItem(
            'Llave Boca Combinada',
            inventario.llaveBocaCombinada,
          ),
          _buildInventarioItem('Alicate', inventario.alicate),
          _buildInventarioItem('Llave de Rueda', inventario.llaveDeRueda),
          _buildInventarioItem('Palanca de Gata', inventario.palancaDeGata),
          _buildInventarioItem('Gata', inventario.gata),
          _buildInventarioItem(
            'Llanta de Repuesto',
            inventario.llantaDeRepuesto,
          ),
          _buildInventarioItem(
            'Triángulo Emergencia',
            inventario.trianguloDeEmergencia,
          ),
        ]),

        const SizedBox(height: 16),

        _buildInventarioSection('Seguridad y Extras', Icons.security, [
          _buildInventarioItem('Botiquín', inventario.botiquin),
          _buildInventarioItem(
            'Perno Seguro Rueda',
            inventario.pernoSeguroRueda,
          ),
          _buildInventarioItem('Extintor', inventario.extintor),
          _buildInventarioItem(
            'Chaleco Reflectivo',
            inventario.chalecoReflectivo,
          ),
          _buildInventarioItem('Conos', inventario.conos),
          _buildInventarioItem('Cable Cargador', inventario.cableCargador),
          _buildInventarioItem('Caja de Fusibles', inventario.cajaDeFusibles),
        ]),

        const SizedBox(height: 16),

        _buildInventarioSection('Otros', Icons.more_horiz, [
          _buildInventarioItem('Malla', inventario.malla),
          _buildInventarioItem('Ambientadores', inventario.ambientadores),
          _buildInventarioItem('Extra', inventario.extra),
          _buildInventarioItem('Extensión', inventario.extension),
        ]),

        if (inventario.otros.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildOtrosSection(inventario.otros),
        ],

        const SizedBox(height: 24),

        // Botón de editar
        Center(
          child: ElevatedButton.icon(
            onPressed: () =>
                _showInventarioForm(context, ref, inventario: inventario),
            icon: const Icon(Icons.edit),
            label: const Text('Editar Inventario'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildInventarioSection(
    String title,
    IconData icon,
    List<Widget> items,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildInventarioItem(String name, int quantity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),

          // Siempre mostrar la cantidad
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: quantity > 0
                  ? Colors.green.shade100
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: quantity > 0
                    ? Colors.green.shade300
                    : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontWeight: FontWeight.bold,
                color: quantity > 0
                    ? Colors.green.shade700
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtrosSection(String otros) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.note, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Observaciones',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(otros, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showInventarioForm(
    BuildContext context,
    WidgetRef ref, {
    InventarioBase? inventario,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InventarioFormWidget(
        informacionUnidadId: informacionUnidadId,
        inventario: inventario, // null = crear, no null = editar
        onSaved: () {
          // Refrescar la data del inventario
          ref.refresh(inventarioDetalleProvider(informacionUnidadId));
        },
      ),
    );
  }
}

