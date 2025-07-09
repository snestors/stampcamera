// ============================================================================
// 🔐 PANTALLA DE LOGIN REFACTORIZADA CON SISTEMA CENTRALIZADO
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/auth_state.dart';
import '../providers/auth_provider.dart';
import '../providers/biometric_provider.dart';
import '../core/core.dart';

class LoginScreenRefactored extends ConsumerStatefulWidget {
  const LoginScreenRefactored({super.key});

  @override
  ConsumerState<LoginScreenRefactored> createState() => _LoginScreenRefactoredState();
}

class _LoginScreenRefactoredState extends ConsumerState<LoginScreenRefactored>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

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
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: DesignTokens.animationSlow,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: DesignTokens.curveEaseOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: DesignTokens.curveEaseOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = info.version;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
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

  Future<void> _authenticateWithBiometric() async {
    try {
      final biometricNotifier = ref.read(biometricProvider.notifier);
      final result = await biometricNotifier.authenticate();
      
      if (result && mounted) {
        // Usar las credenciales guardadas para login automático
        if (_lastUsername != null && _lastPassword != null) {
          await ref
              .read(authProvider.notifier)
              .login(_lastUsername!, _lastPassword!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de autenticación biométrica: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _checkBiometricDialog() {
    final biometricState = ref.read(biometricProvider);
    
    if (biometricState.isAvailable && !biometricState.isSetup) {
      showDialog(
        context: context,
        builder: (context) => _BiometricSetupDialog(
          onAccept: () async {
            await ref.read(biometricProvider.notifier).enableBiometric();
            Navigator.of(context).pop();
          },
          onDecline: () => Navigator.of(context).pop(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final biometricState = ref.watch(biometricProvider);

    // Listener para detectar login exitoso
    ref.listen<AsyncValue<AuthState>>(authProvider, (previous, next) {
      if (previous?.isLoading == true &&
          next.hasValue &&
          next.value?.status == AuthStatus.loggedIn &&
          mounted) {
        Future.delayed(DesignTokens.animationNormal, () {
          if (mounted) {
            _checkBiometricDialog();
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceXL,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    SizedBox(height: DesignTokens.spaceXXXL),
                    _buildLoginForm(authState),
                    SizedBox(height: DesignTokens.spaceXL),
                    _buildBiometricSection(biometricState),
                    SizedBox(height: DesignTokens.spaceXXXL),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXXL),
            boxShadow: DesignTokens.shadowMedium,
          ),
          child: const Icon(
            Icons.camera_alt,
            size: 60,
            color: Colors.white,
          ),
        ),
        SizedBox(height: DesignTokens.spaceXL),
        
        // Título
        Text(
          'StampCamera',
          style: DesignTokens.getTextStyle(
            'xxl',
            weight: DesignTokens.fontWeightBold,
          ).copyWith(
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: DesignTokens.spaceS),
        
        // Subtítulo
        Text(
          'Inspección Vehicular A&G',
          style: DesignTokens.getTextStyle(
            'regular',
            weight: DesignTokens.fontWeightMedium,
          ).copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(AsyncValue<AuthState> authState) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Campo de usuario
          AppTextField(
            controller: _usernameCtrl,
            focusNode: _usernameFocus,
            label: 'Usuario',
            hint: 'Ingresa tu usuario',
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.next,
            isRequired: true,
            validator: (value) => FormValidators.validateRequired(
              value,
              fieldName: 'Usuario',
            ),
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          SizedBox(height: DesignTokens.spaceL),
          
          // Campo de contraseña
          AppTextField.password(
            controller: _passwordCtrl,
            focusNode: _passwordFocus,
            label: 'Contraseña',
            hint: 'Ingresa tu contraseña',
            textInputAction: TextInputAction.done,
            isRequired: true,
            validator: (value) => FormValidators.validateRequired(
              value,
              fieldName: 'Contraseña',
            ),
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: DesignTokens.spaceXL),
          
          // Botón de login
          AppButton.primary(
            text: 'Iniciar Sesión',
            onPressed: authState.isLoading ? null : _submit,
            isLoading: authState.isLoading,
            isFullWidth: true,
            size: AppButtonSize.large,
            icon: Icons.login,
          ),
          
          // Mostrar error si existe
          if (authState.hasError) ...[
            SizedBox(height: DesignTokens.spaceL),
            AppInlineError(
              message: authState.error.toString(),
              onDismiss: () {
                ref.read(authProvider.notifier).clearError();
              },
              dismissible: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBiometricSection(BiometricState biometricState) {
    if (!biometricState.isAvailable) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Divisor
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.borderLight)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceL),
              child: Text(
                'o',
                style: DesignTokens.getTextStyle('s').copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.borderLight)),
          ],
        ),
        SizedBox(height: DesignTokens.spaceXL),
        
        // Botón biométrico
        AppButton.secondary(
          text: 'Usar ${biometricState.biometricType.name}',
          onPressed: biometricState.isSetup ? _authenticateWithBiometric : null,
          icon: _getBiometricIcon(biometricState.biometricType),
          isFullWidth: true,
          size: AppButtonSize.large,
          isOutlined: true,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'A&G Ajustadores',
          style: DesignTokens.getTextStyle('s').copyWith(
            color: AppColors.textSecondary,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
        SizedBox(height: DesignTokens.spaceXS),
        Text(
          'Versión $_appVersion',
          style: DesignTokens.getTextStyle('xs').copyWith(
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  IconData _getBiometricIcon(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return Icons.face;
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.iris:
        return Icons.visibility;
      case BiometricType.weak:
      case BiometricType.strong:
      default:
        return Icons.security;
    }
  }
}

// ============================================================================
// DIALOG DE CONFIGURACIÓN BIOMÉTRICA
// ============================================================================

class _BiometricSetupDialog extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _BiometricSetupDialog({
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
      ),
      title: Row(
        children: [
          Icon(
            Icons.fingerprint,
            color: AppColors.primary,
            size: DesignTokens.iconXL,
          ),
          SizedBox(width: DesignTokens.spaceS),
          Text(
            'Configurar Biometría',
            style: DesignTokens.getTextStyle(
              'l',
              weight: DesignTokens.fontWeightBold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Deseas habilitar la autenticación biométrica para futuros accesos?',
            style: DesignTokens.getTextStyle('regular').copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: DesignTokens.spaceM),
          Container(
            padding: const EdgeInsets.all(DesignTokens.spaceM),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: DesignTokens.iconM,
                ),
                SizedBox(width: DesignTokens.spaceS),
                Expanded(
                  child: Text(
                    'Esto te permitirá acceder más rápido y de forma segura.',
                    style: DesignTokens.getTextStyle('s').copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        AppButton.secondary(
          text: 'Ahora no',
          onPressed: onDecline,
          size: AppButtonSize.small,
        ),
        AppButton.primary(
          text: 'Habilitar',
          onPressed: onAccept,
          size: AppButtonSize.small,
          icon: Icons.check,
        ),
      ],
    );
  }
}

// ============================================================================
// EXTENSIÓN PARA BIOMETRIC TYPE
// ============================================================================

extension BiometricTypeExtension on BiometricType {
  String get name {
    switch (this) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Huella Digital';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.weak:
        return 'Autenticación Débil';
      case BiometricType.strong:
        return 'Autenticación Fuerte';
      default:
        return 'Biometría';
    }
  }
}