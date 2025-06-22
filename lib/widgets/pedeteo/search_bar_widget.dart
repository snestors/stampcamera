// widgets/pedeteo/search_bar_widget.dart (limpio)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';
import 'package:stampcamera/widgets/pedeteo/search_dropdown_widget.dart';

class PedeteoSearchBar extends ConsumerStatefulWidget {
  const PedeteoSearchBar({super.key});

  @override
  ConsumerState<PedeteoSearchBar> createState() => _PedeteoSearchBarState();
}

class _PedeteoSearchBarState extends ConsumerState<PedeteoSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  final FocusNode _searchFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!_searchFocusNode.hasFocus) _hideDropdown();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    ref.read(pedeteoStateProvider.notifier).updateSearchQuery(query);

    setState(() {
      if (query.isNotEmpty && query.length < 17) {
        _showSearchDropdown();
      } else {
        _hideDropdown();
      }
    });
  }

  void _selectVin(RegistroGeneral vin) {
    ref.read(pedeteoStateProvider.notifier).selectVin(vin);
    _searchController.text = vin.vin;
    _hideDropdown();

    final optionsAsync = ref.read(pedeteoOptionsProvider);
    if (optionsAsync.hasValue) {
      ref
          .read(pedeteoStateProvider.notifier)
          .initializeFormWithDefaults(optionsAsync.value!.initialValues);
    }
  }

  void _toggleScanner() {
    ref.read(pedeteoStateProvider.notifier).toggleScanner();
    _hideDropdown();
    _searchFocusNode.unfocus();
  }

  void _showSearchDropdown() {
    _hideDropdown();
    _overlayEntry = OverlayEntry(
      builder: (context) => PedeteoSearchDropdown(
        layerLink: _layerLink,
        onSelectVin: _selectVin,
        onHide: _hideDropdown,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _resetForm() {
    ref.read(pedeteoStateProvider.notifier).resetForm();
    _searchController.clear();
    _hideDropdown();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _hideDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pedeteoStateProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Buscar por VIN o Serie...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: _resetForm,
                    icon: const Icon(Icons.clear),
                  ),
                IconButton(
                  onPressed: _toggleScanner,
                  icon: Icon(
                    state.showScanner ? Icons.close : Icons.qr_code_scanner,
                    color: state.showScanner ? Colors.blue : null,
                  ),
                ),
              ],
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
