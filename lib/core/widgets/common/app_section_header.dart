// ============================================================================
// 🎨 APP SECTION HEADER - HEADERS DE SECCIÓN
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

class AppSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;
  final Color? iconColor;

  const AppSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.count,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.spaceXS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Icon(
            icon, 
            size: DesignTokens.iconL, 
            color: color,
          ),
        ),
        SizedBox(width: DesignTokens.spaceS),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (count != null) ...[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceS,
              vertical: DesignTokens.spaceXS,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: DesignTokens.fontSizeXS,
              ),
            ),
          ),
        ],
      ],
    );
  }
}