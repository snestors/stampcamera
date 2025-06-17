import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class GallerySelectorScreen extends StatefulWidget {
  final List<File> images;
  const GallerySelectorScreen({super.key, required this.images});

  @override
  State<GallerySelectorScreen> createState() => _GallerySelectorScreenState();
}

class _GallerySelectorScreenState extends State<GallerySelectorScreen> {
  final List<File> selected = [];

  void _toggleSelection(File image) {
    setState(() {
      if (selected.contains(image)) {
        selected.remove(image);
      } else if (selected.length < 15) {
        selected.add(image);
      }
    });
  }

  Future<void> _shareSelected() async {
    if (selected.isEmpty) return;

    final result = await SharePlus.instance.share(
      ShareParams(files: selected.map((f) => XFile(f.path)).toList()),
    );

    if (result.status == ShareResultStatus.success) {
      debugPrint('Compartido');
    }
    if (!mounted) return;
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selecciona hasta 15'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: selected.isEmpty ? null : _shareSelected,
          )
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: widget.images.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          final image = widget.images[index];
          final isSelected = selected.contains(image);
          return GestureDetector(
            onTap: () => _toggleSelection(image),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.file(image, fit: BoxFit.cover),
                ),
                if (isSelected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(Icons.check_circle, color: Colors.lightBlueAccent),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
