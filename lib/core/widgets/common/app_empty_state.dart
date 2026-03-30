// ============================================================================
// 🎯 APP EMPTY STATE - ESTADOS VACÍOS ESTÁNDAR
// ============================================================================

import 'package:flutter/material.dart';
import 'package:stampcamera/core/theme/app_colors.dart';
import 'package:stampcamera/core/theme/design_tokens.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final stateColor = color ?? AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceXXXL),
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        border: Border.all(
          color: stateColor.withValues(alpha: 0.1), 
          width: DesignTokens.borderWidthNormal,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: DesignTokens.iconHuge, 
            color: stateColor,
          ),
          const SizedBox(height: DesignTokens.spaceL),
          Text(
            title,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeL,
              fontWeight: FontWeight.bold,
              color: stateColor,
            ),
          ),
          const SizedBox(height: DesignTokens.spaceS),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS, 
              color: stateColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: DesignTokens.spaceL),
            action!,
          ],
        ],
      ),
    );
  }
}