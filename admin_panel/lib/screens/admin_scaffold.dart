import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_theme.dart';
import '../widgets/sidebar.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'categories_screen.dart';
import 'orders_screen.dart';
import 'users_screen.dart';
import 'chat_screen.dart';
import 'preview_screen.dart';
import 'settings_screen.dart';

class AdminScaffold extends StatefulWidget {
  const AdminScaffold({super.key});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  int _selectedIndex = 0;
  bool _chatOpen = false;

  static const _screens = <Widget>[
    DashboardScreen(),
    ProductsScreen(),
    CategoriesScreen(),
    OrdersScreen(),
    UsersScreen(),
    PreviewScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Main layout
          Row(
            children: [
              Sidebar(
                selectedIndex: _selectedIndex,
                userName: auth.userName,
                onItemTapped: (i) => setState(() => _selectedIndex = i),
                onLogout: () async {
                  final nav = Navigator.of(context);
                  await auth.logout();
                  if (mounted) {
                    nav.pushReplacementNamed('/login');
                  }
                },
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _screens,
                ),
              ),
            ],
          ),

          // Chat overlay
          if (_chatOpen)
            Positioned(
              right: 24,
              bottom: 88,
              child: ChatScreen(),
            ),

          // Floating AI chat button
          Positioned(
            right: 24,
            bottom: 24,
            child: FloatingActionButton(
              onPressed: () => setState(() => _chatOpen = !_chatOpen),
              backgroundColor: AppTheme.gold,
              tooltip: 'AI Chat Assistant',
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _chatOpen ? Icons.close_rounded : Icons.smart_toy_rounded,
                  key: ValueKey(_chatOpen),
                  color: AppTheme.bgDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

