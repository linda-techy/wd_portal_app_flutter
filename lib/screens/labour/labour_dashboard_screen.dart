import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'labour_list_screen.dart';
import 'attendance_screen.dart';
import 'mb_list_screen.dart';

class LabourDashboardScreen extends StatefulWidget {
  const LabourDashboardScreen({super.key});

  @override
  State<LabourDashboardScreen> createState() => _LabourDashboardScreenState();
}

class _LabourDashboardScreenState extends State<LabourDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0, // Hide main app bar area, use bottom for tabs
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.coralRed,
          labelColor: AppTheme.deepSlate,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Labourers", icon: Icon(Icons.people)),
            Tab(text: "Attendance", icon: Icon(Icons.calendar_today)),
            Tab(text: "Measurement Book", icon: Icon(Icons.straighten)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          LabourListScreen(),
          AttendanceScreen(),
          MBListScreen(),
        ],
      ),
    );
  }
}
