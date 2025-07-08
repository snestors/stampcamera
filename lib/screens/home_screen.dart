import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stampcamera/providers/auth_provider.dart';
import 'package:stampcamera/widgets/connectivity_app_bar.dart';

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
      backgroundColor: const Color(0xFFF8FAFC), // Gris muy claro corporativo
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ✅ Header con información del usuario
            _buildUserHeader(authState),

            // ✅ Grid de aplicaciones
            _buildApplicationsGrid(context),

            // ✅ Footer informativo
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(AsyncValue authState) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF003B5C), // Color primario de tu empresa
            const Color(0xFF002A42), // Variación más oscura del primario
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003B5C).withValues(alpha: 0.3),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de sección
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Aplicaciones Disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),

          // Grid de aplicaciones
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9, // ✅ Aumentar un poco más la altura
            children: [
              _AppCard(
                title: 'Cámara',
                subtitle: 'Captura y gestiona fotos',
                icon: Icons.camera_alt,
                color: const Color(0xFF003B5C), // Color corporativo principal
                onTap: () =>
                    context.push('/camera', extra: {'camera': cameras.first}),
              ),
              _AppCard(
                title: 'Asistencia',
                subtitle: 'Registro de entrada y salida',
                icon: Icons.access_time,
                color: const Color(0xFF00B4D8), // Color secundario corporativo
                onTap: () => context.pushNamed('asistencia'),
              ),
              _AppCard(
                title: 'Autos',
                subtitle: 'Gestión de vehículos',
                icon: Icons.directions_car,
                color: const Color(0xFF1A5B75), // Variación del color primario
                onTap: () => context.push('/autos'),
              ),
              _AppCard(
                title: 'Próximamente',
                subtitle: 'Nuevas funcionalidades',
                icon: Icons.upcoming,
                color: const Color(0xFF6B7280), // Gris corporativo
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centro de Aplicaciones',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Accede a todas las herramientas desde aquí',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Cerrar Sesión'),
          ],
        ),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout(ref);
              if (!context.mounted) return;
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.upcoming, color: Colors.orange),
            SizedBox(width: 8),
            Text('Próximamente'),
          ],
        ),
        content: const Text('Esta funcionalidad estará disponible pronto.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGETS AUXILIARES
// ============================================================================

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
          ? Colors.grey.withValues(alpha: 0.2)
          : color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isDisabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(16), // ✅ Reducir padding
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDisabled
                      ? Colors.grey.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isDisabled ? Colors.grey : color,
                ),
              ),
              const SizedBox(height: 8), // ✅ Reducir espacio
              Text(
                title,
                style: TextStyle(
                  fontSize: 15, // ✅ Reducir un poco el tamaño
                  fontWeight: FontWeight.bold,
                  color: isDisabled ? Colors.grey : Colors.grey[800],
                ),
                textAlign: TextAlign.center,
                maxLines: 1, // ✅ Solo una línea para el título
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2), // ✅ Reducir espacio
              Flexible(
                // ✅ Usar Flexible en lugar de texto directo
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11, // ✅ Reducir tamaño del subtítulo
                    color: isDisabled ? Colors.grey : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
    // ✅ Usar propiedades correctas del UserModel
    final displayName = _getDisplayName(user);
    final userEmail = user.email ?? '';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _getUserInitials(user),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¡Bienvenido!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (userEmail.isNotEmpty)
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        Icon(
          Icons.waving_hand,
          color: const Color.fromARGB(
            255,
            221,
            239,
            32,
          ), // Color secundario corporativo
          size: 24,
        ),
      ],
    );
  }

  String _getDisplayName(dynamic user) {
    // Combinar firstName y lastName, o usar username como fallback
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
    return const Row(
      children: [
        CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        SizedBox(width: 16),
        Text(
          'Cargando información...',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}

class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.home, color: Colors.white, size: 32),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Bienvenido!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Centro de aplicaciones corporativas',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
