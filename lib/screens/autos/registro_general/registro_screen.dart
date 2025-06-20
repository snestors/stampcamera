import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/providers/autos/registro_general_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/widgets/autos/card_detalle_registro_vin.dart';
import 'package:stampcamera/widgets/vin_scanner_screen.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registrosAsync = ref.watch(registroGeneralProvider);
    final notifier = ref.read(registroGeneralProvider.notifier);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              final trimmed = value.trim();

              if (trimmed.isEmpty) {
                notifier.clearSearch();
              } else {
                notifier.debouncedSearch(trimmed);
              }
            },
            decoration: InputDecoration(
              hintText: 'Buscar VIN o Serie',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VinScannerScreen(
                              onScanned: (vin) {
                                _searchController.text = vin;
                                notifier.search(vin);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        notifier.clearSearch();
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: registrosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (registros) {
              if (registros.isEmpty) {
                return const Center(child: Text('No hay resultados'));
              }

              final showLoader = notifier.hasNextPage && !notifier.isSearching;

              return NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification.metrics.pixels >=
                          scrollNotification.metrics.maxScrollExtent - 100 &&
                      !notifier.isLoadingMore &&
                      showLoader) {
                    notifier.loadMore();
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: registros.length + (showLoader ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < registros.length) {
                      final r = registros[index];
                      return GestureDetector(
                        onTap: () {
                          final vin = r.vin;
                          context.push('/autos/detalle/$vin');
                        },
                        child: DetalleRegistroCard(registro: r),
                      );
                    } else {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
