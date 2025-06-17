import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_version_provider.dart';
import '../services/http_service.dart';

Future<void> verificarVersionApp(BuildContext context, WidgetRef ref) async {
  try {
    final version = await ref.read(appVersionProvider.future);

    final appVersion = await _obtenerVersionActual();
    final isMenorQueMinima =
        _compararVersion(appVersion, version.minRequiredVersion) < 0;
    final isMenorQueUltima =
        _compararVersion(appVersion, version.latestVersion) < 0;

    if (isMenorQueMinima && version.apkUrl != null) {
      if (!context.mounted) return;
      await _forzarActualizacion(context, ref, version.apkUrl!);
    } else if (isMenorQueUltima && version.apkUrl != null) {
      if (!context.mounted) return;
      await _mostrarDialogoActualizacionOpcional(context, ref, version.apkUrl!);
    }
  } catch (e) {
    debugPrint('Error al verificar versión: $e');
  }
}

Future<String> _obtenerVersionActual() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}

/// Retorna -1 si a < b, 0 si son iguales, 1 si a > b
int _compararVersion(String a, String b) {
  final aParts = a.split('.').map(int.parse).toList();
  final bParts = b.split('.').map(int.parse).toList();
  for (int i = 0; i < 3; i++) {
    if (aParts[i] < bParts[i]) return -1;
    if (aParts[i] > bParts[i]) return 1;
  }
  return 0;
}

Future<void> _forzarActualizacion(
  BuildContext context,
  WidgetRef ref,
  String apkUrl,
) async {
  while (true) {
    final actualizado = await _descargarEInstalarAPK(
      context,
      ref,
      apkUrl,
      obligatorio: true,
    );
    if (actualizado) break;
  }
}

Future<void> _mostrarDialogoActualizacionOpcional(
  BuildContext context,
  WidgetRef ref,
  String apkUrl,
) async {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Actualización disponible'),
      content: const Text(
        'Hay una nueva versión disponible. ¿Deseas actualizar?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Más tarde'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _descargarEInstalarAPK(context, ref, apkUrl);
          },
          child: const Text('Actualizar'),
        ),
      ],
    ),
  );
}

Future<bool> _descargarEInstalarAPK(
  BuildContext context,
  WidgetRef ref,
  String apkUrl, {
  bool obligatorio = false,
}) async {
  final http = HttpService();
  final navigator = Navigator.of(context);
  int progreso = 0;

  bool mounted = context.mounted;
  await showDialog(
    context: context,
    barrierDismissible: !obligatorio,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(
            obligatorio
                ? 'Actualización obligatoria'
                : 'Descargando actualización...',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: progreso / 100),
              const SizedBox(height: 12),
              Text('$progreso% completado'),
            ],
          ),
        );
      },
    ),
  );

  try {
    final permiso = await Permission.storage.request();
    if (!permiso.isGranted) throw Exception("Permiso denegado");

    final dir = await getExternalStorageDirectory();
    final filePath = '${dir!.path}/ayg_actualizacion.apk';

    await http.dio.download(
      apkUrl,
      filePath,
      onReceiveProgress: (rec, total) {
        progreso = ((rec / total) * 100).round();
        (context as Element).markNeedsBuild();
      },
    );

    navigator.pop();
    if (!context.mounted) return false;

    await showDialog(
      context: context,
      barrierDismissible: !obligatorio,
      builder: (_) => AlertDialog(
        title: const Text('Descarga completa'),
        content: const Text('¿Deseas instalar ahora la nueva versión?'),
        actions: [
          if (!obligatorio)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _abrirApk(filePath);
            },
            child: const Text('Instalar'),
          ),
        ],
      ),
    );

    return true;
  } catch (e) {
    if (mounted) navigator.pop();
    if (!context.mounted) return false;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text('No se pudo completar la descarga: $e'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    return false;
  }
}

Future<void> _abrirApk(String filePath) async {
  final fileUri = Uri.file(filePath);
  if (await canLaunchUrl(fileUri)) {
    await launchUrl(fileUri);
  } else {
    debugPrint('No se pudo abrir el archivo: $fileUri');
  }
}
