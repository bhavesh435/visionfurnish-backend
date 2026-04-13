import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/order_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String? _statusFilter;
  final _searchCtrl = TextEditingController();

  static const _statuses = [
    'pending',
    'confirmed',
    'processing',
    'packed',
    'shipped',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<OrderProvider>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'delivered':
        return AppTheme.success;
      case 'shipped':
        return AppTheme.info;
      case 'cancelled':
        return AppTheme.danger;
      case 'pending':
        return AppTheme.warning;
      case 'confirmed':
        return AppTheme.gold;
      case 'packed':
        return const Color(0xFF26A69A);
      case 'processing':
        return const Color(0xFF7E57C2);
      default:
        return AppTheme.textSecondary;
    }
  }

  String _fmtDate(String s) {
    try {
      return DateFormat('MMM dd, yyyy  HH:mm').format(DateTime.parse(s));
    } catch (_) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OrderProvider>();
    final currFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Text('Orders',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              ),
              // Search
              SizedBox(
                width: 260,
                height: 40,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by ID or customer...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              op.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) {
                    setState(() {});
                    op.setSearchQuery(v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Status filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _statusFilter,
                    hint: const Text('All Statuses',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    dropdownColor: AppTheme.surfaceDark,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Statuses')),
                      ..._statuses.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                                s[0].toUpperCase() + s.substring(1)),
                          )),
                    ],
                    onChanged: (v) {
                      setState(() => _statusFilter = v);
                      op.fetchOrders(status: v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Table
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.dividerColor.withValues(alpha: 0.5)),
              ),
              child: op.isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.gold))
                  : Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(flex: 1, child: Text('Order ID', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 3, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 2, child: Text('Payment', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 2, child: Text('Action', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                            ],
                          ),
                        ),

                        // Table Rows
                        Expanded(
                          child: ListView.builder(
                            itemCount: op.filteredOrders.length,
                            itemBuilder: (ctx, i) {
                              final o = op.filteredOrders[i];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.3)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(flex: 1, child: Text('#${o.id}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                                    Expanded(flex: 3, child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(o.userName ?? 'N/A', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                        Text(o.userEmail ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                      ],
                                    )),
                                    Expanded(flex: 2, child: Text(currFmt.format(o.total), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                                    Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: _statusChip(o.status))),
                                    Expanded(flex: 2, child: Text((o.paymentMethod ?? 'cod').toUpperCase(), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                                    Expanded(flex: 2, child: Text(_fmtDate(o.createdAt), style: const TextStyle(fontSize: 12))),
                                    Expanded(flex: 2, child: _buildStatusDropdown(o.id, o.status, op)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // Pagination
                        if (op.totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: op.currentPage > 1
                                      ? () => op.fetchOrders(
                                          page: op.currentPage - 1,
                                          status: _statusFilter)
                                      : null,
                                  icon: const Icon(Icons.chevron_left_rounded),
                                ),
                                Text(
                                  'Page ${op.currentPage} of ${op.totalPages}',
                                  style: const TextStyle(color: AppTheme.textSecondary),
                                ),
                                IconButton(
                                  onPressed: op.currentPage < op.totalPages
                                      ? () => op.fetchOrders(
                                          page: op.currentPage + 1,
                                          status: _statusFilter)
                                      : null,
                                  icon: const Icon(Icons.chevron_right_rounded),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStatusDropdown(int orderId, String current, OrderProvider op) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isDense: true,
          dropdownColor: AppTheme.surfaceDark,
          style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
          items: _statuses
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s[0].toUpperCase() + s.substring(1)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null && v != current) {
              op.updateOrderStatus(orderId, v);
            }
          },
        ),
      ),
    );
  }
}
