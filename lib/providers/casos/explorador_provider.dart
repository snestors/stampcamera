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
    );
  }

  bool get isAtRoot => currentCarpetaId == null;
  bool get hasSelection => selectedItems.isNotEmpty;
  bool get hasClipboard => clipboard != null && !clipboard!.isEmpty;

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
          contenido: CarpetaContenidoResponse(
            carpetaPrincipal: state.contenido!.carpetaPrincipal,
            caso: state.contenido!.caso,
            subcarpetas: newSubcarpetas,
            archivos: state.contenido!.archivos,
            totalCarpetas: newSubcarpetas.length,
            totalArchivos: state.contenido!.totalArchivos,
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

  Future<UploadMultipleResponse?> uploadArchivos(List<File> archivos,
      {void Function(double)? onProgress}) async {
    if (state.currentCarpetaId == null) return null;

    try {
      // Optimistic: agregar archivos temporales
      final tempArchivos = archivos
          .map((f) => Archivo.temporary(
                f.path.split(Platform.pathSeparator).last,
                state.currentCarpetaId!,
              ))
          .toList();

      if (state.contenido != null) {
        state = state.copyWith(
          contenido: CarpetaContenidoResponse(
            carpetaPrincipal: state.contenido!.carpetaPrincipal,
            caso: state.contenido!.caso,
            subcarpetas: state.contenido!.subcarpetas,
            archivos: [...state.contenido!.archivos, ...tempArchivos],
            totalCarpetas: state.contenido!.totalCarpetas,
            totalArchivos:
                state.contenido!.totalArchivos + tempArchivos.length,
          ),
        );
      }

      final response = await _service.uploadArchivos(
        carpetaId: state.currentCarpetaId!,
        archivos: archivos,
        onProgress: onProgress,
      );

      // Reemplazar temporales con reales
      if (state.contenido != null) {
        final realArchivos = state.contenido!.archivos
            .where((a) => !a.isTemporary)
            .toList()
          ..addAll(response.creados);

        state = state.copyWith(
          contenido: CarpetaContenidoResponse(
            carpetaPrincipal: state.contenido!.carpetaPrincipal,
            caso: state.contenido!.caso,
            subcarpetas: state.contenido!.subcarpetas,
            archivos: realArchivos,
            totalCarpetas: state.contenido!.totalCarpetas,
            totalArchivos: realArchivos.length,
          ),
        );
      }

      return response;
    } catch (e) {
      debugPrint('Error subiendo archivos: $e');
      // Revertir temporales
      if (state.contenido != null) {
        state = state.copyWith(
          contenido: CarpetaContenidoResponse(
            carpetaPrincipal: state.contenido!.carpetaPrincipal,
            caso: state.contenido!.caso,
            subcarpetas: state.contenido!.subcarpetas,
            archivos:
                state.contenido!.archivos.where((a) => !a.isTemporary).toList(),
            totalCarpetas: state.contenido!.totalCarpetas,
            totalArchivos: state.contenido!.archivos
                .where((a) => !a.isTemporary)
                .length,
          ),
        );
      }
      state = state.copyWith(errorMessage: 'Error al subir archivos');
      return null;
    }
  }

  Future<void> eliminarSeleccion() async {
    if (!state.hasSelection) return;

    try {
      for (final entry in state.selectedItems.entries) {
        if (entry.value == 'archivo') {
          await _service.eliminarArchivo(entry.key);
        } else {
          await _service.eliminarCarpeta(entry.key);
        }
      }

      state = state.copyWith(selectedItems: {});

      if (state.currentCarpetaId != null) {
        await loadContenidoCarpeta(state.currentCarpetaId!);
      }
    } catch (e) {
      debugPrint('Error eliminando: $e');
      state = state.copyWith(errorMessage: 'Error al eliminar');
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

  void _handleWsEvent(AppSocketEvent event) {
    switch (event.type) {
      // ── Presencia (filtrar eventos propios) ──
      case 'usuario_conectado':
      case 'usuario_desconectado':
      case 'usuario_cambio_carpeta':
      case 'usuarios_lista':
        _updateUsuariosConectados(event);
        break;

      case 'usuario_cambio_seleccion':
        if (event.actorId == _currentUserId) break; // Ignorar propios
        _updateUsuarioSeleccion(event);
        break;

      // ── Eventos específicos del explorador (de ws_events.py) ──
      case 'archivo_creado':
        if (event.actorId == _currentUserId) break;
        _handleRemoteArchivoCreado(event);
        break;

      case 'archivo_eliminado':
        if (event.actorId == _currentUserId) break;
        _handleRemoteArchivoEliminado(event);
        break;

      case 'archivo_movido':
        if (event.actorId == _currentUserId) break;
        _handleRemoteArchivoMovido(event);
        break;

      case 'carpeta_creada':
        if (event.actorId == _currentUserId) break;
        _handleRemoteCarpetaCreada(event);
        break;

      case 'carpeta_eliminada':
        if (event.actorId == _currentUserId) break;
        _handleRemoteCarpetaEliminada(event);
        break;

      // ── data_changed de signals (NUNCA filtrar por actor: puede ser
      //    el mismo usuario desde otro dispositivo/navegador) ──
      case 'data_changed':
        if (event.model == 'archivo' || event.model == 'carpeta') {
          if (state.currentCarpetaId != null) {
            loadContenidoCarpeta(state.currentCarpetaId!);
          }
        }
        break;
    }
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

  void _handleRemoteArchivoCreado(AppSocketEvent event) {
    final data = event.raw['data'] as Map<String, dynamic>?;
    if (data == null || state.contenido == null) return;

    final archivo = Archivo.fromJson(data);
    if (archivo.carpeta == state.currentCarpetaId) {
      final archivos = [...state.contenido!.archivos, archivo];
      state = state.copyWith(
        contenido: CarpetaContenidoResponse(
          carpetaPrincipal: state.contenido!.carpetaPrincipal,
          caso: state.contenido!.caso,
          subcarpetas: state.contenido!.subcarpetas,
          archivos: archivos,
          totalCarpetas: state.contenido!.totalCarpetas,
          totalArchivos: archivos.length,
        ),
      );
    }
  }

  void _handleRemoteArchivoEliminado(AppSocketEvent event) {
    final data = event.raw['data'] as Map<String, dynamic>?;
    if (data == null || state.contenido == null) return;

    final archivoId = data['id'] as int;
    final archivos =
        state.contenido!.archivos.where((a) => a.id != archivoId).toList();
    state = state.copyWith(
      contenido: CarpetaContenidoResponse(
        carpetaPrincipal: state.contenido!.carpetaPrincipal,
        caso: state.contenido!.caso,
        subcarpetas: state.contenido!.subcarpetas,
        archivos: archivos,
        totalCarpetas: state.contenido!.totalCarpetas,
        totalArchivos: archivos.length,
      ),
    );
  }

  void _handleRemoteArchivoMovido(AppSocketEvent event) {
    // Refrescar carpeta actual para reflejar cambio
    if (state.currentCarpetaId != null) {
      loadContenidoCarpeta(state.currentCarpetaId!);
    }
  }

  void _handleRemoteCarpetaCreada(AppSocketEvent event) {
    final data = event.raw['data'] as Map<String, dynamic>?;
    if (data == null || state.contenido == null) return;

    final parentId = data['parent_id'] as int? ?? data['parent'] as int?;
    if (parentId == state.currentCarpetaId) {
      final carpeta = Carpeta.fromJson(data);
      final subcarpetas = [...state.contenido!.subcarpetas, carpeta];
      state = state.copyWith(
        contenido: CarpetaContenidoResponse(
          carpetaPrincipal: state.contenido!.carpetaPrincipal,
          caso: state.contenido!.caso,
          subcarpetas: subcarpetas,
          archivos: state.contenido!.archivos,
          totalCarpetas: subcarpetas.length,
          totalArchivos: state.contenido!.totalArchivos,
        ),
      );
    }
  }

  void _handleRemoteCarpetaEliminada(AppSocketEvent event) {
    final data = event.raw['data'] as Map<String, dynamic>?;
    if (data == null || state.contenido == null) return;

    final carpetaId = data['id'] as int;
    final subcarpetas =
        state.contenido!.subcarpetas.where((c) => c.id != carpetaId).toList();
    state = state.copyWith(
      contenido: CarpetaContenidoResponse(
        carpetaPrincipal: state.contenido!.carpetaPrincipal,
        caso: state.contenido!.caso,
        subcarpetas: subcarpetas,
        archivos: state.contenido!.archivos,
        totalCarpetas: subcarpetas.length,
        totalArchivos: state.contenido!.totalArchivos,
      ),
    );
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
