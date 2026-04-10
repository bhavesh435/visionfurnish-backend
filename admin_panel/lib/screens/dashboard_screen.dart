import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () {
        if (mounted) context.read<DashboardProvider>().fetchDashboard();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DashboardProvider>();
    final stats = dp.stats;
    final currFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    if (dp.isLoading && stats == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    }

    if (dp.error != null && stats == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
            const SizedBox(height: 12),
            Text(dp.error!, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => dp.fetchDashboard(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: () => dp.fetchDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Welcome back! Here\'s your store overview.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => dp.fetchDashboard(),
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppTheme.textSecondary,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (stats != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.attach_money_rounded,
                      title: 'Total Revenue',
                      value: currFmt.format(stats.totalRevenue),
                      color: AppTheme.gold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.receipt_long_rounded,
                      title: 'Total Orders',
                      value: stats.totalOrders.toString(),
                      color: AppTheme.info,
                      subtitle: '${stats.pendingOrders} pending',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.people_rounded,
                      title: 'Total Users',
                      value: stats.totalUsers.toString(),
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.shopping_bag_rounded,
                      title: 'Total Products',
                      value: stats.totalProducts.toString(),
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 28),

            // Revenue Chart
            if (stats != null && stats.monthlyRevenue.isNotEmpty) ...[
              Container(
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
                    const Text(
                      'Revenue Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: _calcInterval(stats.monthlyRevenue.map((e) => e.revenue).toList()),
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: AppTheme.dividerColor.withValues(alpha: 0.3),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 70,
                                getTitlesWidget: (value, meta) {
                                  String label;
                                  if (value >= 10000000) {
                                    label = '₹${(value / 10000000).toStringAsFixed(1)}Cr';
                                  } else if (value >= 100000) {
                                    label = '₹${(value / 100000).toStringAsFixed(1)}L';
                                  } else if (value >= 1000) {
                                    label = '₹${(value / 1000).toStringAsFixed(0)}K';
                                  } else {
                                    label = '₹${value.toInt()}';
                                  }
                                  return Text(
                                    label,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < stats.monthlyRevenue.length) {
                                    final m = stats.monthlyRevenue[idx].month;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        m.length >= 7 ? m.substring(5) : m,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: stats.monthlyRevenue
                                  .asMap()
                                  .entries
                                  .map((e) => FlSpot(
                                        e.key.toDouble(),
                                        e.value.revenue,
                                      ))
                                  .toList(),
                              isCurved: true,
                              color: AppTheme.gold,
                              barWidth: 3,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, pct, bar, idx) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: AppTheme.gold,
                                    strokeWidth: 2,
                                    strokeColor: AppTheme.bgDark,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppTheme.gold.withValues(alpha: 0.08),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Recent Orders
            if (stats != null && stats.recentOrders.isNotEmpty) ...[
              Container(
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
                    const Text(
                      'Recent Orders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.5))),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 1, child: Text('Order ID', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                          Expanded(flex: 2, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                          Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                          Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                          Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                        ],
                      ),
                    ),
                    // Rows
                    ...stats.recentOrders.map((o) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.3))),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text('#${o.id}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                            Expanded(flex: 2, child: Text(o.userName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                            Expanded(flex: 2, child: Text(currFmt.format(o.total), style: const TextStyle(fontSize: 13))),
                            Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: _statusChip(o.status))),
                            Expanded(flex: 2, child: Text(_fmtDate(o.createdAt), style: const TextStyle(fontSize: 12))),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _calcInterval(List<double> values) {
    if (values.isEmpty) return 1000;
    final max = values.reduce((a, b) => a > b ? a : b);
    if (max <= 0) return 1000;
    return (max / 4).ceilToDouble();
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'delivered':
        color = AppTheme.success;
        break;
      case 'shipped':
        color = AppTheme.info;
        break;
      case 'cancelled':
        color = AppTheme.danger;
        break;
      case 'pending':
        color = AppTheme.warning;
        break;
      default:
        color = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _fmtDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(d);
    } catch (_) {
      return dateStr;
    }
  }
}
