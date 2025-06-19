import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/screens/autos/autos_screen.dart';
import 'package:stampcamera/screens/camara/camera_screen.dart';
import 'package:stampcamera/screens/camara/fullscreen_image.dart';
import 'package:stampcamera/screens/camara/gallery_selector_screen.dart';

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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      //'/screen_registro': (context) => const ScreenRegistro(),
      GoRoute(path: '/autos', builder: (context, state) => const AutosScreen()),

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
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      // Mientras se carga el estado de auth, quédate en splash
      if (authState is AsyncLoading) return '/';

      // Si hubo un error, tratamos como loggedOut
      if (authState is AsyncError) return '/login';

      final auth = authState.value;

      if (auth == null || auth.status == AuthStatus.loggedOut) {
        return '/login';
      }

      if (auth.status == AuthStatus.loggedIn) {
        // Si intenta ir a login pero ya está logueado, redirigimos a home
        if (state.fullPath == '/login' || state.fullPath == '/') {
          return '/home';
        }
      }

      return null; // No redirigir, continuar con la ruta
    },
  );
});
