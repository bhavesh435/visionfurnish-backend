import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String _password = '';

  // ── Password strength helpers ──
  bool get _hasLength => _password.length >= 8;
  bool get _hasUpper => _password.contains(RegExp(r'[A-Z]'));
  bool get _hasLower => _password.contains(RegExp(r'[a-z]'));
  bool get _hasDigit => _password.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _password.contains(RegExp(r'[!@#%^&*()\-_=+\[\]{};:,.<>?/\\|]'));

  int get _strengthScore =>
      [_hasLength, _hasUpper, _hasLower, _hasDigit, _hasSpecial]
          .where((b) => b)
          .length;

  String get _strengthLabel {
    if (_password.isEmpty) return '';
    switch (_strengthScore) {
      case 1: return 'Very Weak';
      case 2: return 'Weak';
      case 3: return 'Fair';
      case 4: return 'Strong';
      case 5: return 'Very Strong';
      default: return '';
    }
  }

  Color get _strengthColor {
    switch (_strengthScore) {
      case 1: return const Color(0xFFEF4444);
      case 2: return const Color(0xFFF97316);
      case 3: return const Color(0xFFEAB308);
      case 4: return const Color(0xFF22C55E);
      case 5: return const Color(0xFF10B981);
      default: return AppTheme.divider;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a password.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    if (_strengthScore < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Password too weak. Use 8+ chars with uppercase, lowercase, number & special character.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passCtrl.text,
        _phoneCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(auth.error ?? 'Registration failed'),
            backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create Account',
                  style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text('Join VisionFurnish today',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 32),

              _label('Full Name'),
              const SizedBox(height: 8),
              TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                      hintText: 'John Doe',
                      prefixIcon: Icon(Icons.person_outline,
                          size: 20, color: AppTheme.textMuted))),
              const SizedBox(height: 20),

              _label('Email'),
              const SizedBox(height: 8),
              TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                      hintText: 'your@email.com',
                      prefixIcon: Icon(Icons.email_outlined,
                          size: 20, color: AppTheme.textMuted))),
              const SizedBox(height: 20),

              _label('Phone'),
              const SizedBox(height: 8),
              TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                      hintText: '+91 9876543210',
                      prefixIcon: Icon(Icons.phone_outlined,
                          size: 20, color: AppTheme.textMuted))),
              const SizedBox(height: 20),

              _label('Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: AppTheme.textPrimary),
                onChanged: (v) => setState(() => _password = v),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline,
                      size: 20, color: AppTheme.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppTheme.textMuted),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              // ── Password Strength Meter ──
              if (_password.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: List.generate(
                    5,
                    (i) => Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 4 ? 5 : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i < _strengthScore
                              ? _strengthColor
                              : AppTheme.divider,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Password strength',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppTheme.textMuted)),
                    Text(_strengthLabel,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _strengthColor)),
                  ],
                ),
                const SizedBox(height: 10),
                _passCheck('At least 8 characters', _hasLength),
                _passCheck('Uppercase letter (A–Z)', _hasUpper),
                _passCheck('Lowercase letter (a–z)', _hasLower),
                _passCheck('Number (0–9)', _hasDigit),
                _passCheck('Special character (!@#...)', _hasSpecial),
              ],
              const SizedBox(height: 28),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _signup,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.bgPrimary))
                      : const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ',
                      style: GoogleFonts.inter(
                          color: AppTheme.textSecondary, fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('Sign In',
                        style: GoogleFonts.inter(
                            color: AppTheme.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppTheme.textSecondary));

  Widget _passCheck(String label, bool passed) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(
              passed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 14,
              color: passed ? const Color(0xFF22C55E) : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: passed ? AppTheme.textPrimary : AppTheme.textMuted)),
          ],
        ),
      );
}
