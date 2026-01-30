// =============================================================================
// PANTALLA DE DETALLE DE TICKET MUELLE - RESUMEN COMPLETO
// =============================================================================
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';
import 'package:stampcamera/services/graneles/graneles_service.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class TicketDetalleScreen extends ConsumerWidget {
  final int ticketId;

  const TicketDetalleScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketMuelleDetalleProvider(ticketId));
    final permissionsAsync = ref.watch(userGranelesPermissionsProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Resumen Ticket',
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
        data: (ticket) => _TicketDetalleContent(
          ticket: ticket,
          permissions: permissionsAsync.valueOrNull ?? UserGranelesPermissions.defaults(),
          onRefresh: () => ref.invalidate(ticketMuelleDetalleProvider(ticketId)),
        ),
      ),
    );
  }
}

class _TicketDetalleContent extends StatelessWidget {
  final TicketMuelle ticket;
  final UserGranelesPermissions permissions;
  final VoidCallback onRefresh;

  const _TicketDetalleContent({
    required this.ticket,
    required this.permissions,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
    final numberFormat = NumberFormat('#,##0.000', 'es_PE');

    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del ticket
          _buildHeader(context),
          SizedBox(height: DesignTokens.spaceM),

          // =============================================
          // SECCIÓN: MUELLE
          // =============================================
          _buildSection(
            context: context,
            title: 'Muelle',
            icon: Icons.anchor,
            trailing: _buildSectionActions(
              context: context,
              photoUrl: ticket.fotoUrl,
              canEdit: permissions.muelle.canEdit,
              onEdit: () => context.push('/graneles/ticket/editar/${ticket.id}'),
            ),
            children: [
              _buildInfoRow('Número Ticket', ticket.numeroTicket),
              _buildInfoRow('Placa', ticket.placaStr ?? '-'),
              if (ticket.placaTractoStr != null)
                _buildInfoRow('Placa Tracto', ticket.placaTractoStr!),
              _buildInfoRow('Producto', ticket.productoNombre ?? '-'),
              _buildInfoRow('BL', ticket.blStr ?? '-'),
              _buildInfoRow('Bodega', ticket.bodega ?? '-'),
              if (ticket.transporteNombre != null)
                _buildInfoRow('Transporte', ticket.transporteNombre!),
              if (ticket.choferNombre != null)
                _buildInfoRow('Chofer', ticket.choferNombre!),
              const Divider(),
              _buildInfoRow(
                'Inicio Descarga',
                ticket.inicioDescarga != null
                    ? dateTimeFormat.format(ticket.inicioDescarga!)
                    : '-',
              ),
              _buildInfoRow(
                'Fin Descarga',
                ticket.finDescarga != null
                    ? dateTimeFormat.format(ticket.finDescarga!)
                    : '-',
              ),
              _buildInfoRow('Tiempo Cargío', ticket.tiempoCargio ?? '-'),
              if (ticket.observaciones != null && ticket.observaciones!.isNotEmpty) ...[
                const Divider(),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceXS),
                  child: Text(
                    ticket.observaciones!,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: DesignTokens.spaceM),

          // =============================================
          // SECCIÓN: BALANZA
          // =============================================
          if (ticket.balanzaData != null) ...[
            _buildSection(
              context: context,
              title: 'Balanza',
              icon: Icons.scale,
              trailing: _buildSectionActions(
                context: context,
                photoUrl: ticket.balanzaData!.foto1Url,
                canEdit: permissions.balanza.canEdit,
                onEdit: () => context.push('/graneles/balanza/editar/${ticket.balanzaData!.id}'),
              ),
              children: [
                _buildInfoRow('Guía', ticket.balanzaData!.guia),
                if (ticket.balanzaData!.almacen != null)
                  _buildInfoRow('Almacén Destino', ticket.balanzaData!.almacen!),
                if (ticket.balanzaData!.precinto != null)
                  _buildInfoRow('Precinto', ticket.balanzaData!.precinto!),
                if (ticket.balanzaData!.permiso != null)
                  _buildInfoRow('Permiso', ticket.balanzaData!.permiso!),
                const Divider(),
                // Pesos
                _buildWeightRow(
                  numberFormat,
                  ticket.balanzaData!.pesoBruto,
                  ticket.balanzaData!.pesoTara,
                  ticket.balanzaData!.pesoNeto,
                  ticket.balanzaData!.bags,
                ),
                const Divider(),
                // Tiempos
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Entrada', style: TextStyle(fontSize: DesignTokens.fontSizeXS, color: AppColors.textSecondary)),
                          Text(
                            ticket.balanzaData!.fechaEntradaBalanza != null
                                ? dateTimeFormat.format(ticket.balanzaData!.fechaEntradaBalanza!)
                                : '-',
                            style: TextStyle(fontSize: DesignTokens.fontSizeS, fontWeight: FontWeight.w600),
                          ),
                          if (ticket.balanzaData!.balanzaEntrada != null)
                            Text('Bal: ${ticket.balanzaData!.balanzaEntrada}',
                                style: TextStyle(fontSize: DesignTokens.fontSizeXS, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Salida', style: TextStyle(fontSize: DesignTokens.fontSizeXS, color: AppColors.textSecondary)),
                          Text(
                            ticket.balanzaData!.fechaSalidaBalanza != null
                                ? dateTimeFormat.format(ticket.balanzaData!.fechaSalidaBalanza!)
                                : '-',
                            style: TextStyle(fontSize: DesignTokens.fontSizeS, fontWeight: FontWeight.w600),
                          ),
                          if (ticket.balanzaData!.balanzaSalida != null)
                            Text('Bal: ${ticket.balanzaData!.balanzaSalida}',
                                style: TextStyle(fontSize: DesignTokens.fontSizeXS, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (ticket.balanzaData!.observaciones != null && ticket.balanzaData!.observaciones!.isNotEmpty) ...[
                  const Divider(),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceXS),
                    child: Text(
                      ticket.balanzaData!.observaciones!,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: DesignTokens.spaceM),
          ] else ...[
            _buildEmptySection('Balanza', Icons.scale, 'Sin registro de balanza'),
            SizedBox(height: DesignTokens.spaceM),
          ],

          // =============================================
          // SECCIÓN: ALMACÉN
          // =============================================
          if (ticket.almacenData != null) ...[
            _buildSection(
              context: context,
              title: 'Almacén',
              icon: Icons.warehouse,
              trailing: _buildSectionActions(
                context: context,
                photoUrl: ticket.almacenData!.foto1Url,
                canEdit: permissions.almacen.canEdit,
                onEdit: () => context.push('/graneles/almacen/editar/${ticket.almacenData!.id}'),
              ),
              children: [
                // Pesos
                _buildWeightRow(
                  numberFormat,
                  ticket.almacenData!.pesoBruto,
                  ticket.almacenData!.pesoTara,
                  ticket.almacenData!.pesoNeto,
                  ticket.almacenData!.bags,
                ),
                const Divider(),
                // Tiempos
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Entrada', style: TextStyle(fontSize: DesignTokens.fontSizeXS, color: AppColors.textSecondary)),
                          Text(
                            ticket.almacenData!.fechaEntradaAlmacen != null
                                ? dateTimeFormat.format(ticket.almacenData!.fechaEntradaAlmacen!)
                                : '-',
                            style: TextStyle(fontSize: DesignTokens.fontSizeS, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Salida', style: TextStyle(fontSize: DesignTokens.fontSizeXS, color: AppColors.textSecondary)),
                          Text(
                            ticket.almacenData!.fechaSalidaAlmacen != null
                                ? dateTimeFormat.format(ticket.almacenData!.fechaSalidaAlmacen!)
                                : '-',
                            style: TextStyle(fontSize: DesignTokens.fontSizeS, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (ticket.almacenData!.observaciones != null && ticket.almacenData!.observaciones!.isNotEmpty) ...[
                  const Divider(),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceXS),
                    child: Text(
                      ticket.almacenData!.observaciones!,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            _buildEmptySection('Almacén', Icons.warehouse, 'Sin registro de almacén'),
          ],
          SizedBox(height: DesignTokens.spaceL),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spaceS),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: const Icon(Icons.receipt_long, size: 32, color: Colors.white),
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
          // Status badges
          Column(
            children: [
              _buildStatusBadge(
                ticket.tieneBalanza ? 'BALANZA' : 'SIN BAL.',
                ticket.tieneBalanza ? AppColors.success : AppColors.warning,
              ),
              SizedBox(height: DesignTokens.spaceXS),
              _buildStatusBadge(
                ticket.almacenData != null ? 'ALMACÉN' : 'SIN ALM.',
                ticket.almacenData != null ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: DesignTokens.fontSizeXS,
        ),
      ),
    );
  }

  /// Construye los botones de acción para cada sección (foto + editar)
  Widget? _buildSectionActions({
    required BuildContext context,
    String? photoUrl,
    required bool canEdit,
    required VoidCallback onEdit,
  }) {
    final hasPhoto = photoUrl != null;
    if (!hasPhoto && !canEdit) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasPhoto) ...[
          _PhotoButton(url: photoUrl, context: context),
          if (canEdit) SizedBox(width: DesignTokens.spaceXS),
        ],
        if (canEdit)
          _EditButton(onTap: onEdit),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
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

  Widget _buildEmptySection(String title, IconData icon, String message) {
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
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spaceM),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            SizedBox(width: DesignTokens.spaceS),
            Text(
              title,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              message,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
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

  Widget _buildWeightRow(NumberFormat fmt, double bruto, double tara, double neto, int? bags) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildWeightItem('Bruto', fmt.format(bruto), false),
          Container(height: 30, width: 1, color: AppColors.neutral),
          _buildWeightItem('Tara', fmt.format(tara), false),
          Container(height: 30, width: 1, color: AppColors.neutral),
          _buildWeightItem('Neto', fmt.format(neto), true),
          if (bags != null) ...[
            Container(height: 30, width: 1, color: AppColors.neutral),
            _buildWeightItem('Bags', bags.toString(), false),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightItem(String label, String value, bool highlight) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: DesignTokens.fontSizeXS, color: AppColors.textSecondary)),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// BOTONES DE ACCIÓN
// =============================================================================

/// Botón para editar sección
class _EditButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceS,
          vertical: DesignTokens.spaceXS,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, size: 16, color: AppColors.warning),
            SizedBox(width: DesignTokens.spaceXS),
            Text(
              'Editar',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXS,
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón para ver foto
class _PhotoButton extends StatelessWidget {
  final String url;
  final BuildContext context;

  const _PhotoButton({required this.url, required this.context});

  @override
  Widget build(BuildContext outerContext) {
    return InkWell(
      onTap: () => _showPhotoDialog(context, url),
      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceS,
          vertical: DesignTokens.spaceXS,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera, size: 16, color: AppColors.primary),
            SizedBox(width: DesignTokens.spaceXS),
            Text(
              'Ver foto',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXS,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showPhotoDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.all(DesignTokens.spaceM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(DesignTokens.spaceM),
              child: Row(
                children: [
                  Icon(Icons.photo_camera, color: AppColors.primary),
                  SizedBox(width: DesignTokens.spaceS),
                  Text(
                    'Fotografía',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: DesignTokens.fontSizeM,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            // Photo
            ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(DesignTokens.radiusL),
                bottomRight: Radius.circular(DesignTokens.radiusL),
              ),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  height: 300,
                  color: AppColors.surface,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: AppColors.surface,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 48, color: AppColors.textSecondary),
                      SizedBox(height: DesignTokens.spaceS),
                      Text(
                        'No se pudo cargar la imagen',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: DesignTokens.fontSizeS),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
