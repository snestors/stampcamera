import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/auth_state.dart';
import 'package:stampcamera/models/login_flow_model.dart';
import 'package:stampcamera/providers/auth_provider.dart';
import 'package:stampcamera/providers/device_provider.dart';
import 'package:stampcamera/providers/login_flow_provider.dart';
import 'package:stampcamera/services/device_service.dart';
import 'package:stampcamera/services/biometric_service.dart';
import 'package:stampcamera/utils/share_utils.dart';

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
  final _otpCtrl = TextEditingController();
  final _passwordFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _appVersion = '1.0.0';
  String? _lastUsername;
  String? _lastPassword;
  bool _isPersonalDevice = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _biometricLoading = false;

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

        // Verificar si biométrico está disponible y habilitado
        await _checkBiometricStatus();

        // Si biométrico está activo y no fue rechazado recientemente, lanzar automáticamente
        if (_biometricEnabled && !BiometricService().wasRecentlyDeclined) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loginWithBiometric();
          });
        } else {
          // Auto-focus en password para equipos personales sin biométrico
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _passwordFocusNode.requestFocus();
            });
          }
        }
      }
    }
  }

  Future<void> _checkBiometricStatus() async {
    final biometricService = BiometricService();
    final deviceSupported = await biometricService.isDeviceSupported();
    final canCheck = await biometricService.canCheckBiometrics();
    final isEnabled = await biometricService.isBiometricEnabled();
    final hasCredentials = await biometricService.hasStoredCredentials();

    if (mounted) {
      setState(() {
        _biometricAvailable = deviceSupported && canCheck;
        _biometricEnabled = isEnabled && hasCredentials;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _lastUsername = _usernameCtrl.text.trim();
      _lastPassword = _passwordCtrl.text.trim();

      // Para equipos personales con biométrico disponible:
      // Guardar password pendiente para configurar biométrico en home
      if (_isPersonalDevice && _biometricAvailable && _lastPassword != null) {
        BiometricService().setPendingPassword(_lastPassword!);
      }

      ref.read(authProvider.notifier).clearError();

      // El flujo resuelve la autorización del equipo dentro del login:
      // authenticated | pending_otp | pending_admin
      await ref
          .read(loginFlowProvider.notifier)
          .start(_lastUsername!, _lastPassword!);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) return;
    await ref.read(loginFlowProvider.notifier).verifyOtp(code);
  }

  void _cancelLoginFlow() {
    _otpCtrl.clear();
    ref.read(loginFlowProvider.notifier).cancel();
  }

  /// Comparte el código de aprobación por el share sheet del sistema
  /// (WhatsApp personal o Business, SMS, etc.)
  Future<void> _shareUserCode(String code) async {
    final username = _lastUsername ?? _usernameCtrl.text.trim();
    final message = username.isEmpty
        ? 'Solicito aprobación de mi equipo en AYG APP.\nCódigo: $code'
        : 'Solicito aprobación de mi equipo en AYG APP.\nUsuario: $username\nCódigo: $code';

    await SharePlus.instance.share(
      ShareParams(
        text: message,
        sharePositionOrigin: shareOriginOf(context),
      ),
    );
  }

  Future<void> _loginWithBiometric() async {
    if (_biometricLoading) return;

    setState(() => _biometricLoading = true);

    try {
      final biometricService = BiometricService();
      biometricService.clearDeclined();
      final password = await biometricService.authenticateAndGetPassword();

      if (password == null) {
        // Usuario canceló o falló la autenticación
        if (mounted) {
          setState(() => _biometricLoading = false);
        }
        return;
      }

      final username = _usernameCtrl.text.trim();
      if (username.isEmpty) {
        if (mounted) {
          setState(() => _biometricLoading = false);
        }
        return;
      }

      _lastUsername = username;
      _lastPassword = password;

      await ref.read(authProvider.notifier).login(username, password);

      // Si falla el login con biométrico (contraseña cambió),
      // desactivar biométrico para que use contraseña manual
      if (mounted && ref.read(authProvider).value?.status != AuthStatus.loggedIn) {
        await biometricService.disableBiometric();
        setState(() {
          _biometricEnabled = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _biometricLoading = false);
      }
    }
  }

  Future<void> _disableBiometric() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Desactivar biométrico',
      message: '¿Deseas desactivar el acceso biométrico? Deberás ingresar tu contraseña cada vez.',
      confirmText: 'Desactivar',
      cancelText: 'Cancelar',
      isDanger: true,
    );

    if (confirmed == true) {
      await BiometricService().disableBiometric();
      if (mounted) {
        setState(() {
          _biometricEnabled = false;
        });
      }
    }
  }

  Future<void> _clearDeviceRegistration() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Desvincular equipo',
      message: 'Se eliminará el registro de este dispositivo y deberás volver a registrarlo para usarlo.\n\n¿Deseas continuar?',
      confirmText: 'Desvincular',
      cancelText: 'Cancelar',
      isDanger: true,
    );

    if (confirmed == true) {
      final deviceService = DeviceService();
      await deviceService.clearDeviceInfo();
      ref.read(deviceProvider.notifier).reset();
      // El próximo login verifica el equipo dentro del propio flujo,
      // ya no hay que pasar por la pantalla de registro
      if (mounted) {
        setState(() {
          _isPersonalDevice = false;
          _biometricEnabled = false;
          _usernameCtrl.clear();
          _passwordCtrl.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(loginFlowProvider);
    final authErrorMessage = ref.watch(authProvider).value?.errorMessage;
    final errorMessage = flowState.errorMessage ?? authErrorMessage;
    final isLoading = ref.watch(authProvider).isLoading || flowState.isLoading;

    final Widget content;
    switch (flowState.phase) {
      case LoginFlowPhase.otp:
        content = _buildOtpCard(flowState);
        break;
      case LoginFlowPhase.adminApproval:
        content = _buildAdminApprovalCard(flowState);
        break;
      case LoginFlowPhase.credentials:
        content = _buildLoginForm(errorMessage, isLoading);
        break;
    }

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
                    content,
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

  /// Contenedor con el estilo del formulario de login
  Widget _buildFlowCard({required List<Widget> children}) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  /// Fase pending_otp: código de 6 dígitos enviado al correo
  Widget _buildOtpCard(LoginFlowState flow) {
    return _buildFlowCard(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceM),
        const Text(
          'Verificación de equipo',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeXL,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceS),
        Text(
          'Enviamos un código de 6 dígitos a\n${flow.maskedEmail ?? 'tu correo'}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: DesignTokens.fontSizeS,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceL),
        TextField(
          controller: _otpCtrl,
          enabled: !flow.isLoading,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 12,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            filled: true,
            fillColor: AppColors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _verifyOtp(),
        ),
        const SizedBox(height: DesignTokens.spaceL),
        if (flow.errorMessage != null) ...[
          AppInlineError(
            message: flow.errorMessage!,
            onDismiss: () =>
                ref.read(loginFlowProvider.notifier).clearError(),
            dismissible: true,
          ),
          const SizedBox(height: DesignTokens.spaceM),
        ],
        AppButton.primary(
          text: 'Verificar código',
          onPressed:
              flow.isLoading || _otpCtrl.text.trim().length != 6
                  ? null
                  : _verifyOtp,
          isLoading: flow.isLoading,
          size: AppButtonSize.large,
        ),
        const SizedBox(height: DesignTokens.spaceS),
        TextButton(
          onPressed: flow.isLoading
              ? null
              : () =>
                  ref.read(loginFlowProvider.notifier).requestAdminApproval(),
          child: const Text(
            '¿No te llegó el correo? Pedir aprobación del administrador',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: DesignTokens.fontSizeS),
          ),
        ),
        TextButton(
          onPressed: flow.isLoading ? null : _cancelLoginFlow,
          child: const Text(
            'Cancelar',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  /// Fase pending_admin: mostrar user_code y esperar aprobación (polling)
  Widget _buildAdminApprovalCard(LoginFlowState flow) {
    return _buildFlowCard(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.admin_panel_settings_outlined,
            color: AppColors.warning,
            size: 32,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceM),
        const Text(
          'Aprobación requerida',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeXL,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceS),
        const Text(
          'Pide a un administrador o coordinador que apruebe este equipo con el siguiente código:',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceL),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            flow.userCode ?? '----',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
              fontFamily: 'monospace',
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spaceM),
        ElevatedButton.icon(
          onPressed: flow.userCode == null
              ? null
              : () => _shareUserCode(flow.userCode!),
          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 22),
          label: const Text(
            'Compartir código',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spaceL),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: DesignTokens.spaceS),
            Text(
              'Esperando aprobación…',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceS),
        const Text(
          'El código expira en 10 minutos.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeXS,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceS),
        TextButton(
          onPressed: _cancelLoginFlow,
          child: const Text(
            'Cancelar',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
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
            const Text(
              'Bienvenido',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXXL,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
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
                  const SizedBox(height: DesignTokens.spaceL),
                ] else ...[
                  AppTextField(
                    controller: _usernameCtrl,
                    label: 'Usuario',
                    hint: 'Ej: nfarinas',
                    prefixIcon: Icons.person_outline,
                    validator: FormValidators.validateRequired,
                  ),
                  const SizedBox(height: DesignTokens.spaceL),
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
                      ref.read(loginFlowProvider.notifier).clearError();
                    },
                    dismissible: true,
                  ),
                  const SizedBox(height: DesignTokens.spaceL),
                ],

                AppButton.primary(
                  text: 'Ingresar',
                  onPressed: isLoading || _biometricLoading ? null : _submit,
                  isLoading: isLoading,
                  size: AppButtonSize.large,
                ),

                // Botón biométrico para dispositivos personales
                if (_isPersonalDevice && _biometricEnabled) ...[
                  const SizedBox(height: DesignTokens.spaceM),
                  _buildBiometricButton(isLoading),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton(bool isLoading) {
    return InkWell(
      onTap: isLoading || _biometricLoading ? null : _loginWithBiometric,
      borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceM),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_biometricLoading) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: DesignTokens.spaceS),
              const Text(
                'Verificando...',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: DesignTokens.fontSizeM,
                ),
              ),
            ] else ...[
              const Icon(
                Icons.fingerprint,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: DesignTokens.spaceS),
              const Text(
                'Ingresar con biométrico',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: DesignTokens.fontSizeM,
                ),
              ),
            ],
          ],
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
                child: const Icon(
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
                    const Text(
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
                      style: const TextStyle(
                        fontSize: DesignTokens.fontSizeL,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
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
          // Acciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Biométrico toggle
              if (_biometricAvailable && _biometricEnabled)
                InkWell(
                  onTap: _disableBiometric,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fingerprint,
                          size: 16,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Biométrico',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeXS,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Cambiar dispositivo
              InkWell(
                onTap: _clearDeviceRegistration,
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Cambiar equipo',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
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
        ],
      ),
    );
  }

  // Método eliminado - usando AppTextField del sistema de diseño

  // Método eliminado - usando AppErrorState del sistema de diseño

  // Método eliminado - usando AppButton del sistema de diseño

  // Método eliminado - usando AppButton del sistema de diseño

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Versión $_appVersion',
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: DesignTokens.fontSizeXS,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
