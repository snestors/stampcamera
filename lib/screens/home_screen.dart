import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/auth_provider.dart';
import 'package:stampcamera/providers/biometric_provider.dart';
import 'package:stampcamera/widgets/biometric_setup_widget.dart';

import '../main.dart'; // Para acceder a `cameras`

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildUserHeader(authState),
                _buildApplicationsGrid(context),
                _buildFooter(),
              ],
            ),
          ),
          // Widget para manejar configuración de biometría
          const BiometricSetupWidget(),
        ],
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
    final cards = <Widget>[];

    for (final module in modules) {
      cards.add(_buildModuleCard(context, module));
    }

    // Agregar card de "Próximamente" si hay espacio
    if (cards.length % 2 != 0 || cards.length < 4) {
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

  /// Construye una card para un módulo específico
  Widget _buildModuleCard(BuildContext context, dynamic module) {
    final moduleConfig = _getModuleConfig(module.id);

    return _AppCard(
      title: module.name,
      subtitle: moduleConfig.subtitle,
      icon: moduleConfig.icon,
      color: moduleConfig.color,
      onTap: () => _navigateToModule(context, module.id),
      isDisabled: !module.isEnabled,
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
          icon: Icons.agriculture,
          color: AppColors.warning,
          subtitle: 'Gestión de granos',
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
  void _navigateToModule(BuildContext context, String moduleId) {
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
        // Módulo en desarrollo
        _showComingSoonDialog(context);
        break;
      default:
        _showComingSoonDialog(context);
    }
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
          title: 'Próximamente',
          subtitle: 'Nuevas funcionalidades',
          icon: Icons.upcoming,
          color: AppColors.textSecondary,
          onTap: () => _showComingSoonDialog(context),
          isDisabled: true,
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
    final biometricState = ref.read(biometricProvider);

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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Estás seguro de que quieres cerrar sesión?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              if (biometricState.isEnabled) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.fingerprint, color: Colors.orange, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Datos Biométricos',
                              style: TextStyle(
                                fontSize: DesignTokens.fontSizeXS,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                            Text(
                              'Credenciales guardadas',
                              style: TextStyle(
                                fontSize: DesignTokens.fontSizeXS,
                                color: Colors.orange[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (biometricState.isEnabled) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              child: AppButton.secondary(
                text: 'Limpiar Biométrico',
                size: AppButtonSize.small,
                onPressed: () {
                  Navigator.pop(context);
                  _showClearBiometricOnLogoutDialog(context);
                },
              ),
            ),
          ],
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: AppButton.ghost(
                    size: AppButtonSize.small,
                    text: 'Cancelar',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton.error(
                    text: 'Cerrar Sesión',
                    size: AppButtonSize.small,
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(authProvider.notifier).logout(ref);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearBiometricOnLogoutDialog(BuildContext context) {
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
              child: const Icon(
                Icons.fingerprint_outlined,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Limpiar y Cerrar Sesión'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Se eliminarán los datos biométricos y se cerrará la sesión.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              'Esta acción eliminará:',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Credenciales guardadas para biometría\n'
              '• Configuración de acceso biométrico\n'
              '• Sesión actual del usuario',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Podrás reconfigurar la biometría en el próximo login',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeXS,
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
          AppButton.secondary(
            text: 'Limpiar y Cerrar',
            size: AppButtonSize.small,
            onPressed: () async {
              Navigator.pop(context);
              await _clearBiometricAndLogout();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _clearBiometricAndLogout() async {
    try {
      // Primero limpiar biometría
      await ref.read(biometricProvider.notifier).clearAll();

      // Luego hacer logout
      ref.read(authProvider.notifier).logout(ref);

      if (mounted) {
        AppSnackBar.success(context, 'Biometría eliminada y sesión cerrada');
      }
    } catch (e) {
      // Si falla la limpieza de biometría, igual hacer logout
      ref.read(authProvider.notifier).logout(ref);

      if (mounted) {
        AppSnackBar.warning(context, 'Sesión cerrada (error limpiando biometría)');
      }
    }
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
    final biometricState = ref.read(biometricProvider);

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
            if (biometricState.isEnabled) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fingerprint_outlined,
                    color: Colors.orange,
                  ),
                ),
                title: const Text('Limpiar Datos Biométricos'),
                subtitle: const Text(
                  'Eliminar credenciales guardadas para biometría',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showClearBiometricDialog(context);
                },
              ),
              const Divider(),
            ],
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

  void _showClearBiometricDialog(BuildContext context) {
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
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Limpiar Biometría'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro de que quieres eliminar los datos biométricos?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta acción eliminará permanentemente:',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Credenciales guardadas para biometría\n'
              '• Configuración de acceso biométrico\n'
              '• Tendrás que volver a configurar la biometría',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
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
          AppButton.secondary(
            text: 'Limpiar Datos',
            size: AppButtonSize.small,
            onPressed: () async {
              Navigator.pop(context);
              await _clearBiometricData();
            },
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

  Future<void> _clearBiometricData() async {
    try {
      await ref.read(biometricProvider.notifier).clearAll();

      if (mounted) {
        AppSnackBar.success(context, 'Datos biométricos eliminados correctamente');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Error al eliminar datos: $e');
      }
    }
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

  const _AppCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isDisabled ? 1 : 4,
      shadowColor: isDisabled
          ? AppColors.neutral.withValues(alpha: 0.2)
          : color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        onTap: isDisabled ? null : onTap,
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spaceS),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
            gradient: isDisabled
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.1),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceL),
                decoration: BoxDecoration(
                  color: isDisabled
                      ? AppColors.neutral.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                ),
                child: Icon(
                  icon,
                  size: DesignTokens.iconXXXL * 1.4,
                  color: isDisabled ? AppColors.textLight : color,
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
                  color: isDisabled
                      ? AppColors.textLight
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
    final userEmail = user.email ?? '';

    return Row(
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
                  fontSize: DesignTokens.fontSizeL,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (userEmail.isNotEmpty)
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: DesignTokens.fontSizeXS,
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
