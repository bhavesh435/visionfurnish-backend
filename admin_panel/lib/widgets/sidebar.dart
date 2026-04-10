import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final VoidCallback onLogout;
  final String? userName;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onLogout,
    this.userName,
  });

  static const _items = [
    _NavItem(Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(Icons.shopping_bag_rounded, 'Products'),
    _NavItem(Icons.category_rounded, 'Categories'),
    _NavItem(Icons.receipt_long_rounded, 'Orders'),
    _NavItem(Icons.people_rounded, 'Users'),
    _NavItem(Icons.preview_rounded, 'Preview'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          right: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: [
          // ── Logo Area ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.gold, AppTheme.goldDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chair_rounded, color: AppTheme.bgDark, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'VisionFurnish',
                    style: TextStyle(
                      color: AppTheme.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          const SizedBox(height: 12),

          // ── Nav Items ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _items.length,
              itemBuilder: (ctx, i) {
                final item = _items[i];
                final isActive = i == selectedIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onItemTapped(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isActive
                              ? AppTheme.gold.withValues(alpha: 0.12)
                              : Colors.transparent,
                          border: isActive
                              ? Border.all(color: AppTheme.gold.withValues(alpha: 0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: isActive ? AppTheme.gold : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                color: isActive ? AppTheme.gold : AppTheme.textSecondary,
                              ),
                            ),
                            if (isActive) ...[
                              const Spacer(),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.gold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Footer ──
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.gold.withValues(alpha: 0.2),
                  child: Text(
                    (userName ?? 'A')[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName ?? 'Admin',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Administrator',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  color: AppTheme.textSecondary,
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
