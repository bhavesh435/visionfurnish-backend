import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final Category category;
  const ProductListScreen({super.key, required this.category});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts(categoryId: widget.category.id, reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final wishlist = context.watch<WishlistProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text(widget.category.name),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: products.isLoading && products.products.isEmpty
          ? GridView.count(
              crossAxisCount: 2, padding: const EdgeInsets.all(20), mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.65,
              children: List.generate(6, (_) => const SkeletonCard()),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.65,
              ),
              itemCount: products.products.length,
              itemBuilder: (ctx, i) {
                final p = products.products[i];
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
