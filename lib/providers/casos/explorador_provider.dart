// =============================================================================
// EXPLORADOR PROVIDER - Estado del Explorador de Archivos
// =============================================================================
//
// Maneja: navegación jerárquica, selección, clipboard, WebSocket sync,
// usuarios conectados, carga y error states.
// =============================================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/casos/explorador_models.dart';
import 'package:stampcamera/providers/app_socket_provider.dart';
import 'package:stampcamera/providers/auth_provider.dart';
import 'package:stampcamera/services/app_socket_service.dart';
import 'package:stampcamera/services/casos_service.dart';

// ─── Enums de UI ───────────────────────────────────────────────────────

enum ViewMode { list, grid }

enum LoadingState { initial, loading, success, error }

// ─── Clipboard ─────────────────────────────────────────────────────────

class ClipboardData {
  final Map<int, String> items; // id -> 'archivo' | 'carpeta'
  final int sourceCarpetaId;

  const ClipboardData({
    required this.items,
    required this.sourceCarpetaId,
  });

  List<int> get archivoIds => items.entries
      .where((e) => e.value == 'archivo')
      .map((e) => e.key)
      .toList();

  List<int> get carpetaIds => items.entries
      .where((e) => e.value == 'carpeta')
      .map((e) => e.key)
      .toList();

  bool get isEmpty => items.isEmpty;
  int get count => items.length;
}

// ─── Estado principal ──────────────────────────────────────────────────

class ExplorerState {
  // Nivel actual
  final String? selectedRubro; // null = inicio (rubros), nombre = carpetas del rubro
  final int? currentCarpetaId; // null = lista de carpetas raíz

  // Datos
  final List<Carpeta> carpetasRaiz;
  final CarpetaContenidoResponse? contenido;
  final List<RubroGroup> rubros;

  // Loading
  final LoadingState carpetasState;
  final LoadingState contenidoState;
  final String? errorMessage;

  // UI
  final ViewMode viewMode;
  final String searchQuery;
  final Map<int, String> selectedItems; // id -> 'archivo' | 'carpeta'
  final ClipboardData? clipboard;
  final bool showDeleted; // solo superadmin

  // WebSocket
  final List<UsuarioConectado> usuariosConectados;

  // Navegación (breadcrumbs)
  final List<BreadcrumbItem> breadcrumbs;

  // Upload queue
  final List<UploadQueueItem> uploadQueue;

  const ExplorerState({
    this.selectedRubro,
    this.currentCarpetaId,
    this.carpetasRaiz = const [],
    this.contenido,
    this.rubros = const [],
    this.carpetasState = LoadingState.initial,
    this.contenidoState = LoadingState.initial,
    this.errorMessage,
    this.viewMode = ViewMode.list,
    this.searchQuery = '',
    this.selectedItems = const {},
    this.clipboard,
    this.showDeleted = false,
    this.usuariosConectados = const [],
    this.breadcrumbs = const [],
    this.uploadQueue = const [],
  });

  ExplorerState copyWith({
    String? selectedRubro,
    bool clearSelectedRubro = false,
    int? currentCarpetaId,
    bool clearCurrentCarpeta = false,
    List<Carpeta>? carpetasRaiz,
    CarpetaContenidoResponse? contenido,
    bool clearContenido = false,
    List<RubroGroup>? rubros,
    LoadingState? carpetasState,
    LoadingState? contenidoState,
    String? errorMessage,
    bool clearError = false,
    ViewMode? viewMode,
    String? searchQuery,
    Map<int, String>? selectedItems,
    ClipboardData? clipboard,
    bool clearClipboard = false,
    bool? showDeleted,
    List<UsuarioConectado>? usuariosConectados,
    List<BreadcrumbItem>? breadcrumbs,
    List<UploadQueueItem>? uploadQueue,
  }) {
    return ExplorerState(
      selectedRubro:
          clearSelectedRubro ? null : (selectedRubro ?? this.selectedRubro),
      currentCarpetaId: clearCurrentCarpeta
          ? null
          : (currentCarpetaId ?? this.currentCarpetaId),
      carpetasRaiz: carpetasRaiz ?? this.carpetasRaiz,
      contenido: clearContenido ? null : (contenido ?? this.contenido),
      rubros: rubros ?? this.rubros,
      carpetasState: carpetasState ?? this.carpetasState,
      contenidoState: contenidoState ?? this.contenidoState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      viewMode: viewMode ?? this.viewMode,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedItems: selectedItems ?? this.selectedItems,
      clipboard: clearClipboard ? null : (clipboard ?? this.clipboard),
      showDeleted: showDeleted ?? this.showDeleted,
      usuariosConectados: usuariosConectados ?? this.usuariosConectados,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      uploadQueue: uploadQueue ?? this.uploadQueue,
    );
  }

  bool get isAtRoot => currentCarpetaId == null;
  bool get hasSelection => selectedItems.isNotEmpty;
  bool get hasClipboard => clipboard != null && !clipboard!.isEmpty;

  // Upload queue getters
  bool get isUploading => uploadQueue.any((i) =>
      i.status == UploadStatus.pending || i.status == UploadStatus.uploading);
  int get uploadsTotal => uploadQueue.length;
  int get uploadsCompleted =>
      uploadQueue.where((i) => i.status == UploadStatus.completed).length;
  int get uploadsFailed =>
      uploadQueue.where((i) => i.status == UploadStatus.error).length;
  double get uploadTotalProgress {
    if (uploadQueue.isEmpty) return 0;
    return uploadQueue.map((i) => i.progress).reduce((a, b) => a + b) /
        uploadQueue.length;
  }

  /// Carpetas del rubro seleccionado
  List<Carpeta> get carpetasDelRubro {
    if (selectedRubro == null) return [];
    return carpetasRaiz
        .where((c) =>
            (c.casoInfo?.rubroNombre ?? 'Sin Rubro') == selectedRubro)
        .toList();
  }
}

class BreadcrumbItem {
  final int? carpetaId;
  final String label;

  const BreadcrumbItem({this.carpetaId, required this.label});
}

// ─── Provider ──────────────────────────────────────────────────────────

final exploradorProvider =
    StateNotifierProvider<ExploradorNotifier, ExplorerState>((ref) {
  return ExploradorNotifier(ref);
});

// ─── Notifier ──────────────────────────────────────────────────────────

class ExploradorNotifier extends StateNotifier<ExplorerState> {
  final Ref _ref;
  final CasosService _service = CasosService();
  StreamSubscription<AppSocketEvent>? _wsSub;
  int? _currentUserId;

  // Upload queue
  static const int _maxConcurrentUploads = 15;
  int _activeUploads = 0;
  final Map<String, File> _queuedFiles = {};

  ExploradorNotifier(this._ref) : super(const ExplorerState()) {
    _initUserId();
    _listenWebSocket();
  }

  // ─── Inicialización ──────────────────────────────────────────────────

  void _initUserId() {
    final authState = _ref.read(authProvider);
    _currentUserId = authState.value?.user?.id;
  }

  void _listenWebSocket() {
    final service = _ref.read(appSocketServiceProvider);
    _wsSub = service.eventStream.listen(
      _handleWsEvent,
      onError: (e) => debugPrint('ExploradorProvider WS error: $e'),
    );

    // Escuchar reconexiones para re-suscribir carpeta actual
    service.connectionStateStream.listen((wsState) {
      if (wsState == WsConnectionState.connected && state.currentCarpetaId != null) {
        final nombre = _findCarpetaName(state.currentCarpetaId!);
        service.sendCambiarCarpeta(state.currentCarpetaId!, nombre ?? '');
      }
    });
  }

  // ─── Carga de datos ──────────────────────────────────────────────────

  /// Cargar carpetas raíz y agrupar por rubro
  Future<void> loadCarpetasRaiz() async {
    // Suscribir al canal 'casos' para recibir eventos WebSocket
    _ref.read(appSocketProvider.notifier).subscribe('casos');

    state = state.copyWith(carpetasState: LoadingState.loading, clearError: true);

    try {
      final carpetas = await _service.getCarpetasRaiz();

      // Agrupar por rubro
      final rubroMap = <String, List<Carpeta>>{};
      for (final c in carpetas) {
        final rubro = c.casoInfo?.rubroNombre ?? 'Sin Rubro';
        rubroMap.putIfAbsent(rubro, () => []).add(c);
      }

      final rubros = rubroMap.entries
          .map((e) => RubroGroup(
                nombre: e.key,
                count: e.value.length,
                carpetas: e.value,
              ))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));

      state = state.copyWith(
        carpetasRaiz: carpetas,
        rubros: rubros,
        carpetasState: LoadingState.success,
      );
    } catch (e) {
      debugPrint('Error cargando carpetas raiz: $e');
      state = state.copyWith(
        carpetasState: LoadingState.error,
        errorMessage: 'Error al cargar carpetas',
      );
    }
  }

  /// Cargar contenido de una carpeta
  Future<void> loadContenidoCarpeta(int carpetaId) async {
    state = state.copyWith(
      contenidoState: LoadingState.loading,
      currentCarpetaId: carpetaId,
      selectedItems: {},
      clearError: true,
    );

    // Notificar al WebSocket
    final socketService = _ref.read(appSocketServiceProvider);
    if (socketService.isConnected) {
      final carpetaNombre = _findCarpetaName(carpetaId);
      socketService.sendCambiarCarpeta(carpetaId, carpetaNombre ?? '');
    }

    try {
      final contenido = await _service.getContenidoCarpeta(
        carpetaId,
        showDeleted: state.showDeleted,
      );

      // Construir breadcrumbs
      final breadcrumbs = _buildBreadcrumbs(contenido.carpetaPrincipal);

      state = state.copyWith(
        contenido: contenido,
        contenidoState: LoadingState.success,
        breadcrumbs: breadcrumbs,
      );
    } catch (e) {
      debugPrint('Error cargando contenido carpeta $carpetaId: $e');
      state = state.copyWith(
        contenidoState: LoadingState.error,
        errorMessage: 'Error al cargar contenido',
      );
    }
  }

  // ─── Navegación ──────────────────────────────────────────────────────

  /// Seleccionar un rubro (nivel 1 -> nivel 2)
  void selectRubro(String rubroNombre) {
    state = state.copyWith(
      selectedRubro: rubroNombre,
      clearCurrentCarpeta: true,
      clearContenido: true,
      selectedItems: {},
    );
  }

  /// Volver al inicio (rubros)
  void goToInicio() {
    state = state.copyWith(
      clearSelectedRubro: true,
      clearCurrentCarpeta: true,
      clearContenido: true,
      selectedItems: {},
      breadcrumbs: [],
    );
  }

  /// Volver al listado de carpetas del rubro
  void goToRubroCarpetas() {
    state = state.copyWith(
      clearCurrentCarpeta: true,
      clearContenido: true,
      selectedItems: {},
      breadcrumbs: [],
    );
  }

  /// Navegar a una carpeta del breadcrumb
  void navigateToBreadcrumb(int? carpetaId) {
    if (carpetaId == null) {
      goToRubroCarpetas();
    } else {
      loadContenidoCarpeta(carpetaId);
    }
  }

  // ─── Selección ───────────────────────────────────────────────────────

  void toggleSelection(int id, String tipo) {
    final items = Map<int, String>.from(state.selectedItems);
    if (items.containsKey(id)) {
      items.remove(id);
    } else {
      items[id] = tipo;
    }
    state = state.copyWith(selectedItems: items);

    // Notificar selección al WebSocket
    _notifySelectionChange();
  }

  void clearSelection() {
    state = state.copyWith(selectedItems: {});
    _notifySelectionChange();
  }

  void selectAll() {
    if (state.contenido == null) return;
    final items = <int, String>{};
    for (final c in state.contenido!.subcarpetas) {
      if (!c.isDeleted) items[c.id] = 'carpeta';
    }
    for (final a in state.contenido!.archivos) {
      if (!a.isDeleted) items[a.id] = 'archivo';
    }
    state = state.copyWith(selectedItems: items);
    _notifySelectionChange();
  }

  void _notifySelectionChange() {
    final socketService = _ref.read(appSocketServiceProvider);
    if (!socketService.isConnected) return;

    final seleccion = state.selectedItems.entries
        .map((e) => {'id': e.key, 'tipo': e.value})
        .toList();
    socketService.sendCambiarSeleccion(seleccion);
  }

  // ─── Clipboard (Cortar/Pegar) ────────────────────────────────────────

  void cortarSeleccion() {
    if (!state.hasSelection || state.currentCarpetaId == null) return;

    state = state.copyWith(
      clipboard: ClipboardData(
        items: Map.from(state.selectedItems),
        sourceCarpetaId: state.currentCarpetaId!,
      ),
      selectedItems: {},
    );
  }

  Future<void> pegar() async {
    if (!state.hasClipboard || state.currentCarpetaId == null) return;
    final cb = state.clipboard!;

    try {
      // Mover archivos
      if (cb.archivoIds.isNotEmpty) {
        await _service.moverArchivos(
          archivoIds: cb.archivoIds,
          carpetaDestinoId: state.currentCarpetaId!,
        );
      }

      // Mover carpetas
      if (cb.carpetaIds.isNotEmpty) {
        await _service.moverCarpetas(
          carpetaIds: cb.carpetaIds,
          destinoId: state.currentCarpetaId!,
        );
      }

      state = state.copyWith(clearClipboard: true);

      // Recargar contenido
      await loadContenidoCarpeta(state.currentCarpetaId!);
    } catch (e) {
      debugPrint('Error pegando: $e');
      state = state.copyWith(errorMessage: 'Error al mover elementos');
    }
  }

  // ─── CRUD ────────────────────────────────────────────────────────────

  Future<Carpeta?> crearCarpeta(String nombre) async {
    if (state.currentCarpetaId == null) return null;

    try {
      final carpeta = await _service.crearCarpeta(
        nombre: nombre,
        parentId: state.currentCarpetaId!,
      );

      // Optimistic: agregar al estado
      if (state.contenido != null) {
        final newSubcarpetas = [...state.contenido!.subcarpetas, carpeta];
        state = state.copyWith(
          contenido: state.contenido!.copyWith(
            subcarpetas: newSubcarpetas,
            totalCarpetas: newSubcarpetas.length,
          ),
        );
      }

      return carpeta;
    } catch (e) {
      debugPrint('Error creando carpeta: $e');
      state = state.copyWith(errorMessage: 'Error al crear carpeta');
      return null;
    }
  }

  // ─── Upload Queue ───────────────────────────────────────────────────

  /// Agregar archivos a la cola de upload (max 15 simultáneos)
  void addToUploadQueue(List<File> files) {
    if (state.currentCarpetaId == null) return;

    final newItems = <UploadQueueItem>[];
    for (final file in files) {
      final id =
          '${DateTime.now().microsecondsSinceEpoch}_${file.path.hashCode}';
      final fileName = file.path.split(Platform.pathSeparator).last;
      _queuedFiles[id] = file;
      newItems.add(UploadQueueItem(
        id: id,
        fileName: fileName,
        carpetaId: state.currentCarpetaId!,
      ));
    }

    state = state.copyWith(
      uploadQueue: [...state.uploadQueue, ...newItems],
    );

    _processUploadQueue();
  }

  void _processUploadQueue() {
    final pending =
        state.uploadQueue.where((i) => i.status == UploadStatus.pending);
    for (final item in pending) {
      if (_activeUploads >= _maxConcurrentUploads) break;
      _uploadSingleFile(item);
    }
  }

  Future<void> _uploadSingleFile(UploadQueueItem item) async {
    _activeUploads++;
    _updateQueueItem(item.id, status: UploadStatus.uploading);

    final file = _queuedFiles[item.id];
    if (file == null) {
      _activeUploads--;
      _updateQueueItem(item.id,
          status: UploadStatus.error, error: 'Archivo no encontrado');
      _processUploadQueue();
      return;
    }

    try {
      final archivo = await _service.uploadArchivoIndividual(
        carpetaId: item.carpetaId,
        archivo: file,
        onProgress: (p) => _updateQueueItem(item.id, progress: p),
      );

      _updateQueueItem(item.id,
          status: UploadStatus.completed, progress: 1.0);
      _queuedFiles.remove(item.id);

      // Agregar al estado (duplicate check con WS)
      _addArchivoToStateIfNew(archivo);
    } catch (e) {
      debugPrint('Error subiendo ${item.fileName}: $e');
      _updateQueueItem(item.id,
          status: UploadStatus.error, error: 'Error al subir');
    } finally {
      _activeUploads--;
      _processUploadQueue();
      _scheduleQueueCleanup();
    }
  }

  void _updateQueueItem(String id,
      {UploadStatus? status, double? progress, String? error}) {
    state = state.copyWith(
      uploadQueue: state.uploadQueue.map((i) {
        if (i.id == id) {
          return i.copyWith(status: status, progress: progress, error: error);
        }
        return i;
      }).toList(),
    );
  }

  void _addArchivoToStateIfNew(Archivo archivo) {
    if (state.contenido == null) return;
    if (state.contenido!.archivos.any((a) => a.id == archivo.id)) return;

    final archivos = [...state.contenido!.archivos, archivo];
    state = state.copyWith(
      contenido: state.contenido!.copyWith(
        archivos: archivos,
        totalArchivos: archivos.length,
      ),
    );
  }

  void _scheduleQueueCleanup() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final queue = state.uploadQueue
          .where((i) => i.status != UploadStatus.completed)
          .toList();
      if (queue.length != state.uploadQueue.length) {
        state = state.copyWith(uploadQueue: queue);
      }
    });
  }

  void retryFailedUploads() {
    state = state.copyWith(
      uploadQueue: state.uploadQueue.map((i) {
        if (i.status == UploadStatus.error) {
          return i.copyWith(
              status: UploadStatus.pending, progress: 0, clearError: true);
        }
        return i;
      }).toList(),
    );
    _processUploadQueue();
  }

  void cancelUploadQueue() {
    _queuedFiles.clear();
    _activeUploads = 0;
    state = state.copyWith(uploadQueue: []);
  }

  Future<void> eliminarSeleccion() async {
    if (!state.hasSelection) return;

    final itemsToDelete = Map<int, String>.from(state.selectedItems);

    // Optimistic: quitar del estado inmediatamente
    if (state.contenido != null) {
      final archivosIds = itemsToDelete.entries
          .where((e) => e.value == 'archivo')
          .map((e) => e.key)
          .toSet();
      final carpetasIds = itemsToDelete.entries
          .where((e) => e.value == 'carpeta')
          .map((e) => e.key)
          .toSet();

      final archivos = state.contenido!.archivos
          .where((a) => !archivosIds.contains(a.id))
          .toList();
      final subcarpetas = state.contenido!.subcarpetas
          .where((c) => !carpetasIds.contains(c.id))
          .toList();

      state = state.copyWith(
        selectedItems: {},
        contenido: state.contenido!.copyWith(
          subcarpetas: subcarpetas,
          archivos: archivos,
          totalCarpetas: subcarpetas.length,
          totalArchivos: archivos.length,
        ),
      );
    } else {
      state = state.copyWith(selectedItems: {});
    }

    // Ejecutar deletes en backend (WS notificará a otros usuarios)
    try {
      for (final entry in itemsToDelete.entries) {
        if (entry.value == 'archivo') {
          await _service.eliminarArchivo(entry.key);
        } else {
          await _service.eliminarCarpeta(entry.key);
        }
      }
    } catch (e) {
      debugPrint('Error eliminando: $e');
      state = state.copyWith(errorMessage: 'Error al eliminar');
      // Recargar para estado correcto
      if (state.currentCarpetaId != null) {
        await loadContenidoCarpeta(state.currentCarpetaId!);
      }
    }
  }

  Future<void> restaurarArchivo(int archivoId) async {
    try {
      await _service.restaurarArchivo(archivoId);
      if (state.currentCarpetaId != null) {
        await loadContenidoCarpeta(state.currentCarpetaId!);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al restaurar');
    }
  }

  Future<void> restaurarCarpeta(int carpetaId) async {
    try {
      await _service.restaurarCarpeta(carpetaId);
      if (state.currentCarpetaId != null) {
        await loadContenidoCarpeta(state.currentCarpetaId!);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al restaurar');
    }
  }

  // ─── UI Toggles ─────────────────────────────────────────────────────

  void toggleViewMode() {
    state = state.copyWith(
      viewMode:
          state.viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleShowDeleted() {
    state = state.copyWith(showDeleted: !state.showDeleted);
    if (state.currentCarpetaId != null) {
      loadContenidoCarpeta(state.currentCarpetaId!);
    }
  }

  // ─── WebSocket Events ────────────────────────────────────────────────
  //
  // Arquitectura: el backend emite a grupo específico app_casos_carpeta_{id}.
  // Solo recibimos eventos de la carpeta a la que estamos suscritos.
  // No filtramos por actor → soporta sync cross-device (web ↔ phone).
  // Usamos duplicate check por ID para evitar dobles en creates.
  //

  void _handleWsEvent(AppSocketEvent event) {
    switch (event.type) {
      // ── Presencia ──
      case 'usuario_conectado':
      case 'usuario_desconectado':
      case 'usuario_cambio_carpeta':
      case 'usuarios_lista':
        _updateUsuariosConectados(event);
        break;

      case 'usuario_cambio_seleccion':
        if (event.actorId == _currentUserId) break;
        _updateUsuarioSeleccion(event);
        break;

      // ── Eventos de carpeta específica (0 API calls) ──
      case 'archivo_creado':
        _handleArchivoCreado(event);
        break;

      case 'archivo_eliminado':
        _handleArchivoEliminado(event);
        break;

      case 'archivo_movido':
        _handleArchivoMovido(event);
        break;

      case 'carpeta_creada':
        _handleCarpetaCreada(event);
        break;

      case 'carpeta_eliminada':
        _handleCarpetaEliminada(event);
        break;

      // data_changed legacy: ignorar (backend ya emite eventos específicos)
      case 'data_changed':
        break;
    }
  }

  /// Archivo creado: agregar al estado si no existe (duplicate check)
  void _handleArchivoCreado(AppSocketEvent event) {
    final data = event.raw['data'] as Map<String, dynamic>?;
    if (data == null || state.contenido == null) return;

    final archivoId = data['id'] as int?;
    if (archivoId == null) return;

    // Evitar duplicados (ej: upload propio ya agregó optimísticamente)
    if (state.contenido!.archivos.any((a) => a.id == archivoId)) return;

    final archivo = Archivo.fromJson(data);
    // Quitar temporales del mismo nombre (optimistic placeholders)
    final archivos = state.contenido!.archivos
        .where((a) => !a.isTemporary)
        .toList()
      ..add(archivo);

    state = state.copyWith(
      contenido: state.contenido!.copyWith(
        archivos: archivos,
        totalArchivos: archivos.length,
      ),
    );
  }

  /// Archivo eliminado: quitar del estado por ID (idempotente)
  void _handleArchivoEliminado(AppSocketEvent event) {
    final data = event.raw['data'] as Map<String, dynamic>?;
    if (data == null || state.contenido == null) return;

    final archivoId = data['id'] as int?;
    if (archivoId == null) return;

    final archivos =
        state.contenido!.archivos.where((a) => a.id != archivoId).toList();
    if (archivos.length == state.contenido!.archivos.length) return;

    state = state.copyWith(
      contenido: state.contenido!.copyWith(
        archivos: archivos,
        totalArchivos: archivos.length,
      ),
    );
  }

  /// Archivo movido: quitar si salió de esta carpeta
  void _handleArchivoMovido(AppSocketEvent event) {
    final data = event.raw['data'] as Map<String, dynamic>?;
    if (data == null || state.contenido == null) return;

    final archivoId = data['id'] as int?;
    if (archivoId == null) return;

    // Si el archivo se movió FUERA de esta carpeta, remover
    final archivos =
        state.contenido!.archivos.where((a) => a.id != archivoId).toList();
    if (archivos.length != state.contenido!.archivos.length) {
      state = state.copyWith(
        contenido: state.contenido!.copyWith(
          archivos: archivos,
          totalArchivos: archivos.length,
        ),
      );
    }
  }

  /// Carpeta creada: agregar al estado si no existe (duplicate check)
  void _handleCarpetaCreada(AppSocketEvent event) {
    final data = event.raw['data'] as Map<String, dynamic>?;
    if (data == null || state.contenido == null) return;

    final carpetaId = data['id'] as int?;
    if (carpetaId == null) return;

    // Evitar duplicados
    if (state.contenido!.subcarpetas.any((c) => c.id == carpetaId)) return;

    final carpeta = Carpeta.fromJson(data);
    final subcarpetas = [...state.contenido!.subcarpetas, carpeta];
    state = state.copyWith(
      contenido: state.contenido!.copyWith(
        subcarpetas: subcarpetas,
        totalCarpetas: subcarpetas.length,
      ),
    );
  }

  /// Carpeta eliminada: quitar del estado por ID (idempotente)
  void _handleCarpetaEliminada(AppSocketEvent event) {
    final data = event.raw['data'] as Map<String, dynamic>?;
    if (data == null || state.contenido == null) return;

    final carpetaId = data['id'] as int?;
    if (carpetaId == null) return;

    final subcarpetas =
        state.contenido!.subcarpetas.where((c) => c.id != carpetaId).toList();
    if (subcarpetas.length == state.contenido!.subcarpetas.length) return;

    state = state.copyWith(
      contenido: state.contenido!.copyWith(
        subcarpetas: subcarpetas,
        totalCarpetas: subcarpetas.length,
      ),
    );
  }

  void _updateUsuariosConectados(AppSocketEvent event) {
    final usuarios = (event.raw['usuarios_conectados'] as List?)
            ?.map((e) =>
                UsuarioConectado.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    state = state.copyWith(usuariosConectados: usuarios);
  }

  void _updateUsuarioSeleccion(AppSocketEvent event) {
    final data = event.raw['data'] as Map<String, dynamic>?;
    if (data == null) return;

    final userId = data['user_id'] as int;
    final seleccion = (data['seleccion'] as List?)
            ?.map(
                (e) => SeleccionItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final updated = state.usuariosConectados.map((u) {
      if (u.userId == userId) {
        return UsuarioConectado(
          userId: u.userId,
          username: u.username,
          nombre: u.nombre,
          carpetaId: u.carpetaId,
          carpetaNombre: u.carpetaNombre,
          seleccion: seleccion,
        );
      }
      return u;
    }).toList();

    state = state.copyWith(usuariosConectados: updated);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  String? _findCarpetaName(int id) {
    // Buscar en carpetas raíz
    for (final c in state.carpetasRaiz) {
      if (c.id == id) return c.nombre;
    }
    // Buscar en contenido actual
    if (state.contenido != null) {
      if (state.contenido!.carpetaPrincipal.id == id) {
        return state.contenido!.carpetaPrincipal.nombre;
      }
      for (final c in state.contenido!.subcarpetas) {
        if (c.id == id) return c.nombre;
      }
    }
    return null;
  }

  List<BreadcrumbItem> _buildBreadcrumbs(Carpeta carpeta) {
    final items = <BreadcrumbItem>[];

    // El breadcrumb raíz siempre apunta al rubro
    if (state.selectedRubro != null) {
      items.add(BreadcrumbItem(label: state.selectedRubro!));
    }

    // Si la ruta tiene partes, la última es la actual
    // No podemos reconstruir IDs de padres solo con la ruta,
    // así que solo mostramos la carpeta actual
    items.add(BreadcrumbItem(
      carpetaId: carpeta.id,
      label: carpeta.nombre,
    ));

    return items;
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}
