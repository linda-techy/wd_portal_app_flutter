import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:admin/services/boq_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';

/// Modal dialog for managing the BoQ categories (project-scoped) of the
/// current project: list, create, edit, delete (soft-delete with item-count
/// guard).
///
/// Wired in from [BoqScreen]. The launcher should refresh its own
/// categories list after the dialog closes — newly added/removed categories
/// won't appear in the BoQ filter strip until then.
class BoqCategoriesDialog extends StatefulWidget {
  final int projectId;

  const BoqCategoriesDialog({super.key, required this.projectId});

  @override
  State<BoqCategoriesDialog> createState() => _BoqCategoriesDialogState();
}

class _BoqCategoriesDialogState extends State<BoqCategoriesDialog> {
  final BoqService _service = BoqService();
  bool _loading = true;
  List<BoqCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getCategories(widget.projectId);
      // Sort: top-level first by displayOrder, then children grouped under
      // their parents by displayOrder, fallback to name.
      final sorted = _sortHierarchically(list);
      if (!mounted) return;
      setState(() {
        _categories = sorted;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  List<BoqCategory> _sortHierarchically(List<BoqCategory> raw) {
    final byParent = <int?, List<BoqCategory>>{};
    for (final c in raw) {
      byParent.putIfAbsent(c.parentId, () => []).add(c);
    }
    for (final list in byParent.values) {
      list.sort((a, b) {
        final ord = a.displayOrder.compareTo(b.displayOrder);
        if (ord != 0) return ord;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }
    final result = <BoqCategory>[];
    void emit(int? parentId) {
      final children = byParent[parentId] ?? const [];
      for (final c in children) {
        result.add(c);
        emit(c.id);
      }
    }
    emit(null);
    return result;
  }

  Future<void> _openAddDialog() async {
    final created = await showDialog<BoqCategory>(
      context: context,
      builder: (_) => _CategoryEditDialog(
        service: _service,
        projectId: widget.projectId,
        existingCategories: _categories,
      ),
    );
    if (created != null) {
      ErrorHandler.showSuccessSnackBar(
        // ignore: use_build_context_synchronously
        context,
        'Category "${created.name}" created',
      );
      _load();
    }
  }

  Future<void> _openEditDialog(BoqCategory cat) async {
    final saved = await showDialog<BoqCategory>(
      context: context,
      builder: (_) => _CategoryEditDialog(
        service: _service,
        projectId: widget.projectId,
        existingCategories: _categories,
        existing: cat,
      ),
    );
    if (saved != null) {
      ErrorHandler.showSuccessSnackBar(
        // ignore: use_build_context_synchronously
        context,
        'Category "${saved.name}" updated',
      );
      _load();
    }
  }

  Future<void> _confirmDelete(BoqCategory cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Delete category "${cat.name}"? Items currently in this category '
          'will become uncategorized. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.coralRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteCategory(cat.id);
      if (!mounted) return;
      ErrorHandler.showSuccessSnackBar(context, 'Category deleted');
      _load();
    } catch (e) {
      if (!mounted) return;
      // Backend returns 409 if items still reference this category.
      if (e is DioException && e.response?.statusCode == 409) {
        final data = e.response?.data;
        String msg;
        if (data is Map && data['message'] is String &&
            (data['message'] as String).isNotEmpty) {
          msg = data['message'];
        } else if (cat.itemCount > 0) {
          msg =
              'Cannot delete — ${cat.itemCount} item${cat.itemCount == 1 ? '' : 's'} '
              'still reference this category. Reassign first.';
        } else {
          msg =
              'Cannot delete — items still reference this category. '
              'Reassign first.';
        }
        ErrorHandler.showWarningSnackBar(context, msg);
      } else {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.category, color: AppTheme.deepSlate),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Manage BoQ Categories',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: _loading ? null : _load,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _categories.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.category_outlined,
                                    size: 56, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  'No categories yet.',
                                  style: TextStyle(
                                      fontSize: 15, color: Colors.grey),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Add the first one to start grouping BoQ items.',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (ctx, i) =>
                              _buildCategoryTile(_categories[i]),
                        ),
            ),
            const Divider(height: 1),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Category'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepSlate,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _loading ? null : _openAddDialog,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(BoqCategory cat) {
    final isChild = cat.isSubcategory;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(isChild ? 32 : 12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isChild ? Icons.subdirectory_arrow_right : Icons.folder,
              size: 18,
              color: isChild ? Colors.grey : AppTheme.deepSlate,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          cat.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _orderChip(cat.displayOrder),
                      if (cat.itemCount > 0) ...[
                        const SizedBox(width: 6),
                        _itemCountChip(cat.itemCount),
                      ],
                    ],
                  ),
                  if (cat.description != null &&
                      cat.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      cat.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (isChild && cat.parentName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '\u21B3 child of ${cat.parentName}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit',
              onPressed: () => _openEditDialog(cat),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppTheme.coralRed),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(cat),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderChip(int order) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.deepSlate.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '#$order',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.deepSlate,
        ),
      ),
    );
  }

  Widget _itemCountChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$count item${count == 1 ? '' : 's'}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.blue,
        ),
      ),
    );
  }
}

/// Add/edit dialog for a single BoQ category.
class _CategoryEditDialog extends StatefulWidget {
  final BoqService service;
  final int projectId;
  final List<BoqCategory> existingCategories;
  final BoqCategory? existing;

  const _CategoryEditDialog({
    required this.service,
    required this.projectId,
    required this.existingCategories,
    this.existing,
  });

  bool get isEdit => existing != null;

  @override
  State<_CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<_CategoryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _orderCtrl;
  int? _parentId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl =
        TextEditingController(text: widget.existing?.description ?? '');
    _orderCtrl = TextEditingController(
        text: (widget.existing?.displayOrder ?? 0).toString());
    _parentId = widget.existing?.parentId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  /// Categories eligible to be a parent for the current edit:
  /// excludes the category itself, plus all its descendants (to prevent cycles).
  List<BoqCategory> _eligibleParents() {
    if (!widget.isEdit) return widget.existingCategories;
    final selfId = widget.existing!.id;
    final excluded = <int>{selfId};
    bool changed = true;
    while (changed) {
      changed = false;
      for (final c in widget.existingCategories) {
        if (c.parentId != null &&
            excluded.contains(c.parentId) &&
            !excluded.contains(c.id)) {
          excluded.add(c.id);
          changed = true;
        }
      }
    }
    return widget.existingCategories
        .where((c) => !excluded.contains(c.id))
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final name = _nameCtrl.text.trim();
    final descRaw = _descCtrl.text.trim();
    final description = descRaw.isEmpty ? null : descRaw;
    final order = int.tryParse(_orderCtrl.text.trim()) ?? 0;
    try {
      BoqCategory result;
      if (widget.isEdit) {
        // For updates, we always send name/description/order; for parentId
        // we explicitly clear when set to null on a category that previously
        // had a parent.
        final hadParent = widget.existing!.parentId != null;
        result = await widget.service.updateCategory(
          widget.existing!.id,
          name: name,
          description: description ?? '',
          displayOrder: order,
          parentId: _parentId,
          clearParent: hadParent && _parentId == null,
        );
      } else {
        result = await widget.service.createCategory(
          projectId: widget.projectId,
          name: name,
          description: description,
          displayOrder: order,
          parentId: _parentId,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eligible = _eligibleParents();
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Category' : 'New Category'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name
                TextFormField(
                  controller: _nameCtrl,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(255),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Name is required';
                    if (s.length > 255) return 'Max 255 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Description
                TextFormField(
                  controller: _descCtrl,
                  minLines: 3,
                  maxLines: 5,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(1000),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.length > 1000) return 'Max 1000 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Display order
                TextFormField(
                  controller: _orderCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Display order',
                    helperText: 'Lower numbers appear first (default: 0)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return null;
                    if (int.tryParse(s) == null) {
                      return 'Enter a whole number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Parent dropdown
                DropdownButtonFormField<int?>(
                  value: _parentId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Parent category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: <DropdownMenuItem<int?>>[
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Top-level (no parent)'),
                    ),
                    ...eligible.map(
                      (c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(
                          c.parentName != null
                              ? '${c.parentName} \u203A ${c.name}'
                              : c.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _parentId = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.deepSlate,
            foregroundColor: Colors.white,
          ),
          child: Text(_saving
              ? 'Saving...'
              : (widget.isEdit ? 'Save changes' : 'Create category')),
        ),
      ],
    );
  }
}
