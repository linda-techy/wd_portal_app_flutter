import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/config/app_config.dart';
import 'package:admin/features/leads/data/models/lead_quotation.dart';
import 'package:admin/features/leads/data/services/lead_quotation_service.dart';
import 'package:admin/utils/error_handler.dart';

/// Bottom-sheet that handles the customer-facing share-link flow:
///
///   1. Regenerates / fetches the quotation's public_view_token
///   2. Composes the customer URL (`{customerShareBaseUrl}/q/{token}`)
///   3. Offers WhatsApp deep-link, email, or clipboard copy
///   4. Shows the running view count
///
/// "Regenerate" is intentionally a button, not implicit — staff sometimes
/// want a fresh token (after a leak) and sometimes want to keep the
/// existing one. Sticky default: reuse if a token already exists.
class QuotationShareSheet extends StatefulWidget {
  final LeadQuotation quotation;
  final String? customerPhone;

  const QuotationShareSheet({
    super.key,
    required this.quotation,
    this.customerPhone,
  });

  /// Convenience entry point — `await QuotationShareSheet.show(...)`.
  static Future<void> show(BuildContext context,
      {required LeadQuotation quotation, String? customerPhone}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => QuotationShareSheet(
        quotation: quotation,
        customerPhone: customerPhone,
      ),
    );
  }

  @override
  State<QuotationShareSheet> createState() => _QuotationShareSheetState();
}

class _QuotationShareSheetState extends State<QuotationShareSheet> {
  final _service = LeadQuotationService();
  bool _busy = false;
  String? _token;
  int? _viewCount;

  @override
  void initState() {
    super.initState();
    // Reuse the token if the parent quotation already carries one — the
    // common case after the first send. Otherwise we'll generate on demand
    // when staff hits a share action.
    _token = widget.quotation.publicViewToken;
    _loadViewCount();
  }

  Future<void> _loadViewCount() async {
    if (widget.quotation.id == null) return;
    try {
      final n = await _service.getViewCount(widget.quotation.id!);
      if (mounted) setState(() => _viewCount = n);
    } catch (_) {
      // View-count is informational; failing silently is fine.
    }
  }

  /// Fetch a token if we don't have one. Reused by every share action so
  /// the user never sees "no token yet" friction.
  Future<String?> _ensureToken() async {
    if (_token != null) return _token;
    if (widget.quotation.id == null) return null;
    setState(() => _busy = true);
    try {
      final fresh = await _service.regeneratePublicToken(widget.quotation.id!);
      if (mounted) setState(() => _token = fresh);
      return fresh;
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rotate() async {
    if (widget.quotation.id == null) return;
    setState(() => _busy = true);
    try {
      final fresh = await _service.regeneratePublicToken(widget.quotation.id!);
      if (mounted) {
        setState(() => _token = fresh);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Old link is now invalid. New link generated.')),
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareViaWhatsApp() async {
    final token = await _ensureToken();
    if (token == null) return;
    final url = AppConfig.buildQuotationShareUrl(token, source: 'WHATSAPP_LINK');
    final phone = _normalisePhone(widget.customerPhone);
    final message = Uri.encodeComponent(
        'Hi! Here is your quotation from Walldot Builders:\n$url\n\n'
        'Pricing locked till the validity date on the document. '
        'Reply here if you have any questions.');
    final waUrl = phone != null
        ? Uri.parse('https://wa.me/$phone?text=$message')
        : Uri.parse('https://wa.me/?text=$message');
    if (!await launchUrl(waUrl, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  Future<void> _shareViaEmail() async {
    final token = await _ensureToken();
    if (token == null) return;
    final url = AppConfig.buildQuotationShareUrl(token, source: 'EMAIL_LINK');
    final subject = Uri.encodeComponent(
        'Your quotation from Walldot Builders');
    final body = Uri.encodeComponent(
        'Hi,\n\nPlease find your quotation here: $url\n\n'
        'Pricing is locked till the validity date on the document.\n\n'
        'Best regards,\nWalldot Builders');
    final mailto = Uri.parse('mailto:?subject=$subject&body=$body');
    if (!await launchUrl(mailto)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open mail client')),
        );
      }
    }
  }

  Future<void> _copyLink() async {
    final token = await _ensureToken();
    if (token == null) return;
    final url = AppConfig.buildQuotationShareUrl(token, source: 'DIRECT');
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')),
      );
    }
  }

  /// Strip everything but digits and a leading "+", then drop the "+".
  /// `wa.me` expects the international number without "+" or spaces.
  String? _normalisePhone(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    final stripped =
        digits.startsWith('+') ? digits.substring(1) : digits;
    return stripped.isEmpty ? null : stripped;
  }

  @override
  Widget build(BuildContext context) {
    final url = _token != null
        ? AppConfig.buildQuotationShareUrl(_token!)
        : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Share quotation',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(widget.quotation.quotationNumber ?? '',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            if (_viewCount != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      _viewCount == 0
                          ? 'No customer views yet'
                          : 'Customer has viewed this $_viewCount time${_viewCount == 1 ? '' : 's'}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            if (url != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  url,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              )
            else
              const Text(
                'A share link will be generated when you pick a channel below.',
                style: TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text('Share via WhatsApp'),
              subtitle: widget.customerPhone != null
                  ? Text('To ${widget.customerPhone}')
                  : const Text('Contact will be picked at send time'),
              onTap: _busy ? null : _shareViaWhatsApp,
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Share via email'),
              onTap: _busy ? null : _shareViaEmail,
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy link'),
              onTap: _busy ? null : _copyLink,
            ),
            if (_token != null)
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.orange),
                title: const Text('Rotate link'),
                subtitle: const Text(
                    'Invalidates the old link and generates a fresh one'),
                onTap: _busy ? null : _rotate,
              ),
          ],
        ),
      ),
    );
  }
}
