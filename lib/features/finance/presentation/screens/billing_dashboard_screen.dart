import 'package:flutter/material.dart';
import 'package:admin/features/finance/presentation/screens/milestone_list_screen.dart';

class BillingDashboardScreen extends StatefulWidget {
  final int projectId;

  const BillingDashboardScreen({super.key, required this.projectId});

  @override
  State<BillingDashboardScreen> createState() => _BillingDashboardScreenState();
}

class _BillingDashboardScreenState extends State<BillingDashboardScreen> with SingleTickerProviderStateMixin {
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
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Milestones'),
            Tab(text: 'Invoices & Receipts'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              MilestoneListScreen(projectId: widget.projectId),
              const Center(child: Text("Invoices & Receipts List (Coming Soon)")),
            ],
          ),
        ),
      ],
    );
  }
}

