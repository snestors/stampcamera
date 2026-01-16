import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stampcamera/core/core.dart';
import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';
import '../services/device_service.dart';

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
  final _passwordFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _appVersion = '1.0.0';
  String? _lastUsername;
  String? _lastPassword;
  bool _isPersonalDevice = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadDeviceInfo();
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
    if (mounted) {
      setState(() {
        _appVersion = info.version;
      });
    }
  }

  Future<void> _loadDeviceInfo() async {
    final deviceService = DeviceService();
    final deviceType = await deviceService.getStoredDeviceType();
    final storedUsername = await deviceService.getStoredUsername();

    if (deviceType == 'personal' && storedUsername != null) {
      if (mounted) {
        setState(() {
          _isPersonalDevice = true;
          _usernameCtrl.text = storedUsername;
        });
        // Auto-focus en password para equipos personales
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _passwordFocusNode.requestFocus();
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocusNode.dispose();
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

  Future<void> _clearDeviceRegistration() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            const Text('Desvincular equipo'),
          ],
        ),
        content: const Text(
          'Se eliminará el registro de este dispositivo y deberás volver a registrarlo para usarlo.\n\n¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deviceService = DeviceService();
      await deviceService.clearDeviceInfo();
      ref.read(deviceProvider.notifier).reset();
      if (mounted) {
        context.go('/device-registration');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    _buildHeader(),
                    _buildLoginForm(errorMessage, isLoading),
                    const SizedBox(height: 6),
                    _buildFooter(),
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

  Widget _buildLoginForm(String? errorMessage, bool isLoading) {
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
                // Card de usuario para equipos personales
                if (_isPersonalDevice) ...[
                  _buildPersonalDeviceCard(),
                  SizedBox(height: DesignTokens.spaceL),
                ] else ...[
                  AppTextField(
                    controller: _usernameCtrl,
                    label: 'Usuario',
                    hint: 'Ej: nfarinas',
                    prefixIcon: Icons.person_outline,
                    validator: FormValidators.validateRequired,
                  ),
                  SizedBox(height: DesignTokens.spaceL),
                ],

                AppTextField.password(
                  controller: _passwordCtrl,
                  label: 'Contraseña',
                  validator: FormValidators.validateRequired,
                  focusNode: _passwordFocusNode,
                ),
                const SizedBox(height: 20),

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

                AppButton.primary(
                  text: 'Ingresar',
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                  size: AppButtonSize.large,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalDeviceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Header con icono y badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user,
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
                      'Equipo Personal',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeXS,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _usernameCtrl.text,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeL,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.lock_outline,
                color: AppColors.textLight,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Divider
          Divider(
            color: AppColors.primary.withValues(alpha: 0.15),
            height: 1,
          ),
          const SizedBox(height: 8),
          // Acción para cambiar dispositivo
          InkWell(
            onTap: _clearDeviceRegistration,
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Cambiar dispositivo',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
}
