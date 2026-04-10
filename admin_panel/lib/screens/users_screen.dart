import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/user_provider.dart';
import '../widgets/confirm_dialog.dart';

/// Users screen — Security Rules:
/// - Email is ALWAYS displayed as read-only text (never in a TextField)
/// - Password is NEVER fetched, stored, displayed, or editable
/// - Admin can view details, block/unblock, and delete users

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(String s) {
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(s));
    } catch (_) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final up = context.watch<UserProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Text('Users',
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
                    hintText: 'Search by name or email...',
                    prefixIcon:
                        const Icon(Icons.search_rounded, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              up.fetchUsers();
                            },
                          )
                        : null,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (v) => up.fetchUsers(search: v),
                  onChanged: (v) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Security notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.info.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_rounded, size: 16, color: AppTheme.info),
                SizedBox(width: 8),
                Text(
                  'Security: Email is read-only. Passwords are not accessible from this panel.',
                  style: TextStyle(color: AppTheme.info, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
              child: up.isLoading
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
                              Expanded(flex: 1, child: Text('ID', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 4, child: Text('Email', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 2, child: Text('Phone', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 1, child: Text('Role', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 2, child: Text('Joined', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                              Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                            ],
                          ),
                        ),

                        // Table Rows
                        Expanded(
                          child: ListView.builder(
                            itemCount: up.users.length,
                            itemBuilder: (ctx, i) {
                              final u = up.users[i];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.3)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(flex: 1, child: Text('#${u.id}', style: const TextStyle(fontSize: 13))),
                                    Expanded(flex: 3, child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: AppTheme.gold.withValues(alpha: 0.15),
                                          child: Text(
                                            u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                                            style: const TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(u.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                                      ],
                                    )),
                                    Expanded(flex: 4, child: Row(
                                      children: [
                                        const Icon(Icons.lock_outline, size: 12, color: AppTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(u.email, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                                      ],
                                    )),
                                    Expanded(flex: 2, child: Text(u.phone ?? '—', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                                    Expanded(flex: 1, child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: u.role == 'admin' ? AppTheme.gold.withValues(alpha: 0.12) : AppTheme.surfaceDark,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          u.role.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: u.role == 'admin' ? AppTheme.gold : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    )),
                                    Expanded(flex: 2, child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: u.isBlocked
                                              ? AppTheme.danger.withValues(alpha: 0.12)
                                              : AppTheme.success.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          u.isBlocked ? 'Blocked' : 'Active',
                                          style: TextStyle(
                                            color: u.isBlocked ? AppTheme.danger : AppTheme.success,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )),
                                    Expanded(flex: 2, child: Text(_fmtDate(u.createdAt), style: const TextStyle(fontSize: 12))),
                                    Expanded(flex: 2, child: Row(
                                      children: [
                                        Tooltip(
                                          message: u.isBlocked ? 'Unblock user' : 'Block user',
                                          child: IconButton(
                                            icon: Icon(
                                              u.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                                              size: 18,
                                              color: u.isBlocked ? AppTheme.success : AppTheme.warning,
                                            ),
                                            onPressed: () async {
                                              final action = u.isBlocked ? 'unblock' : 'block';
                                              final ok = await showConfirmDialog(
                                                context,
                                                title: '${action[0].toUpperCase()}${action.substring(1)} User',
                                                message: 'Are you sure you want to $action "${u.name}"?',
                                                confirmText: action[0].toUpperCase() + action.substring(1),
                                                confirmColor: u.isBlocked ? AppTheme.success : AppTheme.warning,
                                              );
                                              if (ok && mounted) {
                                                up.toggleBlockUser(u.id);
                                              }
                                            },
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(6),
                                          ),
                                        ),
                                        if (u.role != 'admin') ...[
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.delete_rounded, size: 18, color: AppTheme.danger),
                                            onPressed: () async {
                                              final ok = await showConfirmDialog(
                                                context,
                                                title: 'Delete User',
                                                message: 'Permanently delete "${u.name}"? This cannot be undone.',
                                                confirmText: 'Delete',
                                              );
                                              if (ok && mounted) {
                                                up.deleteUser(u.id);
                                              }
                                            },
                                            tooltip: 'Delete',
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(6),
                                          ),
                                        ],
                                      ],
                                    )),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // Pagination
                        if (up.totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: up.currentPage > 1
                                      ? () => up.fetchUsers(page: up.currentPage - 1)
                                      : null,
                                  icon: const Icon(Icons.chevron_left_rounded),
                                ),
                                Text(
                                  'Page ${up.currentPage} of ${up.totalPages}',
                                  style: const TextStyle(color: AppTheme.textSecondary),
                                ),
                                IconButton(
                                  onPressed: up.currentPage < up.totalPages
                                      ? () => up.fetchUsers(page: up.currentPage + 1)
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
}
