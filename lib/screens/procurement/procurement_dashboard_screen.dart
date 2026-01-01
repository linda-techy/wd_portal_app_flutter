import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/screens/procurement/vendor_list_screen.dart';
import 'package:admin/screens/procurement/po_list_screen.dart';

class ProcurementDashboardScreen extends StatefulWidget {
  const ProcurementDashboardScreen({super.key});

  @override
  State<ProcurementDashboardScreen> createState() => _ProcurementDashboardScreenState();
}

class _ProcurementDashboardScreenState extends State<ProcurementDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          labelColor: AppTheme.coralRed,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.coralRed,
          tabs: const [
            Tab(text: "Vendors", icon: Icon(Icons.business)),
            Tab(text: "Purchase Orders", icon: Icon(Icons.shopping_cart)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          VendorListScreen(),
          PurchaseOrderListScreen(),
        ],
      ),
    );
  }
}
