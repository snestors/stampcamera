import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/asistencia/asistencias_provider.dart';

class BotonMarcarSalida extends ConsumerWidget {
  const BotonMarcarSalida({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(asistenciaStatusProvider);
    final isLoading = status == AsistenciaStatus.salidaLoading;

    return FloatingActionButton.extended(
      heroTag: 'btn_salida',
      label: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isLoading
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Registrando...',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : const Text(
                'Marcar salida',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
      backgroundColor: isLoading ? Colors.grey[400] : Colors.deepOrange[400],
      icon: isLoading ? null : const Icon(Icons.logout_rounded),
      onPressed: isLoading ? null : () => _showConfirmDialog(context, ref),
    );
  }

  void _showConfirmDialog(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ConfirmSalidaDialog(ref: ref),
    );
  }
}

class _ConfirmSalidaDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _ConfirmSalidaDialog({required this.ref});

  @override
  ConsumerState<_ConfirmSalidaDialog> createState() =>
      _ConfirmSalidaDialogState();
}

class _ConfirmSalidaDialogState extends ConsumerState<_ConfirmSalidaDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _isSubmitting = false; // Previene doble tap

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(asistenciaStatusProvider);
    // Usar estado local O estado del provider para máxima protección
    final isLoading = _isSubmitting || status == AsistenciaStatus.salidaLoading;

    return ScaleTransition(
      scale: _scaleAnim,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono animado
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isLoading
                      ? const Color(0xFF003B5C).withValues(alpha: 0.1)
                      : Colors.deepOrange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFF003B5C),
                        ),
                      )
                    : Icon(
                        Icons.logout_rounded,
                        size: 40,
                        color: Colors.deepOrange[400],
                      ),
              ),

              const SizedBox(height: 20),

              // Título
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  isLoading ? 'Registrando salida...' : '¿Finalizar jornada?',
                  key: ValueKey(isLoading),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003B5C),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 12),

              // Descripción
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  isLoading
                      ? 'Obteniendo tu ubicación GPS para\nregistrar la salida...'
                      : 'Se registrará tu salida con la\nubicación actual.',
                  key: ValueKey('desc_$isLoading'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // Botones
              if (!isLoading) ...[
                // Botón confirmar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange[400],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _handleConfirm(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Confirmar Salida',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Botón cancelar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],

              // Indicador de carga
              if (isLoading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gps_fixed, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Obteniendo GPS...',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleConfirm(BuildContext dialogContext) async {
    // Prevenir doble tap
    if (_isSubmitting) return;

    // Activar loading inmediatamente
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    // Capturar navigator y messenger antes del await
    final navigator = Navigator.of(dialogContext);
    final messenger = ScaffoldMessenger.of(dialogContext);

    try {
      final notifier = ref.read(asistenciaActivaProvider.notifier);
      final ok = await notifier.marcarSalida(widget.ref);

      if (!mounted) return;

      navigator.pop();

      if (ok) {
        HapticFeedback.lightImpact();
        _showSuccessSnackbar(messenger, 'Salida registrada correctamente');
      } else {
        HapticFeedback.heavyImpact();
        _showErrorSnackbar(messenger, 'Error al registrar salida');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessSnackbar(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackbar(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
