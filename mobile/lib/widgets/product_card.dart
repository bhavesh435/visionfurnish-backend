import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onFav;
  final bool isFav;

  const ProductCard({super.key, required this.product, required this.onTap, this.onFav, this.isFav = false});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: product.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!, 
                            width: double.infinity, 
                            fit: BoxFit.cover,
                            httpHeaders: const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'},
                            placeholder: (_, __) => Container(color: AppTheme.bgSurface, child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent))),
                            errorWidget: (_, __, ___) => Container(color: AppTheme.bgSurface, child: const Icon(Icons.image_rounded, color: AppTheme.textMuted, size: 32)))
                        : Container(color: AppTheme.bgSurface, child: const Icon(Icons.image_rounded, color: AppTheme.textMuted, size: 32)),
                  ),
                  // Discount badge
                  if (product.hasDiscount)
                    Positioned(
                      top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(8)),
                        child: Text('-${product.discountPercent}%', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  // Wishlist button
                  if (onFav != null)
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: onFav,
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(color: AppTheme.bgPrimary.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)),
                          child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 18, color: isFav ? AppTheme.danger : AppTheme.textSecondary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary, height: 1.3)),
                  const SizedBox(height: 3),
                  if (product.categoryName != null)
                    Text(product.categoryName!, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(child: Text(fmt.format(product.effectivePrice), overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.accent))),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 4),
                        Flexible(child: Text(fmt.format(product.price), overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted, decoration: TextDecoration.lineThrough))),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton Loader ──
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: Container(decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: const BorderRadius.vertical(top: Radius.circular(18))))),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 14, decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(width: 80, height: 10, decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(4))),
                  const Spacer(),
                  Container(width: 60, height: 16, decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
