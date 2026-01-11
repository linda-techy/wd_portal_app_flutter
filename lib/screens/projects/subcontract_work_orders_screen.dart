import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/subcontract_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_handler.dart';
import '../../providers/portal_auth_provider.dart';

/// Subcontract Work Orders Screen
/// Lists all work orders for a project
class SubcontractWorkOrdersScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const SubcontractWorkOrdersScreen({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  State<SubcontractWorkOrdersScreen> createState() => _SubcontractWorkOrdersScreenState();
}

class _SubcontractWorkOrdersScreenState extends State<SubcontractWorkOrdersScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyAuthAndLoadData();
    });
  }

  Future<void> _verifyAuthAndLoadData() async {
    final authProvider = Provider.of<PortalAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (mounted) {
         Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      await context.read<SubcontractProvider>().loadProjectWorkOrders(widget.projectId);
      if (mounted) {
        await context.read<SubcontractProvider>().loadProjectSummaries(widget.projectId);
      }
    } catch (e) {
      if (mounted) {
         // Provider catches errors, but if any slip through:
         await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to load work orders', showToast: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Subcontract Work Orders', style: TextStyle(color: Colors.white, fontSize: 18)),
            Text(
              widget.projectName,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        backgroundColor: AppTheme.deepSlate,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<SubcontractProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.workOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.workOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary Cards
              if (provider.summaries.isNotEmpty) _buildSummaryHeader(provider),

              const SizedBox(height: 8),

              // Work Orders List
              Expanded(
                child: provider.workOrders.isEmpty
                    ? const Center(child: Text('No work orders found'))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.workOrders.length,
                          itemBuilder: (context, index) {
                            final workOrder = provider.workOrders[index];
                            final summary = provider.summaries.firstWhere(
                              (s) => s.workOrderId == workOrder.id,
                              orElse: () => provider.summaries.first,
                            );
                            return _buildWorkOrderCard(workOrder, summary);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to create work order
        },
        backgroundColor: AppTheme.coralRed,
        icon: const Icon(Icons.add),
        label: const Text('New Work Order'),
      ),
    );
  }

  Widget _buildSummaryHeader(SubcontractProvider provider) {
    final summaries = provider.summaries;
    final totalContract = summaries.fold<double>(
      0,
      (sum, s) => sum + s.totalContractAmount,
    );
    final totalPaid = summaries.fold<double>(
      0,
      (sum, s) => sum + s.totalPaid,
    );
    final totalBalance = summaries.fold<double>(
      0,
      (sum, s) => sum + s.balanceDue,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.deepSlate.withOpacity(0.05),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem('Total Contract', _currencyFormat.format(totalContract), AppTheme.deepSlate),
          ),
          Expanded(
            child: _buildSummaryItem('Paid', _currencyFormat.format(totalPaid), AppTheme.successGreen),
          ),
          Expanded(
            child: _buildSummaryItem('Balance', _currencyFormat.format(totalBalance), AppTheme.warningAmber),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkOrderCard(workOrder, summary) {
    final statusColor = _getStatusColor(workOrder.status);
    final progress = summary.percentageCompleted ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to work order detail
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workOrder.workOrderNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepSlate,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          workOrder.vendorName ?? 'Vendor',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      workOrder.statusDisplay,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Scope
              Text(
                workOrder.scopeDescription,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Financial Info
              Row(
                children: [
                  _buildInfoChip(
                    Icons.account_balance_wallet,
                    _currencyFormat.format(workOrder.negotiatedAmount),
                    AppTheme.deepSlate,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.payment,
                    _currencyFormat.format(summary.totalPaid),
                    AppTheme.successGreen,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.pending,
                    _currencyFormat.format(summary.balanceDue),
                    summary.balanceDue > 0 ? AppTheme.warningAmber : Colors.grey,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar (for unit-rate contracts)
              if (workOrder.isUnitRate && progress > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.grey[200],
                        color: AppTheme.successGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${progress.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Measurement basis tag
              Row(
                children: [
                  Icon(
                    workOrder.isLumpsum ? Icons.attach_money : Icons.straighten,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    workOrder.measurementBasisDisplay,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (summary.pendingMeasurements != null && summary.pendingMeasurements! > 0) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.warningAmber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${summary.pendingMeasurements} pending approval',
                        style: TextStyle(fontSize: 11, color: AppTheme.warningAmber),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DRAFT':
        return Colors.grey;
      case 'ISSUED':
        return AppTheme.skyBlue;
      case 'IN_PROGRESS':
        return AppTheme.successGreen;
      case 'COMPLETED':
        return Colors.green;
      case 'TERMINATED':
        return AppTheme.errorRed;
      default:
        return Colors.grey;
    }
  }
}
