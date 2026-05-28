import 'package:flutter/material.dart';
import 'package:admin/models/support_ticket.dart';
import 'package:admin/services/support_service.dart';
import 'package:admin/services/crm_service.dart';
import 'package:admin/models/portal_user.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/constants.dart';
import 'package:intl/intl.dart';

class SupportTicketDetailScreen extends StatefulWidget {
  final int ticketId;
  const SupportTicketDetailScreen({super.key, required this.ticketId});

  @override
  State<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends State<SupportTicketDetailScreen> {
  final SupportService _service = SupportService();
  final CRMService _crmService = CRMService();
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  PortalSupportTicket? _ticket;
  List<PortalUser> _portalUsers = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isActioning = false;
  String? _error;
  int? _selectedAssignee;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getTicketDetail(widget.ticketId),
        _crmService.getAllPortalUsers(),
      ]);
      if (mounted) {
        final ticket = results[0] as PortalSupportTicket;
        final users = results[1] as List<PortalUser>;
        setState(() {
          _ticket = ticket;
          _portalUsers = users;
          _selectedAssignee = ticket.assignedTo;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _assignTicket(int userId) async {
    setState(() => _isActioning = true);
    try {
      final updated = await _service.assignTicket(widget.ticketId, userId);
      if (mounted) {
        setState(() {
          _ticket = updated;
          _selectedAssignee = userId;
          _isActioning = false;
        });
        _showSnack('Ticket assigned successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActioning = false);
        _showSnack('Error: $e', isError: true);
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isActioning = true);
    try {
      final updated = await _service.updateStatus(widget.ticketId, status);
      if (mounted) {
        setState(() {
          _ticket = updated;
          _isActioning = false;
        });
        _showSnack('Status updated to ${_formatLabel(status)}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActioning = false);
        _showSnack('Error: $e', isError: true);
      }
    }
  }

  Future<void> _sendReply() async {
    final message = _replyController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _service.addReply(widget.ticketId, message, staffName: 'Staff');
      _replyController.clear();
      // Reload to get updated replies
      final updated = await _service.getTicketDetail(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticket = updated;
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        _showSnack('Error sending reply: $e', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: Text(
          _ticket?.ticketNumber ?? 'Support Ticket',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_isActioning)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _ticket == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppTheme.errorRed),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _loadData,
            ),
          ],
        ),
      );
    }

    final ticket = _ticket!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTicketHeader(ticket),
                const SizedBox(height: 16),
                _buildActionsCard(ticket),
                const SizedBox(height: 16),
                _buildConversation(ticket),
              ],
            ),
          ),
        ),
        _buildReplyInput(),
      ],
    );
  }

  // ── Ticket header card ────────────────────────────────────────────────────
  Widget _buildTicketHeader(PortalSupportTicket ticket) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ticket number + status
            Row(
              children: [
                Text(
                  ticket.ticketNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusBadge(ticket.status),
                const Spacer(),
                _buildPriorityBadge(ticket.priority),
              ],
            ),
            const SizedBox(height: 10),
            // Subject
            Text(
              ticket.subject,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            if (ticket.description != null &&
                ticket.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                ticket.description!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            const Divider(height: 24),
            // Meta info grid
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _buildMetaItem(
                    Icons.category_outlined, 'Category', _formatLabel(ticket.category)),
                _buildMetaItem(Icons.person_outline, 'Customer',
                    ticket.customerName ?? 'N/A'),
                if (ticket.customerEmail != null)
                  _buildMetaItem(Icons.email_outlined, 'Email',
                      ticket.customerEmail!),
                if (ticket.projectName != null)
                  _buildMetaItem(Icons.folder_outlined, 'Project',
                      ticket.projectName!),
                _buildMetaItem(Icons.schedule_outlined, 'Created',
                    _formatDate(ticket.createdAt)),
                _buildMetaItem(Icons.update_outlined, 'Updated',
                    _formatDate(ticket.updatedAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textTertiary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Actions card ──────────────────────────────────────────────────────────
  Widget _buildActionsCard(PortalSupportTicket ticket) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            // Assign row
            Row(
              children: [
                const Icon(Icons.person_pin_outlined,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                const Text('Assign to:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedAssignee,
                    isDense: true,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Unassigned')),
                      ..._portalUsers.map((u) => DropdownMenuItem(
                            value: u.id,
                            child: Text('${u.firstName} ${u.lastName}'),
                          )),
                    ],
                    onChanged: _isActioning
                        ? null
                        : (val) {
                            if (val != null) _assignTicket(val);
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status buttons
            Row(
              children: [
                const Icon(Icons.swap_horiz_outlined,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                const Text('Status:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                if (ticket.status != 'IN_PROGRESS' &&
                    ticket.status != 'RESOLVED' &&
                    ticket.status != 'CLOSED')
                  _buildActionButton(
                    label: 'Mark In Progress',
                    color: AppTheme.warningAmber,
                    onTap: () => _updateStatus('IN_PROGRESS'),
                  ),
                if (ticket.status != 'RESOLVED' &&
                    ticket.status != 'CLOSED') ...[
                  const SizedBox(width: 8),
                  _buildActionButton(
                    label: 'Mark Resolved',
                    color: AppTheme.successGreen,
                    onTap: () => _updateStatus('RESOLVED'),
                  ),
                ],
                if (ticket.status != 'CLOSED') ...[
                  const SizedBox(width: 8),
                  _buildActionButton(
                    label: 'Close',
                    color: AppTheme.textSecondary,
                    onTap: () => _updateStatus('CLOSED'),
                  ),
                ],
                if (ticket.status == 'CLOSED' || ticket.status == 'RESOLVED') ...[
                  const SizedBox(width: 8),
                  _buildActionButton(
                    label: 'Re-open',
                    color: AppTheme.skyBlue,
                    onTap: () => _updateStatus('OPEN'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: _isActioning ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  // ── Conversation thread ──────────────────────────────────────────────────
  Widget _buildConversation(PortalSupportTicket ticket) {
    final replies = ticket.replies;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Conversation (${replies.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (replies.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                child: const Text(
                  'No messages yet. Add the first reply below.',
                  style: TextStyle(color: AppTheme.textTertiary),
                ),
              )
            else
              ...replies.map((r) => _buildReplyBubble(r)),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBubble(PortalTicketReply reply) {
    final isStaff = reply.isStaff;
    final bubbleColor = isStaff
        ? const Color(0xFFDCF8DC) // light green for staff
        : const Color(0xFFDBECFB); // light blue for customer
    final alignment =
        isStaff ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final mainAlignment =
        isStaff ? MainAxisAlignment.end : MainAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          // Sender label
          Row(
            mainAxisAlignment: mainAlignment,
            children: [
              Icon(
                isStaff ? Icons.support_agent : Icons.person,
                size: 12,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                reply.userName ?? (isStaff ? 'Staff' : 'Customer'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(reply.createdAt),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isStaff ? 12 : 2),
                bottomRight: Radius.circular(isStaff ? 2 : 12),
              ),
            ),
            child: Text(
              reply.message,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reply input ──────────────────────────────────────────────────────────
  Widget _buildReplyInput() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      padding: const EdgeInsets.fromLTRB(
          defaultPadding, 10, defaultPadding, defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Type a reply...',
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
              ),
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: 10),
          _isSending
              ? const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.send_rounded),
                  color: AppTheme.primaryBlue,
                  iconSize: 28,
                  tooltip: 'Send reply',
                  onPressed: _sendReply,
                ),
        ],
      ),
    );
  }

  // ── Badge helpers ────────────────────────────────────────────────────────
  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'OPEN':
        color = AppTheme.skyBlue;
        break;
      case 'IN_PROGRESS':
        color = AppTheme.warningAmber;
        break;
      case 'RESOLVED':
        color = AppTheme.successGreen;
        break;
      default:
        color = AppTheme.textTertiary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        _formatLabel(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color == AppTheme.warningAmber
              ? const Color(0xFF8B6300)
              : color,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority) {
      case 'HIGH':
        color = AppTheme.errorRed;
        break;
      case 'MEDIUM':
        color = AppTheme.constructionOrange;
        break;
      default:
        color = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ── Formatting ───────────────────────────────────────────────────────────
  String _formatLabel(String raw) {
    return raw
        .split('_')
        .map((w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM yy, HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
