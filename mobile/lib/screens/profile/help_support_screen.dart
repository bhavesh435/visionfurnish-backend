import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Help & Support', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Contact
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accent.withValues(alpha: 0.15), AppTheme.accent.withValues(alpha: 0.05)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.headset_mic_rounded, size: 40, color: AppTheme.accent),
                const SizedBox(height: 12),
                Text('Need Help?', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text('Our support team is available 24/7', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _contactChip(Icons.email_outlined, 'Email', () {}),
                    const SizedBox(width: 12),
                    _contactChip(Icons.phone_outlined, 'Call', () {}),
                    const SizedBox(width: 12),
                    _contactChip(Icons.chat_outlined, 'Chat', () {}),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // FAQ
          Text('Frequently Asked Questions', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          _faqItem('How do I track my order?', 'Go to Profile → My Orders to see all your orders and their current status. Tap any order to see detailed tracking.'),
          _faqItem('What is your return policy?', 'We offer a 7-day return policy for all products. Items must be in original condition and packaging.'),
          _faqItem('How does AR view work?', 'Tap "View in AR" on any product page to see how the furniture looks in your space using your phone\'s camera.'),
          _faqItem('How do I change my delivery address?', 'Go to Profile → Addresses to manage your saved addresses. You can add, edit, or delete addresses.'),
          _faqItem('What payment methods do you accept?', 'We accept Cash on Delivery (COD), UPI payments, and Credit/Debit cards.'),
          _faqItem('How do I cancel an order?', 'Orders in "pending" status can be cancelled from the order details page. Once shipped, cancellation is not available.'),
        ],
      ),
    );
  }

  Widget _contactChip(IconData icon, String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: AppTheme.accent),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
      ]),
    ),
  );

  Widget _faqItem(String question, String answer) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.divider)),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      iconColor: AppTheme.accent,
      collapsedIconColor: AppTheme.textMuted,
      title: Text(question, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
      children: [Text(answer, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5))],
    ),
  );
}
