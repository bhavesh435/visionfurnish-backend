import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});
  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWishlist());
  }

  Future<void> _loadWishlist() async {
    try {
      await context.read<WishlistProvider>().fetchWishlist();
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wish = context.watch<WishlistProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Wishlist (${wish.items.length})',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600)),
      ),
      body: _hasError
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded, size: 56, color: AppTheme.textMuted),
                const SizedBox(height: 16),
                Text('Failed to load wishlist', style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _hasError = false);
                    _loadWishlist();
                  },
                  child: const Text('Retry'),
                ),
              ]),
            )
          : wish.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
              : wish.items.isEmpty
                  ? RefreshIndicator(
                      color: AppTheme.accent,
                      backgroundColor: AppTheme.bgCard,
                      onRefresh: _loadWishlist,
                      child: ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.favorite_border_rounded, size: 56, color: AppTheme.textMuted),
                                const SizedBox(height: 16),
                                Text('Your wishlist is empty',
                                    style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary)),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppTheme.accent,
                      backgroundColor: AppTheme.bgCard,
                      onRefresh: _loadWishlist,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.65),
                        itemCount: wish.items.length,
                        itemBuilder: (ctx, i) {
                          final p = wish.items[i];
                          return ProductCard(
                            product: p,
                            onTap: () => Navigator.push(
                                context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id))),
                            isFav: true,
                            onFav: () => wish.toggle(p.id),
                          );
                        },
                      ),
                    ),
    );
  }
}
