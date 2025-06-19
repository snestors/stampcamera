import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class NetworkImagePreview extends StatelessWidget {
  final String thumbnailUrl;
  final String fullImageUrl;
  final double size;

  const NetworkImagePreview({
    super.key,
    required this.thumbnailUrl,
    required this.fullImageUrl,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _FullscreenImage(fullImageUrl: fullImageUrl),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          thumbnailUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _FullscreenImage extends StatefulWidget {
  final String fullImageUrl;

  const _FullscreenImage({required this.fullImageUrl});

  @override
  State<_FullscreenImage> createState() => _FullscreenImageState();
}

class _FullscreenImageState extends State<_FullscreenImage> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _tapDownDetails;

  Future<void> shareImageFromUrl(String imageUrl) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final response = await Dio().get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final file = File(filePath);
      await file.writeAsBytes(response.data!);

      await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
    } catch (e) {
      debugPrint('❌ Error al compartir imagen: $e');
    }
  }

  void _handleDoubleTap() {
    if (_controller.value != Matrix4.identity()) {
      _controller.value = Matrix4.identity();
    } else if (_tapDownDetails != null) {
      final position = _tapDownDetails!.localPosition;
      _controller.value = Matrix4.identity()
        ..translate(-position.dx * 2, -position.dy * 2)
        ..scale(3.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              shareImageFromUrl(widget.fullImageUrl);
            },
          ),
        ],
      ),
      body: GestureDetector(
        onDoubleTapDown: (details) => _tapDownDetails = details,
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _controller,
          panEnabled: true,
          scaleEnabled: true,
          minScale: 1.0,
          maxScale: 4.0,
          child: Center(
            child: Image.network(widget.fullImageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
