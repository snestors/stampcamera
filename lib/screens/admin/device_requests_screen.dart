// =============================================================================
// DEVICE REQUESTS SCREEN - Solicitudes de autorización de equipos (admin)
// =============================================================================
//
// Solo superusuarios. Se actualiza en tiempo real vía WebSocket
// (device_request_changed); sin polling periódico. Refresh manual con
// pull-to-refresh. Confirmaciones integradas en cada tarjeta (sin diálogos).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/admin/device_request_model.dart';
import 'package:stampcamera/providers/admin/device_requests_provider.dart';
import 'package:stampcamera/providers/app_socket_provider.dart';
import 'package:stampcamera/services/admin/device_request_service.dart';

class DeviceRequestsScreen extends ConsumerStatefulWidget {
  const DeviceRequestsScreen({super.key});

  @override
  ConsumerState<DeviceRequestsScreen> createState() =>
      _DeviceRequestsScreenState();
}

class _DeviceRequestsScreenState extends ConsumerState<DeviceRequestsScreen> {
  final _codeController = TextEditingController();
  DeviceRequest? _searchResult;
  String? _searchError;
  bool _searching = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSuperuser = ref.watch(isSuperuserProvider);

    if (!isSuperuser) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(title: const Text('Solicitudes de Equipos')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(DesignTokens.spaceXL),
            child: AppEmptyState(
              icon: Icons.lock_outline,
              title: 'Acceso restringido',
              subtitle: 'Esta sección es exclusiva para superusuarios.',
            ),
          ),
        ),
      );
    }

    final requestsAsync = ref.watch(deviceRequestsProvider);
    final socketState = ref.watch(appSocketProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Solicitudes de Equipos')),
      body: Column(
        children: [
          if (!socketState.isConnected) const _DisconnectedBanner(),
          _buildCodeSearch(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(deviceRequestsProvider.notifier).refresh(),
              child: requestsAsync.when(
                data: (requests) => _buildList(requests),
                loading: () =>
                    const AppLoadingState(message: 'Cargando solicitudes...'),
                error: (error, _) => _buildError(error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Búsqueda por código ─────────────────────────────────────────────

  Widget _buildCodeSearch() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        DesignTokens.spaceL,
        DesignTokens.spaceM,
        DesignTokens.spaceL,
        DesignTokens.spaceS,
      ),
      child: _CardShell(
        accentColor: AppColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con icono en chip, patrón del card del detalle VIN
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceS),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceS),
                const Text(
                  'Aprobar por código',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceM),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-HJ-NP-Za-hj-np-z2-9-]'),
                      ),
                      LengthLimitingTextInputFormatter(9),
                    ],
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Código (ej. NSCY-YDQ5)',
                      hintStyle: const TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        letterSpacing: 0,
                        fontWeight: FontWeight.normal,
                        color: AppColors.textLight,
                      ),
                      prefixIcon: const Icon(Icons.qr_code_2, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusM,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _resolveCode(),
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceS),
                AppButton.primary(
                  text: 'Buscar',
                  size: AppButtonSize.medium,
                  isLoading: _searching,
                  onPressed: _searching ? null : _resolveCode,
                ),
              ],
            ),
            if (_searchError != null) ...[
              const SizedBox(height: DesignTokens.spaceS),
              AppInlineError(
                message: _searchError!,
                dismissible: true,
                onDismiss: () => setState(() => _searchError = null),
              ),
            ],
            if (_searchResult != null) ...[
              const SizedBox(height: DesignTokens.spaceS),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Resultado de la búsqueda',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeXS,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() {
                      _searchResult = null;
                      _codeController.clear();
                    }),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              _DeviceRequestCard(
                key: ValueKey('search_${_searchResult!.id}'),
                request: _searchResult!,
                highlighted: true,
                onApprove: (scope) => _approve(_searchResult!, scope),
                onReject: () => _reject(_searchResult!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _resolveCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _searchError = 'Ingresa el código de la solicitud');
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
      _searchResult = null;
    });
    try {
      final result = await ref
          .read(deviceRequestsProvider.notifier)
          .resolveCode(code);
      if (!mounted) return;
      setState(() => _searchResult = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _searchError = DeviceRequestService.messageFromError(e));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  // ─── Acciones ────────────────────────────────────────────────────────

  Future<DeviceRequest> _approve(
    DeviceRequest request,
    DeviceApprovalScope scope,
  ) async {
    final updated = await ref
        .read(deviceRequestsProvider.notifier)
        .approve(request.id, scope);
    if (mounted && _searchResult?.id == updated.id) {
      setState(() => _searchResult = updated);
    }
    return updated;
  }

  Future<DeviceRequest> _reject(DeviceRequest request) async {
    final updated = await ref
        .read(deviceRequestsProvider.notifier)
        .reject(request.id);
    if (mounted && _searchResult?.id == updated.id) {
      setState(() => _searchResult = updated);
    }
    return updated;
  }

  // ─── Listado ─────────────────────────────────────────────────────────

  Widget _buildList(List<DeviceRequest> requests) {
    if (requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: DesignTokens.spaceL,
          right: DesignTokens.spaceL,
          top: DesignTokens.spaceXXXL,
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        children: const [
          AppEmptyState(
            icon: Icons.phonelink_lock,
            title: 'Sin solicitudes',
            subtitle: 'No hay solicitudes de autorización de equipos.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: DesignTokens.spaceL,
        right: DesignTokens.spaceL,
        top: DesignTokens.spaceS,
        bottom: DesignTokens.spaceL + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.spaceS),
      itemBuilder: (context, index) {
        final request = requests[index];
        return _DeviceRequestCard(
          key: ValueKey('request_${request.id}'),
          request: request,
          onApprove: (scope) => _approve(request, scope),
          onReject: () => _reject(request),
        );
      },
    );
  }

  Widget _buildError(Object error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: DesignTokens.spaceL,
        right: DesignTokens.spaceL,
        top: DesignTokens.spaceXL,
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      children: [
        AppErrorState(
          title: 'Error al cargar solicitudes',
          message: DeviceRequestService.messageFromError(error),
          onRetry: () => ref.read(deviceRequestsProvider.notifier).refresh(),
        ),
      ],
    );
  }
}

// ─── Banner de desconexión ─────────────────────────────────────────────

class _DisconnectedBanner extends StatelessWidget {
  const _DisconnectedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceL,
        vertical: DesignTokens.spaceS,
      ),
      color: AppColors.warning.withValues(alpha: 0.15),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, size: 16, color: AppColors.warning),
          SizedBox(width: DesignTokens.spaceS),
          Expanded(
            child: Text(
              'Sin conexión en tiempo real. Desliza hacia abajo para actualizar.',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXS,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de solicitud ──────────────────────────────────────────────

enum _CardAction { approvePersonal, approvePublic, reject }

class _DeviceRequestCard extends StatefulWidget {
  final DeviceRequest request;
  final bool highlighted;
  final Future<DeviceRequest> Function(DeviceApprovalScope scope) onApprove;
  final Future<DeviceRequest> Function() onReject;

  const _DeviceRequestCard({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
    this.highlighted = false,
  });

  @override
  State<_DeviceRequestCard> createState() => _DeviceRequestCardState();
}

class _DeviceRequestCardState extends State<_DeviceRequestCard> {
  _CardAction? _pendingAction;
  bool _working = false;
  String? _error;

  DeviceRequest get request => widget.request;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(request.status);

    return _CardShell(
      accentColor: statusColor,
      borderColor: widget.highlighted
          ? AppColors.primary.withValues(alpha: 0.5)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: icono en chip + usuario + estado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.spaceS),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Icon(Icons.phonelink_lock, color: statusColor, size: 20),
              ),
              const SizedBox(width: DesignTokens.spaceS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.displayUser,
                      style: const TextStyle(
                        fontSize: DesignTokens.fontSizeM,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (request.userFullName.trim().isNotEmpty)
                      Text(
                        request.username,
                        style: const TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              _StatusBadge(label: request.statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceM),

          // Detalle: dispositivo, cliente, vencimiento
          _detailRow(Icons.devices_other, 'Equipo', request.displayDevice),
          _detailRow(
            Icons.language,
            'Cliente',
            request.clientType == 'web'
                ? 'Web'
                : request.clientType == 'api'
                ? 'App móvil'
                : request.clientType,
          ),
          _detailRow(Icons.schedule, 'Vence', _expiryText(request)),
          if (request.resolvedByUsername != null &&
              request.resolvedByUsername!.isNotEmpty)
            _detailRow(
              Icons.how_to_reg,
              'Resuelta por',
              '${request.resolvedByUsername}'
                  '${request.approvalScope != null ? ' (${request.approvalScope!.label.toLowerCase()})' : ''}',
            ),

          if (_error != null) ...[
            const SizedBox(height: DesignTokens.spaceS),
            AppInlineError(
              message: _error!,
              dismissible: true,
              onDismiss: () => setState(() => _error = null),
            ),
          ],

          // Acciones (solo pendientes de admin)
          if (request.isPendingAdmin) ...[
            const SizedBox(height: DesignTokens.spaceS),
            if (_pendingAction == null)
              _buildActionButtons()
            else
              _buildInlineConfirmation(),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceXS),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: DesignTokens.spaceS),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: DesignTokens.spaceS,
      runSpacing: DesignTokens.spaceS,
      children: [
        AppButton.success(
          text: 'Personal',
          icon: Icons.person,
          size: AppButtonSize.small,
          onPressed: () =>
              setState(() => _pendingAction = _CardAction.approvePersonal),
        ),
        AppButton.secondary(
          text: 'Público',
          icon: Icons.groups,
          size: AppButtonSize.small,
          onPressed: () =>
              setState(() => _pendingAction = _CardAction.approvePublic),
        ),
        AppButton.error(
          text: 'Rechazar',
          icon: Icons.block,
          size: AppButtonSize.small,
          onPressed: () => setState(() => _pendingAction = _CardAction.reject),
        ),
      ],
    );
  }

  /// Confirmación integrada en la tarjeta (sin diálogos genéricos)
  Widget _buildInlineConfirmation() {
    final (message, color) = switch (_pendingAction!) {
      _CardAction.approvePersonal => (
        '¿Aprobar como equipo PERSONAL?',
        AppColors.success,
      ),
      _CardAction.approvePublic => (
        '¿Aprobar como equipo PÚBLICO?',
        AppColors.secondary,
      ),
      _CardAction.reject => ('¿Rechazar esta solicitud?', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXS,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          if (_working)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            TextButton(
              onPressed: () => setState(() => _pendingAction = null),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: _confirmPendingAction,
              child: Text(
                'Confirmar',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmPendingAction() async {
    final action = _pendingAction;
    if (action == null || _working) return;

    setState(() {
      _working = true;
      _error = null;
    });

    try {
      switch (action) {
        case _CardAction.approvePersonal:
          await widget.onApprove(DeviceApprovalScope.personal);
        case _CardAction.approvePublic:
          await widget.onApprove(DeviceApprovalScope.public);
        case _CardAction.reject:
          await widget.onReject();
      }
      if (mounted) setState(() => _pendingAction = null);
    } catch (e) {
      if (mounted) {
        setState(() => _error = DeviceRequestService.messageFromError(e));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _expiryText(DeviceRequest request) {
    final expiresAt = request.expiresAt;
    if (expiresAt == null) return '—';
    final formatted = DateFormat('dd/MM/yyyy HH:mm').format(expiresAt);
    if (!request.isPendingAdmin &&
        request.status != DeviceRequestStatus.pendingOtp) {
      return formatted;
    }
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return '$formatted (vencida)';
    if (remaining.inMinutes < 60) {
      return '$formatted (en ${remaining.inMinutes} min)';
    }
    return formatted;
  }

  Color _statusColor(DeviceRequestStatus? status) {
    switch (status) {
      case DeviceRequestStatus.pendingAdmin:
        return AppColors.warning;
      case DeviceRequestStatus.pendingOtp:
        return AppColors.info;
      case DeviceRequestStatus.approved:
        return AppColors.success;
      case DeviceRequestStatus.rejected:
        return AppColors.error;
      case DeviceRequestStatus.consumed:
        return AppColors.accent;
      case DeviceRequestStatus.expired:
      case null:
        return AppColors.textSecondary;
    }
  }
}

/// Shell de tarjeta del design system: fondo blanco, radio L, sombra sutil
/// y accent strip lateral de 4px (mismo patrón que DetalleRegistroCard y
/// FormFieldsCard de pedeteo).
class _CardShell extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final Color? borderColor;

  const _CardShell({
    required this.child,
    required this.accentColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceM),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceS,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: DesignTokens.fontSizeXS,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
