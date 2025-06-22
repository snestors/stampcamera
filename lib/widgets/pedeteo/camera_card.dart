// widgets/pedeteo/camera_card.dart (migrado a ReusableCameraCard)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/widgets/common/reusable_camera_card.dart';

class CameraCard extends ConsumerWidget {
  const CameraCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pedeteoStateProvider);

    debugPrint('🔍 CameraCard - capturedImagePath: ${state.capturedImagePath}');

    return ReusableCameraCard(
      title: 'Foto del VIN',
      subtitle: 'Asegúrate de que el VIN sea legible',
      currentImagePath: state.capturedImagePath,
      onImageSelected: (imagePath) {
        ref.read(pedeteoStateProvider.notifier).setCapturedImage(imagePath);
      },
      showGalleryOption: true,
      cameraButtonText: 'Tomar foto',
      galleryButtonText: 'Elegir de galería',
      primaryColor: const Color(0xFF0A2D3E),
    );
  }
}
