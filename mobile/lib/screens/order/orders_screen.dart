import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderProvider>().fetchOrders()); }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('My Orders'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: orders.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : orders.orders.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(24)),
                    child: const Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 20),
                  Text('No orders yet', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  Text('Your orders will appear here', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
                ]))
              : RefreshIndicator(
                  color: AppTheme.accent,
                  backgroundColor: AppTheme.bgCard,
                  onRefresh: () => context.read<OrderProvider>().fetchOrders(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: orders.orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _orderCard(orders.orders[i], fmt),
                  ),
                ),
    );
  }

  Widget _orderCard(Order o, NumberFormat fmt) {
    final color = _statusColor(o.status);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Order #${o.id}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(o.status.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fmt.format(o.total), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.accent)),
                    const SizedBox(height: 2),
                    Text(_fmtDate(o.createdAt), style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'delivered': return AppTheme.success;
      case 'shipped': return AppTheme.info;
      case 'packed': return AppTheme.warning;
      case 'cancelled': return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  String _fmtDate(String d) {
    try { return DateFormat('MMM dd, yyyy').format(DateTime.parse(d)); } catch (_) { return d; }
  }
}

// ═══════════════════════════════════
// Order Detail + Tracking Timeline
// ═══════════════════════════════════
class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final o = await context.read<OrderProvider>().fetchOrderById(widget.orderId);
    if (mounted) setState(() { _order = o; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _order == null
              ? Center(child: Text('Order not found', style: GoogleFonts.inter(color: AppTheme.textSecondary)))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Timeline tracker
                    _buildTimeline(_order!.status),
                    const SizedBox(height: 28),

                    // Order Items
                    if (_order!.items != null && _order!.items!.isNotEmpty) ...[
                      _section('Items'),
                      const SizedBox(height: 12),
                      ...(_order!.items!.map((item) => _orderItemCard(item, fmt))),
                      const SizedBox(height: 20),
                    ],

                    // Order info
                    _section('Order Details'),
                    const SizedBox(height: 12),
                    _infoCard([
                      _row('Status', _order!.status.toUpperCase()),
                      _row('Total', fmt.format(_order!.total)),
                      _row('Payment', _paymentLabel(_order!.paymentMethod)),
                      _row('Date', _fmtDate(_order!.createdAt)),
                    ]),
                    const SizedBox(height: 20),

                    if (_order!.shippingAddress != null) ...[
                      _section('Shipping Address'),
                      const SizedBox(height: 12),
                      _infoCard([
                        _row('Address', _order!.shippingAddress!),
                        _row('City', '${_order!.city ?? ''}, ${_order!.state ?? ''}'),
                        _row('ZIP', _order!.zipCode ?? ''),
                        _row('Phone', _order!.phone ?? ''),
                      ]),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
    );
  }

  Widget _orderItemCard(OrderItem item, NumberFormat fmt) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.divider)),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: item.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: item.imageUrl!, width: 60, height: 60, fit: BoxFit.cover,
                  httpHeaders: const {'User-Agent': 'Mozilla/5.0'},
                  errorWidget: (_, __, ___) => Container(width: 60, height: 60, color: AppTheme.bgSurface, child: const Icon(Icons.image, color: AppTheme.textMuted, size: 20)),
                )
              : Container(width: 60, height: 60, color: AppTheme.bgSurface, child: const Icon(Icons.image, color: AppTheme.textMuted, size: 20)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName ?? 'Product #${item.productId}',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Text('Qty: ${item.quantity}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
        ),
        Text(fmt.format(item.unitPrice * item.quantity),
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.accent)),
      ],
    ),
  );

  Widget _buildTimeline(String status) {
    final steps = ['pending', 'packed', 'shipped', 'delivered'];
    final current = steps.indexOf(status.toLowerCase());
    final isCancelled = status.toLowerCase() == 'cancelled';

    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3))),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.cancel_rounded, color: AppTheme.danger, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Cancelled', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.danger)),
                const SizedBox(height: 4),
                Text('This order has been cancelled', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
              ],
            )),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: List.generate(steps.length, (i) {
          final done = i <= current;
          final isActive = i == current;
          final isLast = i == steps.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 32 : 28, height: isActive ? 32 : 28,
                    decoration: BoxDecoration(
                      color: done ? AppTheme.accent : AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(isActive ? 10 : 8),
                      boxShadow: isActive ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 8)] : null,
                    ),
                    child: Icon(done ? Icons.check : _stepIcon(steps[i]), size: 14, color: done ? AppTheme.bgPrimary : AppTheme.textMuted),
                  ),
                  if (!isLast) Container(width: 2, height: 32, color: done ? AppTheme.accent : AppTheme.divider),
                ],
              ),
              const SizedBox(width: 14),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_stepLabel(steps[i]), style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: done ? AppTheme.textPrimary : AppTheme.textMuted,
                    )),
                    Text(_stepDesc(steps[i]), style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                    if (!isLast) const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  IconData _stepIcon(String s) {
    switch (s) { case 'packed': return Icons.inventory_2_outlined; case 'shipped': return Icons.local_shipping_outlined; case 'delivered': return Icons.check_circle_outline; default: return Icons.schedule; }
  }
  String _stepLabel(String s) => s[0].toUpperCase() + s.substring(1);
  String _stepDesc(String s) {
    switch (s) { case 'pending': return 'Order received'; case 'packed': return 'Items packed & ready'; case 'shipped': return 'Out for delivery'; case 'delivered': return 'Delivered successfully'; default: return ''; }
  }

  String _paymentLabel(String? m) {
    switch (m) { case 'cod': return 'Cash on Delivery'; case 'upi': return 'UPI Payment'; case 'card': return 'Credit/Debit Card'; default: return m ?? 'N/A'; }
  }

  Widget _section(String t) => Text(t, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary));
  Widget _infoCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.divider)),
    child: Column(children: children),
  );
  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 90, child: Text(l, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted))),
      Expanded(child: Text(v, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500))),
    ]),
  );

  String _fmtDate(String d) { try { return DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(d)); } catch (_) { return d; } }
}
