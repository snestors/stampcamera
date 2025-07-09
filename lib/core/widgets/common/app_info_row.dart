// ============================================================================
// 📝 APP INFO ROW - WIDGETS DE INFORMACIÓN
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

class AppInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLarge;

  const AppInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
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
            size: DesignTokens.iconS, 
            color: color,
          ),
        ),
        SizedBox(width: DesignTokens.spaceS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXS * 0.8,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: DesignTokens.spaceXXS),
              Text(
                value,
                style: TextStyle(
                  fontSize: isLarge ? DesignTokens.fontSizeL : DesignTokens.fontSizeS,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}