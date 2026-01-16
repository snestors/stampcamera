// ============================================================================
// 📂 lib/widgets/common/search_bar_widget.dart - WIDGET REUTILIZABLE
// ============================================================================
import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onScannerPressed;
  final VoidCallback? onSecondaryAction;
  final Widget? customSuffixWidget;
  final bool showClearButton;
  final bool showScannerButton;
  final IconData scannerIcon;
  final IconData? secondaryActionIcon;
  final String? scannerTooltip;
  final String? secondaryActionTooltip;
  final Color? scannerButtonColor;
  final Color? backgroundColor;
  final Color? fillColor;
  final bool hasDropdown;
  final Widget? child; // Para CompositedTransformTarget cuando se necesite

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onScannerPressed,
    this.onSecondaryAction,
    this.customSuffixWidget,
    this.showClearButton = true,
    this.showScannerButton = true,
    this.scannerIcon = Icons.qr_code_scanner,
    this.secondaryActionIcon,
    this.scannerTooltip = 'Escanear código',
    this.secondaryActionTooltip,
    this.scannerButtonColor,
    this.backgroundColor,
    this.fillColor,
    this.hasDropdown = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actualBackgroundColor =
        backgroundColor ?? theme.scaffoldBackgroundColor;
    final actualFillColor = fillColor ?? Colors.grey[100];
    final actualScannerColor = scannerButtonColor ?? theme.primaryColor;

    Widget searchField = TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: _buildSuffixActions(context, actualScannerColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: actualFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );

    // Si necesita dropdown, envolver en CompositedTransformTarget
    if (hasDropdown && child != null) {
      searchField = CompositedTransformTarget(
        link: LayerLink(),
        child: searchField,
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: actualBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: searchField),
              if (showScannerButton) ...[
                const SizedBox(width: 8),
                _buildScannerButton(context, actualScannerColor),
              ],
              if (secondaryActionIcon != null) ...[
                const SizedBox(width: 8),
                _buildSecondaryActionButton(context),
              ],
            ],
          ),
          // Widget hijo personalizado (ej: dropdown)
          if (child != null) child!,
        ],
      ),
    );
  }

  Widget? _buildSuffixActions(BuildContext context, Color scannerColor) {
    if (customSuffixWidget != null) {
      return customSuffixWidget;
    }

    final actions = <Widget>[];

    // Botón clear
    if (showClearButton && controller.text.isNotEmpty) {
      actions.add(
        IconButton(
          onPressed: () {
            controller.clear();
            onClear?.call();
          },
          icon: const Icon(Icons.clear),
          color: Colors.grey[600],
          tooltip: 'Limpiar',
        ),
      );
    }

    if (actions.isEmpty) return null;

    return actions.length == 1
        ? actions.first
        : Row(mainAxisSize: MainAxisSize.min, children: actions);
  }

  Widget _buildScannerButton(BuildContext context, Color color) {
    return IconButton(
      onPressed: onScannerPressed,
      icon: Icon(scannerIcon),
      style: IconButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltip: scannerTooltip,
    );
  }

  Widget _buildSecondaryActionButton(BuildContext context) {
    return IconButton(
      onPressed: onSecondaryAction,
      icon: Icon(secondaryActionIcon),
      style: IconButton.styleFrom(
        backgroundColor: Colors.grey[300],
        foregroundColor: Colors.grey[700],
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltip: secondaryActionTooltip,
    );
  }
}
