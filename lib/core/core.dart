// ============================================================================
// 🎯 CORE SYSTEM - PUNTO DE ENTRADA UNIFICADO
// ============================================================================

// Base abstractions
export 'has_id.dart';

// Tema y diseño
export 'theme/app_colors.dart';
export 'theme/design_tokens.dart';

// Helpers centralizados
export 'helpers/validators/form_validators.dart';
export 'helpers/validators/business_validators.dart';
export 'helpers/formatters/date_formatters.dart';
export 'helpers/formatters/text_formatters.dart';
export 'helpers/ui_helpers/vehicle_helpers.dart';

// ============================================================================
// CONVENCIÓN DE WIDGETS
// - lib/core/widgets/common/  → widgets de PRESENTACIÓN reutilizables SIN
//   imports de dominio (models/providers/services); se exportan aquí y se
//   consumen vía `core/core.dart`.
// - lib/widgets/<feature>/    → widgets atados a un feature (importan su
//   dominio: models/providers de esa feature).
// - lib/widgets/common/       → SOLO widgets de dominio transversal (infra de
//   toda la app: cámara reutilizable, cola offline, banner de notificaciones
//   en vivo). No es un cajón de sastre; lo genérico va a core.
//   Excepción: search_bar_widget.dart (UI genérica) sigue ahí porque lo
//   importa registro_screen.dart, que está fuera de alcance para editar.
// ============================================================================

// Widgets comunes
export 'widgets/buttons/app_button.dart';
export 'widgets/forms/app_text_field.dart';
export 'widgets/common/app_loading_state.dart';
export 'widgets/common/app_error_state.dart';
export 'widgets/common/app_card.dart';
export 'widgets/common/app_empty_state.dart';
export 'widgets/common/app_info_row.dart';
export 'widgets/common/app_section_header.dart';
export 'widgets/common/app_search_select.dart';
export 'widgets/common/app_search_dropdown.dart';
export 'widgets/common/fullscreen_image_viewer.dart';

// Feedback widgets (diálogos, snackbars)
export 'widgets/feedback/app_dialog.dart';
export 'widgets/feedback/app_snackbar.dart';
