import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';
import '../product/product_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchCategories();
      context.read<ProductProvider>().fetchFeatured();
      context.read<ProductProvider>().fetchProducts(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final wishlist = context.watch<WishlistProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            floating: true,
            backgroundColor: AppTheme.bgPrimary,
            expandedHeight: 110,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('VisionFurnish', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.accent)),
                          const SizedBox(height: 2),
                          Text('Discover luxury furniture', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showSearch(context),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Categories ──
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: Text('Categories', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: products.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (ctx, i) => _categoryChip(products.categories[i]),
                  ),
                ),
              ],
            ),
          ),

          // ── AR Scan Banner ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _ArScanBanner(),
            ),
          ),

          // ── Featured ──
          if (products.featured.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Featured', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    Text('See all', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.accent, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: products.featured.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (ctx, i) {
                    final p = products.featured[i];
                    return SizedBox(
                      width: 170,
                      child: ProductCard(
                        product: p, onTap: () => _openDetail(p),
                        isFav: wishlist.isWishlisted(p.id),
                        onFav: () => wishlist.toggle(p.id),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // ── All Products ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: Text('All Products', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: products.isLoading && products.products.isEmpty
                ? SliverGrid.count(
                    crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.65,
                    children: List.generate(6, (_) => const SkeletonCard()),
                  )
                : SliverGrid.count(
                    crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.65,
                    children: products.products.map((p) => ProductCard(
                      product: p, onTap: () => _openDetail(p),
                      isFav: wishlist.isWishlisted(p.id),
                      onFav: () => wishlist.toggle(p.id),
                    )).toList(),
                  ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _categoryChip(Category cat) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListScreen(category: cat))),
      child: Container(
        width: 80,
        decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: cat.imageUrl != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: cat.imageUrl!, fit: BoxFit.cover, httpHeaders: const {'User-Agent': 'Mozilla/5.0'}))
                  : const Icon(Icons.category_rounded, color: AppTheme.accent, size: 20),
            ),
            const SizedBox(height: 8),
            Text(cat.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _openDetail(Product p) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)));
  }

  void _showSearch(BuildContext ctx) {
    showSearch(context: ctx, delegate: _ProductSearchDelegate());
  }
}

// ── AR Scan Banner ──
class _ArScanBanner extends StatefulWidget {
  @override
  State<_ArScanBanner> createState() => _ArScanBannerState();
}

class _ArScanBannerState extends State<_ArScanBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/scan-ar'),
      child: AnimatedBuilder(
        animation: _shimmerAnim,
        builder: (_, __) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [
                Color(0xFF1A1208),
                Color(0xFF2A1E0A),
                Color(0xFF1A1208),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.accent.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon box
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.3),
                      AppTheme.accentDark.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.view_in_ar_rounded,
                  color: AppTheme.accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(
                          'Scan Furniture → AR',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'NEW',
                          style: GoogleFonts.inter(
                            color: AppTheme.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      'Upload any furniture photo — see it in your room instantly',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Arrow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.accent,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Search Delegate ──
class _ProductSearchDelegate extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) => AppTheme.darkTheme.copyWith(
    appBarTheme: const AppBarTheme(backgroundColor: AppTheme.bgPrimary, elevation: 0),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: AppTheme.textMuted),
      border: InputBorder.none,
    ),
  );

  @override
  List<Widget> buildActions(BuildContext ctx) => [IconButton(icon: const Icon(Icons.clear), onPressed: () { query = ''; })];
  @override
  Widget buildLeading(BuildContext ctx) => IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => close(ctx, ''));

  @override
  Widget buildResults(BuildContext ctx) => _buildSearchResults(ctx);
  @override
  Widget buildSuggestions(BuildContext ctx) => query.length < 2 ? const SizedBox() : _buildSearchResults(ctx);

  Widget _buildSearchResults(BuildContext ctx) {
    return FutureBuilder<List<Product>>(
      future: ProductProvider().searchProducts(query),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
        final results = snap.data ?? [];
        if (results.isEmpty) return Center(child: Text('No products found', style: GoogleFonts.inter(color: AppTheme.textSecondary)));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (ctx, i) {
            final p = results[i];
            return ListTile(
              leading: p.imageUrl != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: p.imageUrl!, width: 50, height: 50, fit: BoxFit.cover, httpHeaders: const {'User-Agent': 'Mozilla/5.0'})) : null,
              title: Text(p.name, style: const TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text('₹${p.effectivePrice.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.accent)),
              onTap: () { close(ctx, ''); Navigator.push(ctx, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id))); },
            );
          },
        );
      },
    );
  }
}
