// widgets/common/reusable_camera_card.dart
/**
 * 📸 COMPONENTE REUTILIZABLE DE CÁMARA
 * 
 * 🎯 PROPÓSITO:
 * Componente que permite tomar fotos con cámara o seleccionar de galería.
 * Procesa automáticamente las imágenes con logo y timestamp.
 * 
 * 📝 CARACTERÍSTICAS:
 * - ✅ Tomar foto con cámara
 * - ✅ Seleccionar imagen de galería  
 * - ✅ Vista previa con zoom
 * - ✅ Procesamiento automático (logo + timestamp)
 * - ✅ Títulos y colores personalizables
 * - ✅ Opción de ocultar galería
 * - ✅ Manejo de errores y estados de carga
 * 
 * 🚀 EJEMPLOS DE USO:
 * 
 * // Uso básico
 * String? photoPath;
 * ReusableCameraCard(
 *   title: 'Foto del VIN',
 *   currentImagePath: photoPath,
 *   onImageSelected: (path) => setState(() => photoPath = path),
 * )
 * 
 * // Con Provider/Riverpod
 * ReusableCameraCard(
 *   title: 'Foto del Vehículo',
 *   currentImagePath: ref.watch(vehicleProvider).photoPath,
 *   onImageSelected: (path) {
 *     ref.read(vehicleProvider.notifier).setPhoto(path);
 *   },
 * )
 * 
 * // Personalizado
 * ReusableCameraCard(
 *   title: 'Documento de Identidad',
 *   subtitle: 'Debe ser legible y completo',
 *   currentImagePath: documentPath,
 *   onImageSelected: (path) => saveDocument(path),
 *   showGalleryOption: false, // Solo cámara
 *   primaryColor: Colors.blue,
 *   cameraButtonText: 'Fotografiar documento',
 * )
 * 
 * // Múltiples imágenes
 * String? frontPhoto, backPhoto, interiorPhoto;
 * Column(
 *   children: [
 *     ReusableCameraCard(
 *       title: 'Vista Frontal',
 *       currentImagePath: frontPhoto,
 *       onImageSelected: (path) => setState(() => frontPhoto = path),
 *     ),
 *     ReusableCameraCard(
 *       title: 'Vista Trasera',
 *       currentImagePath: backPhoto,
 *       onImageSelected: (path) => setState(() => backPhoto = path),
 *     ),
 *   ],
 * )
 * 
 * 📋 PARÁMETROS:
 * - title: Título principal (obligatorio)
 * - currentImagePath: Path de imagen actual (null = sin imagen)
 * - onImageSelected: Callback cuando se selecciona imagen
 * - subtitle: Texto descriptivo opcional
 * - showGalleryOption: Mostrar botón de galería (default: true)
 * - cameraButtonText: Texto del botón de cámara
 * - galleryButtonText: Texto del botón de galería
 * - primaryColor: Color principal del tema
 * 
 * 🔄 FLUJO:
 * 1. Usuario ve preview (placeholder si currentImagePath = null)
 * 2. Toca botón cámara/galería
 * 3. Selecciona/toma imagen
 * 4. Se procesa automáticamente (logo + timestamp)
 * 5. Se ejecuta onImageSelected(processedPath)
 * 6. Padre actualiza currentImagePath
 * 7. Card muestra nueva imagen
 * 
 * 📦 DEPENDENCIAS REQUERIDAS:
 * - camera: ^0.10.0+4
 * - image_picker: ^1.0.4
 * 
 * 🎨 COMPORTAMIENTO VISUAL:
 * - Sin imagen: Placeholder con ícono
 * - Con imagen: Preview + badge "Procesada" + botón zoom
 * - Estados de carga durante procesamiento
 * - Botones adaptativos según configuración
 */

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:stampcamera/utils/image_processor.dart';

class ReusableCameraCard extends StatelessWidget {
  /// Título principal de la card
  final String title;

  /// Path de la imagen actual (null si no hay imagen seleccionada)
  final String? currentImagePath;

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

  /// Constructor del componente reutilizable de cámara
  ///
  /// [title] es obligatorio y aparece como título principal
  /// [onImageSelected] es obligatorio - recibe el path de imagen procesada
  /// [currentImagePath] debe ser manejado por el widget padre
  /// [showGalleryOption] controla si mostrar el botón de galería
  const ReusableCameraCard({
    super.key,
    required this.title,
    this.currentImagePath,
    required this.onImageSelected,
    this.subtitle,
    this.showGalleryOption = true,
    this.cameraButtonText = 'Tomar foto',
    this.galleryButtonText = 'Elegir de galería',
    this.primaryColor,
  });

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
  /// Muestra placeholder si no hay imagen, o la imagen con controles si existe
  Widget _buildImagePreview(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: currentImagePath == null ? Colors.grey[100] : null,
      ),
      child: currentImagePath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  // Imagen principal
                  Image.file(
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
                  ),
                  // Badge de procesada
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
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
                    ),
                  ),
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

  /// Construye los botones de acción según la configuración
  /// - Si showGalleryOption = false: solo botón de cámara
  /// - Si showGalleryOption = true: botón cámara + botón galería
  Widget _buildActionButtons(BuildContext context, Color primaryColor) {
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
          label: Text(
            currentImagePath != null ? 'Cambiar foto' : cameraButtonText,
          ),
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
      builder: (context) =>
          _CameraModal(title: title, onImageCaptured: onImageSelected),
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
            // Configuración con marcas (sin GPS)
            final config = WatermarkConfig(
              showLogo: true,
              showTimestamp: true,
              showLocation: false,
              logoPosition: WatermarkPosition.topRight,
              timestampPosition: WatermarkPosition.bottomRight,
              compressionQuality: 95,
              timestampFontSize: FontSize.large,
            );

            processedPath = await processImageWithWatermark(
              image.path,
              config: config,
              autoGPS: false,
            );
          } else {
            // Solo compresión
            final config = WatermarkConfig(
              showLogo: false,
              showTimestamp: false,
              showLocation: false,
              compressionQuality: 95,
            );

            processedPath = await processImageWithWatermark(
              image.path,
              config: config,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
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
  void _showFullImage(BuildContext context) {
    if (currentImagePath == null) return;

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
                child: Image.file(File(currentImagePath!), fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/**
 * 📷 MODAL DE CÁMARA REUTILIZABLE
 * 
 * Modal que maneja la captura de fotos con preview y confirmación.
 * Procesa automáticamente las imágenes tomadas.
 * 
 * 🔄 FLUJO:
 * 1. Inicializa cámara
 * 2. Muestra preview de cámara
 * 3. Usuario toma foto
 * 4. Procesa imagen (logo + timestamp)
 * 5. Muestra preview de resultado
 * 6. Usuario confirma o repite
 * 7. Retorna path de imagen procesada
 */

// Modal de cámara reutilizable
class _CameraModal extends StatefulWidget {
  final String title;
  final Function(String) onImageCaptured;

  const _CameraModal({required this.title, required this.onImageCaptured});

  @override
  State<_CameraModal> createState() => _CameraModalState();
}

class _CameraModalState extends State<_CameraModal> {
  CameraController? _cameraController;
  bool _isInitialized = false; // Estado de inicialización de cámara
  bool _isProcessing = false; // Estado de procesamiento de imagen
  String? _capturedImagePath; // Path de imagen capturada y procesada

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  /// Inicializa la cámara al abrir el modal
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      }
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
    }
  }

  /// Toma la foto y la procesa automáticamente
  /// Utiliza el return directo de processAndSaveImage para mayor eficiencia
  Future<void> _takePicture() async {
    if (_cameraController?.value.isInitialized != true) return;

    try {
      setState(() => _isProcessing = true);

      // 1. Capturar imagen
      final image = await _cameraController!.takePicture();

      final config = WatermarkConfig(
        showLogo: true,
        showTimestamp: true,
        showLocation: true,
        logoPosition: WatermarkPosition.topRight,
        timestampPosition: WatermarkPosition.bottomRight,
        locationPosition: WatermarkPosition.bottomLeft, // GPS abajo izquierda
        compressionQuality: 95,
        timestampFontSize: FontSize.large,
      );

      final processedImagePath = await processImageWithWatermark(
        image.path,
        config: config,
        autoGPS: false,
      );

      // 3. Actualizar estado con imagen procesada
      if (mounted) {
        setState(() {
          _capturedImagePath = processedImagePath;
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Confirma la imagen y cierra el modal
  void _confirmImage() {
    if (_capturedImagePath != null) {
      widget.onImageCaptured(_capturedImagePath!);
      Navigator.of(context).pop();
    }
  }

  /// Permite tomar otra foto (descarta la actual)
  void _retakePhoto() {
    setState(() {
      _capturedImagePath = null;
      _isProcessing = false;
    });
  }

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
            child: _capturedImagePath != null
                ? _buildImagePreview()
                : _buildCameraPreview(),
          ),

          // Controles
          Container(
            padding: const EdgeInsets.all(20),
            child: _capturedImagePath != null
                ? _buildImageControls()
                : _buildCameraControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(File(_capturedImagePath!), fit: BoxFit.contain),
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
          onPressed: _retakePhoto,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.refresh),
          label: const Text('Repetir'),
        ),
        ElevatedButton.icon(
          onPressed: _confirmImage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.check),
          label: const Text('Confirmar'),
        ),
      ],
    );
  }
}
