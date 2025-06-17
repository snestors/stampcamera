import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/screens/camara/camera_screen.dart';
import 'package:stampcamera/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

import '../main.dart'; // Para acceder a `cameras`

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _abrirCamara(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraScreen(camera: cameras.first),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplicaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              context.go('/login'); // Redirige manualmente si es necesario
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Asistencia'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Asistencia en construcción')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Cámara'),
            onTap: () => _abrirCamara(context),
          ),
          ListTile(
            leading: const Icon(Icons.directions_car),
            title: const Text('Autos'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Autos en construcción')),
              );
            },
          ),
        ],
      ),
    );
  }
}
