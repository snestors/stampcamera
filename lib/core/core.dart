// ============================================================================
// 🎯 CORE SYSTEM - PUNTO DE ENTRADA UNIFICADO
// ============================================================================

// Tema y diseño
export 'theme/app_colors.dart';
export 'theme/design_tokens.dart';

// Helpers centralizados
export 'helpers/validators/form_validators.dart';
export 'helpers/validators/business_validators.dart';
export 'helpers/formatters/date_formatters.dart';
export 'helpers/formatters/text_formatters.dart';
export 'helpers/ui_helpers/vehicle_helpers.dart';

// Widgets comunes
export 'widgets/buttons/app_button.dart';
export 'widgets/forms/app_text_field.dart';
export 'widgets/common/app_loading_state.dart';
export 'widgets/common/app_error_state.dart';

// Re-exportar custom_colors.dart para compatibilidad
export '../../theme/custom_colors.dart';