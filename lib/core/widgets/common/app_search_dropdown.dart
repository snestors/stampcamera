// ============================================================================
// 🔍 APP SEARCH DROPDOWN - DROPDOWN ELEGANTE CON BÚSQUEDA LOCAL
// Similar al diseño de graneles pero para búsqueda local de opciones
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

class AppSearchDropdownOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;

  const AppSearchDropdownOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
  });
}

class AppSearchDropdown<T> extends StatefulWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<AppSearchDropdownOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final Widget? prefixIcon;
  final bool isRequired;

  const AppSearchDropdown({
    super.key,
    required this.label,
    required this.options,
    this.hint,
    this.value,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.isRequired = false,
  });

  @override
  State<AppSearchDropdown<T>> createState() => _AppSearchDropdownState<T>();
}

class _AppSearchDropdownState<T> extends State<AppSearchDropdown<T>> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _fieldKey = GlobalKey();
  bool _isExpanded = false;
  List<AppSearchDropdownOption<T>> _filteredOptions = [];
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _focusNode.addListener(_onFocusChange);
    _updateControllerText();
  }

  void _updateControllerText() {
    final selected = widget.options
        .where((opt) => opt.value == widget.value)
        .firstOrNull;
    if (selected != null) {
      _controller.text = selected.label;
    }
  }

  void _onFocusChange() {
    if (!mounted) return;

    if (_focusNode.hasFocus) {
      setState(() {
        _isExpanded = true;
        _filteredOptions = widget.options;
        // Seleccionar todo el texto para facilitar la búsqueda
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      });

      // Desplazar el campo hacia arriba para que quede visible sobre el teclado
      _scrollToField();
    } else {
      // Pequeño delay para permitir selección antes de cerrar
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() {
            _isExpanded = false;
            _updateControllerText();
          });
        }
      });
    }
  }

  /// Desplaza el scroll para que el campo quede visible sobre el teclado
  void _scrollToField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _fieldKey.currentContext == null) return;

      // Esperar un poco para que el teclado termine de aparecer
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || _fieldKey.currentContext == null) return;

        Scrollable.ensureVisible(
          _fieldKey.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.2, // Posicionar el campo en el 20% superior de la pantalla visible
        );
      });
    });
  }

  @override
  void didUpdateWidget(AppSearchDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _updateControllerText();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _filterOptions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions = widget.options.where((option) {
          return option.label.toLowerCase().contains(query.toLowerCase()) ||
              (option.subtitle?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  void _selectOption(AppSearchDropdownOption<T> option) {
    _controller.text = option.label;
    widget.onChanged?.call(option.value);
    _focusNode.unfocus();
    setState(() {
      _isExpanded = false;
      _errorText = null;
    });
  }

  void _clearSelection() {
    _controller.clear();
    widget.onChanged?.call(null);
    setState(() {
      _filteredOptions = widget.options;
    });
  }

  String? _validate() {
    if (widget.validator != null) {
      return widget.validator!(widget.value);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null;
    final isSelected = hasValue && !_isExpanded;

    return FormField<T>(
      validator: (_) => _validate(),
      builder: (formState) {
        _errorText = formState.errorText;

        return Column(
          key: _fieldKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Input Field - Mismo estilo que los demás DropdownButtonFormField
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              onChanged: _filterOptions,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: widget.isRequired ? '${widget.label} *' : widget.label,
                hintText: widget.hint,
                hintStyle: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: AppColors.textSecondary,
                ),
                prefixIcon: widget.prefixIcon,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: _clearSelection,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    Padding(
                      padding: EdgeInsets.only(right: DesignTokens.spaceS),
                      child: Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                        size: DesignTokens.iconM,
                      ),
                    ),
                  ],
                ),
                // Mismo estilo de bordes que DropdownButtonFormField
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
                filled: true,
                fillColor: AppColors.surface,
                // Mostrar error del FormField
                errorText: _errorText,
                errorStyle: TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
                  color: AppColors.error,
                ),
              ),
            ),

            // Dropdown Results
            if (_isExpanded && _filteredOptions.isNotEmpty)
              Container(
                margin: EdgeInsets.only(top: DesignTokens.spaceXS),
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  border: Border.all(color: AppColors.neutral),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceXS),
                  itemCount: _filteredOptions.length,
                  itemBuilder: (context, index) {
                    final option = _filteredOptions[index];
                    final isItemSelected = option.value == widget.value;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectOption(option),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: DesignTokens.spaceM,
                            vertical: DesignTokens.spaceS,
                          ),
                          decoration: BoxDecoration(
                            color: isItemSelected
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : null,
                          ),
                          child: Row(
                            children: [
                              if (option.leading != null) ...[
                                option.leading!,
                                SizedBox(width: DesignTokens.spaceS),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.label,
                                      style: TextStyle(
                                        fontSize: DesignTokens.fontSizeS,
                                        fontWeight: isItemSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isItemSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (option.subtitle != null)
                                      Text(
                                        option.subtitle!,
                                        style: TextStyle(
                                          fontSize: DesignTokens.fontSizeXS,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isItemSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // No results message
            if (_isExpanded && _filteredOptions.isEmpty)
              Container(
                margin: EdgeInsets.only(top: DesignTokens.spaceXS),
                padding: EdgeInsets.all(DesignTokens.spaceM),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  border: Border.all(color: AppColors.neutral),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: DesignTokens.spaceS),
                    Text(
                      'No se encontraron resultados',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
