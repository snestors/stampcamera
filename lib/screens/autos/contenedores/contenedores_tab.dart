// screens/autos/contenedores/contenedores_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/contenedor_model.dart';
import 'package:stampcamera/providers/autos/contenedor_provider.dart';
import 'package:stampcamera/screens/autos/contenedores/contenedor_form.dart';
import 'package:stampcamera/theme/custom_colors.dart';

class ContenedoresTab extends ConsumerStatefulWidget {
  const ContenedoresTab({super.key});

  @override
  ConsumerState<ContenedoresTab> createState() => _ContenedoresTabState();
}

class _ContenedoresTabState extends ConsumerState<ContenedoresTab> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Cargar más cuando esté cerca del final
      // ref.read(contenedorProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contenedoresState = ref.watch(contenedorProvider);
    final notifier = ref.read(contenedorProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Header con búsqueda
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildSearchBar(notifier),
          ),

          // Lista de contenedores
          Expanded(
            child: contenedoresState.when(
              data: (contenedores) =>
                  _buildContenedoresList(contenedores, notifier),
              loading: () => _buildLoadingState(),
              error: (error, _) => _buildErrorState(error, notifier),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar(ContenedorNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: notifier.debouncedSearch,
        decoration: InputDecoration(
          hintText: 'Buscar por número de contenedor...',
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.secondary,
            size: AppDimensions.iconL,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    notifier.clearFilters();
                  },
                )
              : notifier.isSearching
              ? Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.all(AppDimensions.paddingM),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
            vertical: AppDimensions.paddingM,
          ),
        ),
      ),
    );
  }

  Widget _buildContenedoresList(
    List<ContenedorModel> contenedores,
    ContenedorNotifier notifier,
  ) {
    if (contenedores.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'No hay contenedores',
          subtitle:
              'No se encontraron contenedores que coincidan con tu búsqueda',
          color: AppColors.textSecondary,
          action: ElevatedButton.icon(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Crear Contenedor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: AppColors.secondary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        itemCount: contenedores.length,
        itemBuilder: (context, index) {
          final contenedor = contenedores[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
            child: _buildContenedorCard(contenedor),
          );
        },
      ),
    );
  }

  Widget _buildContenedorCard(ContenedorModel contenedor) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del contenedor
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: AppColors.secondary,
                  size: AppDimensions.iconL,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contenedor.nContenedor,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contenedor.naveDescarga,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, contenedor),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: AppColors.error),
                        SizedBox(width: 8),
                        Text(
                          'Eliminar',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.paddingM),

          // Información del contenedor
          if (contenedor.zonaInspeccion != null) ...[
            AppInfoRow(
              icon: Icons.location_on,
              label: 'Zona de Inspección',
              value: contenedor.zonaInspeccion!.value,
              color: AppColors.info,
            ),
            const SizedBox(height: AppDimensions.paddingS),
          ],

          // Precintos
          if (contenedor.precinto1 != null || contenedor.precinto2 != null) ...[
            Row(
              children: [
                if (contenedor.precinto1 != null) ...[
                  Expanded(
                    child: AppInfoRow(
                      icon: Icons.lock_outline,
                      label: 'Precinto 1',
                      value: contenedor.precinto1!,
                      color: AppColors.warning,
                    ),
                  ),
                ],
                if (contenedor.precinto1 != null &&
                    contenedor.precinto2 != null)
                  const SizedBox(width: AppDimensions.paddingM),
                if (contenedor.precinto2 != null) ...[
                  Expanded(
                    child: AppInfoRow(
                      icon: Icons.lock_outline,
                      label: 'Precinto 2',
                      value: contenedor.precinto2!,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppDimensions.paddingS),
          ],

          // Fotos disponibles
          Row(
            children: [
              _buildPhotoIndicator(
                'Contenedor',
                contenedor.hasContenedorPhoto,
                contenedor.imagenThumbnailUrl,
                contenedor.fotoContenedorUrl,
              ),
              const SizedBox(width: AppDimensions.paddingS),
              _buildPhotoIndicator(
                'Precinto 1',
                contenedor.hasPrecinto1Photo,
                contenedor.imagenThumbnailPrecintoUrl,
                contenedor.fotoPrecinto1Url,
              ),
              if (contenedor.hasPrecinto2Photo) ...[
                const SizedBox(width: AppDimensions.paddingS),
                _buildPhotoIndicator(
                  'Precinto 2',
                  contenedor.hasPrecinto2Photo,
                  contenedor.imagenThumbnailPrecinto2Url,
                  contenedor.fotoPrecinto2Url,
                ),
              ],
              if (contenedor.hasContenedorVacioPhoto) ...[
                const SizedBox(width: AppDimensions.paddingS),
                _buildPhotoIndicator(
                  'Vacío',
                  contenedor.hasContenedorVacioPhoto,
                  contenedor.imagenThumbnailContenedorVacioUrl,
                  contenedor.fotoContenedorVacioUrl,
                ),
              ],
            ],
          ),

          const SizedBox(height: AppDimensions.paddingS),

          // Footer con fecha y usuario
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: AppDimensions.iconS,
                color: AppColors.textLight,
              ),
              const SizedBox(width: 4),
              Text(
                contenedor.createAt,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Icon(
                Icons.person,
                size: AppDimensions.iconS,
                color: AppColors.textLight,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _extractUserName(contenedor.createBy),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoIndicator(
    String label,
    bool hasPhoto,
    String? thumbnailUrl,
    String? fullImageUrl,
  ) {
    if (!hasPhoto || thumbnailUrl == null || fullImageUrl == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(
            color: AppColors.textLight.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.camera_alt_outlined,
          size: AppDimensions.iconL,
          color: AppColors.textLight,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showImageModal(label, fullImageUrl),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS - 1),
          child: Image.network(
            thumbnailUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;

              return Container(
                color: AppColors.backgroundLight,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.secondary,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.error.withValues(alpha: 0.1),
                child: Icon(
                  Icons.error_outline,
                  size: AppDimensions.iconL,
                  color: AppColors.error,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showImageModal(String title, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header del modal
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusXL),
                    topRight: Radius.circular(AppDimensions.radiusXL),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.camera_alt,
                      color: AppColors.secondary,
                      size: AppDimensions.iconL,
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: Text(
                        'Foto: $title',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),

              // Imagen
              Flexible(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppDimensions.radiusXL),
                      bottomRight: Radius.circular(AppDimensions.radiusXL),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppDimensions.radiusXL),
                      bottomRight: Radius.circular(AppDimensions.radiusXL),
                    ),
                    child: InteractiveViewer(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;

                          return SizedBox(
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: AppColors.secondary,
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                        : null,
                                  ),
                                  const SizedBox(
                                    height: AppDimensions.paddingM,
                                  ),
                                  const Text(
                                    'Cargando imagen...',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return SizedBox(
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: AppColors.error,
                                    size: 48,
                                  ),
                                  const SizedBox(
                                    height: AppDimensions.paddingM,
                                  ),
                                  const Text(
                                    'Error al cargar imagen',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.secondary),
          SizedBox(height: AppDimensions.paddingL),
          Text(
            'Cargando contenedores...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, ContenedorNotifier notifier) {
    return Center(
      child: AppEmptyState(
        icon: Icons.error_outline,
        title: 'Error al cargar',
        subtitle: error.toString(),
        color: AppColors.error,
        action: ElevatedButton.icon(
          onPressed: notifier.refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  String _extractUserName(String fullUserInfo) {
    // Extrae solo el nombre del formato "Apellido, Nombre (email)"
    final parts = fullUserInfo.split('(');
    if (parts.isNotEmpty) {
      return parts[0].trim();
    }
    return fullUserInfo;
  }

  void _handleMenuAction(String action, ContenedorModel contenedor) {
    switch (action) {
      case 'editar':
        _showEditDialog(contenedor);
        break;
      case 'eliminar':
        _confirmDelete(contenedor);
        break;
    }
  }

  // Para crear nuevo contenedor (desde FAB o botón)
  void _showCreateDialog(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ContenedorForm()));
  }

  // Para editar contenedor existente (desde menú)
  void _showEditDialog(ContenedorModel contenedor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContenedorForm(contenedor: contenedor),
      ),
    );
  }

  void _confirmDelete(ContenedorModel contenedor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de eliminar el contenedor ${contenedor.nContenedor}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await ref
                  .read(contenedorProvider.notifier)
                  .deleteContenedor(contenedor.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Contenedor eliminado correctamente'
                          : 'Error al eliminar contenedor',
                    ),
                    backgroundColor: success
                        ? AppColors.success
                        : AppColors.error,
                  ),
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
