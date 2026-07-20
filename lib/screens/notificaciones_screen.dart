import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/notificacion_model.dart';
import 'package:stampcamera/providers/notificaciones_provider.dart';
import 'package:stampcamera/utils/notification_route_mapper.dart';

/// Centro de notificaciones (bandeja efímera, espejo de la web):
/// solo no-leídas; marcar como leída la elimina del servidor.
class NotificacionesScreen extends ConsumerWidget {
  const NotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificacionesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (state.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Marcar todas como leídas',
              onPressed: () => _confirmarMarcarTodas(context, ref),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificacionesProvider.notifier).load(),
        child: _buildBody(context, ref, state),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    NotificacionesState state,
  ) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.items.isEmpty) {
      // ListView para que el pull-to-refresh funcione en vacío
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const AppEmptyState(
            icon: Icons.notifications_none,
            title: 'Sin notificaciones',
            subtitle: 'Cuando recibas una notificación aparecerá aquí',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: DesignTokens.spaceM,
        right: DesignTokens.spaceM,
        top: DesignTokens.spaceM,
        bottom: DesignTokens.spaceM + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: state.items.length,
      separatorBuilder: (_, index) =>
          const SizedBox(height: DesignTokens.spaceS),
      itemBuilder: (context, index) {
        final notif = state.items[index];
        return _NotificacionCard(
          notif: notif,
          onDismissed: () =>
              ref.read(notificacionesProvider.notifier).markAsRead(notif.id),
          onTap: () => _mostrarDetalle(context, ref, notif),
        );
      },
    );
  }

  Future<void> _confirmarMarcarTodas(BuildContext context, WidgetRef ref) async {
    final confirmar = await AppDialog.confirm(
      context,
      title: 'Marcar todas como leídas',
      message:
          'Las notificaciones leídas se eliminan y no se pueden recuperar. ¿Continuar?',
      confirmText: 'Marcar todas',
      cancelText: 'Cancelar',
    );
    if (confirmar == true) {
      ref.read(notificacionesProvider.notifier).markAllAsRead();
    }
  }

  void _mostrarDetalle(
    BuildContext context,
    WidgetRef ref,
    NotificacionModel notif,
  ) {
    final appRoute = mapWebRouteToApp(notif.url);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusL),
        ),
      ),
      builder: (sheetContext) {
        final estilo = estiloNotificacion(notif.tipo);
        return Padding(
          padding: EdgeInsets.only(
            left: DesignTokens.spaceL,
            right: DesignTokens.spaceL,
            top: DesignTokens.spaceL,
            bottom: DesignTokens.spaceL +
                MediaQuery.of(sheetContext).viewPadding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spaceS),
                    decoration: BoxDecoration(
                      color: estilo.color.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusM),
                    ),
                    child: Icon(estilo.icon, color: estilo.color, size: 22),
                  ),
                  const SizedBox(width: DesignTokens.spaceM),
                  Expanded(
                    child: Text(
                      notif.titulo,
                      style: const TextStyle(
                        fontSize: DesignTokens.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceM),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    notif.cuerpo,
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceS),
              Text(
                [
                  if (notif.emitidoPor.isNotEmpty) 'De: ${notif.emitidoPor}',
                  notif.tiempoRelativo,
                ].join(' · '),
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: DesignTokens.spaceL),
              Row(
                children: [
                  Expanded(
                    child: AppButton.ghost(
                      text: 'Marcar como leída',
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        ref
                            .read(notificacionesProvider.notifier)
                            .markAsRead(notif.id);
                      },
                    ),
                  ),
                  if (appRoute != null) ...[
                    const SizedBox(width: DesignTokens.spaceS),
                    Expanded(
                      child: AppButton.primary(
                        text: 'Abrir',
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          ref
                              .read(notificacionesProvider.notifier)
                              .markAsRead(notif.id);
                          context.push(appRoute);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Estilo (color + icono) según el tipo de notificación del backend.
({Color color, IconData icon}) estiloNotificacion(String tipo) {
  switch (tipo) {
    case 'success':
      return (color: AppColors.success, icon: Icons.check_circle_outline);
    case 'warning':
      return (color: AppColors.warning, icon: Icons.warning_amber_rounded);
    case 'error':
      return (color: AppColors.error, icon: Icons.error_outline);
    case 'message':
      return (color: AppColors.secondary, icon: Icons.chat_bubble_outline);
    default: // info
      return (color: AppColors.info, icon: Icons.notifications_none);
  }
}

class _NotificacionCard extends StatelessWidget {
  const _NotificacionCard({
    required this.notif,
    required this.onDismissed,
    required this.onTap,
  });

  final NotificacionModel notif;
  final VoidCallback onDismissed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final estilo = estiloNotificacion(notif.tipo);

    return Dismissible(
      key: ValueKey('notif_${notif.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: DesignTokens.spaceL),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done, color: Colors.white, size: 20),
            SizedBox(width: DesignTokens.spaceS),
            Text(
              'Leída',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: DesignTokens.fontSizeS,
              ),
            ),
          ],
        ),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        elevation: 1,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceM),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceS),
                  decoration: BoxDecoration(
                    color: estilo.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Icon(estilo.icon, color: estilo.color, size: 20),
                ),
                const SizedBox(width: DesignTokens.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: DesignTokens.fontSizeM,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notif.cuerpo,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: DesignTokens.fontSizeS,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceS),
                      Text(
                        [
                          if (notif.emitidoPor.isNotEmpty) notif.emitidoPor,
                          notif.tiempoRelativo,
                        ].join(' · '),
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
