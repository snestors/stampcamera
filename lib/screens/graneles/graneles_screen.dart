// =============================================================================
// PANTALLA PRINCIPAL DE GRANELES
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/screens/graneles/tabs/servicios_tab.dart';
import 'package:stampcamera/screens/graneles/tabs/tickets_tab.dart';
import 'package:stampcamera/screens/graneles/tabs/balanzas_tab.dart';
import 'package:stampcamera/screens/graneles/tabs/almacen_tab.dart';
import 'package:stampcamera/screens/graneles/tabs/silos_tab.dart';

class GranelesScreen extends ConsumerStatefulWidget {
  const GranelesScreen({super.key});

  @override
  ConsumerState<GranelesScreen> createState() => _GranelesScreenState();
}

class _GranelesScreenState extends ConsumerState<GranelesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Graneles',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: DesignTokens.fontSizeL,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ServiciosTab(),
          TicketsTab(),
          BalanzasTab(),
          AlmacenTab(),
          SilosTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: DesignTokens.fontSizeXS,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: DesignTokens.fontSizeXS,
            ),
            tabs: const [
              Tab(text: 'Servicios', icon: Icon(Icons.list_alt, size: 20)),
              Tab(text: 'Tickets', icon: Icon(Icons.receipt_long, size: 20)),
              Tab(text: 'Balanzas', icon: Icon(Icons.scale, size: 20)),
              Tab(text: 'Almacén', icon: Icon(Icons.warehouse, size: 20)),
              Tab(text: 'Silos', icon: Icon(Icons.storage, size: 20)),
            ],
          ),
        ),
      ),
    );
  }
}
