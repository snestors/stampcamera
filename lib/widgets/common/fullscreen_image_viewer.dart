// =============================================================================
// VISOR DE IMAGEN A PANTALLA COMPLETA CON PINCH TO ZOOM, COMPARTIR Y DESCARGAR
// Reutilizable para todas las vistas (tickets, balanzas, almacen, contenedores)
// =============================================================================
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stampcamera/core/core.dart';

class FullscreenImageViewer extends StatefulWidget {
  /// URL de la imagen (para imagenes de red)
  final String? imageUrl;

  /// Path local de la imagen (para archivos locales)
  final String? localPath;

  final String? title;
  final String? heroTag;

  const FullscreenImageViewer({
    super.key,
    this.imageUrl,
    this.localPath,
    this.title,
    this.heroTag,
  }) : assert(imageUrl != null || localPath != null,
            'Debe proporcionar imageUrl o localPath');

  /// Metodo estatico para abrir el visor con imagen de red
  static void open(
    BuildContext context, {
    required String imageUrl,
    String? title,
    String? heroTag,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenImageViewer(
          imageUrl: imageUrl,
          title: title,
          heroTag: heroTag,
        ),
      ),
    );
  }

  /// Metodo estatico para abrir el visor con imagen local
  static void openLocal(
    BuildContext context, {
    required String localPath,
    String? title,
    String? heroTag,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenImageViewer(
          localPath: localPath,
          title: title,
          heroTag: heroTag,
        ),
      ),
    );
  }

  /// Determina si la imagen es local
  bool get isLocal => localPath != null;

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _transformationController.dispose();
    super.dispose();
  }

  /// Doble tap para zoom
  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else if (_doubleTapDetails != null) {
      final position = _doubleTapDetails!.localPosition;
      _transformationController.value = Matrix4.identity()
        ..setTranslationRaw(-position.dx * 2, -position.dy * 2, 0.0)
        ..multiply(Matrix4.diagonal3Values(3.0, 3.0, 1.0));
    }
  }

  /// Descargar imagen usando Dio
  Future<File?> _downloadImageToTemp() async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final response = await Dio().get<List<int>>(
        widget.imageUrl!,
        options: Options(responseType: ResponseType.bytes),
      );

      final file = File(filePath);
      await file.writeAsBytes(response.data!);
      return file;
    } catch (e) {
      debugPrint('Error descargando imagen: $e');
      return null;
    }
  }

  /// Compartir imagen
  Future<void> _shareImage() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      File? file;
      if (widget.isLocal) {
        file = File(widget.localPath!);
      } else {
        file = await _downloadImageToTemp();
      }

      if (file == null || !file.existsSync()) {
        _showError('No se pudo cargar la imagen');
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: widget.title,
        ),
      );
    } catch (e) {
      _showError('Error al compartir: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Guardar imagen
  Future<void> _downloadImage() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${dir.path}/$fileName';

      if (widget.isLocal) {
        // Copiar archivo local
        final sourceFile = File(widget.localPath!);
        await sourceFile.copy(filePath);
      } else {
        // Descargar de URL
        final response = await Dio().get<List<int>>(
          widget.imageUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        final file = File(filePath);
        await file.writeAsBytes(response.data!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Guardado: $fileName')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: widget.title != null
            ? Text(
                widget.title!,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              )
            : null,
        actions: [
          // Boton compartir
          IconButton(
            onPressed: _isLoading ? null : _shareImage,
            icon: const Icon(Icons.share),
            tooltip: 'Compartir',
          ),
          // Boton guardar
          IconButton(
            onPressed: _isLoading ? null : _downloadImage,
            icon: const Icon(Icons.download),
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen con zoom (doble tap + pinch)
          GestureDetector(
            onDoubleTapDown: (details) => _doubleTapDetails = details,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: widget.heroTag != null
                    ? Hero(tag: widget.heroTag!, child: _buildImage())
                    : _buildImage(),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (widget.isLocal) {
      return Image.file(
        File(widget.localPath!),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 64, color: Colors.white54),
            SizedBox(height: 16),
            Text('Error al cargar imagen', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl!,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 64, color: Colors.white54),
          SizedBox(height: 16),
          Text('Error al cargar imagen', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
