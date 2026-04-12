import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../models/models.dart';
import '../../providers/product_provider.dart';
import '../../providers/providers.dart';
import '../../config/theme.dart';
import '../cart/checkout_screen.dart';
import 'ar_view_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _pageCtrl = PageController();
  int _selectedColorIdx = -1;
  bool _addingToCart = false;
  Product? _product;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final p = await context.read<ProductProvider>().fetchProductById(widget.productId);
    if (mounted) setState(() { _product = p; _loading = false; });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _selectColor(int idx) {
    setState(() {
      _selectedColorIdx = _selectedColorIdx == idx ? -1 : idx;
    });
    if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(0);
  }

  Future<void> _addToCart(int productId) async {
    setState(() => _addingToCart = true);
    await context.read<CartProvider>().addToCart(productId);
    if (mounted) setState(() => _addingToCart = false);
  }

  List<String> _heroImages(Product p) {
    if (_selectedColorIdx >= 0 && p.colorVariants[_selectedColorIdx].images.isNotEmpty) {
      return p.colorVariants[_selectedColorIdx].images;
    }
    if (p.images360.isNotEmpty) return p.images360;
    if (p.images.isNotEmpty) return p.images;
    if (p.imageUrl != null) return [p.imageUrl!];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFC9A96E))),
      );
    }
    if (_product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(backgroundColor: const Color(0xFF0A0A0A)),
        body: const Center(child: Text('Product not found', style: TextStyle(color: Colors.white))),
      );
    }

    final p = _product!;
    final wishlistP = context.watch<WishlistProvider>();
    final isWished = wishlistP.isWishlisted(p.id);
    final images = _heroImages(p);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: CustomScrollView(
        slivers: [
          // ── Hero Image ──
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: AppTheme.bgSurface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                  child: Icon(isWished ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isWished ? Colors.redAccent : Colors.white, size: 20),
                ),
                onPressed: () => context.read<WishlistProvider>().toggle(p.id),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(children: [
                if (images.isEmpty)
                  Container(color: AppTheme.bgSurface, child: const Center(
                    child: Icon(Icons.image_not_supported_outlined, size: 60, color: AppTheme.textSecondary)))
                else ...[
                  PageView.builder(
                    controller: _pageCtrl,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() {}),
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: images[i], fit: BoxFit.cover, width: double.infinity,
                      placeholder: (_, __) => Container(color: AppTheme.bgSurface,
                          child: const Center(child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2))),
                      errorWidget: (_, __, ___) => Container(color: AppTheme.bgSurface,
                          child: const Icon(Icons.broken_image_rounded, size: 60, color: AppTheme.textSecondary)),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(bottom: 16, left: 0, right: 0,
                      child: Center(child: SmoothPageIndicator(
                        controller: _pageCtrl, count: images.length,
                        effect: WormEffect(dotHeight: 7, dotWidth: 7,
                            activeDotColor: AppTheme.accent, dotColor: Colors.white30),
                      ))),
                ],
              ]),
            ),
          ),

          // ── Product Info ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Name + rating
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white))),
                  if (p.avgRating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded, color: AppTheme.accent, size: 16),
                        const SizedBox(width: 2),
                        Text(p.avgRating!.toStringAsFixed(1), style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                      ]),
                    ),
                ]),
                const SizedBox(height: 6),
                if (p.reviewCount != null)
                  Text('${p.reviewCount} reviews', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 12),

                // Price
                Row(children: [
                  Text('₹${p.effectivePrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.accent)),
                  if (p.hasDiscount) ...[
                    const SizedBox(width: 10),
                    Text('₹${p.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, decoration: TextDecoration.lineThrough)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                      child: Text('${p.discountPercent}% OFF',
                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ],
                ]),
                const SizedBox(height: 20),

                // ── Color Variants ──
                if (p.colorVariants.isNotEmpty) ...[
                  const Text('Color', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: p.colorVariants.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final cv = p.colorVariants[i];
                        final selected = _selectedColorIdx == i;
                        Color swatchColor;
                        try {
                          swatchColor = Color(int.parse('FF${cv.hex.replaceAll('#', '')}', radix: 16));
                        } catch (_) {
                          swatchColor = Colors.grey;
                        }
                        return GestureDetector(
                          onTap: () => _selectColor(i),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                color: swatchColor, shape: BoxShape.circle,
                                border: Border.all(color: selected ? AppTheme.accent : Colors.transparent, width: 2.5),
                                boxShadow: selected ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.5), blurRadius: 6)] : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(cv.name, style: TextStyle(fontSize: 10, color: selected ? AppTheme.accent : AppTheme.textSecondary)),
                          ]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── View Buttons ──
                Row(children: [
                  if (p.images360.isNotEmpty)
                    Expanded(child: _ViewBtn(
                      icon: Icons.threesixty_rounded, label: '360° View', color: Colors.blueAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _View360Screen(product: p))),
                    )),
                  if (p.images360.isNotEmpty && p.arModel != null) const SizedBox(width: 12),
                  if (p.arModel != null)
                    Expanded(child: _ViewBtn(
                      icon: Icons.view_in_ar_rounded, label: 'View in AR', color: AppTheme.accent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArViewScreen(product: p))),
                    )),
                ]),
                if (p.images360.isEmpty && p.arModel == null)
                  Row(children: [
                    Expanded(child: _ViewBtn(icon: Icons.threesixty_rounded, label: '360° View', color: AppTheme.textMuted,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('360° images not available for this product'))))),
                    const SizedBox(width: 12),
                    Expanded(child: _ViewBtn(icon: Icons.view_in_ar_rounded, label: 'View in AR', color: AppTheme.textMuted,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AR not available for this product'))))),
                  ]),

                const SizedBox(height: 24),

                // ── Description ──
                if (p.description != null && p.description!.isNotEmpty) ...[
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(p.description!, style: const TextStyle(color: AppTheme.textSecondary, height: 1.6)),
                  const SizedBox(height: 20),
                ],

                // ── Specifications ──
                if (p.material != null || p.dimensions != null || p.color != null) ...[
                  const Text('Specifications', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14)),
                    child: Column(children: [
                      if (p.material != null) _specRow('Material', p.material!),
                      if (p.dimensions != null) _specRow('Dimensions', p.dimensions!),
                      if (p.color != null) _specRow('Color', p.color!),
                      _specRow('Availability', p.stock > 0 ? '${p.stock} in stock' : 'Out of stock',
                          valueColor: p.stock > 0 ? Colors.greenAccent : Colors.redAccent),
                    ]),
                  ),
                ],
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12)],
        ),
        child: p.stock <= 0
            ? SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.bgSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Out of Stock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              )
            : Row(
                children: [
                  // Add to Cart
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _addingToCart ? null : () async {
                          await _addToCart(p.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${p.name} added to cart'),
                                backgroundColor: AppTheme.success,
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(label: 'VIEW', textColor: Colors.white, onPressed: () => Navigator.pushNamed(context, '/main')),
                              ),
                            );
                          }
                        },
                        icon: _addingToCart
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent))
                            : const Icon(Icons.shopping_cart_outlined, size: 20),
                        label: const Text('Add to Cart'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                          side: const BorderSide(color: AppTheme.accent, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Buy Now
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _addingToCart ? null : () async {
                          setState(() => _addingToCart = true);
                          final ok = await context.read<CartProvider>().addToCart(p.id);
                          if (mounted) {
                            setState(() => _addingToCart = false);
                            if (ok) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                            }
                          }
                        },
                        icon: const Icon(Icons.flash_on_rounded, size: 20),
                        label: const Text('Buy Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: AppTheme.bgPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _specRow(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(flex: 2, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
      Expanded(flex: 3, child: Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
  );
}

// ── View Button ──

class _ViewBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ViewBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    ),
  );
}

// ── 360° View Screen ──

class _View360Screen extends StatefulWidget {
  final Product product;
  const _View360Screen({required this.product});
  @override
  State<_View360Screen> createState() => _View360ScreenState();
}

class _View360ScreenState extends State<_View360Screen> {
  final _pageCtrl = PageController();
  int _current = 0;
  List<String> get images => widget.product.images360;

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: const Text('360° View', style: TextStyle(color: Colors.white)),
      actions: [
        Padding(padding: const EdgeInsets.only(right: 16),
          child: Center(child: Text('${_current + 1}/${images.length}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)))),
      ],
    ),
    body: Column(children: [
      Expanded(
        child: PageView.builder(
          controller: _pageCtrl,
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) => InteractiveViewer(
            child: CachedNetworkImage(imageUrl: images[i], fit: BoxFit.contain, width: double.infinity,
              placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
              errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded, color: AppTheme.textSecondary, size: 60))),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(children: [
          SmoothPageIndicator(controller: _pageCtrl, count: images.length,
            effect: WormEffect(dotHeight: 8, dotWidth: 8, activeDotColor: AppTheme.accent, dotColor: Colors.white30)),
          const SizedBox(height: 12),
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.chevron_left_rounded, color: AppTheme.textSecondary),
            SizedBox(width: 8),
            Text('Swipe to rotate', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
          ]),
          const SizedBox(height: 12),
          if (images.length > 1)
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: images.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: i == _current ? AppTheme.accent : Colors.transparent, width: 2),
                    ),
                    child: ClipRRect(borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(imageUrl: images[i], width: 60, height: 60, fit: BoxFit.cover)),
                  ),
                ),
              ),
            ),
        ]),
      ),
    ]),
  );
}

// AR View Screen is now in ar_view_screen.dart
