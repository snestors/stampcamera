import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/providers/registro_general_provider.dart';

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
            onSubmitted: (value) {
              if (value.trim().isEmpty) {
                notifier.clearSearch();
              } else {
                notifier.search(value.trim());
              }
            },
            decoration: InputDecoration(
              hintText: 'Buscar VIN o Serie',
              suffixIcon: notifier.isSearching || notifier.searchingFromApi
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        notifier.clearSearch();
                      },
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

              return NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification.metrics.pixels >=
                          scrollNotification.metrics.maxScrollExtent - 100 &&
                      !notifier.isLoadingMore &&
                      !notifier.isSearching &&
                      !notifier.searchingFromApi) {
                    notifier.loadMore();
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: registros.length + (notifier.hasNextPage ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < registros.length) {

                      final r = registros[index];
                    return ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: Text(r.vin),
                      subtitle: Text('${r.marca ?? ''} - ${r.modelo ?? ''}'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Seleccionado: ${r.vin}')),
                        );
                      },
                    ); }
                    else {

                    }
                    
                      // Mostrar loading solo al final de la lista
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    

                  

                    
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
