// =============================================================================
// TAB DE BALANZAS
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';

class BalanzasTab extends ConsumerWidget {
  final int? servicioId;

  const BalanzasTab({super.key, this.servicioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (servicioId == null) {
      return _buildNoServicioSelected();
    }

    final balanzasAsync = ref.watch(balanzasProvider(servicioId!));

    return balanzasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            SizedBox(height: DesignTokens.spaceM),
            Text(
              'Error al cargar balanzas',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: DesignTokens.spaceS),
            TextButton.icon(
              onPressed: () => ref.invalidate(balanzasProvider(servicioId!)),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (balanzas) {
        if (balanzas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.scale_outlined, size: 64, color: AppColors.textSecondary),
                SizedBox(height: DesignTokens.spaceM),
                Text(
                  'No hay balanzas registradas',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(balanzasProvider(servicioId!));
          },
          child: ListView.builder(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            itemCount: balanzas.length,
            itemBuilder: (context, index) {
              return _BalanzaCard(balanza: balanzas[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildNoServicioSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_outlined, size: 64, color: AppColors.textSecondary),
          SizedBox(height: DesignTokens.spaceM),
          Text(
            'Selecciona un servicio',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            'Ve a la pestaña SERVICIOS y selecciona uno',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanzaCard extends StatelessWidget {
  final Balanza balanza;

  const _BalanzaCard({required this.balanza});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final numberFormat = NumberFormat('#,##0.000', 'es_PE');

    return Card(
      margin: EdgeInsets.only(bottom: DesignTokens.spaceM),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con guía y ticket
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceS,
                    vertical: DesignTokens.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.scale, size: 14, color: Colors.white),
                      SizedBox(width: DesignTokens.spaceXS),
                      Text(
                        'Guía: ${balanza.guia}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: DesignTokens.fontSizeS,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: DesignTokens.spaceS),
                Text(
                  'Ticket: ${balanza.ticketNumero ?? "-"}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spaceM),

            // Placa y almacén
            Row(
              children: [
                Icon(Icons.local_shipping, size: 16, color: AppColors.textSecondary),
                SizedBox(width: DesignTokens.spaceS),
                Text(
                  balanza.placaStr ?? 'Sin placa',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(Icons.warehouse, size: 14, color: AppColors.textSecondary),
                SizedBox(width: DesignTokens.spaceXS),
                Text(
                  balanza.almacen ?? 'Sin almacén',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spaceM),

            // Pesos
            Container(
              padding: EdgeInsets.all(DesignTokens.spaceS),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _PesoItem(
                    label: 'Bruto',
                    value: numberFormat.format(balanza.pesoBruto),
                    unit: 'TM',
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: AppColors.neutral,
                  ),
                  _PesoItem(
                    label: 'Tara',
                    value: numberFormat.format(balanza.pesoTara),
                    unit: 'TM',
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: AppColors.neutral,
                  ),
                  _PesoItem(
                    label: 'Neto',
                    value: numberFormat.format(balanza.pesoNeto),
                    unit: 'TM',
                    highlight: true,
                  ),
                  if (balanza.bags != null) ...[
                    Container(
                      height: 30,
                      width: 1,
                      color: AppColors.neutral,
                    ),
                    _PesoItem(
                      label: 'Bags',
                      value: balanza.bags.toString(),
                      unit: '',
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: DesignTokens.spaceS),

            // Tiempos
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                SizedBox(width: DesignTokens.spaceXS),
                Text(
                  'Entrada: ${balanza.fechaEntradaBalanza != null ? timeFormat.format(balanza.fechaEntradaBalanza!) : "-"}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: DesignTokens.spaceM),
                Text(
                  'Salida: ${balanza.fechaSalidaBalanza != null ? timeFormat.format(balanza.fechaSalidaBalanza!) : "-"}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            // Observaciones
            if (balanza.observaciones != null && balanza.observaciones!.isNotEmpty) ...[
              SizedBox(height: DesignTokens.spaceS),
              const Divider(),
              Text(
                balanza.observaciones!,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PesoItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool highlight;

  const _PesoItem({
    required this.label,
    required this.value,
    required this.unit,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeXS,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: DesignTokens.spaceXS),
        Text(
          value,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}
