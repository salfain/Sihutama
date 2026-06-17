import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/providers/theme_provider.dart';
import '../../../core/network/api_client.dart';

const counselorColor = Color(0xFF7C3AED);

class CounselorShellPage extends ConsumerWidget {
  final Widget child;
  const CounselorShellPage({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/counselor/counseling')) return 1;
    if (location.startsWith('/counselor/students')) return 2;
    if (location.startsWith('/counselor/surveys')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/counselor');
        break;
      case 1:
        context.go('/counselor/counseling');
        break;
      case 2:
        context.go('/counselor/students');
        break;
      case 3:
        context.go('/counselor/surveys');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppTheme.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bimbingan Konseling', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: isDark ? Colors.orange.shade300 : Colors.grey.shade700),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, size: 22, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () async {
              final router = GoRouter.of(context);
              await ApiClient().clearToken();
              router.go('/login');
            },
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            if (!isDark) BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 20, offset: const Offset(0, -5)),
          ],
          border: Border(top: BorderSide(color: isDark ? Colors.white.withAlpha(20) : Colors.transparent)),
        ),
        child: BottomNavigationBar(
          currentIndex: _calculateSelectedIndex(context),
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          selectedItemColor: isDark ? Colors.purple.shade300 : counselorColor,
          unselectedItemColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          elevation: 0,
          onTap: (i) => _onItemTapped(i, context),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Konseling'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Buku Siswa'),
            BottomNavigationBarItem(icon: Icon(Icons.poll_rounded), label: 'Angket'),
          ],
        ),
      ),
    );
  }
}
