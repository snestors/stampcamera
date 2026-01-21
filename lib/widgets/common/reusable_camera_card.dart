// widgets/common/reusable_camera_card.dart
/// 📸 COMPONENTE REUTILIZABLE DE CÁMARA (v2.1)
///
/// 🎯 PROPÓSITO:
/// Componente que permite tomar fotos con cámara o seleccionar de galería.
/// Soporte para preview de imágenes desde URL (para formularios de edición).
/// Procesa automáticamente las imágenes con logo y timestamp.
///
/// 📝 CARACTERÍSTICAS:
/// - ✅ Tomar foto con cámara
/// - ✅ Seleccionar imagen de galería
/// - ✅ Vista previa con zoom (local + URL)
/// - ✅ Procesamiento automático (logo + timestamp)
/// - ✅ Soporte para URLs existentes (formularios de edición)
/// - ✅ Títulos y colores personalizables
/// - ✅ Opción de ocultar galería
/// - ✅ Manejo de errores y estados de carga
/// - ✅ Resolución de cámara configurable
///
/// 🚀 EJEMPLOS DE USO:
///
/// // Formulario nuevo con resolución por defecto (veryHigh)
/// String? photoPath;
/// ReusableCameraCard(
///   title: 'Foto del VIN',
///   currentImagePath: photoPath,
///   onImageSelected: (path) => setState(() => photoPath = path),
/// )
///
/// // Con resolución específica
/// ReusableCameraCard(
///   title: 'Foto del Vehículo',
///   currentImagePath: photoPath,
///   cameraResolution: CameraResolution.high,
///   onImageSelected: (path) => setState(() => photoPath = path),
/// )
///
/// // Formulario de edición con resolución custom
/// ReusableCameraCard(
///   title: 'Foto del Vehículo',
///   currentImagePath: localPhotoPath,
///   currentImageUrl: 'https://api.example.com/photos/123.jpg',
///   cameraResolution: CameraResolution.high,
///   onImageSelected: (path) => setState(() => localPhotoPath = path),
/// )
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stampcamera/config/camera/camera_config.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/utils/image_processor.dart';

/// Enum personalizado para resoluciones de cámara
/// Evita la necesidad de importar la librería camera en otros archivos
enum CameraResolution {
  /// Alta resolución (ResolutionPreset.high)
  high,

  /// Muy alta resolución (ResolutionPreset.veryHigh)
  veryHigh,
}

/// Extensión para convertir CameraResolution a ResolutionPreset
extension CameraResolutionExtension on CameraResolution {
  ResolutionPreset get toResolutionPreset {
    switch (this) {
      case CameraResolution.high:
        return ResolutionPreset.high;
      case CameraResolution.veryHigh:
        return ResolutionPreset.veryHigh;
    }
  }
}

class ReusableCameraCard extends StatelessWidget {
  /// Título principal de la card
  final String title;

  /// Path de la imagen local (nueva foto tomada/seleccionada)
  final String? currentImagePath;

  /// URL de imagen existente (para formularios de edición)
  final String? currentImageUrl;

  /// URL del thumbnail (opcional, para mejor performance)
  final String? thumbnailUrl;

  /// Callback ejecutado cuando se selecciona una nueva imagen
  /// Recibe el path de la imagen procesada
  final Function(String imagePath) onImageSelected;

  /// Texto descriptivo opcional bajo el título
  final String? subtitle;

  /// Si mostrar el botón de galería (default: true)
  final bool showGalleryOption;

  /// Texto del botón de cámara (default: "Tomar foto")
  final String cameraButtonText;

  /// Texto del botón de galería (default: "Elegir de galería")
  final String galleryButtonText;

  /// Color principal para botones (default: Color(0xFF0A2D3E))
  final Color? primaryColor;

  /// Resolución de la cámara (default: CameraResolution.veryHigh)
  /// Solo permite high o veryHigh
  final CameraResolution cameraResolution;

  /// Constructor del componente reutilizable de cámara
  ///
  /// [title] es obligatorio y aparece como título principal
  /// [onImageSelected] es obligatorio - recibe el path de imagen procesada
  /// [currentImagePath] tiene prioridad sobre [currentImageUrl]
  /// [currentImageUrl] útil para formularios de edición con imágenes existentes
  /// [thumbnailUrl] mejora performance al mostrar preview de URLs
  /// [cameraResolution] permite configurar la resolución (solo high o veryHigh)
  const ReusableCameraCard({
    super.key,
    required this.title,
    this.currentImagePath,
    this.currentImageUrl,
    this.thumbnailUrl,
    required this.onImageSelected,
    this.subtitle,
    this.showGalleryOption = true,
    this.cameraButtonText = 'Tomar foto',
    this.galleryButtonText = 'De galería',
    this.primaryColor,
    this.cameraResolution = CameraResolution.high,
  });

  /// Determina si hay una imagen para mostrar
  bool get hasImage => currentImagePath != null || currentImageUrl != null;

  /// Determina si la imagen actual es local (nueva)
  bool get isLocalImage => currentImagePath != null;

  /// Obtiene la URL efectiva para mostrar (thumbnail o URL completa)
  String? get effectiveImageUrl => thumbnailUrl ?? currentImageUrl;

  @override
  Widget build(BuildContext context) {
    // Color efectivo con fallback al color por defecto
    final effectivePrimaryColor = primaryColor ?? const Color(0xFF0A2D3E);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(title, style: Theme.of(context).textTheme.titleLarge),

            // Subtítulo opcional
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],

            const SizedBox(height: 16),

            // Preview de la imagen
            _buildImagePreview(context),

            const SizedBox(height: 16),

            // Botones de acción
            _buildActionButtons(context, effectivePrimaryColor),

            // Información
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'La foto será marcada automáticamente con logo y timestamp',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el preview de la imagen
  /// Soporte para imágenes locales y URLs
  Widget _buildImagePreview(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: !hasImage ? Colors.grey[100] : null,
      ),
      child: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  // Imagen principal (local o URL)
                  isLocalImage ? _buildLocalImage() : _buildNetworkImage(),

                  // Badge de estado
                  Positioned(top: 8, right: 8, child: _buildImageBadge()),

                  // Botón para ver imagen completa
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: FloatingActionButton.small(
                      onPressed: () => _showFullImage(context),
                      backgroundColor: Colors.black54,
                      child: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Toma una foto o selecciona de galería',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  /// Widget para imagen local
  Widget _buildLocalImage() {
    return Image.file(
      File(currentImagePath!),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.red.shade50,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(height: 8),
                Text('Error al cargar imagen'),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Widget para imagen desde URL
  Widget _buildNetworkImage() {
    return Image.network(
      effectiveImageUrl!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.red.shade50,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(height: 8),
                Text('Error al cargar imagen'),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construye el badge según el tipo de imagen
  Widget _buildImageBadge() {
    if (isLocalImage) {
      // Nueva imagen local procesada
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Procesada',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      // Imagen existente desde URL
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_done, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Existente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Construye los botones de acción según la configuración
  Widget _buildActionButtons(BuildContext context, Color primaryColor) {
    // Texto dinámico del botón principal
    final String mainButtonText = hasImage ? 'Cambiar foto' : cameraButtonText;

    if (!showGalleryOption) {
      // Solo botón de cámara
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _openCameraModal(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.camera_alt),
          label: Text(mainButtonText),
        ),
      );
    }

    // Dos botones: cámara y galería
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openCameraModal(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.camera_alt),
            label: Text(cameraButtonText),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _pickFromGallery(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.photo_library),
            label: Text(galleryButtonText),
          ),
        ),
      ],
    );
  }

  /// Abre el modal de cámara para tomar foto
  void _openCameraModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CameraModal(
        title: title,
        cameraResolution: cameraResolution,
        onImageCaptured: onImageSelected,
      ),
    );
  }

  /// Permite seleccionar imagen de la galería
  /// Procesa automáticamente la imagen seleccionada
  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null && context.mounted) {
        // Preguntar si quiere marcar la imagen
        final bool? quiereMarcar = await _preguntarSiMarcar(context);

        if (quiereMarcar != null) {
          // Mostrar diálogo de procesamiento
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      quiereMarcar
                          ? 'Marcando imagen...'
                          : 'Comprimiendo imagen...',
                    ),
                  ],
                ),
              ),
            );
          }

          String processedPath;
          if (quiereMarcar) {
            // Usar preset de galería con marcas
            processedPath = await processImageWithWatermark(
              image.path,
              config: WatermarkPresets.gallery,
              autoGPS: false,
            );
          } else {
            // Usar preset sin marcas (solo compresión)
            processedPath = await processImageWithWatermark(
              image.path,
              config: WatermarkPresets.none,
              autoGPS: false,
            );
          }

          // Cerrar diálogo
          if (context.mounted) {
            Navigator.of(context).pop();
            onImageSelected(processedPath);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        AppSnackBar.error(context, 'Error al seleccionar imagen: $e');
      }
    }
  }

  Future<bool?> _preguntarSiMarcar(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar imagen'),
        content: const Text('¿Deseas agregar logo y timestamp?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, solo comprimir'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, marcar'),
          ),
        ],
      ),
    );
  }

  /// Muestra la imagen en pantalla completa con zoom
  /// Soporte para imágenes locales y URLs
  void _showFullImage(BuildContext context) {
    if (!hasImage) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: isLocalImage
                    ? Image.file(File(currentImagePath!), fit: BoxFit.contain)
                    : Image.network(
                        currentImageUrl!, // Usar URL completa para fullscreen
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📷 MODAL DE CÁMARA REUTILIZABLE (Actualizado con resolución configurable)
///
/// Modal que maneja la captura de fotos con preview y confirmación.
/// Procesa automáticamente las imágenes tomadas.
/// Ahora soporta resolución configurable.

// Modal de cámara reutilizable
class _CameraModal extends StatefulWidget {
  final String title;
  final CameraResolution cameraResolution;
  final Function(String) onImageCaptured;

  const _CameraModal({
    required this.title,
    required this.cameraResolution,
    required this.onImageCaptured,
  });

  @override
  State<_CameraModal> createState() => _CameraModalState();
}

class _CameraModalState extends State<_CameraModal> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _initError; // Error durante inicialización
  String? _originalImagePath;  // Imagen original (para preview inmediato)
  String? _processedImagePath; // Imagen procesada (para confirmar)

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // Timeout de 10 segundos para evitar loading infinito
      final cameras = await availableCameras().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout al obtener cámaras'),
      );

      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _initError = 'No se encontraron cámaras disponibles');
        }
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        widget.cameraResolution.toResolutionPreset,
        imageFormatGroup: ImageFormatGroup.jpeg,
        enableAudio: false,
      );

      await _cameraController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout al inicializar cámara'),
      );

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
      if (mounted) {
        setState(() => _initError = 'Error al inicializar cámara: $e');
      }
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController?.value.isInitialized != true) return;

    try {
      // Tomar foto
      final image = await _cameraController!.takePicture();

      // Mostrar imagen ORIGINAL inmediatamente (sin esperar procesamiento)
      if (mounted) {
        setState(() {
          _originalImagePath = image.path;
          _isProcessing = true; // Indica que está procesando en background
        });
      }

      // Procesar en background (no bloquea la UI)
      final processedPath = await processImageWithWatermark(
        image.path,
        config: WatermarkPresets.withGps,
        autoGPS: false,
      );

      // Actualizar con imagen procesada
      if (mounted) {
        setState(() {
          _processedImagePath = processedPath;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppSnackBar.error(context, 'Error: $e');
      }
    }
  }

  void _confirmImage() {
    // Solo confirmar si ya tenemos la imagen procesada
    if (_processedImagePath != null) {
      widget.onImageCaptured(_processedImagePath!);
      Navigator.of(context).pop();
    }
  }

  void _retakePhoto() {
    setState(() {
      _originalImagePath = null;
      _processedImagePath = null;
      _isProcessing = false;
    });
  }

  // Verifica si hay una imagen para mostrar (original o procesada)
  bool get _hasImage => _originalImagePath != null;

  // Obtiene la mejor imagen disponible (procesada si existe, sino original)
  String? get _displayImagePath => _processedImagePath ?? _originalImagePath;

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Camera Preview o Image Preview
          Expanded(
            child: _hasImage
                ? _buildImagePreview()
                : _buildCameraPreview(),
          ),

          // Controles
          Container(
            padding: const EdgeInsets.all(20),
            child: _hasImage
                ? _buildImageControls()
                : _buildCameraControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    // Mostrar error si falló la inicialización
    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Error de cámara',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _initError!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _initError = null;
                    _isInitialized = false;
                  });
                  _initCamera();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Iniciando cámara...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        CameraPreview(_cameraController!),
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Procesando imagen...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Stack(
        children: [
          // Imagen (original o procesada)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(_displayImagePath!),
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Indicador de procesamiento (si todavía está procesando)
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'Procesando...',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Badge de estado
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isProcessing ? Colors.orange : Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isProcessing ? Icons.hourglass_empty : Icons.check_circle,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isProcessing ? 'Procesando' : 'Lista',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FloatingActionButton(
          onPressed: _isInitialized && !_isProcessing ? _takePicture : null,
          backgroundColor: Colors.white,
          child: _isProcessing
              ? const CircularProgressIndicator(color: Colors.black)
              : const Icon(Icons.camera_alt, color: Colors.black, size: 32),
        ),
      ],
    );
  }

  Widget _buildImageControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _retakePhoto,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.refresh),
          label: const Text('Repetir'),
        ),
        ElevatedButton.icon(
          // Solo habilitar cuando termine de procesar
          onPressed: _isProcessing ? null : _confirmImage,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isProcessing ? Colors.grey : Colors.green,
            foregroundColor: Colors.white,
          ),
          icon: _isProcessing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.check),
          label: Text(_isProcessing ? 'Espere...' : 'Confirmar'),
        ),
      ],
    );
  }
}
