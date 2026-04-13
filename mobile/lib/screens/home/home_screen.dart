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
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchCategories();
      context.read<ProductProvider>().fetchFeatured();
      context.read<ProductProvider>().fetchProducts(reset: true);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      context.read<ProductProvider>().loadMore();
    }
  }

  Future<void> _onRefresh() async {
    final provider = context.read<ProductProvider>();
    await Future.wait([
      provider.fetchCategories(),
      provider.fetchFeatured(),
      provider.fetchProducts(reset: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final wishlist = context.watch<WishlistProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.accent,
        backgroundColor: AppTheme.bgCard,
        displacement: 60,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              pinned: false,
              floating: false,
              snap: false,
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


            // ── Featured ──
            if (products.featured.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Featured', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _FeaturedListScreen())),
                        child: Text('See all', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.accent, fontWeight: FontWeight.w500)),
                      ),
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
                  : SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.65,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final p = products.products[i];
                          return ProductCard(
                            key: ValueKey(p.id),
                            product: p, onTap: () => _openDetail(p),
                            isFav: wishlist.isWishlisted(p.id),
                            onFav: () => wishlist.toggle(p.id),
                          );
                        },
                        childCount: products.products.length,
                      ),
                    ),
            ),

            // ── Load More / End Indicator ──
            SliverToBoxAdapter(
              child: products.isLoading && products.products.isNotEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2)),
                    )
                  : const SizedBox.shrink(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
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

// ── Featured "See All" Screen ──
class _FeaturedListScreen extends StatelessWidget {
  const _FeaturedListScreen();

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final wishlist = context.watch<WishlistProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Featured Products', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: products.featured.isEmpty
          ? Center(child: Text('No featured products', style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary)))
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.65,
              ),
              itemCount: products.featured.length,
              itemBuilder: (ctx, i) {
                final p = products.featured[i];
                return ProductCard(
                  product: p,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id))),
                  isFav: wishlist.isWishlisted(p.id),
                  onFav: () => wishlist.toggle(p.id),
                );
              },
            ),
    );
  }
}
