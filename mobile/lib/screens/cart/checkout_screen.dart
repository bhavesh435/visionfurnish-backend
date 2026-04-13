import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../providers/auth_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _paymentMethod = 'cod';
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchSiteSettings();
    });
  }

  @override
  void dispose() { _addressCtrl.dispose(); _cityCtrl.dispose(); _stateCtrl.dispose(); _zipCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _placeOrder() async {
    if (_addressCtrl.text.isEmpty || _cityCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppTheme.danger));
      return;
    }
    setState(() => _placing = true);

    // If UPI selected, launch UPI app first
    if (_paymentMethod == 'upi') {
      final settings = context.read<AuthProvider>().siteSettings;
      final upiId = settings['upi_id'] ?? '';
      if (upiId.isEmpty) {
        if (mounted) {
          setState(() => _placing = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI payment is not configured. Please contact support.'), backgroundColor: AppTheme.danger));
        }
        return;
      }
      final cart = context.read<CartProvider>();
      final total = cart.total;
      final upiUrl = 'upi://pay?pa=$upiId&pn=VisionFurnish&am=${total.toStringAsFixed(2)}&cu=INR&tn=VisionFurnish+Order+Payment';
      final uri = Uri.parse(upiUrl);
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          if (mounted) {
            setState(() => _placing = false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No UPI app found. Please install a UPI app.'), backgroundColor: AppTheme.danger));
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          setState(() => _placing = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to launch UPI: $e'), backgroundColor: AppTheme.danger));
        }
        return;
      }
    }

    final ok = await context.read<OrderProvider>().placeOrder({
      'shipping_address': _addressCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'state': _stateCtrl.text.trim(),
      'zip_code': _zipCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'payment_method': _paymentMethod,
    });
    if (!mounted) return;
    setState(() => _placing = false);
    if (ok) {
      context.read<CartProvider>().fetchCart();
      showDialog(context: context, barrierDismissible: false, builder: (_) => _SuccessDialog());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to place order'), backgroundColor: AppTheme.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Shipping Address'),
            const SizedBox(height: 14),
            _field(_addressCtrl, 'Street Address *', Icons.location_on_outlined),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_cityCtrl, 'City *', Icons.location_city_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _field(_stateCtrl, 'State', Icons.map_outlined)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_zipCtrl, 'ZIP Code', Icons.pin_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _field(_phoneCtrl, 'Phone *', Icons.phone_outlined, type: TextInputType.phone)),
            ]),
            const SizedBox(height: 28),

            _sectionTitle('Payment Method'),
            const SizedBox(height: 14),
            _paymentOption('cod', 'Cash on Delivery', Icons.money_rounded),
            const SizedBox(height: 10),
            _paymentOption('upi', 'UPI Payment', Icons.account_balance_rounded),
            const SizedBox(height: 10),
            _paymentOption('card', 'Credit/Debit Card', Icons.credit_card_rounded),
            const SizedBox(height: 28),

            // Order summary
            _sectionTitle('Order Summary'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
              child: Column(
                children: [
                  _summaryRow('Subtotal', fmt.format(cart.total)),
                  _summaryRow('Shipping', 'FREE'),
                  const Divider(color: AppTheme.divider, height: 20),
                  _summaryRow('Total', fmt.format(cart.total), bold: true),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _placing ? null : _placeOrder,
                child: _placing
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bgPrimary))
                    : Text('Place Order — ${fmt.format(cart.total)}'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary));
  Widget _field(TextEditingController c, String hint, IconData icon, {TextInputType type = TextInputType.text}) => TextField(
    controller: c, keyboardType: type, style: const TextStyle(color: AppTheme.textPrimary),
    decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 20, color: AppTheme.textMuted)),
  );

  Widget _paymentOption(String value, String label, IconData icon) => GestureDetector(
    onTap: () => setState(() => _paymentMethod = value),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _paymentMethod == value ? AppTheme.accent.withValues(alpha: 0.08) : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _paymentMethod == value ? AppTheme.accent : AppTheme.divider, width: _paymentMethod == value ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: _paymentMethod == value ? AppTheme.accent : AppTheme.textMuted),
          const SizedBox(width: 14),
          Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: _paymentMethod == value ? AppTheme.accent : AppTheme.textPrimary)),
          const Spacer(),
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _paymentMethod == value ? AppTheme.accent : AppTheme.textMuted, width: 2)),
            child: _paymentMethod == value ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.accent))) : null,
          ),
        ],
      ),
    ),
  );

  Widget _summaryRow(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: bold ? AppTheme.textPrimary : AppTheme.textSecondary, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
        Text(value, style: GoogleFonts.outfit(fontSize: bold ? 18 : 14, color: bold ? AppTheme.accent : AppTheme.textPrimary, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      ],
    ),
  );
}

// ── Success Dialog ──
class _SuccessDialog extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) {
    return Dialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.check_circle_rounded, size: 36, color: AppTheme.success),
            ),
            const SizedBox(height: 20),
            Text('Order Placed!', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('Your order has been placed successfully. You can track it in your orders.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () { Navigator.of(ctx).popUntil((r) => r.isFirst); },
                child: const Text('Continue Shopping'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
