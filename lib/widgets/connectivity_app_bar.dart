// lib/widgets/connectivity_app_bar.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/providers/connectivity_provider.dart';

class ConnectivityAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool centerTitle;

  const ConnectivityAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityProvider);

    return AppBar(
      title: title,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      actions: [
        // Agregar las acciones personalizadas
        ...actions ?? [],
        // Agregar indicador de conectividad
        Padding(
          padding: EdgeInsets.only(right: 8),
          child: Icon(
            connectivityState.isOnline ? Icons.wifi : Icons.wifi_off,
            color: connectivityState.isOnline ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

// Versión con más información en un popup
class ConnectivityAppBarWithDetails extends ConsumerWidget
    implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool centerTitle;

  const ConnectivityAppBarWithDetails({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityProvider);

    return AppBar(
      title: title,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      actions: [
        // Agregar las acciones personalizadas
        ...actions ?? [],
        // Indicador clickeable con más detalles
        IconButton(
          icon: Icon(
            connectivityState.isOnline ? Icons.wifi : Icons.wifi_off,
            color: connectivityState.isOnline ? Colors.green : Colors.red,
            size: 20,
          ),
          onPressed: () =>
              _showConnectivityInfo(context, ref, connectivityState),
          tooltip: connectivityState.isOnline ? 'Conectado' : 'Sin conexión',
        ),
      ],
    );
  }

  void _showConnectivityInfo(
    BuildContext context,
    WidgetRef ref,
    ConnectivityState state,
  ) {
    final status = state.isOnline ? 'Conectado' : 'Sin conexión';
    final connectionType = _getConnectionType(state.connectivityResult);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              state.isOnline ? Icons.wifi : Icons.wifi_off,
              color: state.isOnline ? Colors.green : Colors.red,
            ),
            SizedBox(width: 8),
            Text('Conectividad'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estado: $status'),
            SizedBox(height: 8),
            Text('Tipo: $connectionType'),
            SizedBox(height: 8),
            Text('Última verificación: ${_formatTime(state.lastChecked)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(connectivityProvider.notifier).forceCheck();
              Navigator.pop(context);
            },
            child: Text('Verificar'),
          ),
        ],
      ),
    );
  }

  String _getConnectionType(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      return 'WiFi';
    } else if (results.contains(ConnectivityResult.mobile)) {
      return 'Datos móviles';
    } else if (results.contains(ConnectivityResult.none)) {
      return 'Sin conexión';
    } else {
      return 'Desconocido';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Hace ${difference.inSeconds} segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minutos';
    } else {
      return 'Hace ${difference.inHours} horas';
    }
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
