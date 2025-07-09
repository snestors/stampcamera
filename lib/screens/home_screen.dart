import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/auth_provider.dart';
import 'package:stampcamera/widgets/connectivity_app_bar.dart';
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
      appBar: ConnectivityAppBarWithDetails(
        title: const Text(
          'Aplicaciones',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
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
          GridView.count(
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
          ),
        ],
      ),
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
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        title: const Text('Próximamente'),
        content: const Text(
          'Esta funcionalidad estará disponible en una próxima actualización.',
        ),
        actions: [
          AppButton.primary(
            text: 'Entendido',
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
          padding: EdgeInsets.all(DesignTokens.spaceL),
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
                  size: DesignTokens.iconXXXL,
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
                  fontSize: DesignTokens.fontSizeXS,
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
