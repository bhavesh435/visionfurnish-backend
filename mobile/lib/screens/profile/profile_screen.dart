import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: Text('Profile', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar + Name
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accentDark]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                    style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, color: AppTheme.bgPrimary),
                  )),
                ),
                const SizedBox(height: 16),
                Text(user?.name ?? 'User', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(user?.email ?? '', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 36),

          _menuItem(Icons.receipt_long_rounded, 'My Orders', () => Navigator.pushNamed(context, '/orders')),
          _menuItem(Icons.favorite_border_rounded, 'Wishlist', () {}),
          _menuItem(Icons.location_on_outlined, 'Addresses', () {}),
          _menuItem(Icons.headset_mic_outlined, 'Help & Support', () {}),
          _menuItem(Icons.info_outline_rounded, 'About', () {}),
          const SizedBox(height: 20),

          // Logout
          GestureDetector(
            onTap: () async {
              await auth.logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, size: 20, color: AppTheme.danger),
                  const SizedBox(width: 10),
                  Text('Log Out', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.danger)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: AppTheme.bgCard,
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 20, color: AppTheme.accent),
      ),
      title: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 22),
    ),
  );
}
