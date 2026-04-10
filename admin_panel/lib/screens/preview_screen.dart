import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _isPhone = true;
  ProductModel? _selectedProduct;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              const Icon(Icons.preview_rounded, color: AppTheme.gold, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer Preview',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('See how your store looks to customers',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              // Device toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DeviceToggleBtn(
                      icon: Icons.phone_iphone_rounded,
                      label: 'Phone',
                      isActive: _isPhone,
                      onTap: () => setState(() {
                        _isPhone = true;
                        _selectedProduct = null;
                      }),
                    ),
                    const SizedBox(width: 4),
                    _DeviceToggleBtn(
                      icon: Icons.desktop_windows_rounded,
                      label: 'Desktop',
                      isActive: !_isPhone,
                      onTap: () => setState(() {
                        _isPhone = false;
                        _selectedProduct = null;
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Device Frame ──
          Expanded(
            child: Center(
              child: _isPhone ? _buildPhoneFrame() : _buildDesktopFrame(),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PHONE FRAME
  // ═══════════════════════════════════════════════════════════
  Widget _buildPhoneFrame() {
    return Container(
      width: 390,
      constraints: const BoxConstraints(minHeight: 750),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFF333333), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: AppTheme.gold.withValues(alpha: 0.05),
            blurRadius: 60,
          ),
        ],
      ),
      child: Column(
        children: [
          // Notch
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 120,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          // Screen content
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(32),
              ),
              clipBehavior: Clip.antiAlias,
              child: _selectedProduct != null
                  ? _ProductDetailMobile(
                      product: _selectedProduct!,
                      onBack: () => setState(() => _selectedProduct = null),
                    )
                  : _ProductGridMobile(
                      onProductTap: (p) => setState(() => _selectedProduct = p),
                    ),
            ),
          ),
          // Home indicator
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            width: 140,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DESKTOP FRAME
  // ═══════════════════════════════════════════════════════════
  Widget _buildDesktopFrame() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1100),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF444444), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          // Browser chrome
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                // Traffic lights
                Row(
                  children: [
                    _dot(const Color(0xFFFF5F57)),
                    const SizedBox(width: 6),
                    _dot(const Color(0xFFFFBD2E)),
                    const SizedBox(width: 6),
                    _dot(const Color(0xFF28C940)),
                  ],
                ),
                const SizedBox(width: 20),
                // URL bar
                Expanded(
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_rounded, size: 12, color: Color(0xFF28C940)),
                        SizedBox(width: 6),
                        Text(
                          'visionfurnish.com/shop',
                          style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
          // Desktop screen content
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: Color(0xFF0D0D0D),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
              ),
              child: _selectedProduct != null
                  ? _ProductDetailDesktop(
                      product: _selectedProduct!,
                      onBack: () => setState(() => _selectedProduct = null),
                    )
                  : _ProductGridDesktop(
                      onProductTap: (p) => setState(() => _selectedProduct = p),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

// ═══════════════════════════════════════════════════════════════
// DEVICE TOGGLE BUTTON
// ═══════════════════════════════════════════════════════════════
class _DeviceToggleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DeviceToggleBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16,
                color: isActive ? AppTheme.bgDark : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppTheme.bgDark : AppTheme.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MOBILE — Product Grid
// ═══════════════════════════════════════════════════════════════
class _ProductGridMobile extends StatelessWidget {
  final ValueChanged<ProductModel> onProductTap;
  const _ProductGridMobile({required this.onProductTap});

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Column(
      children: [
        // App bar mock
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          color: const Color(0xFF0D0D0D),
          child: const Row(
            children: [
              Text('VisionFurnish',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD4A843))),
              Spacer(),
              Icon(Icons.search_rounded, color: Colors.white70, size: 22),
              SizedBox(width: 12),
              Icon(Icons.shopping_bag_outlined, color: Colors.white70, size: 22),
            ],
          ),
        ),

        // Product grid
        Expanded(
          child: pp.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4A843)))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: pp.products.length,
                  itemBuilder: (ctx, i) =>
                      _MobileProductCard(product: pp.products[i], fmt: fmt, onTap: onProductTap),
                ),
        ),

        // Bottom nav mock
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MockNavIcon(Icons.home_rounded, 'Home', true),
              _MockNavIcon(Icons.explore_rounded, 'Explore', false),
              _MockNavIcon(Icons.favorite_border_rounded, 'Wishlist', false),
              _MockNavIcon(Icons.person_outline_rounded, 'Account', false),
            ],
          ),
        ),
      ],
    );
  }
}

class _MockNavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _MockNavIcon(this.icon, this.label, this.active);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22,
            color: active ? const Color(0xFFD4A843) : const Color(0xFF666666)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
              fontSize: 10,
              color: active ? const Color(0xFFD4A843) : const Color(0xFF666666),
            )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MOBILE — Product Card
// ═══════════════════════════════════════════════════════════════
class _MobileProductCard extends StatelessWidget {
  final ProductModel product;
  final NumberFormat fmt;
  final ValueChanged<ProductModel> onTap;

  const _MobileProductCard({
    required this.product,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        product.discountPrice != null && product.discountPrice! < product.price;
    final effectivePrice = hasDiscount ? product.discountPrice! : product.price;
    final discountPct = hasDiscount
        ? ((product.price - product.discountPrice!) / product.price * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => onTap(product),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(13)),
                    child: product.imageUrl != null
                        ? Image.network(product.imageUrl!,
                            width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imgPlaceholder())
                        : _imgPlaceholder(),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('$discountPct% OFF',
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.favorite_border_rounded,
                          size: 14, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.categoryName != null)
                      Text(product.categoryName!,
                          style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFFD4A843),
                              fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF5F5F5))),
                    const Spacer(),
                    Row(
                      children: [
                        Text(fmt.format(effectivePrice),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD4A843))),
                        if (hasDiscount) ...[
                          const SizedBox(width: 4),
                          Text(fmt.format(product.price),
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF666666),
                                  decoration: TextDecoration.lineThrough)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        width: double.infinity,
        color: const Color(0xFF222222),
        child: const Icon(Icons.image_rounded, size: 32, color: Color(0xFF444444)),
      );
}

// ═══════════════════════════════════════════════════════════════
// MOBILE — Product Detail
// ═══════════════════════════════════════════════════════════════
class _ProductDetailMobile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onBack;
  const _ProductDetailMobile({required this.product, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final hasDiscount =
        product.discountPrice != null && product.discountPrice! < product.price;
    final effectivePrice = hasDiscount ? product.discountPrice! : product.price;
    final discountPct = hasDiscount
        ? ((product.price - product.discountPrice!) / product.price * 100).round()
        : 0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Stack(
                  children: [
                    SizedBox(
                      height: 280,
                      width: double.infinity,
                      child: product.imageUrl != null
                          ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF1A1A1A),
                                  child: const Icon(Icons.image_rounded,
                                      size: 48, color: Color(0xFF444444))))
                          : Container(
                              color: const Color(0xFF1A1A1A),
                              child: const Icon(Icons.image_rounded,
                                  size: 48, color: Color(0xFF444444))),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: GestureDetector(
                        onTap: onBack,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.categoryName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A843).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(product.categoryName!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFD4A843),
                                  fontWeight: FontWeight.w600)),
                        ),
                      const SizedBox(height: 10),
                      Text(product.name,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF5F5F5))),
                      const SizedBox(height: 10),

                      // Price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(fmt.format(effectivePrice),
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD4A843))),
                          if (hasDiscount) ...[
                            const SizedBox(width: 8),
                            Text(fmt.format(product.price),
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                    decoration: TextDecoration.lineThrough)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('$discountPct% OFF',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4CAF50))),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.stock > 0
                            ? 'In Stock (${product.stock})'
                            : 'Out of Stock',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: product.stock > 0
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFEF5350),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Details
                      if (product.material != null ||
                          product.dimensions != null ||
                          product.color != null) ...[
                        const Text('Details',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF5F5F5))),
                        const SizedBox(height: 10),
                        if (product.material != null)
                          _detailRow('Material', product.material!),
                        if (product.dimensions != null)
                          _detailRow('Dimensions', product.dimensions!),
                        if (product.color != null)
                          _detailRow('Color', product.color!),
                        const SizedBox(height: 20),
                      ],

                      if (product.description != null) ...[
                        const Text('Description',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF5F5F5))),
                        const SizedBox(height: 8),
                        Text(product.description!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9E9EB8),
                                height: 1.6)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.remove, size: 16, color: Colors.white70),
                    SizedBox(width: 12),
                    Text('1',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF5F5F5))),
                    SizedBox(width: 12),
                    Icon(Icons.add, size: 16, color: Colors.white70),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A843),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_rounded,
                          size: 18, color: Color(0xFF0D0D0D)),
                      SizedBox(width: 8),
                      Text('Add to Cart',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D0D0D))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
                width: 90,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF666666)))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFF5F5F5),
                        fontWeight: FontWeight.w500))),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// DESKTOP — Product Grid
// ═══════════════════════════════════════════════════════════════
class _ProductGridDesktop extends StatelessWidget {
  final ValueChanged<ProductModel> onProductTap;
  const _ProductGridDesktop({required this.onProductTap});

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Column(
      children: [
        // Navbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          color: const Color(0xFF111111),
          child: const Row(
            children: [
              Text('VisionFurnish',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD4A843))),
              SizedBox(width: 40),
              Text('Home', style: TextStyle(fontSize: 14, color: Color(0xFFD4A843))),
              SizedBox(width: 24),
              Text('Shop', style: TextStyle(fontSize: 14, color: Colors.white70)),
              SizedBox(width: 24),
              Text('Categories', style: TextStyle(fontSize: 14, color: Colors.white70)),
              Spacer(),
              Icon(Icons.search_rounded, color: Colors.white70, size: 20),
              SizedBox(width: 20),
              Icon(Icons.favorite_border_rounded, color: Colors.white70, size: 20),
              SizedBox(width: 20),
              Icon(Icons.shopping_bag_outlined, color: Colors.white70, size: 20),
              SizedBox(width: 20),
              Icon(Icons.person_outline_rounded, color: Colors.white70, size: 20),
            ],
          ),
        ),

        // Content
        Expanded(
          child: pp.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4A843)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Featured Products',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF5F5F5))),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: pp.products
                            .map((p) => SizedBox(
                                  width: 220,
                                  child: _DesktopProductCard(
                                      product: p, fmt: fmt, onTap: onProductTap),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DESKTOP — Product Card
// ═══════════════════════════════════════════════════════════════
class _DesktopProductCard extends StatefulWidget {
  final ProductModel product;
  final NumberFormat fmt;
  final ValueChanged<ProductModel> onTap;

  const _DesktopProductCard({
    required this.product,
    required this.fmt,
    required this.onTap,
  });

  @override
  State<_DesktopProductCard> createState() => _DesktopProductCardState();
}

class _DesktopProductCardState extends State<_DesktopProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final hasDiscount = p.discountPrice != null && p.discountPrice! < p.price;
    final effectivePrice = hasDiscount ? p.discountPrice! : p.price;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _hovered
                    ? const Color(0xFFD4A843).withValues(alpha: 0.4)
                    : const Color(0xFF2A2A2A)),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: const Color(0xFFD4A843).withValues(alpha: 0.08),
                      blurRadius: 20,
                    )
                  ]
                : [],
          ),
          transform: _hovered ? (Matrix4.identity()..translate(0, -4, 0)) : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: p.imageUrl != null
                      ? Image.network(p.imageUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF222222),
                              child: const Icon(Icons.image_rounded,
                                  size: 32, color: Color(0xFF444444))))
                      : Container(
                          color: const Color(0xFF222222),
                          child: const Icon(Icons.image_rounded,
                              size: 32, color: Color(0xFF444444))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF5F5F5))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(widget.fmt.format(effectivePrice),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD4A843))),
                        if (hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(widget.fmt.format(p.price),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF666666),
                                  decoration: TextDecoration.lineThrough)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DESKTOP — Product Detail
// ═══════════════════════════════════════════════════════════════
class _ProductDetailDesktop extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onBack;
  const _ProductDetailDesktop({required this.product, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final hasDiscount =
        product.discountPrice != null && product.discountPrice! < product.price;
    final effectivePrice = hasDiscount ? product.discountPrice! : product.price;
    final discountPct = hasDiscount
        ? ((product.price - product.discountPrice!) / product.price * 100).round()
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios_new,
                    size: 14, color: Color(0xFFD4A843)),
                SizedBox(width: 6),
                Text('Back to Shop',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFD4A843),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Two-column layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 400,
                    child: product.imageUrl != null
                        ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF1A1A1A),
                                child: const Icon(Icons.image_rounded,
                                    size: 64, color: Color(0xFF444444))))
                        : Container(
                            color: const Color(0xFF1A1A1A),
                            child: const Icon(Icons.image_rounded,
                                size: 64, color: Color(0xFF444444))),
                  ),
                ),
              ),
              const SizedBox(width: 40),

              // Info
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A843).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(product.categoryName!,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFD4A843))),
                      ),
                    const SizedBox(height: 14),
                    Text(product.name,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF5F5F5))),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(fmt.format(effectivePrice),
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD4A843))),
                        if (hasDiscount) ...[
                          const SizedBox(width: 12),
                          Text(fmt.format(product.price),
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                  decoration: TextDecoration.lineThrough)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('$discountPct% OFF',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4CAF50))),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.stock > 0
                          ? 'In Stock (${product.stock})'
                          : 'Out of Stock',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: product.stock > 0
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFEF5350),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (product.description != null) ...[
                      Text(product.description!,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9E9EB8),
                              height: 1.7)),
                      const SizedBox(height: 24),
                    ],

                    // Details
                    if (product.material != null ||
                        product.dimensions != null ||
                        product.color != null) ...[
                      const Divider(color: Color(0xFF2A2A2A)),
                      const SizedBox(height: 12),
                      if (product.material != null)
                        _row('Material', product.material!),
                      if (product.dimensions != null)
                        _row('Dimensions', product.dimensions!),
                      if (product.color != null)
                        _row('Color', product.color!),
                      const SizedBox(height: 20),
                    ],

                    // CTA
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222222),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.remove, size: 18, color: Colors.white70),
                              SizedBox(width: 16),
                              Text('1',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFF5F5F5))),
                              SizedBox(width: 16),
                              Icon(Icons.add, size: 18, color: Colors.white70),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4A843),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_rounded,
                                    size: 20, color: Color(0xFF0D0D0D)),
                                SizedBox(width: 8),
                                Text('Add to Cart',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0D0D0D))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
                width: 110,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF666666)))),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFF5F5F5),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}
