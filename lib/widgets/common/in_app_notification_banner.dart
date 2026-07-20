import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/theme/app_colors.dart';
import 'package:stampcamera/core/theme/design_tokens.dart';
import 'package:stampcamera/models/notificacion_model.dart';
import 'package:stampcamera/providers/app_socket_provider.dart';
import 'package:stampcamera/routes/app_router.dart';
import 'package:stampcamera/utils/notification_route_mapper.dart';

/// Banner emergente para notificaciones en vivo (WS) con la app en
/// foreground. Se monta sobre TODA la app vía `MaterialApp.router(builder:)`
/// — FCM cubre background/app cerrada; este banner cubre el hueco visible
/// cuando la app está abierta (donde FCM no muestra nada a propósito).
///
/// Comportamiento: entra deslizando desde arriba, se auto-cierra a los 5s,
/// swipe hacia arriba lo descarta y tap navega a la ruta mapeada de la
/// notificación (si existe equivalente móvil).
class InAppNotificationBanner extends ConsumerStatefulWidget {
  const InAppNotificationBanner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState
    extends ConsumerState<InAppNotificationBanner> {
  NotificacionModel? _current;
  bool _visible = false;
  Timer? _autoDismissTimer;
  Timer? _clearTimer;

  static const _showDuration = Duration(seconds: 5);
  static const _animDuration = Duration(milliseconds: 250);

  void _show(NotificacionModel notif) {
    _autoDismissTimer?.cancel();
    _clearTimer?.cancel();
    setState(() {
      _current = notif;
      _visible = true;
    });
    _autoDismissTimer = Timer(_showDuration, _dismiss);
  }

  void _dismiss() {
    if (!mounted || !_visible) return;
    _autoDismissTimer?.cancel();
    setState(() => _visible = false);
    // Desmontar el banner recién cuando termina la animación de salida
    _clearTimer = Timer(_animDuration, () {
      if (mounted) setState(() => _current = null);
    });
  }

  void _onTap() {
    final route = mapWebRouteToApp(_current?.url);
    _dismiss();
    if (route != null) {
      ref.read(appRouterProvider).push(route);
    }
  }

  ({Color color, IconData icon}) _estiloPorTipo(String tipo) {
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

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _clearTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(wsNotificationsProvider, (_, next) {
      next.whenData((data) {
        final notif = NotificacionModel.fromWs(data);
        if (notif.esRuidoAutomatico) return;
        _show(notif);
      });
    });

    final notif = _current;
    return Stack(
      children: [
        widget.child,
        if (notif != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + DesignTokens.spaceS,
            left: DesignTokens.spaceM,
            right: DesignTokens.spaceM,
            child: AnimatedSlide(
              offset: _visible ? Offset.zero : const Offset(0, -2),
              duration: _animDuration,
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: _animDuration,
                child: _buildBanner(notif),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBanner(NotificacionModel notif) {
    final estilo = _estiloPorTipo(notif.tipo);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < -100) _dismiss();
      },
      child: Material(
        color: Colors.white,
        elevation: 6,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        child: InkWell(
          onTap: _onTap,
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
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusM),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: DesignTokens.fontSizeS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceS),
                GestureDetector(
                  onTap: _dismiss,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
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
