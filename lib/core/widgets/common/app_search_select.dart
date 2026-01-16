// ============================================================================
// 🔍 APP SEARCH SELECT - DROPDOWN CON BÚSQUEDA
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

class AppSearchSelectOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;

  const AppSearchSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
  });
}

class AppSearchSelect<T> extends StatefulWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<AppSearchSelectOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final Widget? prefixIcon;
  final String? helperText;
  final String? errorText;
  final bool isRequired;
  final String searchHint;

  const AppSearchSelect({
    super.key,
    required this.label,
    required this.options,
    this.hint,
    this.value,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.searchHint = 'Buscar...',
  });

  @override
  State<AppSearchSelect<T>> createState() => _AppSearchSelectState<T>();
}

class _AppSearchSelectState<T> extends State<AppSearchSelect<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  List<AppSearchSelectOption<T>> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _focusNode.addListener(_onFocusChange);

    // Mostrar el valor seleccionado en el input
    final selectedOption = widget.options
        .where((option) => option.value == widget.value)
        .firstOrNull;
    if (selectedOption != null) {
      _searchController.text = selectedOption.label;
    }
  }

  void _onFocusChange() {
    if (!mounted) return;

    if (_focusNode.hasFocus && !_isOpen) {
      _showOverlay();
    } else if (!_focusNode.hasFocus && _isOpen) {
      _removeOverlay();
    }
  }

  @override
  void didUpdateWidget(AppSearchSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Actualizar el texto del controller cuando cambie el valor seleccionado
    if (widget.value != oldWidget.value) {
      final selectedOption = widget.options
          .where((option) => option.value == widget.value)
          .firstOrNull;
      if (selectedOption != null) {
        _searchController.text = selectedOption.label;
      } else {
        _searchController.clear();
      }
    }
  }

  @override
  void dispose() {
    // Limpiar overlay inmediatamente para evitar referencias a widget destruido
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }

    _searchController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spaceXS),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (widget.isRequired)
                  Text(
                    ' *',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),

        // Search Select Field
        CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            enabled: widget.enabled,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hint ?? 'Buscar...',
              hintStyle: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: widget.enabled
                    ? AppColors.textSecondary
                    : AppColors.textLight,
                size: DesignTokens.iconM,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                borderSide: BorderSide(
                  color: AppColors.neutral,
                  width: DesignTokens.borderWidthNormal,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: DesignTokens.borderWidthNormal,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: DesignTokens.borderWidthNormal,
                ),
              ),
              fillColor: widget.enabled
                  ? AppColors.surface
                  : AppColors.backgroundLight,
              filled: true,
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // Helper/Error Text
        if (widget.helperText != null || widget.errorText != null)
          Padding(
            padding: EdgeInsets.only(top: DesignTokens.spaceXS),
            child: Text(
              widget.errorText ?? widget.helperText!,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: widget.errorText != null
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  void _onSearchChanged(String query) {
    if (!mounted) return;

    _filterOptions(query);

    if (!_isOpen) {
      _showOverlay();
    } else {
      // Reconstruir overlay para ajustar posición con teclado
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _showOverlay() {
    if (!mounted || _isOpen) return;

    // No limpiar el controller aquí, mantener el texto actual
    _filteredOptions = widget.options;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);

    if (mounted) {
      setState(() {
        _isOpen = true;
      });
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) {
        // Obtener altura del teclado
        final mediaQuery = MediaQuery.of(context);
        final keyboardHeight = mediaQuery.viewInsets.bottom;
        final screenHeight = mediaQuery.size.height;

        // Calcular posición del dropdown considerando el teclado
        final dropdownTop = position.dy + size.height + 8;
        final dropdownMaxHeight =
            screenHeight - dropdownTop - keyboardHeight - 20;
        final shouldShowAbove = dropdownMaxHeight < 150 && position.dy > 200;

        final dropdownHeight = (dropdownMaxHeight > 150)
            ? 300.0
            : dropdownMaxHeight.clamp(150.0, 300.0);
        final finalOffset = shouldShowAbove
            ? Offset(0, -dropdownHeight - 8)
            : Offset(0, size.height + 8);

        return GestureDetector(
          onTap: () => _removeOverlay(), // Cerrar al tocar fuera
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // Área completa para detectar taps fuera
              Positioned.fill(child: Container(color: Colors.transparent)),
              // El dropdown real
              Positioned(
                width: size.width,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: finalOffset,
                  child: GestureDetector(
                    onTap:
                        () {}, // Prevenir que se cierre cuando se toca el dropdown
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      child: Container(
                        constraints: BoxConstraints(maxHeight: dropdownHeight),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusM,
                          ),
                          border: Border.all(
                            color: AppColors.neutral,
                            width: DesignTokens.borderWidthNormal,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Options List (sin search field interno)
                            Flexible(
                              child: _filteredOptions.isEmpty
                                  ? Padding(
                                      padding: EdgeInsets.all(
                                        DesignTokens.spaceL,
                                      ),
                                      child: Text(
                                        'No se encontraron resultados',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: DesignTokens.fontSizeS,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _filteredOptions.length,
                                      itemBuilder: (context, index) {
                                        final option = _filteredOptions[index];
                                        final isSelected =
                                            option.value == widget.value;

                                        return InkWell(
                                          onTap: () => _selectOption(option),
                                          child: Container(
                                            padding: EdgeInsets.all(
                                              DesignTokens.spaceM,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.primary
                                                        .withValues(alpha: 0.1)
                                                  : null,
                                            ),
                                            child: Row(
                                              children: [
                                                if (option.leading != null) ...[
                                                  option.leading!,
                                                  SizedBox(
                                                    width: DesignTokens.spaceS,
                                                  ),
                                                ],
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        option.label,
                                                        style: TextStyle(
                                                          fontSize: DesignTokens
                                                              .fontSizeS,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w600
                                                              : FontWeight.w500,
                                                          color: isSelected
                                                              ? AppColors
                                                                    .primary
                                                              : AppColors
                                                                    .textPrimary,
                                                        ),
                                                      ),
                                                      if (option.subtitle !=
                                                          null)
                                                        Text(
                                                          option.subtitle!,
                                                          style: TextStyle(
                                                            fontSize:
                                                                DesignTokens
                                                                    .fontSizeXS,
                                                            color: AppColors
                                                                .textSecondary,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                if (isSelected)
                                                  Icon(
                                                    Icons.check,
                                                    color: AppColors.primary,
                                                    size: DesignTokens.iconM,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _filterOptions(String query) {
    if (!mounted) return;

    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions = widget.options.where((option) {
          final searchText = query.toLowerCase();
          return option.label.toLowerCase().contains(searchText) ||
              (option.subtitle?.toLowerCase().contains(searchText) ?? false);
        }).toList();
      }
    });

    // Rebuild overlay with filtered options
    if (mounted && _overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _selectOption(AppSearchSelectOption<T> option) {
    if (!mounted) return;

    _searchController.text = option.label;
    widget.onChanged?.call(option.value);
    _removeOverlay();
    // Quitar focus para evitar que se reabra inmediatamente
    if (mounted) {
      _focusNode.unfocus();
    }
  }
}
