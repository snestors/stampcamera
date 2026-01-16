import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stampcamera/screens/autos/autos_screen.dart';
import 'package:stampcamera/screens/autos/inventario/inventario_detalle_nave_screen.dart';
import 'package:stampcamera/screens/autos/inventario/inventario_detalle_screen.dart';
import 'package:stampcamera/screens/autos/registro_general/detalle_registro_screen.dart';
import 'package:stampcamera/screens/camara/camera_screen.dart';
import 'package:stampcamera/screens/camara/fullscreen_image.dart';
import 'package:stampcamera/screens/camara/gallery_selector_screen.dart';
import 'package:stampcamera/screens/privacy_policy_screen.dart';
import 'package:stampcamera/screens/registro_asistencia_screen.dart';

import '../providers/auth_provider.dart';
import '../models/auth_state.dart';
import '../utils/go_router_refresh_stream.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authProvider.notifier).stream,
    ),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyAcceptanceScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/asistencia',
        name: 'asistencia',
        builder: (context, state) => const RegistroAsistenciaScreen(),
      ),
      GoRoute(
        path: '/autos',
        builder: (context, state) => const AutosScreen(),
        routes: [
          GoRoute(
            path: 'detalle/:vin',
            builder: (context, state) {
              final vin = state.pathParameters['vin']!;
              return DetalleRegistroScreen(vin: vin);
            },
          ),
          GoRoute(
            path: 'inventario/nave/:naveId',
            builder: (context, state) {
              final naveIdString = state.pathParameters['naveId']!;
              final naveId = int.parse(naveIdString);
              return InventarioDetalleNaveScreen(naveId: naveId);
            },
          ),
          GoRoute(
            path: 'inventario/detalle/:infId',
            builder: (context, state) {
              final infIdString = state.pathParameters['infId']!;
              final infId = int.parse(infIdString);
              return InventarioDetalleScreen(informacionUnidadId: infId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/camera',
        name: 'camera',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final camera = extra['camera'] as CameraDescription;
          return CameraScreen(camera: camera);
        },
        routes: [
          GoRoute(
            path: 'fullscreen',
            name: 'fullscreen',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              final camera = extra['camera'] as CameraDescription;
              final index = extra['index'] as int;
              return FullscreenImage(camera: camera, initialIndex: index);
            },
          ),
          GoRoute(
            path: 'gallery',
            name: 'gallery',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              final camera = extra['camera'] as CameraDescription;
              return GallerySelectorScreen(camera: camera);
            },
          ),
        ],
      ),
    ],
    redirect: (context, state) async {
      // 🔥 VERIFICAR POLÍTICA PRIMERO
      final prefs = await SharedPreferences.getInstance();
      final privacyAccepted = prefs.getBool('privacy_policy_accepted') ?? false;

      // Si no ha aceptado la política y no está en /privacy, redirigir
      if (!privacyAccepted && state.fullPath != '/privacy') {
        return '/privacy';
      }

      // Si ya aceptó la política, continuar con lógica de auth
      if (privacyAccepted) {
        final authState = ref.read(authProvider);

        if (authState is AsyncLoading) return '/';
        if (authState is AsyncError) return '/login';

        final auth = authState.value;

        if (auth == null || auth.status == AuthStatus.loggedOut) {
          // Si está en privacy y no está logueado, ir a login
          if (state.fullPath == '/privacy') return '/login';
          return '/login';
        }

        if (auth.status == AuthStatus.loggedIn) {
          if (state.fullPath == '/login' ||
              state.fullPath == '/' ||
              state.fullPath == '/privacy') {
            return '/home';
          }
        }
      }

      return null;
    },
  );
});
