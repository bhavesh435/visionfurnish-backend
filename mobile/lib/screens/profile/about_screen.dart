import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text('About', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Logo & App Name
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accentDark]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.weekend_rounded, size: 40, color: AppTheme.bgPrimary),
                ),
                const SizedBox(height: 16),
                Text('VisionFurnish', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.accent)),
                const SizedBox(height: 4),
                Text('Version 1.0.0', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Description
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About VisionFurnish', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                Text(
                  'VisionFurnish is a premium furniture shopping app with AR (Augmented Reality) technology. Visualize how furniture looks in your space before buying — try before you buy, right from your phone.',
                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Features
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Key Features', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                _featureRow(Icons.view_in_ar_rounded, 'AR Furniture Preview', 'See furniture in your space using AR'),
                _featureRow(Icons.threesixty_rounded, '360° Product Views', 'Explore products from every angle'),
                _featureRow(Icons.smart_toy_rounded, 'AI Chat Assistant', 'Get personalized furniture recommendations'),
                _featureRow(Icons.palette_rounded, 'Color Variants', 'View products in different colors'),
                _featureRow(Icons.local_shipping_rounded, 'Order Tracking', 'Track your orders in real-time'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Legal links
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
            child: Column(children: [
              _legalItem('Terms of Service', Icons.description_outlined, () {}),
              const Divider(color: AppTheme.divider, height: 1, indent: 16, endIndent: 16),
              _legalItem('Privacy Policy', Icons.privacy_tip_outlined, () {}),
              const Divider(color: AppTheme.divider, height: 1, indent: 16, endIndent: 16),
              _legalItem('Licenses', Icons.article_outlined, () => showLicensePage(context: context, applicationName: 'VisionFurnish', applicationVersion: '1.0.0')),
            ]),
          ),
          const SizedBox(height: 28),

          Center(
            child: Text('Made with ❤️ in India', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: AppTheme.accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
        ),
      ],
    ),
  );

  Widget _legalItem(String label, IconData icon, VoidCallback onTap) => ListTile(
    onTap: onTap,
    leading: Icon(icon, size: 20, color: AppTheme.textMuted),
    title: Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary)),
    trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textMuted),
  );
}
