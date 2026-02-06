// =============================================================================
// EXPLORADOR SCREEN - Contenido de una carpeta (subcarpetas + archivos)
// =============================================================================
//
// Nivel 3: Contenido de la carpeta con acciones CRUD
// - Crear subcarpeta
// - Subir archivos
// - Selección múltiple
// - Cortar/Pegar
// - Eliminar
// - Usuarios conectados
// =============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/casos/explorador_models.dart';
import 'package:stampcamera/providers/app_socket_provider.dart';
import 'package:stampcamera/providers/casos/explorador_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ExploradorScreen extends ConsumerStatefulWidget {
  final int carpetaId;

  const ExploradorScreen({super.key, required this.carpetaId});

  @override
  ConsumerState<ExploradorScreen> createState() => _ExploradorScreenState();
}

class _ExploradorScreenState extends ConsumerState<ExploradorScreen> {
  double _uploadProgress = 0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exploradorProvider.notifier).loadContenidoCarpeta(widget.carpetaId);
      ref.read(appSocketProvider.notifier)
          .notifyRouteChange('/app/casos/${widget.carpetaId}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploradorProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(state),
      body: _buildBody(state),
      floatingActionButton: _buildFAB(state),
      bottomNavigationBar: state.hasSelection ? _buildSelectionBar(state) : null,
    );
  }

  // ─── AppBar ──────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(ExplorerState state) {
    final title = state.contenido?.carpetaPrincipal.nombre ?? 'Carpeta';

    if (state.hasSelection) {
      return AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => ref.read(exploradorProvider.notifier).clearSelection(),
        ),
        title: Text('${state.selectedItems.length} seleccionado(s)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: () => ref.read(exploradorProvider.notifier).selectAll(),
            tooltip: 'Seleccionar todo',
          ),
        ],
      );
    }

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (state.contenido?.caso != null)
            Text(
              state.contenido!.caso!.nCaso,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      actions: [
        // Usuarios conectados
        if (state.usuariosConectados.length > 1)
          _buildUsuariosConectados(state),
        // Indicador de conexión
        _buildConnectionDot(),
        // Menú
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(value, state),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'nueva_carpeta',
              child: ListTile(
                leading: Icon(Icons.create_new_folder),
                title: Text('Nueva carpeta'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'subir_archivos',
              child: ListTile(
                leading: Icon(Icons.upload_file),
                title: Text('Subir archivos'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            if (state.hasClipboard)
              PopupMenuItem(
                value: 'pegar',
                child: ListTile(
                  leading: const Icon(Icons.content_paste),
                  title: Text('Pegar (${state.clipboard!.count})'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionDot() {
    final socketState = ref.watch(appSocketProvider);
    final color = socketState.isConnected
        ? AppColors.success
        : socketState.isReconnecting
            ? Colors.orange
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }

  Widget _buildUsuariosConectados(ExplorerState state) {
    // Excluir usuario actual
    final otros = state.usuariosConectados.where((u) {
      // No podemos filtrar sin userId, mostramos todos
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _showUsuariosDialog(state),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people, size: 16, color: AppColors.info),
              const SizedBox(width: 4),
              Text(
                '${otros.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Body ────────────────────────────────────────────────────────────

  Widget _buildBody(ExplorerState state) {
    if (state.contenidoState == LoadingState.loading) {
      return const AppLoadingState(message: 'Cargando contenido...');
    }

    if (state.contenidoState == LoadingState.error) {
      return AppErrorState(
        message: state.errorMessage ?? 'Error al cargar',
        onRetry: () {
          ref.read(exploradorProvider.notifier)
              .loadContenidoCarpeta(widget.carpetaId);
        },
      );
    }

    if (state.contenido == null) {
      return const AppEmptyState(
        icon: Icons.folder_off_outlined,
        title: 'Sin contenido',
        subtitle: 'No se pudo cargar la carpeta',
      );
    }

    final contenido = state.contenido!;
    final subcarpetas = contenido.subcarpetas;
    final archivos = contenido.archivos;

    if (subcarpetas.isEmpty && archivos.isEmpty) {
      return _buildEmptyFolder(state);
    }

    // Upload progress
    return Column(
      children: [
        if (_isUploading) _buildUploadProgress(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(exploradorProvider.notifier)
                .loadContenidoCarpeta(widget.carpetaId),
            child: ListView(
              padding: EdgeInsets.all(DesignTokens.spaceM),
              children: [
                // Subcarpetas
                if (subcarpetas.isNotEmpty) ...[
                  _SectionTitle(
                    title: 'Carpetas',
                    count: subcarpetas.length,
                  ),
                  SizedBox(height: DesignTokens.spaceS),
                  ...subcarpetas.map((c) => _CarpetaItem(
                        carpeta: c,
                        isSelected: state.selectedItems.containsKey(c.id),
                        onTap: () {
                          if (state.hasSelection) {
                            ref.read(exploradorProvider.notifier)
                                .toggleSelection(c.id, 'carpeta');
                          } else {
                            context.push('/casos/explorador/${c.id}');
                          }
                        },
                        onLongPress: () {
                          ref.read(exploradorProvider.notifier)
                              .toggleSelection(c.id, 'carpeta');
                        },
                        onRestore: c.isDeleted
                            ? () => ref
                                .read(exploradorProvider.notifier)
                                .restaurarCarpeta(c.id)
                            : null,
                      )),
                  SizedBox(height: DesignTokens.spaceL),
                ],

                // Archivos
                if (archivos.isNotEmpty) ...[
                  _SectionTitle(
                    title: 'Archivos',
                    count: archivos.length,
                  ),
                  SizedBox(height: DesignTokens.spaceS),
                  ...archivos.map((a) => _ArchivoItem(
                        archivo: a,
                        isSelected: state.selectedItems.containsKey(a.id),
                        onTap: () {
                          if (state.hasSelection) {
                            ref.read(exploradorProvider.notifier)
                                .toggleSelection(a.id, 'archivo');
                          } else {
                            _openArchivo(a);
                          }
                        },
                        onLongPress: () {
                          ref.read(exploradorProvider.notifier)
                              .toggleSelection(a.id, 'archivo');
                        },
                        onRestore: a.isDeleted
                            ? () => ref
                                .read(exploradorProvider.notifier)
                                .restaurarArchivo(a.id)
                            : null,
                      )),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyFolder(ExplorerState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: AppColors.textLight,
          ),
          SizedBox(height: DesignTokens.spaceM),
          Text(
            'Carpeta vacía',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeL,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            'Crea una subcarpeta o sube archivos',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: AppColors.textLight,
            ),
          ),
          SizedBox(height: DesignTokens.spaceXL),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppButton(
                text: 'Nueva carpeta',
                icon: Icons.create_new_folder,
                onPressed: () => _showCrearCarpetaDialog(),
                size: AppButtonSize.small,
                isOutlined: true,
              ),
              SizedBox(width: DesignTokens.spaceM),
              AppButton.primary(
                text: 'Subir archivos',
                icon: Icons.upload_file,
                onPressed: () => _pickAndUploadFiles(),
                size: AppButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      color: AppColors.info.withValues(alpha: 0.1),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: DesignTokens.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subiendo archivos...',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppColors.neutral,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── FAB ─────────────────────────────────────────────────────────────

  Widget? _buildFAB(ExplorerState state) {
    if (state.hasSelection || _isUploading) return null;

    return FloatingActionButton(
      onPressed: () => _pickAndUploadFiles(),
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  // ─── Selection Bar ───────────────────────────────────────────────────

  Widget _buildSelectionBar(ExplorerState state) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM,
        vertical: DesignTokens.spaceS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.neutral)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: Icons.content_cut,
              label: 'Cortar',
              onTap: () {
                ref.read(exploradorProvider.notifier).cortarSeleccion();
                AppSnackBar.info(context, 'Elementos cortados');
              },
            ),
            _ActionButton(
              icon: Icons.delete_outline,
              label: 'Eliminar',
              color: Colors.red,
              onTap: () => _confirmarEliminar(state),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Acciones ────────────────────────────────────────────────────────

  void _handleMenuAction(String action, ExplorerState state) {
    switch (action) {
      case 'nueva_carpeta':
        _showCrearCarpetaDialog();
        break;
      case 'subir_archivos':
        _pickAndUploadFiles();
        break;
      case 'pegar':
        ref.read(exploradorProvider.notifier).pegar();
        break;
    }
  }

  void _showCrearCarpetaDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        title: Row(
          children: [
            Icon(Icons.create_new_folder, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Nueva carpeta'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nombre de la carpeta',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context);
              ref.read(exploradorProvider.notifier).crearCarpeta(value.trim());
            }
          },
        ),
        actions: [
          AppButton.ghost(
            text: 'Cancelar',
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(context),
          ),
          AppButton.primary(
            text: 'Crear',
            size: AppButtonSize.small,
            onPressed: () {
              final nombre = controller.text.trim();
              if (nombre.isNotEmpty) {
                Navigator.pop(context);
                ref.read(exploradorProvider.notifier).crearCarpeta(nombre);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      final files = result.paths
          .where((p) => p != null)
          .map((p) => File(p!))
          .toList();

      if (files.isEmpty) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });

      final response = await ref.read(exploradorProvider.notifier).uploadArchivos(
        files,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      setState(() => _isUploading = false);

      if (response != null && mounted) {
        if (response.totalErrores > 0) {
          AppSnackBar.warning(
            context,
            '${response.totalCreados} subido(s), ${response.totalErrores} error(es)',
          );
        } else {
          AppSnackBar.success(
            context,
            '${response.totalCreados} archivo(s) subido(s)',
          );
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        AppSnackBar.error(context, 'Error al subir archivos');
      }
    }
  }

  void _confirmarEliminar(ExplorerState state) async {
    final count = state.selectedItems.length;
    final confirmado = await AppDialog.confirm(
      context,
      title: 'Eliminar elementos',
      message: '¿Eliminar $count elemento${count > 1 ? 's' : ''} seleccionado${count > 1 ? 's' : ''}?',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
    );

    if (confirmado == true) {
      await ref.read(exploradorProvider.notifier).eliminarSeleccion();
      if (mounted) {
        AppSnackBar.success(context, 'Elementos eliminados');
      }
    }
  }

  void _openArchivo(Archivo archivo) {
    if (archivo.archivoUrl != null) {
      launchUrl(
        Uri.parse(archivo.archivoUrl!),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  void _showUsuariosDialog(ExplorerState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        title: Row(
          children: [
            Icon(Icons.people, color: AppColors.info),
            const SizedBox(width: 8),
            const Text('Usuarios conectados'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: state.usuariosConectados.length,
            itemBuilder: (context, index) {
              final u = state.usuariosConectados[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    u.nombre.isNotEmpty ? u.nombre[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(u.nombre.isNotEmpty ? u.nombre : u.username),
                subtitle: u.carpetaNombre != null
                    ? Text(
                        'En: ${u.carpetaNombre}',
                        style: TextStyle(fontSize: DesignTokens.fontSizeXS),
                      )
                    : null,
                dense: true,
              );
            },
          ),
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
}

// ─── Widgets ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.neutral,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CarpetaItem extends StatelessWidget {
  final Carpeta carpeta;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onRestore;

  const _CarpetaItem({
    required this.carpeta,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isDeleted = carpeta.isDeleted;

    return Card(
      margin: EdgeInsets.only(bottom: DesignTokens.spaceXS),
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.08)
          : isDeleted
              ? Colors.red.withValues(alpha: 0.05)
              : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: isSelected
            ? BorderSide(color: AppColors.primary, width: 1.5)
            : isDeleted
                ? BorderSide(color: Colors.red.withValues(alpha: 0.3))
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spaceM),
          child: Row(
            children: [
              Icon(
                Icons.folder,
                color: isDeleted
                    ? Colors.red.withValues(alpha: 0.5)
                    : Colors.amber[700],
                size: 28,
              ),
              SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carpeta.nombre,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        fontWeight: FontWeight.w500,
                        color: isDeleted
                            ? Colors.red[600]
                            : AppColors.textPrimary,
                        decoration:
                            isDeleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${carpeta.subcarpetasCount} carpetas, ${carpeta.archivosCount} archivos',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeXS * 0.9,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDeleted && onRestore != null)
                IconButton(
                  icon: const Icon(Icons.restore, color: Colors.green, size: 20),
                  onPressed: onRestore,
                  tooltip: 'Restaurar',
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textLight,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchivoItem extends StatelessWidget {
  final Archivo archivo;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onRestore;

  const _ArchivoItem({
    required this.archivo,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    this.onRestore,
  });

  IconData _getFileIcon() {
    if (archivo.isTemporary) return Icons.hourglass_top;
    if (archivo.esImagen) return Icons.image;
    if (archivo.esPdf) return Icons.picture_as_pdf;

    switch (archivo.extension.toLowerCase()) {
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor() {
    if (archivo.isTemporary) return Colors.grey;
    if (archivo.esImagen) return Colors.blue;
    if (archivo.esPdf) return Colors.red;

    switch (archivo.extension.toLowerCase()) {
      case 'doc':
      case 'docx':
        return Colors.blue[700]!;
      case 'xls':
      case 'xlsx':
        return Colors.green[700]!;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDeleted = archivo.isDeleted;

    return Card(
      margin: EdgeInsets.only(bottom: DesignTokens.spaceXS),
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.08)
          : isDeleted
              ? Colors.red.withValues(alpha: 0.05)
              : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: isSelected
            ? BorderSide(color: AppColors.primary, width: 1.5)
            : isDeleted
                ? BorderSide(color: Colors.red.withValues(alpha: 0.3))
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: archivo.isTemporary ? null : onTap,
        onLongPress: archivo.isTemporary ? null : onLongPress,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spaceM),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getFileColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileIcon(),
                  color: isDeleted
                      ? Colors.red.withValues(alpha: 0.5)
                      : _getFileColor(),
                  size: 22,
                ),
              ),
              SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      archivo.nombre,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        fontWeight: FontWeight.w400,
                        color: isDeleted
                            ? Colors.red[600]
                            : AppColors.textPrimary,
                        decoration:
                            isDeleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      archivo.isTemporary
                          ? 'Subiendo...'
                          : '${archivo.sizeDisplay} ${archivo.createdByName != null ? "- ${archivo.createdByName}" : ""}',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeXS * 0.9,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (archivo.isTemporary)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (isDeleted && onRestore != null)
                IconButton(
                  icon: const Icon(Icons.restore, color: Colors.green, size: 20),
                  onPressed: onRestore,
                  tooltip: 'Restaurar',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? AppColors.textPrimary, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color ?? AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
