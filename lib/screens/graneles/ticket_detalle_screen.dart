// =============================================================================
// PANTALLA DE DETALLE DE TICKET MUELLE
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class TicketDetalleScreen extends ConsumerWidget {
  final int ticketId;

  const TicketDetalleScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketMuelleDetalleProvider(ticketId));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Detalle Ticket',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: DesignTokens.fontSizeL,
          ),
        ),
      ),
      body: ticketAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => ConnectionErrorScreen(
          error: error,
          onRetry: () => ref.invalidate(ticketMuelleDetalleProvider(ticketId)),
        ),
        data: (ticket) => _TicketDetalleContent(ticket: ticket),
      ),
    );
  }
}

class _TicketDetalleContent extends StatelessWidget {
  final TicketMuelle ticket;

  const _TicketDetalleContent({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del ticket
          _buildHeader(),
          SizedBox(height: DesignTokens.spaceM),

          // Información principal
          _buildSection(
            title: 'Información Principal',
            icon: Icons.info_outline,
            children: [
              _buildInfoRow('Número Ticket', ticket.numeroTicket),
              _buildInfoRow('Placa', ticket.placaStr ?? '-'),
              if (ticket.placaTractoStr != null)
                _buildInfoRow('Placa Tracto', ticket.placaTractoStr!),
              _buildInfoRow('Producto', ticket.productoNombre ?? '-'),
              _buildInfoRow('BL', ticket.blStr ?? '-'),
              _buildInfoRow('Bodega', ticket.bodega ?? '-'),
            ],
          ),
          SizedBox(height: DesignTokens.spaceM),

          // Transporte
          if (ticket.transporteNombre != null || ticket.choferNombre != null)
            _buildSection(
              title: 'Transporte',
              icon: Icons.local_shipping,
              children: [
                if (ticket.transporteNombre != null)
                  _buildInfoRow('Empresa', ticket.transporteNombre!),
                if (ticket.choferNombre != null)
                  _buildInfoRow('Chofer', ticket.choferNombre!),
              ],
            ),
          if (ticket.transporteNombre != null || ticket.choferNombre != null)
            SizedBox(height: DesignTokens.spaceM),

          // Tiempos de descarga
          _buildSection(
            title: 'Tiempos de Descarga',
            icon: Icons.access_time,
            children: [
              _buildInfoRow(
                'Inicio',
                ticket.inicioDescarga != null
                    ? dateTimeFormat.format(ticket.inicioDescarga!)
                    : '-',
              ),
              _buildInfoRow(
                'Fin',
                ticket.finDescarga != null
                    ? dateTimeFormat.format(ticket.finDescarga!)
                    : '-',
              ),
              _buildInfoRow(
                'Tiempo Cargío',
                ticket.tiempoCargio ?? '-',
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceM),

          // Observaciones
          if (ticket.observaciones != null && ticket.observaciones!.isNotEmpty)
            _buildSection(
              title: 'Observaciones',
              icon: Icons.notes,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceS),
                  child: Text(
                    ticket.observaciones!,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          if (ticket.observaciones != null && ticket.observaciones!.isNotEmpty)
            SizedBox(height: DesignTokens.spaceM),

          // Foto
          if (ticket.fotoUrl != null) ...[
            _buildSection(
              title: 'Fotografía',
              icon: Icons.photo_camera,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceS),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    child: Image.network(
                      ticket.fotoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: AppColors.surface,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: AppColors.surface,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: DesignTokens.spaceS),
                            Text(
                              'No se pudo cargar la imagen',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: DesignTokens.fontSizeS,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceS),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticket #${ticket.numeroTicket}',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeXL,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spaceXS),
                    Text(
                      ticket.placaStr ?? 'Sin placa',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeM,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceM,
                  vertical: DesignTokens.spaceS,
                ),
                decoration: BoxDecoration(
                  color: ticket.tieneBalanza
                      ? AppColors.success
                      : AppColors.warning,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Text(
                  ticket.tieneBalanza ? 'CON BALANZA' : 'SIN BALANZA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: DesignTokens.fontSizeXS,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                SizedBox(width: DesignTokens.spaceS),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
