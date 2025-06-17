import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/screens/camara/camera_screen.dart';
import 'package:stampcamera/providers/auth_provider.dart';
import 'package:stampcamera/utils/verificar_version_app.dart';
import 'package:stampcamera/widgets/user_card.dart';

import '../main.dart'; // Para acceder a `cameras`

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _versionChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_versionChecked) {
      _versionChecked = true;
      verificarVersionApp(context, ref); // Aquí se ejecuta una vez
    }
  }

  void _abrirCamara(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CameraScreen(camera: cameras.first)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplicaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          authState.when(
            data: (auth) {
              if (!auth.isLoggedIn || auth.user == null) {
                return const SizedBox();
              }
              return UserCard(user: auth.user!);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const SizedBox(),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Cámara'),
            onTap: () => _abrirCamara(context),
          ),
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
