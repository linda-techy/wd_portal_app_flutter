import 'package:flutter/material.dart';
import 'package:admin/features/finance/presentation/screens/milestone_list_screen.dart';
import 'package:admin/screens/customer_projects/project_payments_screen.dart'; // Existing screen or new?
// Assuming ProjectPaymentsScreen handles general payments, but Phase 4 might supersede it.
// For now, let's create a dashboard that tabs between Milestones and Invoices/Receipts.

class BillingDashboardScreen extends StatefulWidget {
  final int projectId;

  const BillingDashboardScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  _BillingDashboardScreenState createState() => _BillingDashboardScreenState();
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
          tabs: [
            Tab(text: 'Milestones'),
            Tab(text: 'Invoices & Receipts'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              MilestoneListScreen(projectId: widget.projectId),
              Center(child: Text("Invoices & Receipts List (Coming Soon)")), // To be implemented or linked to existing invoices
            ],
          ),
        ),
      ],
    );
  }
}

