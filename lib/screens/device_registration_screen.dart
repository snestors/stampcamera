import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/core/core.dart';
import '../providers/device_provider.dart';

class DeviceRegistrationScreen extends ConsumerStatefulWidget {
  const DeviceRegistrationScreen({super.key});

  @override
  ConsumerState<DeviceRegistrationScreen> createState() =>
      _DeviceRegistrationScreenState();
}

class _DeviceRegistrationScreenState
    extends ConsumerState<DeviceRegistrationScreen> {
  final _usernameController = TextEditingController();
  final _codeController = TextEditingController();
  final _tokenController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _tokenFormKey = GlobalKey<FormState>();

  // 0 = código email, 1 = token
  int _selectedMethod = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _codeController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildContent(deviceState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.phonelink_lock,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Registrar Dispositivo',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeXL,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Autoriza este dispositivo para acceder',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(DeviceState deviceState) {
    switch (deviceState.status) {
      case DeviceRegistrationStatus.checking:
        return _buildLoadingState();
      case DeviceRegistrationStatus.notRegistered:
        return _buildRegistrationForm(deviceState);
      case DeviceRegistrationStatus.awaitingCode:
        return _buildCodeVerificationForm(deviceState);
      case DeviceRegistrationStatus.awaitingToken:
        return _buildTokenFormAfterRequest(deviceState);
      case DeviceRegistrationStatus.registered:
        return _buildSuccessState(deviceState);
      case DeviceRegistrationStatus.error:
        return _buildErrorState(deviceState);
    }
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            'Verificando...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: DesignTokens.fontSizeS,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(DeviceState deviceState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selector de método
        _buildMethodSelector(),
        const SizedBox(height: 16),

        // Formulario según método seleccionado
        if (_selectedMethod == 0)
          _buildEmailCodeForm(deviceState)
        else
          _buildTokenForm(deviceState),
      ],
    );
  }

  Widget _buildMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.neutral.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMethodTab(
              index: 0,
              icon: Icons.email_outlined,
              label: 'Con código',
            ),
          ),
          Expanded(
            child: _buildMethodTab(
              index: 1,
              icon: Icons.vpn_key_outlined,
              label: 'Con token',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailCodeForm(DeviceState deviceState) {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('email_code_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              border: Border.all(color: AppColors.neutral.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ingresa tu usuario',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Te enviaremos un código a tu email registrado',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXS,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _usernameController,
                  label: 'Usuario',
                  hint: 'Ej: jperez',
                  prefixIcon: Icons.person_outline,
                  validator: FormValidators.validateRequired,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (deviceState.errorMessage != null) ...[
            AppInlineError(
              message: deviceState.errorMessage!,
              onDismiss: () => ref.read(deviceProvider.notifier).clearError(),
              dismissible: true,
            ),
            const SizedBox(height: 12),
          ],
          AppButton.primary(
            text: 'Enviar Código',
            onPressed: deviceState.isLoading ? null : _requestCode,
            isLoading: deviceState.isLoading,
            size: AppButtonSize.large,
          ),
        ],
      ),
    );
  }

  Widget _buildTokenForm(DeviceState deviceState) {
    return Form(
      key: _tokenFormKey,
      child: Column(
        key: const ValueKey('token_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              border: Border.all(color: AppColors.neutral.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Token de registro',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Solicita el token a tu administrador',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXS,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _tokenController,
                  label: 'Token',
                  hint: 'Pega el token aquí',
                  prefixIcon: Icons.vpn_key_outlined,
                  validator: FormValidators.validateRequired,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (deviceState.errorMessage != null) ...[
            AppInlineError(
              message: deviceState.errorMessage!,
              onDismiss: () => ref.read(deviceProvider.notifier).clearError(),
              dismissible: true,
            ),
            const SizedBox(height: 12),
          ],
          AppButton.primary(
            text: 'Registrar Dispositivo',
            onPressed: deviceState.isLoading ? null : _registerWithToken,
            isLoading: deviceState.isLoading,
            size: AppButtonSize.large,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeVerificationForm(DeviceState deviceState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Código enviado',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeM,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          deviceState.maskedEmail ?? 'a tu email',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeXS,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _codeController,
                label: 'Código de 6 dígitos',
                hint: '123456',
                prefixIcon: Icons.lock_outline,
                type: AppTextFieldType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'El código expira en 5 minutos',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (deviceState.errorMessage != null) ...[
          AppInlineError(
            message: deviceState.errorMessage!,
            onDismiss: () => ref.read(deviceProvider.notifier).clearError(),
            dismissible: true,
          ),
          const SizedBox(height: 12),
        ],
        AppButton.primary(
          text: 'Verificar',
          onPressed: deviceState.isLoading ? null : _verifyCode,
          isLoading: deviceState.isLoading,
          size: AppButtonSize.large,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _goBack,
          child: Text(
            'Volver',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildTokenFormAfterRequest(DeviceState deviceState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Usuario sin email',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeM,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Solicita un token de registro al administrador.',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _tokenController,
                label: 'Token',
                hint: 'Pega el token aquí',
                prefixIcon: Icons.vpn_key_outlined,
                validator: FormValidators.validateRequired,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (deviceState.errorMessage != null) ...[
          AppInlineError(
            message: deviceState.errorMessage!,
            onDismiss: () => ref.read(deviceProvider.notifier).clearError(),
            dismissible: true,
          ),
          const SizedBox(height: 12),
        ],
        AppButton.primary(
          text: 'Registrar con Token',
          onPressed: deviceState.isLoading ? null : _registerWithToken,
          isLoading: deviceState.isLoading,
          size: AppButtonSize.large,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _goBack,
          child: Text(
            'Volver',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(DeviceState deviceState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 48,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Dispositivo Registrado',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeL,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (deviceState.deviceName != null) ...[
            const SizedBox(height: 4),
            Text(
              deviceState.deviceName!,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: deviceState.isPersonal
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Text(
              deviceState.isPersonal ? 'Equipo personal' : 'Equipo compartido',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXS,
                fontWeight: FontWeight.w600,
                color: deviceState.isPersonal ? AppColors.primary : AppColors.warning,
              ),
            ),
          ),
          if (deviceState.user != null && deviceState.isPersonal) ...[
            const SizedBox(height: 8),
            Text(
              'Asignado a: ${deviceState.user!.fullName}',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              text: 'Continuar',
              onPressed: () => context.go('/login'),
              size: AppButtonSize.large,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(DeviceState deviceState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Error',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeL,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            deviceState.errorMessage ?? 'Error desconocido',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              text: 'Reintentar',
              onPressed: () => ref.read(deviceProvider.notifier).checkDeviceStatus(),
              size: AppButtonSize.large,
            ),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    ref.read(deviceProvider.notifier).backToRequestCode();
    _codeController.clear();
    _tokenController.clear();
  }

  Future<void> _requestCode() async {
    if (!_emailFormKey.currentState!.validate()) return;
    await ref.read(deviceProvider.notifier).requestCode(
      username: _usernameController.text.trim(),
    );
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 6) {
      ref.read(deviceProvider.notifier).setError('El código debe tener 6 dígitos');
      return;
    }
    await ref.read(deviceProvider.notifier).registerWithCode(
      _codeController.text.trim(),
    );
  }

  Future<void> _registerWithToken() async {
    // Verificar directamente el valor del controller
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ref.read(deviceProvider.notifier).setError('Ingresa el token');
      return;
    }
    await ref.read(deviceProvider.notifier).registerWithToken(token);
  }
}
