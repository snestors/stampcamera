import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:camera/camera.dart';
import 'package:stampcamera/providers/theme_provider.dart';
import 'package:stampcamera/services/background_queue_service.dart';
import 'package:stampcamera/services/offline_sync_handler.dart';
import 'package:stampcamera/services/push_notification_service.dart';
import 'package:stampcamera/services/storage_health_service.dart';
import 'package:stampcamera/services/update_service.dart';
import 'package:stampcamera/core/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:stampcamera/utils/image_processor.dart';
import 'package:stampcamera/core/helpers/formatters/date_formatters.dart';
import 'package:stampcamera/routes/app_router.dart';
import 'package:stampcamera/widgets/common/in_app_notification_banner.dart';

late List<CameraDescription> cameras;
late ProviderContainer _providerContainer;

Future<void> main() async {
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Edge-to-edge para Android 15+
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  // Inicializar timezone America/Lima para toda la app
  initTimezone();

  // Firebase (push FCM); si no hay config la app sigue sin push
  await PushNotificationService.initializeFirebase();

  // IMPORTANTE: Verificar salud del storage ANTES de cualquier otra operacion
  // Esto soluciona el problema de corrupcion al cambiar entre debug y release
  final storageHealthy = await storageHealthService.checkAndRepairStorage();
  if (!storageHealthy) {
    debugPrint('⚠️ Storage fue reparado - el usuario debera iniciar sesion nuevamente');
  }

  cameras = await availableCameras();

  await initializeImageProcessor();
  BackgroundQueueService().start();
  FlutterNativeSplash.remove();

  await initializeDateFormatting('es', null);

  // Crear ProviderContainer para inicializar servicios
  _providerContainer = ProviderContainer();

  // Inicializar el sistema de sincronizacion offline-first
  offlineSyncHandler.initialize(_providerContainer);
  backgroundQueueService.initialize(_providerContainer);

  runApp(
    UncontrolledProviderScope(
      container: _providerContainer,
      child: const MyApp(),
    ),
  );

  // Verificar actualizacion al inicio y al volver del background
  UpdateService().initialize();

  // Navegación al tocar una push (app en background o terminada)
  PushNotificationService()
      .setupInteractedMessages(_providerContainer.read(appRouterProvider));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(materialThemeModeProvider);

    return MaterialApp.router(
      title: 'A&G Inspección Vehicular',
      debugShowCheckedModeBanner: false,
      routerConfig: router,

      // Banner emergente global de notificaciones en vivo (foreground)
      builder: (context, child) =>
          InAppNotificationBanner(child: child ?? const SizedBox.shrink()),

      // ✅ Usar los temas corporativos A&G desde AppTheme
      theme: AppTheme.lightTheme, // Tema claro corporativo
      darkTheme: AppTheme.darkTheme, // Tema oscuro corporativo
      themeMode: themeMode, // Modo desde provider (light por defecto)
    );
  }
}
