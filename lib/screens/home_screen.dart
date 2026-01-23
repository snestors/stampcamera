import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/auth_provider.dart';
import 'package:stampcamera/services/biometric_service.dart';

import '../main.dart'; // Para acceder a `cameras`

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Verificar si hay configuración biométrica pendiente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingBiometricSetup();
    });
  }

  Future<void> _checkPendingBiometricSetup() async {
    final biometricService = BiometricService();
    final pendingPassword = biometricService.consumePendingPassword();

    if (pendingPassword == null) return;

    // Si ya está habilitado, solo actualizar la contraseña silenciosamente
    final isEnabled = await biometricService.isBiometricEnabled();
    if (isEnabled) {
      await biometricService.enableBiometric(pendingPassword);
      return;
    }

    // Primera vez: preguntar si quiere habilitar biométrico
    if (!mounted) return;
    final shouldEnable = await AppDialog.confirm(
      context,
      title: 'Acceso biométrico',
      message:
          '¿Deseas habilitar el acceso con huella/rostro para iniciar sesión más rápido?',
      confirmText: 'Habilitar',
      cancelText: 'Ahora no',
    );

    if (shouldEnable == true) {
      await biometricService.enableBiometric(pendingPassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Aplicaciones',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.settings, color: AppColors.primary, size: 20),
              ),
              onPressed: () => _showSettingsDialog(context),
              tooltip: 'Configuración',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.logout, color: Colors.red, size: 20),
              ),
              onPressed: () => _showLogoutDialog(context),
              tooltip: 'Cerrar sesión',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUserHeader(authState),
            _buildApplicationsGrid(context),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(AsyncValue authState) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(DesignTokens.spaceL),
      padding: EdgeInsets.all(DesignTokens.spaceXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: authState.when(
        data: (auth) {
          if (!auth.isLoggedIn || auth.user == null) {
            return const _WelcomeMessage();
          }
          return _UserInfo(user: auth.user!);
        },
        loading: () => const _LoadingUserInfo(),
        error: (e, _) => const _WelcomeMessage(),
      ),
    );
  }

  Widget _buildApplicationsGrid(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: DesignTokens.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: DesignTokens.spaceXS,
              bottom: DesignTokens.spaceXS,
            ),
            child: Text(
              'Aplicaciones Disponibles',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeL,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          authState.when(
            data: (auth) {
              if (!auth.isLoggedIn || auth.user == null) {
                return _buildDefaultGrid(context);
              }
              return _buildModulesGrid(context, auth.user!);
            },
            loading: () => _buildDefaultGrid(context),
            error: (e, st) => _buildDefaultGrid(context),
          ),
        ],
      ),
    );
  }

  /// Grid de módulos basado en permisos del usuario
  Widget _buildModulesGrid(BuildContext context, dynamic user) {
    final modules = user.availableModules;

    // Si el usuario no tiene módulos disponibles (clientes externos)
    if (modules.isEmpty) {
      return _buildNoAccessMessage();
    }

    final cards = <Widget>[];

    for (final module in modules) {
      cards.add(_buildModuleCard(context, module, user));
    }

    // Agregar cards de "Próximamente" para completar mínimo 4 y siempre número par
    while (cards.length < 4 || cards.length % 2 != 0) {
      cards.add(_AppCard(
        title: 'Próximamente',
        subtitle: 'Nuevas funcionalidades',
        icon: Icons.upcoming,
        color: AppColors.textSecondary,
        onTap: () => _showComingSoonDialog(context),
        isDisabled: true,
      ));
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: cards,
    );
  }

  /// Mensaje cuando el usuario no tiene acceso a la app móvil
  Widget _buildNoAccessMessage() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceXL),
      margin: EdgeInsets.symmetric(vertical: DesignTokens.spaceL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.web,
            size: 64,
            color: AppColors.warning,
          ),
          SizedBox(height: DesignTokens.spaceM),
          Text(
            'Acceso Solo Web',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeL,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            'Tu cuenta está configurada para acceso web únicamente. '
            'Para usar la aplicación móvil, contacta al administrador.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una card para un módulo específico
  Widget _buildModuleCard(BuildContext context, dynamic module, dynamic user) {
    final moduleConfig = _getModuleConfig(module.id);
    final isBlocked = user.isModuleBlocked(module.id);

    return _AppCard(
      title: module.name,
      subtitle: isBlocked
          ? 'Requiere asistencia activa'
          : moduleConfig.subtitle,
      icon: moduleConfig.icon,
      color: moduleConfig.color,
      onTap: () => _navigateToModule(context, module.id, user),
      isDisabled: !module.isEnabled,
      isBlocked: isBlocked,
    );
  }

  /// Configuración visual de cada módulo
  _ModuleConfig _getModuleConfig(String moduleId) {
    switch (moduleId) {
      case 'camera':
        return _ModuleConfig(
          icon: Icons.camera_alt,
          color: AppColors.primary,
          subtitle: 'Captura y gestiona fotos',
        );
      case 'asistencia':
        return _ModuleConfig(
          icon: Icons.access_time,
          color: AppColors.secondary,
          subtitle: 'Registro de entrada y salida',
        );
      case 'autos':
        return _ModuleConfig(
          icon: Icons.directions_car,
          color: AppColors.accent,
          subtitle: 'Gestión de vehículos',
        );
      case 'granos':
        return _ModuleConfig(
          icon: Icons.directions_boat,
          color: AppColors.warning,
          subtitle: 'Gestión de graneles',
        );
      default:
        return _ModuleConfig(
          icon: Icons.apps,
          color: AppColors.textSecondary,
          subtitle: 'Módulo disponible',
        );
    }
  }

  /// Navega al módulo seleccionado
  void _navigateToModule(BuildContext context, String moduleId, dynamic user) {
    // Verificar si el módulo está bloqueado por falta de asistencia
    if (user.isModuleBlocked(moduleId)) {
      _showAsistenciaRequiredDialog(context);
      return;
    }

    switch (moduleId) {
      case 'camera':
        context.push('/camera', extra: {'camera': cameras.first});
        break;
      case 'asistencia':
        context.pushNamed('asistencia');
        break;
      case 'autos':
        context.push('/autos');
        break;
      case 'granos':
        context.push('/graneles');
        break;
      default:
        _showComingSoonDialog(context);
    }
  }

  /// Muestra diálogo indicando que se requiere asistencia activa
  void _showAsistenciaRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.access_time, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Text('Asistencia Requerida'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para acceder a este módulo necesitas tener una asistencia activa.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: DesignTokens.spaceM),
            Container(
              padding: EdgeInsets.all(DesignTokens.spaceM),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  SizedBox(width: DesignTokens.spaceS),
                  Expanded(
                    child: Text(
                      'Ve a "Asistencia" y marca tu entrada para habilitar este módulo.',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
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
          AppButton.ghost(
            text: 'Cancelar',
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(context),
          ),
          AppButton.primary(
            text: 'Ir a Asistencia',
            size: AppButtonSize.small,
            onPressed: () {
              Navigator.pop(context);
              context.pushNamed('asistencia');
            },
          ),
        ],
      ),
    );
  }

  /// Grid por defecto (sin autenticación o error)
  Widget _buildDefaultGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: [
        _AppCard(
          title: 'Cámara',
          subtitle: 'Captura y gestiona fotos',
          icon: Icons.camera_alt,
          color: AppColors.primary,
          onTap: () =>
              context.push('/camera', extra: {'camera': cameras.first}),
        ),
        _AppCard(
          title: 'Asistencia',
          subtitle: 'Registro de entrada y salida',
          icon: Icons.access_time,
          color: AppColors.secondary,
          onTap: () => context.pushNamed('asistencia'),
        ),
        _AppCard(
          title: 'Autos',
          subtitle: 'Gestión de vehículos',
          icon: Icons.directions_car,
          color: AppColors.accent,
          onTap: () => context.push('/autos'),
        ),
        _AppCard(
          title: 'Graneles',
          subtitle: 'Gestión de graneles',
          icon: Icons.directions_boat,
          color: AppColors.warning,
          onTap: () => context.push('/graneles'),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      margin: EdgeInsets.all(DesignTokens.spaceS),
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(color: AppColors.neutral),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.info,
            size: DesignTokens.iconM,
          ),
          SizedBox(width: DesignTokens.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centro de Aplicaciones',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Accede a todas las herramientas desde aquí',
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
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Cerrar Sesión'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          AppButton.ghost(
            size: AppButtonSize.small,
            text: 'Cancelar',
            onPressed: () => Navigator.pop(context),
          ),
          AppButton.error(
            text: 'Cerrar Sesión',
            size: AppButtonSize.small,
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout(ref);
            },
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    AppDialog.info(
      context,
      title: 'Próximamente',
      message: 'Esta funcionalidad estará disponible en una próxima actualización.',
      buttonText: 'Entendido',
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        title: Row(
          children: [
            Icon(Icons.settings, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Configuración'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info_outline, color: AppColors.info),
              ),
              title: const Text('Acerca de'),
              subtitle: const Text('Información de la aplicación'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
          ],
        ),
        actions: [
          AppButton.ghost(
            text: 'Cerrar',
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info_outline, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Text('Acerca de'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A&G Inspección Vehicular',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeL,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aplicación para gestión de vehículos con cámara de sellos.',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.business, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'A&G Logistics',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          AppButton.primary(
            text: 'Cerrar',
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

}

// Widgets auxiliares
class _AppCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDisabled;
  final bool isBlocked;

  const _AppCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isDisabled = false,
    this.isBlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isBlocked ? Colors.orange : color;
    final isInactive = isDisabled || isBlocked;

    return Card(
      elevation: isInactive ? 1 : 4,
      shadowColor: isInactive
          ? AppColors.neutral.withValues(alpha: 0.2)
          : effectiveColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        side: isBlocked
            ? BorderSide(color: Colors.orange.withValues(alpha: 0.5), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        onTap: isDisabled ? null : onTap, // Bloqueado aún permite tap para mostrar diálogo
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spaceS),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
            gradient: isDisabled
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isBlocked
                        ? [
                            Colors.orange.withValues(alpha: 0.08),
                            Colors.orange.withValues(alpha: 0.03),
                          ]
                        : [
                            color.withValues(alpha: 0.1),
                            color.withValues(alpha: 0.05),
                          ],
                  ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Container(
                    padding: EdgeInsets.all(DesignTokens.spaceL),
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? AppColors.neutral.withValues(alpha: 0.2)
                          : effectiveColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                    ),
                    child: Icon(
                      icon,
                      size: DesignTokens.iconXXXL * 1.4,
                      color: isDisabled ? AppColors.textLight : effectiveColor,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spaceS),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeRegular,
                      fontWeight: FontWeight.bold,
                      color: isDisabled
                          ? AppColors.textLight
                          : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: DesignTokens.spaceXS),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeXS * 0.9,
                      color: isBlocked
                          ? Colors.orange[700]
                          : (isDisabled
                              ? AppColors.textLight
                              : AppColors.textSecondary),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Icono de candado para módulos bloqueados
              if (isBlocked)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserInfo extends StatelessWidget {
  final dynamic user;

  const _UserInfo({required this.user});

  @override
  Widget build(BuildContext context) {
    final displayName = _getDisplayName(user);
    final userInitials = _getUserInitials(user);
    final hasAsistencia = user.hasActiveAsistencia ?? false;
    final asistencia = user.ultimaAsistenciaActiva;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: Center(
                child: Text(
                  userInitials,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: DesignTokens.spaceL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: DesignTokens.fontSizeS,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: DesignTokens.fontSizeM,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.waving_hand,
              color: AppColors.warning,
              size: DesignTokens.iconL,
            ),
          ],
        ),
        // Estado de asistencia
        SizedBox(height: DesignTokens.spaceM),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceM,
            vertical: DesignTokens.spaceS,
          ),
          decoration: BoxDecoration(
            color: hasAsistencia
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.orange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: hasAsistencia
                  ? Colors.green.withValues(alpha: 0.5)
                  : Colors.orange.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasAsistencia ? Icons.check_circle : Icons.access_time,
                color: hasAsistencia ? Colors.green[300] : Colors.orange[300],
                size: 16,
              ),
              SizedBox(width: DesignTokens.spaceS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasAsistencia ? 'Asistencia Activa' : 'Sin Asistencia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: DesignTokens.fontSizeXS,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasAsistencia && asistencia != null) ...[
                      Text(
                        '${asistencia.zonaTrabajoNombre ?? ""}${asistencia.horasTrabajadasDisplay != null ? " - ${asistencia.horasTrabajadasDisplay}" : ""}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: DesignTokens.fontSizeXS * 0.9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      Text(
                        'Marca entrada para acceder a todos los módulos',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: DesignTokens.fontSizeXS * 0.9,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDisplayName(dynamic user) {
    final firstName = user.firstName ?? '';
    final lastName = user.lastName ?? '';
    final username = user.username ?? 'Usuario';

    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }

    return username;
  }

  String _getUserInitials(dynamic user) {
    final firstName = user.firstName ?? '';
    final lastName = user.lastName ?? '';
    final username = user.username ?? 'U';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if (username.isNotEmpty) {
      return username[0].toUpperCase();
    }

    return 'U';
  }
}

class _LoadingUserInfo extends StatelessWidget {
  const _LoadingUserInfo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        SizedBox(width: DesignTokens.spaceL),
        Text(
          'Cargando información...',
          style: TextStyle(
            color: Colors.white,
            fontSize: DesignTokens.fontSizeRegular,
          ),
        ),
      ],
    );
  }
}

class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.home, color: Colors.white, size: DesignTokens.iconXL),
        SizedBox(width: DesignTokens.spaceL),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Bienvenido!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: DesignTokens.fontSizeL,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Accede a todas las herramientas disponibles',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: DesignTokens.fontSizeS,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Configuración visual de un módulo
class _ModuleConfig {
  final IconData icon;
  final Color color;
  final String subtitle;

  const _ModuleConfig({
    required this.icon,
    required this.color,
    required this.subtitle,
  });
}
