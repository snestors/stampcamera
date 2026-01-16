// =====================================================
// screens/pedeteo_screen.dart - Con integración de ConnectionErrorScreen
// =====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';
import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/widgets/pedeteo/search_bar_widget.dart';
import 'package:stampcamera/widgets/pedeteo/scanner_widget.dart';
import 'package:stampcamera/widgets/pedeteo/registration_form_widget.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class PedeteoScreen extends ConsumerWidget {
  const PedeteoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pedeteoStateProvider);
    final optionsAsync = ref.watch(pedeteoOptionsProvider);

    // Loading state
    if (optionsAsync.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Cargando opciones...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Error state - ConnectionErrorScreen maneja automáticamente todos los tipos de error
    if (optionsAsync.hasError) {
      return ConnectionErrorScreen(
        error: optionsAsync.error!,
        onRetry: () => ref.invalidate(pedeteoOptionsProvider),
      );
    }

    // Estado normal - Contenido principal
    final vinsDisponibles = optionsAsync.value?.vinsDisponibles ?? [];
    final pedeteadosEnSesion = ref.watch(pedeteadosEnSesionProvider);

    // Filtrar: pedeteados del servidor + pedeteados en esta sesión
    final vinsPedeteados = vinsDisponibles
        .where((v) => v.pedeteado || pedeteadosEnSesion.contains(v.vin))
        .toList();

    final vinsNoPedeteados = vinsDisponibles
        .where((v) => !v.pedeteado && !pedeteadosEnSesion.contains(v.vin))
        .toList();

    return Column(
      children: [
        // Barra de búsqueda
        const PedeteoSearchBar(),

        // Contador de progreso
        _buildProgressIndicator(vinsPedeteados.length, vinsNoPedeteados.length),

        // Scanner de códigos de barras
        if (state.showScanner) const Expanded(child: PedeteoScannerWidget()),

        // Formulario de registro
        if (state.showForm && !state.showScanner)
          const Expanded(child: PedeteoRegistrationForm()),

        // Lista de VINs
        if (!state.showScanner && !state.showForm)
          Expanded(
            child: _buildVinsList(
              vinsNoPedeteados,
              vinsPedeteados,
              pedeteadosEnSesion,
            ),
          ),
      ],
    );
  }

  /// Lista de VINs con secciones: pendientes y pedeteados
  Widget _buildVinsList(
    List<RegistroGeneral> noPedeteados,
    List<RegistroGeneral> pedeteados,
    Set<String> pedeteadosEnSesion,
  ) {
    return ListView(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      children: [
        // Sección: Pendientes
        if (noPedeteados.isNotEmpty) ...[
          _buildSectionHeader(
            'Pendientes',
            noPedeteados.length,
            Icons.pending,
            AppColors.warning,
          ),
          ...noPedeteados.map((v) => _buildVinTile(v, false, false)),
          SizedBox(height: DesignTokens.spaceL),
        ],

        // Sección: Ya pedeteados
        if (pedeteados.isNotEmpty) ...[
          _buildSectionHeader(
            'Pedeteados',
            pedeteados.length,
            Icons.check_circle,
            AppColors.success,
          ),
          ...pedeteados.map(
            (v) => _buildVinTile(
              v,
              true,
              pedeteadosEnSesion.contains(v.vin), // Marcado en esta sesión
            ),
          ),
        ],

        // Estado vacío si no hay nada
        if (noPedeteados.isEmpty && pedeteados.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No hay VINs disponibles'),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spaceS),
      child: Row(
        children: [
          Icon(icon, color: color, size: DesignTokens.iconS),
          SizedBox(width: DesignTokens.spaceXS),
          Text(
            title,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(width: DesignTokens.spaceXS),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXS,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVinTile(
    RegistroGeneral vin,
    bool isPedeteado,
    bool pedeteadoEnSesion,
  ) {
    final color = isPedeteado ? AppColors.success : AppColors.primary;

    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spaceXS),
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM,
        vertical: DesignTokens.spaceS,
      ),
      decoration: BoxDecoration(
        color: isPedeteado
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Icono de estado
          Icon(
            isPedeteado ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color,
            size: DesignTokens.iconS,
          ),
          SizedBox(width: DesignTokens.spaceS),

          // VIN
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vin.vin,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
                if (vin.marca != null || vin.modelo != null)
                  Text(
                    '${vin.marca ?? ''} ${vin.modelo ?? ''}'.trim(),
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // Badge si fue pedeteado en esta sesión
          if (pedeteadoEnSesion)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceS,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Text(
                'NUEVO',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXS * 0.9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Indicador de progreso
  Widget _buildProgressIndicator(int pedeteados, int pendientes) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM,
        vertical: DesignTokens.spaceS,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Pedeteados
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: DesignTokens.iconS,
                color: AppColors.success,
              ),
              SizedBox(width: DesignTokens.spaceXS),
              Text(
                '$pedeteados',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              Text(
                ' pedeteados',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // Pendientes
          Row(
            children: [
              Icon(
                Icons.pending,
                size: DesignTokens.iconS,
                color: AppColors.warning,
              ),
              SizedBox(width: DesignTokens.spaceXS),
              Text(
                '$pendientes',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
              Text(
                ' pendientes',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
