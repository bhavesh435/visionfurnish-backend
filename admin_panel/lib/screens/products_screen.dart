import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../config/app_theme.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../models/product_model.dart';
import '../widgets/confirm_dialog.dart';
import '../services/upload_service.dart';
import '../providers/auth_provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ProductProvider>().fetchProducts();
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showProductForm([ProductModel? product]) {
    showDialog(
      context: context,
      builder: (ctx) => _ProductFormDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    final currFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Products',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
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
                              pp.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) {
                    setState(() {});
                    pp.setSearchQuery(v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showProductForm(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Product'),
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
                border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
              ),
              child: pp.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.5))),
                          ),
                          child: const Row(children: [
                            Expanded(flex: 1, child: Text('ID', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                            Expanded(flex: 1, child: Text('Image', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                            Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                            Expanded(flex: 2, child: Text('Price', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                            Expanded(flex: 1, child: Text('Stock', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                            Expanded(flex: 2, child: Text('Category', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                            Expanded(flex: 1, child: Text('Featured', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                            Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                          ]),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: pp.filteredProducts.length,
                            itemBuilder: (ctx, i) {
                              final p = pp.filteredProducts[i];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.3))),
                                ),
                                child: Row(children: [
                                  Expanded(flex: 1, child: Text('#${p.id}', style: const TextStyle(fontSize: 13))),
                                  Expanded(flex: 1, child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                        ? GestureDetector(
                                            onTap: () => _showImagePreview(p.imageUrl!, p.name),
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: Image.network(p.imageUrl!, width: 40, height: 40, fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => Container(width: 40, height: 40, color: AppTheme.surfaceDark, child: const Icon(Icons.broken_image_rounded, size: 18, color: AppTheme.textSecondary))),
                                              ),
                                            ),
                                          )
                                        : Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.image_rounded, size: 18, color: AppTheme.textSecondary)),
                                  )),
                                  Expanded(flex: 3, child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                      Row(children: [
                                        if (p.images360.isNotEmpty) _badge('360°', Colors.blue),
                                        if (p.colorVariants.isNotEmpty) _badge('Colors', Colors.purple),
                                        if (p.arModel != null) _badge('AR', Colors.green),
                                      ]),
                                    ],
                                  )),
                                  Expanded(flex: 2, child: Text(currFmt.format(p.price), style: const TextStyle(fontSize: 13))),
                                  Expanded(flex: 1, child: Text(p.stock.toString(), style: TextStyle(color: p.stock > 0 ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.w600, fontSize: 13))),
                                  Expanded(flex: 2, child: Text(p.categoryName ?? '—', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                                  Expanded(flex: 1, child: Align(alignment: Alignment.centerLeft, child: Icon(p.isFeatured ? Icons.star_rounded : Icons.star_border_rounded, color: p.isFeatured ? AppTheme.gold : AppTheme.textSecondary, size: 20))),
                                  Expanded(flex: 2, child: Row(children: [
                                    IconButton(icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.info), onPressed: () => _showProductForm(p), tooltip: 'Edit', constraints: const BoxConstraints(), padding: const EdgeInsets.all(6)),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded, size: 18, color: AppTheme.danger),
                                      onPressed: () async {
                                        final ok = await showConfirmDialog(context, title: 'Delete Product', message: 'Are you sure you want to delete "${p.name}"?', confirmText: 'Delete');
                                        if (ok && mounted) pp.deleteProduct(p.id);
                                      },
                                      tooltip: 'Delete', constraints: const BoxConstraints(), padding: const EdgeInsets.all(6),
                                    ),
                                  ])),
                                ]),
                              );
                            },
                          ),
                        ),
                        if (pp.totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              IconButton(onPressed: pp.currentPage > 1 ? () => pp.fetchProducts(page: pp.currentPage - 1) : null, icon: const Icon(Icons.chevron_left_rounded)),
                              Text('Page ${pp.currentPage} of ${pp.totalPages}', style: const TextStyle(color: AppTheme.textSecondary)),
                              IconButton(onPressed: pp.currentPage < pp.totalPages ? () => pp.fetchProducts(page: pp.currentPage + 1) : null, icon: const Icon(Icons.chevron_right_rounded)),
                            ]),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(String imageUrl, String productName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(32),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 48, 8),
                    child: Text(
                      productName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Flexible(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 300,
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.broken_image_rounded, size: 48, color: AppTheme.textSecondary),
                                  SizedBox(height: 8),
                                  Text('Failed to load image', style: TextStyle(color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: AppTheme.bgDark.withValues(alpha: 0.7),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(ctx),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.close_rounded, color: AppTheme.textPrimary, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    margin: const EdgeInsets.only(right: 4, top: 2),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
  );
}

// ── Product Form Dialog ───────────────────────────────────────

class _ProductFormDialog extends StatefulWidget {
  final ProductModel? product;
  const _ProductFormDialog({this.product});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ColorVariantEntry {
  TextEditingController name;
  TextEditingController hex;
  List<TextEditingController> images;

  _ColorVariantEntry({String nameVal = '', String hexVal = '#AAAAAA', List<String> imgVals = const []})
      : name = TextEditingController(text: nameVal),
        hex = TextEditingController(text: hexVal),
        images = imgVals.map((v) => TextEditingController(text: v)).toList();

  void dispose() {
    name.dispose();
    hex.dispose();
    for (final c in images) c.dispose();
  }

  Map<String, dynamic> toJson() => {
    'name': name.text.trim(),
    'hex': hex.text.trim().isEmpty ? '#AAAAAA' : hex.text.trim(),
    'images': images.map((c) => c.text.trim()).where((v) => v.isNotEmpty).toList(),
  };
}

class _ProductFormDialogState extends State<_ProductFormDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabCtrl;

  // Basic fields
  late TextEditingController _nameCtrl, _descCtrl, _priceCtrl, _discountCtrl, _stockCtrl,
      _imageCtrl, _materialCtrl, _dimensionsCtrl, _colorCtrl, _arModelCtrl;
  int? _categoryId;
  bool _isFeatured = false;
  bool _saving = false;

  // Extra images (existing)
  final List<TextEditingController> _extraImageCtrls = [];
  // 360° images
  final List<TextEditingController> _img360Ctrls = [];
  // Color variants
  final List<_ColorVariantEntry> _colorVariants = [];

  // AR upload state
  bool _arUploading = false;
  String? _arUploadError;
  String? _arUploadedFilename;

  // AI Generate 3D state
  bool   _aiGenerating    = false;
  int    _aiProgress      = 0;
  String? _aiTaskId;
  String? _aiError;
  String? _aiStatus;
  Timer?  _aiPollTimer;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    final p = widget.product;
    _nameCtrl       = TextEditingController(text: p?.name ?? '');
    _descCtrl       = TextEditingController(text: p?.description ?? '');
    _priceCtrl      = TextEditingController(text: p?.price.toString() ?? '');
    _discountCtrl   = TextEditingController(text: p?.discountPrice?.toString() ?? '');
    _stockCtrl      = TextEditingController(text: p?.stock.toString() ?? '0');
    _imageCtrl      = TextEditingController(text: p?.imageUrl ?? '');
    _materialCtrl   = TextEditingController(text: p?.material ?? '');
    _dimensionsCtrl = TextEditingController(text: p?.dimensions ?? '');
    _colorCtrl      = TextEditingController(text: p?.color ?? '');
    _arModelCtrl    = TextEditingController(text: p?.arModel ?? '');
    _categoryId     = p?.categoryId;
    _isFeatured     = p?.isFeatured ?? false;

    if (p != null) {
      for (final img in p.images) _extraImageCtrls.add(TextEditingController(text: img));
      for (final img in p.images360) _img360Ctrls.add(TextEditingController(text: img));
      for (final cv in p.colorVariants) {
        _colorVariants.add(_ColorVariantEntry(nameVal: cv.name, hexVal: cv.hex, imgVals: cv.images));
      }
    }
  }

  @override
  void dispose() {
    _aiPollTimer?.cancel();
    _tabCtrl.dispose();
    for (final c in [_nameCtrl, _descCtrl, _priceCtrl, _discountCtrl, _stockCtrl,
      _imageCtrl, _materialCtrl, _dimensionsCtrl, _colorCtrl, _arModelCtrl]) c.dispose();
    for (final c in _extraImageCtrls) c.dispose();
    for (final c in _img360Ctrls) c.dispose();
    for (final cv in _colorVariants) cv.dispose();
    super.dispose();
  }

  // ── Auto-Assign 3D Model (Free & Instant) ───────────────────
  Future<void> _startAiGeneration() async {
    if (!isEdit) return;
    final productId = widget.product!.id;
    final token = await context.read<AuthProvider>().token ?? '';

    setState(() {
      _aiGenerating = true;
      _aiProgress   = 0;
      _aiError      = null;
      _aiStatus     = 'PENDING';
      _aiTaskId     = null;
    });

    try {
      // Animate progress bar while waiting
      _aiPollTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() { if (_aiProgress < 85) _aiProgress += 5; });
      });

      // Call backend — returns instantly with the matched model URL
      final result = await UploadService.startGenerate3D(productId, token);
      _aiPollTimer?.cancel();

      if (!mounted) return;

      final glbUrl     = result['glbUrl']     as String?;
      final modelLabel = result['modelLabel'] as String? ?? '3D Model';
      final status     = result['status']     as String? ?? 'SUCCEEDED';

      if (status == 'SUCCEEDED' && glbUrl != null) {
        setState(() {
          _arModelCtrl.text = glbUrl;
          _aiGenerating     = false;
          _aiProgress       = 100;
          _aiStatus         = 'SUCCEEDED';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 3D model assigned: $modelLabel'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        setState(() { _aiGenerating = false; _aiError = 'No model found for this product.'; });
      }
    } catch (e) {
      _aiPollTimer?.cancel();
      if (mounted) {
        setState(() {
          _aiGenerating = false;
          _aiError      = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }


  // ── Pick & Upload .glb ──────────────────────────────────────
  Future<void> _pickAndUploadGlb() async {
    setState(() {
      _arUploading = false;
      _arUploadError = null;
    });

    // Open OS file picker filtered to .glb/.gltf
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['glb', 'gltf'],
      dialogTitle: 'Select 3D Model (.glb)',
    );

    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) return;

    setState(() => _arUploading = true);

    try {
      final url = await UploadService.uploadGlbModel(File(picked.path!));
      if (mounted) {
        setState(() {
          _arModelCtrl.text = url;
          _arUploadedFilename = picked.name;
          _arUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _arUploadError = e.toString().replaceFirst('Exception: ', '');
          _arUploading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // Send price/stock/discount_price as strings so express-validator's
    // isFloat / isInt validators (which require string input) pass.
    final body = <String, dynamic>{
      'name':        _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price':       _priceCtrl.text.trim(),
      'stock':       _stockCtrl.text.trim(),
      'is_featured': _isFeatured,
    };

    if (_discountCtrl.text.trim().isNotEmpty) body['discount_price'] = _discountCtrl.text.trim();
    if (_categoryId != null) body['category_id'] = _categoryId;
    if (_imageCtrl.text.trim().isNotEmpty) body['image_url'] = _imageCtrl.text.trim();
    if (_materialCtrl.text.trim().isNotEmpty) body['material'] = _materialCtrl.text.trim();
    if (_dimensionsCtrl.text.trim().isNotEmpty) body['dimensions'] = _dimensionsCtrl.text.trim();
    if (_colorCtrl.text.trim().isNotEmpty) body['color'] = _colorCtrl.text.trim();
    if (_arModelCtrl.text.trim().isNotEmpty) body['ar_model'] = _arModelCtrl.text.trim();

    final extraImages = _extraImageCtrls.map((c) => c.text.trim()).where((v) => v.isNotEmpty).toList();
    if (extraImages.isNotEmpty) body['images'] = extraImages;

    final imgs360 = _img360Ctrls.map((c) => c.text.trim()).where((v) => v.isNotEmpty).toList();
    if (imgs360.isNotEmpty) body['images_360'] = imgs360;

    final colorVars = _colorVariants.map((cv) => cv.toJson()).where((cv) => (cv['name'] as String).isNotEmpty).toList();
    if (colorVars.isNotEmpty) body['color_variants'] = colorVars;

    final pp = context.read<ProductProvider>();
    final bool ok = isEdit ? await pp.updateProduct(widget.product!.id, body) : await pp.createProduct(body);

    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        Navigator.pop(context);
      } else if (pp.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pp.error!),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CategoryProvider>().categories;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 640,
        constraints: const BoxConstraints(maxHeight: 760),
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'Edit Product' : 'Add Product',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              // Tabs
              TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppTheme.gold,
                labelColor: AppTheme.gold,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: const [
                  Tab(text: 'Basic Info'),
                  Tab(text: '360° & AR'),
                  Tab(text: 'Color Variants'),
                ],
              ),
              const SizedBox(height: 12),

              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    // ── Tab 1: Basic Info ──
                    SingleChildScrollView(
                      child: Column(children: [
                        TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Product Name *'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: TextFormField(controller: _priceCtrl, decoration: const InputDecoration(labelText: 'Price *'), keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _discountCtrl, decoration: const InputDecoration(labelText: 'Discount Price'), keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _stockCtrl, decoration: const InputDecoration(labelText: 'Stock *'), keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
                        ]),
                        const SizedBox(height: 12),
                        TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: _categoryId,
                          decoration: const InputDecoration(labelText: 'Category'),
                          dropdownColor: AppTheme.surfaceDark,
                          items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                          onChanged: (v) => setState(() => _categoryId = v),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(controller: _imageCtrl, decoration: const InputDecoration(labelText: 'Main Image URL')),
                        const SizedBox(height: 8),
                        ..._extraImageCtrls.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            Expanded(child: TextFormField(controller: e.value, decoration: InputDecoration(labelText: 'Additional Image ${e.key + 1}'))),
                            IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppTheme.danger, size: 20), onPressed: () => setState(() { _extraImageCtrls[e.key].dispose(); _extraImageCtrls.removeAt(e.key); })),
                          ]),
                        )),
                        TextButton.icon(onPressed: () => setState(() => _extraImageCtrls.add(TextEditingController())), icon: const Icon(Icons.add_photo_alternate_rounded, size: 18), label: const Text('Add Extra Image URL')),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: TextFormField(controller: _materialCtrl, decoration: const InputDecoration(labelText: 'Material'))),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _dimensionsCtrl, decoration: const InputDecoration(labelText: 'Dimensions'))),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _colorCtrl, decoration: const InputDecoration(labelText: 'Color'))),
                        ]),
                        const SizedBox(height: 12),
                        SwitchListTile(value: _isFeatured, onChanged: (v) => setState(() => _isFeatured = v), title: const Text('Featured Product'), activeThumbColor: AppTheme.gold, contentPadding: EdgeInsets.zero),
                      ]),
                    ),

                    // ── Tab 2: 360° Images & AR ──
                    SingleChildScrollView(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        // ── AI Generate 3D Card ───────────────────
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.gold.withValues(alpha: 0.08),
                                Colors.purple.withValues(alpha: 0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _aiError != null
                                  ? AppTheme.danger
                                  : _aiProgress == 100
                                      ? AppTheme.success
                                      : AppTheme.gold.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Icon(Icons.auto_awesome_rounded,
                                  color: AppTheme.gold, size: 18),
                              const SizedBox(width: 8),
                              const Text('Auto-Assign 3D Model (Free & Instant)',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              const Spacer(),
                              if (_aiStatus != null && _aiGenerating)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.gold.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(_aiStatus ?? '',
                                      style: const TextStyle(fontSize: 10, color: AppTheme.gold,
                                          fontWeight: FontWeight.w600)),
                                ),
                            ]),
                            const SizedBox(height: 4),
                            Text(
                              'Auto-assigns a free furniture 3D model based on product name & category. Instant!',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 12),

                            if (_aiGenerating) ...[  
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: _aiProgress / 100,
                                  backgroundColor: AppTheme.gold.withValues(alpha: 0.15),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(children: [
                                const SizedBox(width: 4, height: 4,
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.gold)),
                                const SizedBox(width: 10),
                                Text('Assigning 3D model... $_aiProgress%',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                const Spacer(),
                                Text('~1–5 min',
                                    style: TextStyle(fontSize: 11,
                                        color: AppTheme.textSecondary.withValues(alpha: 0.6))),
                              ]),
                            ] else if (_aiProgress == 100) ...[  
                              Row(children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: AppTheme.success, size: 18),
                                const SizedBox(width: 8),
                                const Text('3D model ready! URL auto-filled below.',
                                    style: TextStyle(fontSize: 12, color: AppTheme.success,
                                        fontWeight: FontWeight.w600)),
                              ]),
                            ] else ...[  
                              // Generate button
                              SizedBox(
                                height: 38,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.gold,
                                    foregroundColor: AppTheme.bgDark,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                    disabledBackgroundColor: AppTheme.gold.withValues(alpha: 0.3),
                                  ),
                                  onPressed: (!isEdit || _imageCtrl.text.trim().isEmpty)
                                      ? null
                                      : _startAiGeneration,
                                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                                  label: const Text('Generate 3D Model'),
                                ),
                              ),
                              if (!isEdit)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text('Save the product first, then generate 3D.',
                                      style: TextStyle(fontSize: 11,
                                          color: AppTheme.textSecondary.withValues(alpha: 0.7))),
                                )
                              else if (_imageCtrl.text.trim().isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text('Add a Main Image URL first to enable AI generation.',
                                      style: TextStyle(fontSize: 11,
                                          color: AppTheme.textSecondary.withValues(alpha: 0.7))),
                                ),
                            ],

                            if (_aiError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: AppTheme.danger, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(_aiError!,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.danger))),
                                ]),
                              ),
                          ]),
                        ),
                        const Divider(height: 8),
                        const Text('360° Images', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Add image URLs for the 360° view. Multiple angles recommended (front, side, back, etc.)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(height: 10),
                        ..._img360Ctrls.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            Expanded(child: TextFormField(controller: e.value, decoration: InputDecoration(labelText: '360° Image ${e.key + 1} URL', prefixIcon: const Icon(Icons.threesixty_rounded, size: 18)))),
                            IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppTheme.danger, size: 20), onPressed: () => setState(() { _img360Ctrls[e.key].dispose(); _img360Ctrls.removeAt(e.key); })),
                          ]),
                        )),
                        TextButton.icon(onPressed: () => setState(() => _img360Ctrls.add(TextEditingController())), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Add 360° Image URL')),
                        const Divider(height: 28),

                        // ── AR Model Upload ────────────────────────────
                        const Text('AR 3D Model (.glb)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          'Upload a .glb file — the mobile app will load it in Three.js AR mode.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 12),

                        // Upload button area
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _arUploadError != null
                                  ? AppTheme.danger
                                  : _arUploadedFilename != null || _arModelCtrl.text.isNotEmpty
                                      ? AppTheme.success
                                      : AppTheme.dividerColor,
                            ),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            // File info or placeholder
                            if (_arUploadedFilename != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(children: [
                                  const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _arUploadedFilename!,
                                      style: const TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ]),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(children: [
                                  Icon(Icons.view_in_ar_rounded,
                                      color: _arModelCtrl.text.isNotEmpty ? AppTheme.success : AppTheme.textSecondary,
                                      size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _arModelCtrl.text.isNotEmpty ? 'Model already set (see URL below)' : 'No .glb file selected',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _arModelCtrl.text.isNotEmpty ? AppTheme.success : AppTheme.textSecondary,
                                    ),
                                  ),
                                ]),
                              ),

                            // Upload button / progress
                            if (_arUploading)
                              const Row(children: [
                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold)),
                                SizedBox(width: 10),
                                Text('Uploading 3D model…', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              ])
                            else
                              SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.gold.withValues(alpha: 0.15),
                                    foregroundColor: AppTheme.gold,
                                    side: const BorderSide(color: AppTheme.gold),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  onPressed: _pickAndUploadGlb,
                                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                                  label: Text(_arUploadedFilename != null ? 'Replace .glb File' : 'Pick .glb File'),
                                ),
                              ),

                            // Error
                            if (_arUploadError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(_arUploadError!, style: const TextStyle(fontSize: 11, color: AppTheme.danger)),
                              ),
                          ]),
                        ),

                        const SizedBox(height: 12),
                        // Manual URL override
                        TextFormField(
                          controller: _arModelCtrl,
                          decoration: const InputDecoration(
                            labelText: 'AR Model URL (auto-filled after upload, or paste manually)',
                            prefixIcon: Icon(Icons.link_rounded, size: 18),
                          ),
                          style: const TextStyle(fontSize: 12),
                          onChanged: (_) => setState(() {}),
                        ),
                        if (_arModelCtrl.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('✓ AR model URL is set', style: TextStyle(fontSize: 12, color: AppTheme.success)),
                          ),
                      ]),
                    ),

                    // ── Tab 3: Color Variants ──
                    SingleChildScrollView(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Color Variants', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Each variant has a name, hex color code, and images for that color.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(height: 12),
                        ..._colorVariants.asMap().entries.map((e) {
                          final cv = e.value;
                          final idx = e.key;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.dividerColor),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: TextFormField(controller: cv.name, decoration: const InputDecoration(labelText: 'Color Name', isDense: true))),
                                const SizedBox(width: 12),
                                Expanded(child: TextFormField(controller: cv.hex, decoration: const InputDecoration(labelText: 'Hex Code (e.g. #4A6741)', isDense: true))),
                                const SizedBox(width: 8),
                                // Color preview box
                                StatefulBuilder(builder: (ctx, set) {
                                  Color? c;
                                  try { c = Color(int.parse('FF${cv.hex.text.replaceAll('#', '')}', radix: 16)); } catch (_) {}
                                  return Container(width: 36, height: 36, decoration: BoxDecoration(color: c ?? Colors.grey, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.dividerColor)));
                                }),
                                const SizedBox(width: 4),
                                IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 20), onPressed: () => setState(() { _colorVariants[idx].dispose(); _colorVariants.removeAt(idx); })),
                              ]),
                              const SizedBox(height: 10),
                              const Text('Images for this color:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(height: 6),
                              ...cv.images.asMap().entries.map((ie) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(children: [
                                  Expanded(child: TextFormField(controller: ie.value, decoration: InputDecoration(labelText: 'Image ${ie.key + 1} URL', isDense: true))),
                                  IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppTheme.danger, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => setState(() { cv.images[ie.key].dispose(); cv.images.removeAt(ie.key); })),
                                ]),
                              )),
                              TextButton.icon(onPressed: () => setState(() => cv.images.add(TextEditingController())), icon: const Icon(Icons.add_photo_alternate_outlined, size: 16), label: const Text('Add Image', style: TextStyle(fontSize: 12))),
                            ]),
                          );
                        }),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _colorVariants.add(_ColorVariantEntry())),
                          icon: const Icon(Icons.palette_outlined, size: 18),
                          label: const Text('Add Color Variant'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceDark, foregroundColor: AppTheme.gold),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bgDark))
                      : Text(isEdit ? 'Update' : 'Create'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
