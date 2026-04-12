import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'addresses_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';

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
          // Avatar + Name + Edit
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                  child: Stack(
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
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.bgPrimary, width: 2),
                          ),
                          child: const Icon(Icons.edit_rounded, size: 12, color: AppTheme.accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(user?.name ?? 'User', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(user?.email ?? '', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
                if (user?.phone != null && user!.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(user.phone!, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Account section
          _sectionLabel('Account'),
          const SizedBox(height: 10),
          _menuItem(Icons.person_outline_rounded, 'Edit Profile', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
          _menuItem(Icons.receipt_long_rounded, 'My Orders', () => Navigator.pushNamed(context, '/orders')),
          _menuItem(Icons.favorite_border_rounded, 'Wishlist', () {
            // Navigate to wishlist tab (index 2 in BottomNav)
            Navigator.pop(context);
          }),
          _menuItem(Icons.location_on_outlined, 'Addresses', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesScreen()))),

          const SizedBox(height: 20),

          // Support section
          _sectionLabel('Support'),
          const SizedBox(height: 10),
          _menuItem(Icons.headset_mic_outlined, 'Help & Support', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()))),
          _menuItem(Icons.info_outline_rounded, 'About', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),

          const SizedBox(height: 24),

          // Logout
          GestureDetector(
            onTap: () => _showLogoutDialog(context, auth),
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
          const SizedBox(height: 24),

          Center(child: Text('VisionFurnish v1.0.0', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted))),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted, letterSpacing: 1)),
  );

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
