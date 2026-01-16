import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/auth_state.dart';
import '../providers/auth_provider.dart';
import '../providers/biometric_provider.dart';

class BiometricSetupWidget extends ConsumerStatefulWidget {
  const BiometricSetupWidget({super.key});

  @override
  ConsumerState<BiometricSetupWidget> createState() =>
      _BiometricSetupWidgetState();
}

class _BiometricSetupWidgetState extends ConsumerState<BiometricSetupWidget> {
  bool _hasShownSnackBar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowBiometricSnackBar();
    });
  }

  Future<void> _checkAndShowBiometricSnackBar() async {
    if (_hasShownSnackBar || !mounted) return;

    final biometricState = ref.read(biometricProvider);
    final authState = ref.read(authProvider);

    if (authState.value?.status == AuthStatus.loggedIn &&
        biometricState.isAvailable &&
        !biometricState.isEnabled) {
      final hasCredentials = await ref
          .read(biometricProvider.notifier)
          .hasStoredCredentials();

      if (!hasCredentials && mounted) {
        _hasShownSnackBar = true;

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          _showBiometricSnackBar(biometricState);
        }
      }
    }
  }

  void _showBiometricSnackBar(BiometricState biometricState) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.fingerprint, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Configura tu ${biometricState.biometricType.toLowerCase()} para acceso rápido',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF003B5C),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Configurar',
          textColor: Colors.white,
          onPressed: () => _showCredentialsDialog(biometricState),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showCredentialsDialog(BiometricState biometricState) {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: 400,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF003B5C).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.fingerprint,
                        color: const Color(0xFF003B5C),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configurar Biometría',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'Acceso rápido y seguro',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Verifica tus credenciales para habilitar el acceso biométrico.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue[700],
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Campo usuario
                          TextFormField(
                            controller: usernameController,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              labelText: 'Usuario',
                              hintText: 'Ingresa tu usuario',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: const Color(0xFF003B5C),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF003B5C),
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (val) => val?.isEmpty ?? true
                                ? 'Usuario requerido'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Campo contraseña
                          TextFormField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              hintText: 'Ingresa tu contraseña',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: const Color(0xFF003B5C),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF003B5C),
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (val) => val?.isEmpty ?? true
                                ? 'Contraseña requerida'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          usernameController.dispose();
                          passwordController.dispose();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(dialogContext);

                            await _setupBiometric(
                              usernameController.text.trim(),
                              passwordController.text.trim(),
                            );

                            usernameController.dispose();
                            passwordController.dispose();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003B5C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Habilitar Biometría',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setupBiometric(String username, String password) async {
    if (!mounted) return;

    try {
      final success = await ref
          .read(biometricProvider.notifier)
          .setupBiometric(username, password);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    success
                        ? '✅ Autenticación biométrica habilitada'
                        : '❌ Error al configurar biometría',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error: ${e.toString()}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
