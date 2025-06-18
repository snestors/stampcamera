import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_version_provider.dart';

Future<void> verificarVersionApp(BuildContext context, WidgetRef ref) async {
  try {
    final version = await ref.read(appVersionProvider.future);

    if (version.mustUpdate && version.apkUrl != null) {
      if (!context.mounted) return;
      await _forzarActualizacion(context, version.apkUrl!);
    } else if (version.shouldUpdate && version.apkUrl != null) {
      if (!context.mounted) return;
      await _mostrarDialogoActualizacionOpcional(context, version.apkUrl!);
    }
  } catch (e) {
    debugPrint('Error al verificar versión: $e');
  }
}

Future<void> _forzarActualizacion(BuildContext context, String apkUrl) async {
  while (true) {
    final actualizado = await _abrirUrlApk(context, apkUrl, obligatorio: true);
    if (actualizado) break;
  }
}

Future<void> _mostrarDialogoActualizacionOpcional(
  BuildContext context,
  String apkUrl,
) async {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Actualización disponible'),
      content: const Text('Hay una nueva versión disponible. ¿Deseas actualizar?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Más tarde'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await _abrirUrlApk(context, apkUrl);
          },
          child: const Text('Actualizar'),
        ),
      ],
    ),
  );
}

Future<bool> _abrirUrlApk(
  BuildContext context,
  String apkUrl, {
  bool obligatorio = false,
}) async {
  try {
    final uri = Uri.parse(apkUrl);

    await showDialog(
      context: context,
      barrierDismissible: !obligatorio,
      builder: (_) => AlertDialog(
        title: Text(obligatorio ? 'Actualización obligatoria' : 'Descarga disponible'),
        content: const Text('Serás redirigido al navegador para descargar la nueva versión.'),
        actions: [
          if (!obligatorio)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          TextButton(
            onPressed: () async {
              
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text('Ir al navegador'),
          ),
        ],
      ),
    );

    return true;
  } catch (e) {
    debugPrint('[APK] Error al abrir URL: $e');
    return false;
  }
}