import 'package:flutter/material.dart';
import '../../../data/models/lead_score_history.dart';
import '../../../data/services/lead_service.dart';
import 'package:intl/intl.dart';
import 'package:admin/utils/error_handler.dart';

/// Widget displaying timeline of lead score changes
/// Shows audit trail of how lead scores changed over time
class LeadScoreHistoryTimeline extends StatefulWidget {
  final String leadId;

  const LeadScoreHistoryTimeline({super.key, required this.leadId});

  @override
  State<LeadScoreHistoryTimeline> createState() =>
      _LeadScoreHistoryTimelineState();
}

class _LeadScoreHistoryTimelineState extends State<LeadScoreHistoryTimeline> {
  final LeadService _leadService = LeadService();
  List<LeadScoreHistory> _scoreHistory = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadScoreHistory();
  }

  Future<void> _loadScoreHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final history = await _leadService.getLeadScoreHistory(widget.leadId);
      setState(() {
        _scoreHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to load score history');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorMessage'),
            ElevatedButton(
              onPressed: _loadScoreHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_scoreHistory.isEmpty) {
      return const Center(
        child: Text(
          'No score history recorded yet.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadScoreHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _scoreHistory.length,
        itemBuilder: (context, index) {
          final history = _scoreHistory[index];
          return _buildTimelineItem(history, index == _scoreHistory.length - 1);
        },
      ),
    );
  }

  Widget _buildTimelineItem(LeadScoreHistory history, bool isLast) {
    final Color scoreColor = _getScoreColor(history.newScore);
    final Color categoryColor = _getCategoryColor(history.newCategory);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: scoreColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForChange(history.scoreChange),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: categoryColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        history.newCategory,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: categoryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Score: ${history.newScore}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                if (history.previousScore != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    history.scoreChangeText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: history.scoreChange > 0
                                          ? Colors.green
                                          : history.scoreChange < 0
                                              ? Colors.red
                                              : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, y HH:mm')
                                .format(history.scoredAt),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (history.previousCategory != null &&
                          history.previousCategory != history.newCategory) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Category: ',
                                style: TextStyle(fontSize: 12)),
                            Text(
                              history.categoryChangeText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (history.reason != null &&
                          history.reason!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          history.reason!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (history.scoredByName != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Scored by: ${history.scoredByName}',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score > 60) return Colors.red; // HOT
    if (score >= 30) return Colors.orange; // WARM
    return Colors.grey; // COLD
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'HOT':
        return Colors.red;
      case 'WARM':
        return Colors.orange;
      case 'COLD':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForChange(int change) {
    if (change > 0) return Icons.trending_up;
    if (change < 0) return Icons.trending_down;
    return Icons.trending_flat;
  }
}
