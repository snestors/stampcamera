import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/asistencia/asistencias_provider.dart';

void showMarcarEntradaBottomSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const ModalMarcarEntrada(),
  );
}

class ModalMarcarEntrada extends ConsumerStatefulWidget {
  const ModalMarcarEntrada({super.key});

  @override
  ConsumerState<ModalMarcarEntrada> createState() => _ModalMarcarEntradaState();
}

class _ModalMarcarEntradaState extends ConsumerState<ModalMarcarEntrada>
    with SingleTickerProviderStateMixin {
  int? _selectedZonaId;
  int? _selectedNaveId;
  final TextEditingController comentarioCtrl = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _isSubmitting = false; // Previene doble tap

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    comentarioCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formOptionsAsync = ref.watch(asistenciaFormOptionsProvider);
    final status = ref.watch(asistenciaStatusProvider);
    // Usar estado local O estado del provider para máxima protección
    final isLoading = _isSubmitting || status == AsistenciaStatus.entradaLoading;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: formOptionsAsync.when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _buildErrorState(e.toString()),
          data: (opciones) => _buildForm(opciones, isLoading),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error al cargar opciones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => ref.invalidate(asistenciaFormOptionsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(FormularioAsistenciaOptions opciones, bool isLoading) {
    final zonas = opciones.zonas;
    final naves = opciones.naves;

    return Stack(
      children: [
        // Contenido del formulario
        SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Header con icono
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF003B5C),
                        const Color(0xFF003B5C).withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Marcar Entrada',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Registra el inicio de tu jornada',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Zona de trabajo (requerido)
                AppSearchDropdown<int>(
                  label: 'Zona de trabajo',
                  hint: 'Buscar zona...',
                  value: _selectedZonaId,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.location_on, color: Color(0xFF003B5C)),
                  options: zonas
                      .map((zona) => AppSearchDropdownOption<int>(
                            value: zona.id,
                            label: zona.value,
                          ))
                      .toList(),
                  onChanged: isLoading
                      ? null
                      : (value) => setState(() => _selectedZonaId = value),
                ),

                const SizedBox(height: 16),

                // Nave (opcional)
                AppSearchDropdown<int>(
                  label: 'Nave / Embarque',
                  hint: 'Buscar nave (opcional)...',
                  value: _selectedNaveId,
                  isRequired: false,
                  prefixIcon: const Icon(Icons.directions_boat, color: Color(0xFF00B4D8)),
                  options: naves
                      .map((nave) => AppSearchDropdownOption<int>(
                            value: nave.id,
                            label: nave.value,
                          ))
                      .toList(),
                  onChanged: isLoading
                      ? null
                      : (value) => setState(() => _selectedNaveId = value),
                ),

                const SizedBox(height: 16),

                // Comentario
                TextFormField(
                  controller: comentarioCtrl,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Comentario (opcional)',
                    hintText: 'Agrega un comentario...',
                    prefixIcon: const Icon(Icons.comment_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF003B5C),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isLoading ? Colors.grey[100] : Colors.grey[50],
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // Botón de confirmar
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B4D8),
                      foregroundColor: Colors.white,
                      elevation: isLoading ? 0 : 2,
                      shadowColor: const Color(0xFF00B4D8).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isLoading ? null : _handleSubmit,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Obteniendo ubicación...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, size: 22),
                                const SizedBox(width: 8),
                                const Text(
                                  'Confirmar Entrada',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Botón cancelar
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: isLoading ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Loading overlay
        if (isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF003B5C),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Registrando entrada...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF003B5C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Obteniendo ubicación GPS',
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
          ),
      ],
    );
  }


  Future<void> _handleSubmit() async {
    // Prevenir doble tap
    if (_isSubmitting) return;

    // Validación
    if (_selectedZonaId == null) {
      HapticFeedback.heavyImpact();
      _showErrorSnackbar('Selecciona una zona de trabajo');
      return;
    }

    // Activar loading inmediatamente
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final notifier = ref.read(asistenciaActivaProvider.notifier);
      final ok = await notifier.marcarEntrada(
        zonaTrabajoId: _selectedZonaId!,
        naveId: _selectedNaveId,
        comentario:
            comentarioCtrl.text.trim().isEmpty ? null : comentarioCtrl.text.trim(),
        wref: ref,
      );

      if (!mounted) return;

      if (ok) {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();
        _showSuccessSnackbar('Entrada registrada correctamente');
      } else {
        HapticFeedback.heavyImpact();
        _showErrorSnackbar('Error al registrar entrada');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    AppSnackBar.success(context, message);
  }

  void _showErrorSnackbar(String message) {
    AppSnackBar.error(context, message);
  }
}
