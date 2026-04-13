import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = ApiService();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _chatUrlCtrl = TextEditingController();
  final _upiIdCtrl = TextEditingController();
  final _privacyCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _chatUrlCtrl.dispose();
    _upiIdCtrl.dispose();
    _privacyCtrl.dispose();
    _termsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get(ApiConfig.siteSettings);
      if (res['success'] == true && res['data'] != null) {
        final s = res['data']['settings'] as Map<String, dynamic>? ?? {};
        _emailCtrl.text = s['support_email']?.toString() ?? '';
        _phoneCtrl.text = s['support_phone']?.toString() ?? '';
        _chatUrlCtrl.text = s['support_chat_url']?.toString() ?? '';
        _upiIdCtrl.text = s['upi_id']?.toString() ?? '';
        _privacyCtrl.text = s['privacy_policy']?.toString() ?? '';
        _termsCtrl.text = s['terms_of_service']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('Load settings error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      await _api.put(ApiConfig.siteSettings, body: {
        'settings': {
          'support_email': _emailCtrl.text.trim(),
          'support_phone': _phoneCtrl.text.trim(),
          'support_chat_url': _chatUrlCtrl.text.trim(),
          'upi_id': _upiIdCtrl.text.trim(),
          'privacy_policy': _privacyCtrl.text.trim(),
          'terms_of_service': _termsCtrl.text.trim(),
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(
              child: Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            ),
            ElevatedButton.icon(
              onPressed: _saving ? null : _saveSettings,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bgDark))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(_saving ? 'Saving...' : 'Save Changes'),
            ),
          ]),
          const SizedBox(height: 20),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Contact Details Section
                        _sectionCard(
                          'Contact Details',
                          Icons.contact_phone_rounded,
                          'These details are shown on the mobile app Help & Support page.',
                          [
                            _fieldRow('Support Email', _emailCtrl, 'e.g. support@example.com', Icons.email_outlined),
                            const SizedBox(height: 16),
                            _fieldRow('Support Phone', _phoneCtrl, 'e.g. +91 9876543210', Icons.phone_outlined),
                            const SizedBox(height: 16),
                            _fieldRow('Chat URL (WhatsApp link)', _chatUrlCtrl, 'e.g. https://wa.me/919876543210', Icons.chat_outlined),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Payment Section
                        _sectionCard(
                          'Payment Settings',
                          Icons.payment_rounded,
                          'Configure UPI payment details for the checkout flow.',
                          [
                            _fieldRow('UPI ID', _upiIdCtrl, 'e.g. merchant@paytm', Icons.account_balance_rounded),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.gold.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.gold),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'When a customer selects UPI payment, the app will open their UPI app with this ID pre-filled for payment.',
                                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.gold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Privacy Policy Section
                        _sectionCard(
                          'Privacy Policy',
                          Icons.privacy_tip_rounded,
                          'Shown on the mobile app\'s Privacy & Security page.',
                          [
                            TextField(
                              controller: _privacyCtrl,
                              maxLines: 6,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'Enter your privacy policy...',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Terms of Service Section
                        _sectionCard(
                          'Terms of Service',
                          Icons.description_rounded,
                          'Shown on the mobile app\'s Privacy & Security page.',
                          [
                            TextField(
                              controller: _termsCtrl,
                              maxLines: 6,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'Enter your terms of service...',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, IconData icon, String subtitle, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: AppTheme.gold),
              const SizedBox(width: 10),
              Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _fieldRow(String label, TextEditingController ctrl, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
