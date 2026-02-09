import 'package:flutter/material.dart';
import 'package:admin/theme/app_theme.dart';
import 'material_list_screen.dart';
import 'stock_report_screen.dart';

class InventoryDashboardScreen extends StatefulWidget {
  const InventoryDashboardScreen({super.key});

  @override
  State<InventoryDashboardScreen> createState() =>
      _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState extends State<InventoryDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.coralRed,
          labelColor: AppTheme.deepSlate,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Material Catalog", icon: Icon(Icons.inventory)),
            Tab(text: "Stock Report", icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MaterialListScreen(),
          StockReportScreen(),
        ],
      ),
    );
  }
}
