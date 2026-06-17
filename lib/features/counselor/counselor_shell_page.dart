import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';

const counselorColor = Color(0xFF7C3AED);

class CounselorShellPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bimbingan Konseling', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 22, color: Colors.black54),
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
            BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _calculateSelectedIndex(context),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: counselorColor,
          unselectedItemColor: Colors.grey.shade400,
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
