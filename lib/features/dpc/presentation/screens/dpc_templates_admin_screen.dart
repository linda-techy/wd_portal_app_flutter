import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/constants.dart';
import 'package:admin/models/dpc/dpc_scope_template.dart';
import 'package:admin/services/dpc_template_service.dart';
import 'package:admin/utils/error_handler.dart';

/// Admin-only listing of DPC scope templates.
///
/// Renders the 10 (or however many) `DpcScopeTemplate` rows; tapping a row
/// pushes the per-template editor.
class DpcTemplatesAdminScreen extends StatefulWidget {
  const DpcTemplatesAdminScreen({super.key});

  @override
  State<DpcTemplatesAdminScreen> createState() =>
      _DpcTemplatesAdminScreenState();
}

class _DpcTemplatesAdminScreenState extends State<DpcTemplatesAdminScreen> {
  final DpcTemplateService _service = DpcTemplateService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<DpcScopeTemplate> _templates = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.listTemplates();
      list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      if (!mounted) return;
      setState(() {
        _templates = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorHandler.getErrorMessage(e);
        _loading = false;
      });
    }
  }

  List<DpcScopeTemplate> get _filtered {
    if (_query.isEmpty) return _templates;
    final q = _query.toLowerCase();
    return _templates.where((t) {
      return t.code.toLowerCase().contains(q) ||
          t.title.toLowerCase().contains(q) ||
          (t.subtitle?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('DPC Scope Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: containerBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search templates by code or title...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: defaultPadding),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: errorColor),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return const Center(
        child: Text('No templates found.',
            style: TextStyle(color: textSecondary)),
      );
    }
    return ListView.separated(
      itemBuilder: (ctx, i) => _templateCard(filtered[i]),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: filtered.length,
    );
  }

  Widget _templateCard(DpcScopeTemplate t) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.go('/dpc/templates/${t.id}'),
      child: Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: containerBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: boxPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${t.displayOrder}',
                  style: const TextStyle(
                      color: primaryColor, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: boxInfo,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: boxBorderInfo),
                        ),
                        child: Text(t.code,
                            style: const TextStyle(
                                fontSize: 11,
                                color: infoColor,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (t.subtitle != null && t.subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(t.subtitle!,
                          style: const TextStyle(
                              fontSize: 12, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: boxGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${t.options.length} options',
                  style: const TextStyle(
                      fontSize: 11, color: textSecondary)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: textMuted),
          ],
        ),
      ),
    );
  }
}
