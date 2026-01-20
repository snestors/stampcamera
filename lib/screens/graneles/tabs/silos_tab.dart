// =============================================================================
// TAB DE SILOS
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';

class SilosTab extends ConsumerWidget {
  final int? servicioId;

  const SilosTab({super.key, this.servicioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (servicioId == null) {
      return _buildNoServicioSelected();
    }

    final silosAsync = ref.watch(silosProvider(servicioId!));

    return silosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            SizedBox(height: DesignTokens.spaceM),
            Text(
              'Error al cargar silos',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: DesignTokens.spaceS),
            TextButton.icon(
              onPressed: () => ref.invalidate(silosProvider(servicioId!)),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (silos) {
        if (silos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storage_outlined, size: 64, color: AppColors.textSecondary),
                SizedBox(height: DesignTokens.spaceM),
                Text(
                  'No hay registros de silos',
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
            ref.invalidate(silosProvider(servicioId!));
          },
          child: ListView.builder(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            itemCount: silos.length,
            itemBuilder: (context, index) {
              return _SiloCard(silo: silos[index]);
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

class _SiloCard extends StatelessWidget {
  final Silos silo;

  const _SiloCard({required this.silo});

  @override
  Widget build(BuildContext context) {
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
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
            // Header con número de silo
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceS,
                    vertical: DesignTokens.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storage, size: 14, color: Colors.white),
                      SizedBox(width: DesignTokens.spaceXS),
                      Text(
                        'N° ${silo.numeroSilo ?? "-"}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: DesignTokens.fontSizeS,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spaceM),

            // Producto
            Row(
              children: [
                Icon(Icons.inventory_2, size: 16, color: AppColors.textSecondary),
                SizedBox(width: DesignTokens.spaceS),
                Expanded(
                  child: Text(
                    silo.productoNombre ?? 'Sin producto',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spaceM),

            // Peso y bags
            Container(
              padding: EdgeInsets.all(DesignTokens.spaceS),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Peso',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: DesignTokens.spaceXS),
                      Text(
                        silo.peso != null ? numberFormat.format(silo.peso!) : '-',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeM,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'TM',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (silo.bags != null) ...[
                    Container(
                      height: 40,
                      width: 1,
                      color: AppColors.neutral,
                    ),
                    Column(
                      children: [
                        Text(
                          'Bags',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeXS,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: DesignTokens.spaceXS),
                        Text(
                          silo.bags.toString(),
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeM,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          'unidades',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeXS,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: DesignTokens.spaceS),

            // Fecha y hora
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                SizedBox(width: DesignTokens.spaceXS),
                Text(
                  silo.fechaHora != null
                      ? dateTimeFormat.format(silo.fechaHora!)
                      : 'Sin fecha',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
