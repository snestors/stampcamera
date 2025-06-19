import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/providers/registro_general_provider.dart';
import 'package:stampcamera/utils/debouncer.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer();
  }

  @override
  void dispose() {
    _debouncer.cancel();
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

              _debouncer.run(() {
                if (trimmed.isEmpty) {
                  notifier.clearSearch();
                } else {
                  notifier.search(trimmed);
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar VIN o Serie',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    print(
                      'Index: $index, Total: ${registros.length}, Show Loader: $showLoader',
                    );
                    if (index < registros.length) {
                      final r = registros[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.serie != null && r.serie!.isNotEmpty
                                    ? '${r.vin} (${r.serie})'
                                    : r.vin,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('${r.marca ?? ''} - ${r.modelo ?? ''}'),
                              Text('Color: ${r.color ?? 'N/A'}'),
                              Text('Versión: ${r.version ?? 'N/A'}'),
                              Text('Nave: ${r.naveDescarga ?? 'N/A'}'),
                              Text('BL: ${r.bl ?? 'N/A'}'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    r.pedeteado
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: r.pedeteado
                                        ? Colors.green
                                        : Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pedeteado',
                                    style: TextStyle(fontSize: 12),
                                  ),

                                  const SizedBox(width: 12),

                                  Icon(
                                    r.danos ? Icons.check_circle : Icons.cancel,
                                    color: r.danos ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text('Daños', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
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
