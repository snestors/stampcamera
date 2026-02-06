import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stampcamera/screens/autos/autos_screen.dart';
import 'package:stampcamera/screens/autos/contenedores/contenedor_form.dart';
import 'package:stampcamera/widgets/autos/forms/dano_form.dart';
import 'package:stampcamera/widgets/autos/forms/registro_vin_forms.dart';
import 'package:stampcamera/widgets/autos/forms/fotos_presentacion_form.dart';
import 'package:stampcamera/screens/autos/inventario/inventario_detalle_nave_screen.dart';
import 'package:stampcamera/screens/autos/inventario/inventario_detalle_screen.dart';
import 'package:stampcamera/screens/autos/registro_general/detalle_registro_screen.dart';
import 'package:stampcamera/screens/autos/reporte_pedeteo_screen.dart';
import 'package:stampcamera/screens/camara/camera_screen.dart';
import 'package:stampcamera/screens/camara/fullscreen_image.dart';
import 'package:stampcamera/screens/camara/gallery_selector_screen.dart';
import 'package:stampcamera/screens/graneles/graneles_screen.dart';
import 'package:stampcamera/screens/graneles/servicio_dashboard_screen.dart';
import 'package:stampcamera/screens/graneles/ticket_detalle_screen.dart';
import 'package:stampcamera/screens/graneles/ticket_crear_screen.dart';
import 'package:stampcamera/screens/graneles/balanza_crear_screen.dart';
import 'package:stampcamera/screens/graneles/almacen_crear_screen.dart';
import 'package:stampcamera/screens/graneles/silos_crear_screen.dart';
import 'package:stampcamera/screens/privacy_policy_screen.dart';
import 'package:stampcamera/screens/registro_asistencia_screen.dart';
import 'package:stampcamera/screens/device_registration_screen.dart';
import 'package:stampcamera/screens/casos/casos_home_screen.dart';
import 'package:stampcamera/screens/casos/explorador_screen.dart';

import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';
import '../models/auth_state.dart';
import '../utils/go_router_refresh_stream.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream.multi([
      ref.watch(authProvider.notifier).stream,
      ref.watch(deviceProvider.notifier).stream,
    ]),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyAcceptanceScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/device-registration',
        builder: (context, state) => const DeviceRegistrationScreen(),
      ),
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
          GoRoute(
            path: 'reporte-pedeteo',
            name: 'reporte-pedeteo',
            builder: (context, state) => const ReportePedeteoScreen(),
          ),
          // Formularios con transición slide-up
          GoRoute(
            path: 'dano/crear/:vin',
            pageBuilder: (context, state) => _slideUpPage(
              state,
              DanoForm(vin: state.pathParameters['vin']!),
            ),
          ),
          GoRoute(
            path: 'dano/editar/:vin/:danoId',
            pageBuilder: (context, state) => _slideUpPage(
              state,
              DanoForm(
                vin: state.pathParameters['vin']!,
                danoId: int.parse(state.pathParameters['danoId']!),
              ),
            ),
          ),
          GoRoute(
            path: 'registro-vin/crear/:vin',
            pageBuilder: (context, state) => _slideUpPage(
              state,
              RegistroVinForm(vin: state.pathParameters['vin']!),
            ),
          ),
          GoRoute(
            path: 'registro-vin/editar/:vin',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return _slideUpPage(
                state,
                RegistroVinForm(
                  vin: state.pathParameters['vin']!,
                  registroVin: extra?['registroVin'],
                ),
              );
            },
          ),
          GoRoute(
            path: 'foto/crear/:vin',
            pageBuilder: (context, state) => _slideUpPage(
              state,
              FotoPresentacionForm(vin: state.pathParameters['vin']!),
            ),
          ),
          GoRoute(
            path: 'foto/editar/:vin',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return _slideUpPage(
                state,
                FotoPresentacionForm(
                  vin: state.pathParameters['vin']!,
                  fotoId: extra?['fotoId'] as int?,
                  tipoInicial: extra?['tipoInicial'] as String?,
                  nDocumentoInicial: extra?['nDocumentoInicial'] as String?,
                ),
              );
            },
          ),
          GoRoute(
            path: 'contenedor/crear',
            pageBuilder: (context, state) => _slideUpPage(
              state,
              const ContenedorForm(),
            ),
          ),
          GoRoute(
            path: 'contenedor/editar',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return _slideUpPage(
                state,
                ContenedorForm(contenedor: extra?['contenedor']),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/graneles',
        name: 'graneles',
        builder: (context, state) => const GranelesScreen(),
        routes: [
          GoRoute(
            path: 'servicio/:servicioId/dashboard',
            name: 'servicio-dashboard',
            builder: (context, state) {
              final servicioIdString = state.pathParameters['servicioId']!;
              final servicioId = int.parse(servicioIdString);
              return ServicioDashboardScreen(servicioId: servicioId);
            },
          ),
          // IMPORTANTE: Rutas específicas deben ir ANTES de las rutas con parámetros genéricos
          // Ruta sin servicioId - muestra BLs de todas las naves en operación
          GoRoute(
            path: 'ticket/crear',
            builder: (context, state) {
              return const TicketCrearScreen();
            },
          ),
          // Ruta con servicioId - para compatibilidad con navegación desde servicio específico
          GoRoute(
            path: 'ticket/crear/:servicioId',
            builder: (context, state) {
              final servicioIdString = state.pathParameters['servicioId']!;
              final servicioId = int.parse(servicioIdString);
              return TicketCrearScreen(servicioId: servicioId);
            },
          ),
          GoRoute(
            path: 'ticket/editar/:ticketId',
            builder: (context, state) {
              final ticketIdString = state.pathParameters['ticketId']!;
              final ticketId = int.parse(ticketIdString);
              return TicketCrearScreen.edit(ticketId: ticketId);
            },
          ),
          // Ruta genérica de ticket al final
          GoRoute(
            path: 'ticket/:ticketId',
            builder: (context, state) {
              final ticketIdString = state.pathParameters['ticketId']!;
              final ticketId = int.parse(ticketIdString);
              return TicketDetalleScreen(ticketId: ticketId);
            },
          ),
          // Rutas de Balanza
          GoRoute(
            path: 'balanza/crear',
            builder: (context, state) {
              return const BalanzaCrearScreen();
            },
          ),
          GoRoute(
            path: 'balanza/editar/:balanzaId',
            builder: (context, state) {
              final balanzaIdString = state.pathParameters['balanzaId']!;
              final balanzaId = int.parse(balanzaIdString);
              return BalanzaCrearScreen.edit(balanzaId: balanzaId);
            },
          ),
          // Rutas de Almacén
          GoRoute(
            path: 'almacen/crear',
            builder: (context, state) {
              return const AlmacenCrearScreen();
            },
          ),
          GoRoute(
            path: 'almacen/editar/:almacenId',
            builder: (context, state) {
              final almacenIdString = state.pathParameters['almacenId']!;
              final almacenId = int.parse(almacenIdString);
              return AlmacenCrearScreen.edit(almacenId: almacenId);
            },
          ),
          // Rutas de Silos
          GoRoute(
            path: 'silos/crear',
            builder: (context, state) {
              return const SilosCrearScreen();
            },
          ),
          GoRoute(
            path: 'silos/editar/:siloId',
            builder: (context, state) {
              final siloIdString = state.pathParameters['siloId']!;
              final siloId = int.parse(siloIdString);
              return SilosCrearScreen.edit(siloId: siloId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/casos',
        name: 'casos',
        builder: (context, state) => const CasosHomeScreen(),
        routes: [
          GoRoute(
            path: 'explorador/:carpetaId',
            builder: (context, state) {
              final carpetaIdString = state.pathParameters['carpetaId']!;
              final carpetaId = int.parse(carpetaIdString);
              return ExploradorScreen(carpetaId: carpetaId);
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
      // 🔥 1. VERIFICAR POLÍTICA PRIMERO
      final prefs = await SharedPreferences.getInstance();
      final privacyAccepted = prefs.getBool('privacy_policy_accepted') ?? false;

      // Si no ha aceptado la política y no está en /privacy, redirigir
      if (!privacyAccepted && state.fullPath != '/privacy') {
        return '/privacy';
      }

      // Si ya aceptó la política, continuar con verificaciones
      if (privacyAccepted) {
        // 🔐 2. VERIFICAR DISPOSITIVO DE CONFIANZA
        final deviceState = ref.read(deviceProvider);

        // Si está verificando el dispositivo, mostrar splash
        if (deviceState.status == DeviceRegistrationStatus.checking) {
          if (state.fullPath != '/') return '/';
          return null;
        }

        // Si el dispositivo no está registrado, ir a registro
        if (deviceState.status == DeviceRegistrationStatus.notRegistered ||
            deviceState.status == DeviceRegistrationStatus.awaitingCode ||
            deviceState.status == DeviceRegistrationStatus.awaitingToken) {
          if (state.fullPath != '/device-registration') {
            return '/device-registration';
          }
          return null;
        }

        // 🔑 3. VERIFICAR AUTENTICACIÓN
        final authState = ref.read(authProvider);

        if (authState is AsyncLoading) return '/';
        if (authState is AsyncError) return '/login';

        final auth = authState.value;

        if (auth == null || auth.status == AuthStatus.loggedOut) {
          // Si no está logueado, ir a login
          if (state.fullPath == '/privacy' ||
              state.fullPath == '/device-registration' ||
              state.fullPath == '/') {
            return '/login';
          }
          if (state.fullPath != '/login') return '/login';
          return null;
        }

        if (auth.status == AuthStatus.loggedIn) {
          if (state.fullPath == '/login' ||
              state.fullPath == '/' ||
              state.fullPath == '/privacy' ||
              state.fullPath == '/device-registration') {
            return '/home';
          }
        }
      }

      return null;
    },
  );
});

/// Transición slide-up para formularios (como modal fullscreen)
CustomTransitionPage<T> _slideUpPage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      );
    },
  );
}
