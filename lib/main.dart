import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:camera/camera.dart';
import 'package:stampcamera/services/background_queue_service.dart';
import 'package:stampcamera/services/update_service.dart'; // ✅ AGREGAR
import 'package:stampcamera/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:stampcamera/utils/image_processor.dart';
import 'routes/app_router.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  cameras = await availableCameras();

  await initializeImageProcessor();
  BackgroundQueueService().start();
  FlutterNativeSplash.remove();

  await initializeDateFormatting('es', null);

  runApp(const ProviderScope(child: MyApp()));

  // 🎯 VERIFICAR ACTUALIZACIÓN (igual que el ejemplo)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    UpdateService.checkForUpdate();
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'AYG',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: agTheme,
    );
  }
}
