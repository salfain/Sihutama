import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

const _bkPurple = Color(0xFF7C3AED);
const _bkPurpleLight = Color(0xFF8B5CF6);

/// Shell SIBIKONS siswa — bottom nav banking style
/// Tab: Beranda · Konseling · Permohonan · Profil
class StudentBkShellPage extends ConsumerWidget {
  final Widget child;
  const StudentBkShellPage({super.key, required this.child});

  int _index(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc == '/student/bk-portal/konseling') return 1;
    if (loc == '/student/bk-portal/permohonan') return 2;
    if (loc == '/student/bk-portal/profil') return 3;
    return 0;
  }

  void _onTap(int i, BuildContext context) {
    switch (i) {
      case 0: context.go('/student/bk-portal'); break;
      case 1: context.go('/student/bk-portal/konseling'); break;
      case 2: context.go('/student/bk-portal/permohonan'); break;
      case 3: context.go('/student/bk-portal/profil'); break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppTheme.isDark(context);
    final idx = _index(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(top: BorderSide(
            color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade200,
            width: 1)),
          boxShadow: [
            if (!isDark) BoxShadow(
              color: _bkPurple.withAlpha(15),
              blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _navItem(context, ref, 0, idx, Icons.home_rounded, Icons.home_outlined, 'Beranda'),
                _navItem(context, ref, 1, idx, Icons.forum_rounded, Icons.forum_outlined, 'Konseling'),
                // Tombol tengah (+) menonjol
                _centerButton(context),
                _navItem(context, ref, 2, idx, Icons.inbox_rounded, Icons.inbox_outlined, 'Permohonan'),
                _navItem(context, ref, 3, idx, Icons.person_rounded, Icons.person_outlined, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, WidgetRef ref, int tabIdx, int currentIdx,
      IconData active, IconData inactive, String label) {
    final isDark = AppTheme.isDark(context);
    final isSelected = tabIdx == currentIdx;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(tabIdx, context),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? _bkPurple.withAlpha(isDark ? 40 : 25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSelected ? active : inactive,
              color: isSelected
                  ? (isDark ? _bkPurpleLight : _bkPurple)
                  : (isDark ? Colors.grey[500] : Colors.grey[400]),
              size: 22),
          ),
          const SizedBox(height: 2),
          Text(label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? _bkPurpleLight : _bkPurple)
                  : (isDark ? Colors.grey[500] : Colors.grey[400]))),
        ]),
      ),
    );
  }

  // Tombol + tengah (Ajukan Konseling cepat)
  Widget _centerButton(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(2, context), // ke tab permohonan
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _bkPurple.withAlpha(70),
                  blurRadius: 10, offset: const Offset(0, 4)),
              ]),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 2),
          Text('Ajukan',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              color: _bkPurple.withAlpha(200))),
        ]),
      ),
    );
  }
}
