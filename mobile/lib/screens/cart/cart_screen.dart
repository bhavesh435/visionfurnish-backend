import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CartProvider>().fetchCart()); }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Cart (${cart.itemCount})', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600)),
        actions: [
          if (cart.items.isNotEmpty) IconButton(icon: const Icon(Icons.delete_sweep_rounded, size: 22), onPressed: () => cart.clearCart()),
        ],
      ),
      body: cart.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : cart.items.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.shopping_cart_outlined, size: 56, color: AppTheme.textMuted),
                    const SizedBox(height: 16),
                    Text('Your cart is empty', style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary)),
                  ]),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (ctx, i) => _cartItem(cart.items[i], cart, fmt),
                      ),
                    ),
                    // Checkout bar
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      decoration: const BoxDecoration(color: AppTheme.bgCard, border: Border(top: BorderSide(color: AppTheme.divider))),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                              Text(fmt.format(cart.total), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.accent)),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                              icon: const Icon(Icons.shopping_bag_rounded, size: 20),
                              label: const Text('Checkout'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _cartItem(CartItem item, CartProvider cart, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imageUrl != null
                ? CachedNetworkImage(imageUrl: item.imageUrl!, width: 80, height: 80, fit: BoxFit.cover, httpHeaders: const {'User-Agent': 'Mozilla/5.0'})
                : Container(width: 80, height: 80, color: AppTheme.bgSurface, child: const Icon(Icons.image, color: AppTheme.textMuted)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text(fmt.format(item.effectivePrice), style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.accent)),
              ],
            ),
          ),
          Column(
            children: [
              // Quantity
              Container(
                decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    GestureDetector(onTap: () => cart.updateQuantity(item.id, item.quantity + 1), child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.add, size: 16))),
                    Text('${item.quantity}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    GestureDetector(onTap: () { if (item.quantity > 1) cart.updateQuantity(item.id, item.quantity - 1); }, child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.remove, size: 16))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(onTap: () => cart.removeItem(item.id), child: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.danger)),
            ],
          ),
        ],
      ),
    );
  }
}
