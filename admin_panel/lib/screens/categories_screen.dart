import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/category_provider.dart';
import '../models/category_model.dart';
import '../widgets/confirm_dialog.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showForm([CategoryModel? cat]) {
    showDialog(
      context: context,
      builder: (ctx) => _CategoryFormDialog(category: cat),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CategoryProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Categories',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              ),
              SizedBox(
                width: 260,
                height: 40,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by name or ID...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              cp.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) {
                    setState(() {});
                    cp.setSearchQuery(v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Category'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.dividerColor.withValues(alpha: 0.5)),
              ),
              child: cp.isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.gold))
                  : Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(flex: 1, child: Text('ID', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 3, child: Text('Slug', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 2, child: Text('Products', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                            ],
                          ),
                        ),

                        // Table Rows
                        Expanded(
                          child: ListView.builder(
                            itemCount: cp.filteredCategories.length,
                            itemBuilder: (ctx, i) {
                              final c = cp.filteredCategories[i];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.3)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(flex: 1, child: Text('#${c.id}', style: const TextStyle(fontSize: 13))),
                                    Expanded(flex: 3, child: Text(c.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                                    Expanded(flex: 3, child: Text(c.slug, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                                    Expanded(flex: 2, child: Text(c.productCount?.toString() ?? '0', style: const TextStyle(fontSize: 13))),
                                    Expanded(flex: 2, child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.info),
                                          onPressed: () => _showForm(c),
                                          tooltip: 'Edit',
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.delete_rounded, size: 18, color: AppTheme.danger),
                                          onPressed: () async {
                                            final ok = await showConfirmDialog(
                                              context,
                                              title: 'Delete Category',
                                              message: 'Delete "${c.name}"? Products in this category will be uncategorized.',
                                              confirmText: 'Delete',
                                            );
                                            if (ok && mounted) {
                                              cp.deleteCategory(c.id);
                                            }
                                          },
                                          tooltip: 'Delete',
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6),
                                        ),
                                      ],
                                    )),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Form ─────────────────────────────────────────────

class _CategoryFormDialog extends StatefulWidget {
  final CategoryModel? category;
  const _CategoryFormDialog({this.category});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _imageCtrl;
  int? _parentId;
  bool _saving = false;

  bool get isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _imageCtrl = TextEditingController(text: c?.imageUrl ?? '');
    _parentId = c?.parentId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
    };
    if (_descCtrl.text.trim().isNotEmpty) body['description'] = _descCtrl.text.trim();
    if (_imageCtrl.text.trim().isNotEmpty) body['image_url'] = _imageCtrl.text.trim();
    if (_parentId != null) body['parent_id'] = _parentId;

    final cp = context.read<CategoryProvider>();
    bool ok;
    if (isEdit) {
      ok = await cp.updateCategory(widget.category!.id, body);
    } else {
      ok = await cp.createCategory(body);
    }

    if (mounted) {
      setState(() => _saving = false);
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CategoryProvider>().categories;

    return Dialog(
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'Edit Category' : 'Add Category',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Category Name *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageCtrl,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _parentId,
                decoration:
                    const InputDecoration(labelText: 'Parent Category'),
                dropdownColor: AppTheme.surfaceDark,
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...cats
                      .where((c) => c.id != widget.category?.id)
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => setState(() => _parentId = v),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.bgDark))
                        : Text(isEdit ? 'Update' : 'Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
