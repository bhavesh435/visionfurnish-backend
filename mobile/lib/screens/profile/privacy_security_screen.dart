import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchSiteSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AuthProvider>().siteSettings;
    final privacyPolicy = settings['privacy_policy'] ?? 'Your privacy is important to us. We collect only the information necessary to provide our services. Your personal data is encrypted and stored securely. We do not share your information with third parties without your consent.';
    final terms = settings['terms_of_service'] ?? 'By using VisionFurnish, you agree to our terms of service. All purchases are subject to our return and refund policy.';

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Privacy & Security', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Security Features Section
          _sectionHeader(Icons.shield_rounded, 'Security Features'),
          const SizedBox(height: 16),
          _securityItem(
            Icons.lock_rounded,
            'End-to-End Encryption',
            'Your payment and personal data is encrypted using industry-standard AES-256 encryption.',
          ),
          _securityItem(
            Icons.verified_user_rounded,
            'Secure Authentication',
            'We use JWT tokens with strong password requirements including uppercase, lowercase, numbers, and special characters.',
          ),
          _securityItem(
            Icons.security_rounded,
            'Data Protection',
            'Your information is stored on secure servers with regular security audits and monitoring.',
          ),
          _securityItem(
            Icons.phonelink_lock_rounded,
            'Session Management',
            'Your sessions are tokenized and expire automatically. You can log out from all devices at any time.',
          ),
          const SizedBox(height: 28),

          // Privacy Policy Section
          _sectionHeader(Icons.privacy_tip_rounded, 'Privacy Policy'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Text(
              privacyPolicy,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.6),
            ),
          ),
          const SizedBox(height: 28),

          // Data We Collect Section
          _sectionHeader(Icons.storage_rounded, 'Data We Collect'),
          const SizedBox(height: 16),
          _dataItem('Personal Information', 'Name, email, phone number for account management and communication.'),
          _dataItem('Order Information', 'Shipping address, payment method, and purchase history for order processing.'),
          _dataItem('Device Information', 'Device type and OS version for optimizing your app experience.'),
          _dataItem('Usage Analytics', 'Anonymous usage data to improve our services and user experience.'),
          const SizedBox(height: 28),

          // Your Rights Section
          _sectionHeader(Icons.gavel_rounded, 'Your Rights'),
          const SizedBox(height: 16),
          _rightItem('Access', 'Request a copy of all personal data we hold about you.'),
          _rightItem('Rectification', 'Update or correct any inaccurate personal information.'),
          _rightItem('Deletion', 'Request deletion of your account and associated data.'),
          _rightItem('Portability', 'Export your data in a standard format.'),
          const SizedBox(height: 28),

          // Terms of Service Section
          _sectionHeader(Icons.description_rounded, 'Terms of Service'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Text(
              terms,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.6),
            ),
          ),
          const SizedBox(height: 32),

          // App version info
          Center(
            child: Text(
              'VisionFurnish v1.0.0 • Last updated: April 2026',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) => Row(
    children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: AppTheme.accent),
      ),
      const SizedBox(width: 12),
      Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
    ],
  );

  Widget _securityItem(IconData icon, String title, String desc) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppTheme.success),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Text(desc, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _dataItem(String title, String desc) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.circle, size: 8, color: AppTheme.accent),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ]),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Text(desc, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
        ),
      ],
    ),
  );

  Widget _rightItem(String title, String desc) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppTheme.info.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppTheme.info),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(desc, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.3)),
            ],
          ),
        ),
      ],
    ),
  );
}
