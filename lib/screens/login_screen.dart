import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/auth_state.dart';
import '../providers/auth_provider.dart';
import '../providers/biometric_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _lastUsername;
  String? _lastPassword;
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );

    _animationController.forward();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _lastUsername = _usernameCtrl.text.trim();
      _lastPassword = _passwordCtrl.text.trim();

      await ref
          .read(authProvider.notifier)
          .login(_lastUsername!, _lastPassword!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final biometricState = ref.watch(biometricProvider);

    // Listener para detectar login exitoso
    ref.listen<AsyncValue<AuthState>>(authProvider, (previous, next) {
      if (previous?.isLoading == true &&
          next.hasValue &&
          next.value?.status == AuthStatus.loggedIn &&
          mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _checkBiometricDialog();
          }
        });
      }
    });

    final errorMessage = ref.watch(authProvider).value?.errorMessage;
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            final availableHeight = constraints.maxHeight - keyboardHeight;

            return SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(minHeight: availableHeight),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Espaciado superior flexible
                    //SizedBox(height: availableHeight * 0.1),

                    // Header del logo
                    _buildHeader(),

                    //SizedBox(height: availableHeight * 0.02),

                    // Formulario
                    _buildLoginForm(errorMessage, isLoading, biometricState),
                    const SizedBox(height: 6),
                    // Footer
                    _buildFooter(),

                    // Espaciado final mínimo
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Logo con diseño mejorado
            Hero(
              tag: 'app_logo',
              child: Container(
                height: 100,
                width: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/logo_principal.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            //const SizedBox(height: 5),

            // Título mejorado
            Text(
              'Bienvenido',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXXL,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ingresa tus credenciales para continuar',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(
    String? errorMessage,
    bool isLoading,
    BiometricState biometricState,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
            boxShadow: [
              BoxShadow(
                color: AppColors.overlayDark.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Campo Usuario
                AppTextField(
                  controller: _usernameCtrl,
                  label: 'Usuario',
                  hint: 'Ej: nfarinas',
                  prefixIcon: Icons.person_outline,
                  validator: FormValidators.validateRequired,
                ),
                SizedBox(height: DesignTokens.spaceL),

                // Campo Contraseña
                AppTextField.password(
                  controller: _passwordCtrl,
                  label: 'Contraseña',
                  validator: FormValidators.validateRequired,
                ),
                const SizedBox(height: 20),

                // Mensaje de error
                if (errorMessage != null) ...[
                  AppInlineError(
                    message: errorMessage,
                    onDismiss: () {
                      ref.read(authProvider.notifier).clearError();
                    },
                    dismissible: true,
                  ),
                  SizedBox(height: DesignTokens.spaceL),
                ],

                // Botón Login
                AppButton.primary(
                  text: 'Ingresar',
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                  size: AppButtonSize.large,
                ),

                // Sección Biométrica
                if (biometricState.isEnabled) ...[
                  const SizedBox(height: 16),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.neutral)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceL),
                        child: Text(
                          'o',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.neutral)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botón Biométrico
                  AppButton.secondary(
                    text: biometricState.isLoading 
                        ? 'Autenticando...' 
                        : 'Acceso Biométrico',
                    onPressed: biometricState.isLoading ? null : _biometricLogin,
                    icon: Icons.fingerprint,
                    isLoading: biometricState.isLoading,
                    size: AppButtonSize.large,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Método eliminado - usando AppTextField del sistema de diseño

  // Método eliminado - usando AppErrorState del sistema de diseño

  // Método eliminado - usando AppButton del sistema de diseño

  // Método eliminado - usando AppButton del sistema de diseño

  Widget _buildFooter() {
    return Text(
      'Versión $_appVersion',
      style: TextStyle(
        color: AppColors.textLight, 
        fontSize: DesignTokens.fontSizeXS,
      ),
      textAlign: TextAlign.center,
    );
  }

  Future<void> _checkBiometricDialog() async {
    if (!mounted) return;

    print('🔍 LoginScreen: Verificando si mostrar diálogo biométrico...');

    final biometricState = ref.read(biometricProvider);
    print(
      '🔍 LoginScreen: isAvailable=${biometricState.isAvailable}, isEnabled=${biometricState.isEnabled}',
    );

    if (biometricState.isAvailable && !biometricState.isEnabled) {
      final hasCredentials = await ref
          .read(biometricProvider.notifier)
          .hasStoredCredentials();
      print('🔍 LoginScreen: hasStoredCredentials=$hasCredentials');

      if (!hasCredentials) {
        print('✅ LoginScreen: Mostrando diálogo de configuración biométrica');
        _showBiometricDialog();
      } else {
        print('❌ LoginScreen: Ya hay credenciales, no se muestra diálogo');
      }
    } else {
      print('❌ LoginScreen: Biometría no disponible o ya habilitada');
    }
  }

  Future<void> _biometricLogin() async {
    if (!mounted) return;

    final success = await ref
        .read(biometricProvider.notifier)
        .authenticateAndLogin();

    if (!success && mounted) {
      final biometricState = ref.read(biometricProvider);
      if (biometricState.error != null) {
        final isCredentialError =
            biometricState.error!.contains('Credenciales incorrectas') ||
            biometricState.error!.contains('Error en login');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    isCredentialError
                        ? Icons.warning_amber_rounded
                        : Icons.error_outline,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCredentialError
                              ? 'Credenciales Expiradas'
                              : 'Error de Autenticación',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCredentialError
                              ? 'Configura biometría nuevamente con tus credenciales actuales.'
                              : biometricState.error!.length > 50
                              ? '${biometricState.error!.substring(0, 47)}...'
                              : biometricState.error!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: isCredentialError
                ? Colors.orange[600]
                : Colors.red[600],
            duration: Duration(seconds: isCredentialError ? 5 : 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
          ),
        );

        if (isCredentialError) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ref.read(biometricProvider.notifier).refresh();
            }
          });
        }
      }
    }
  }

  void _showBiometricDialog() {
    if (!mounted) return;

    final biometricState = ref.read(biometricProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.fingerprint, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Habilitar ${biometricState.biometricType}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Quieres usar tu ${biometricState.biometricType.toLowerCase()} para iniciar sesión más rápido la próxima vez?',
            ),
            const SizedBox(height: 8),
            Text(
              'Te pediremos confirmar tus credenciales para configurarlo.',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXS, 
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _lastUsername = null;
              _lastPassword = null;
            },
            child: const Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                _showCredentialsDialog();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _showCredentialsDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    if (_lastUsername != null) {
      usernameController.text = _lastUsername!;
    }

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
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.fingerprint,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirmar Credenciales',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Para habilitar biometría',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
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
                              color: Colors.green.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Confirma tus credenciales para habilitar el acceso rápido con biometría.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.green[700],
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
                              hintText: 'Confirma tu usuario',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: AppColors.primary,
                              ),
                              filled: true,
                              fillColor: AppColors.backgroundLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.neutral,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.error),
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
                              hintText: 'Confirma tu contraseña',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppColors.primary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: AppColors.backgroundLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.neutral,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.error),
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
                          _lastUsername = null;
                          _lastPassword = null;
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

                            await _enableBiometric(
                              usernameController.text.trim(),
                              passwordController.text.trim(),
                            );

                            _lastUsername = null;
                            _lastPassword = null;
                            usernameController.dispose();
                            passwordController.dispose();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
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

  Future<void> _enableBiometric(String username, String password) async {
    if (!mounted) return;

    try {
      final success = await ref
          .read(biometricProvider.notifier)
          .setupBiometric(username, password);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '✅ Autenticación biométrica habilitada'
                  : '❌ Error al habilitar autenticación biométrica',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
