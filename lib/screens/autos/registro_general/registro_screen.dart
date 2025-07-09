// ============================================================================
// 📂 lib/screens/autos/registro_general/registro_screen.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';
import 'package:stampcamera/providers/autos/registro_general_provider.dart';
import 'package:stampcamera/widgets/autos/card_detalle_registro_vin.dart';
import 'package:stampcamera/widgets/vin_scanner_screen.dart';
import 'package:stampcamera/widgets/common/search_bar_widget.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final notifier = ref.read(registroGeneralProvider.notifier);

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!notifier.isLoadingMore &&
            notifier.hasNextPage &&
            !notifier.isSearching) {
          notifier.loadMore();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registrosAsync = ref.watch(registroGeneralProvider);
    final notifier = ref.read(registroGeneralProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          // ✅ Barra de búsqueda reutilizable
          SearchBarWidget(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: 'Buscar por VIN o Serie...',
            onChanged: (value) {
              if (value.trim().isEmpty) {
                notifier.clearSearch();
              } else {
                notifier.debouncedSearch(value);
              }
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                notifier.search(value);
                _searchFocusNode.unfocus();
              }
            },
            onClear: () {
              notifier.clearSearch();
              _searchFocusNode.unfocus();
            },
            onScannerPressed: () => _openScanner(notifier),
            scannerTooltip: 'Escanear código VIN',
          ),

          // ✅ Lista de resultados
          Expanded(child: _buildResultsList(registrosAsync, notifier)),
        ],
      ),
    );
  }

  // ============================================================================
  // MÉTODOS PRIVADOS PARA EL UI
  // ============================================================================

  Widget _buildResultsList(
    AsyncValue<List<RegistroGeneral>> registrosAsync,
    RegistroGeneralNotifier notifier,
  ) {
    return registrosAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),

      // ✅ Usar ConnectionErrorScreen para manejo inteligente de errores
      error: (error, stackTrace) => ConnectionErrorScreen(
        error: error,
        onRetry: () => notifier.refresh(),
      ),

      data: (registros) => _buildDataState(registros, notifier),
    );
  }

  Widget _buildDataState(
    List<RegistroGeneral> registros,
    RegistroGeneralNotifier notifier,
  ) {
    if (registros.isEmpty) {
      return _buildEmptyState(notifier);
    }

    final showLoadMoreIndicator = notifier.hasNextPage && !notifier.isSearching;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(DesignTokens.spaceS),
        itemCount: registros.length + (showLoadMoreIndicator ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < registros.length) {
            final registro = registros[index];
            return Padding(
              padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceXS),
              child: GestureDetector(
                onTap: () => _navigateToDetail(registro.vin),
                child: DetalleRegistroCard(registro: registro),
              ),
            );
          }

          return Container(
            padding: EdgeInsets.all(DesignTokens.spaceL),
            alignment: Alignment.center,
            child: Column(
              children: [
                if (notifier.isLoadingMore) ...[
                  AppLoadingState.circular(
                    message: 'Cargando más resultados...',
                  ),
                ] else ...[
                  AppButton.ghost(
                    text: 'Cargar más',
                    icon: Icons.expand_more,
                    onPressed: () => notifier.loadMore(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(RegistroGeneralNotifier notifier) {
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Sin resultados' : 'No hay registros',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'No se encontraron registros que coincidan con "${_searchController.text}"'
                : 'Aún no hay registros disponibles',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          if (isSearching) ...[
            AppButton.secondary(
              text: 'Limpiar búsqueda',
              icon: Icons.clear,
              onPressed: () {
                _searchController.clear();
                notifier.clearSearch();
              },
            ),
          ] else ...[
            AppButton.primary(
              text: 'Actualizar',
              icon: Icons.refresh,
              onPressed: () => notifier.refresh(),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // MÉTODOS DE ACCIÓN
  // ============================================================================

  void _openScanner(RegistroGeneralNotifier notifier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VinScannerScreen(
          onScanned: (vin) {
            _searchController.text = vin;
            notifier.search(vin);
            _searchFocusNode.unfocus();
          },
        ),
      ),
    );
  }

  void _navigateToDetail(String vin) {
    context.push('/autos/detalle/$vin');
  }
}
