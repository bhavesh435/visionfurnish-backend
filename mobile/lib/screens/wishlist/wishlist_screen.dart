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
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => context.read<WishlistProvider>().fetchWishlist()); }

  @override
  Widget build(BuildContext context) {
    final wish = context.watch<WishlistProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: Text('Wishlist (${wish.items.length})', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600))),
      body: wish.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : wish.items.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.favorite_border_rounded, size: 56, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text('Your wishlist is empty', style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary)),
                ]))
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.65),
                  itemCount: wish.items.length,
                  itemBuilder: (ctx, i) {
                    final p = wish.items[i];
                    return ProductCard(
                      product: p,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id))),
                      isFav: true,
                      onFav: () => wish.toggle(p.id),
                    );
                  },
                ),
    );
  }
}
