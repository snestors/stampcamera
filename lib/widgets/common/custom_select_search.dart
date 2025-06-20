import 'package:flutter/material.dart';
import 'package:stampcamera/utils/debouncer.dart'; // Ajusta según tu ruta real

class CustomSelectSearch<T> extends StatefulWidget {
  final Future<List<T>> Function(String query) onSearch;
  final String Function(T item) itemToString;
  final void Function(T item) onItemSelected;
  final String labelText;
  final Widget? suffixIcon;
  final int maxResults;

  const CustomSelectSearch({
    super.key,
    required this.onSearch,
    required this.itemToString,
    required this.onItemSelected,
    this.labelText = '',
    this.suffixIcon,
    this.maxResults = 5,
  });

  @override
  State<CustomSelectSearch<T>> createState() => _CustomSelectSearchState<T>();
}

class _CustomSelectSearchState<T> extends State<CustomSelectSearch<T>> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  late Debouncer _debouncer;
  OverlayEntry? _overlayEntry;

  List<T> _items = [];

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(delay: const Duration(milliseconds: 350));

    _controller.addListener(_onChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _removeOverlay();
    });
  }

  void _onChanged() {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length >= 17) {
      _removeOverlay();
      return;
    }

    _debouncer.run(() async {
      final items = await widget.onSearch(text);
      if (!mounted) return;

      setState(() {
        _items = items;
      });

      _removeOverlay();
      if (_items.isEmpty) return;

      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    });
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 64,
        left: 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 60),
          showWhenUnlinked: false,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: _items
                        .take(widget.maxResults)
                        .map(
                          (item) => ListTile(
                            title: Text(widget.itemToString(item)),
                            onTap: () {
                              _controller.text = widget.itemToString(item);
                              widget.onItemSelected(item);
                              _removeOverlay();
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.close),
                  title: const Text('Cerrar'),
                  onTap: _removeOverlay,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debouncer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.labelText,
          suffixIcon: widget.suffixIcon,
        ),
      ),
    );
  }
}
