// =====================================================
// widgets/pedeteo/search_bar_widget.dart - ACTUALIZACIÓN NECESARIA
// =====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';
import 'package:stampcamera/widgets/pedeteo/search_dropdown_widget.dart';
import 'package:stampcamera/widgets/common/search_bar_widget.dart';

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
    if (!_searchFocusNode.hasFocus) {
      // Delay para permitir tap en dropdown antes de ocultar
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_searchFocusNode.hasFocus) {
          _hideDropdown();
        }
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    ref.read(pedeteoStateProvider.notifier).updateSearchQuery(query);

    setState(() {
      if (query.isNotEmpty && query.length < 17 && _searchFocusNode.hasFocus) {
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
    _searchFocusNode.unfocus();

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
      builder: (context) => GestureDetector(
        onTap: _hideDropdown,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Área transparente para cerrar dropdown
            Positioned.fill(child: Container()),
            // Dropdown real
            PedeteoSearchDropdown(
              layerLink: _layerLink,
              onSelectVin: _selectVin,
              onHide: _hideDropdown,
            ),
          ],
        ),
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

    return CompositedTransformTarget(
      link: _layerLink,
      child: SearchBarWidget(
        controller: _searchController,
        focusNode: _searchFocusNode,
        hintText: 'Buscar por VIN o Serie...',
        backgroundColor: Colors.grey[100],
        fillColor: Colors.white,
        onChanged: (value) {
          // La lógica ya está en _onSearchChanged que se ejecuta automáticamente
        },
        onClear: _resetForm,
        onScannerPressed: _toggleScanner,
        scannerIcon: state.showScanner ? Icons.close : Icons.qr_code_scanner,
        scannerTooltip: state.showScanner
            ? 'Cerrar scanner'
            : 'Escanear código',
        scannerButtonColor: state.showScanner ? Colors.red : null,
      ),
    );
  }
}
