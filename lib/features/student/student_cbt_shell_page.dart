import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

const _blue = Color(0xFF1D4ED8);
const _blueLight = Color(0xFF3B82F6);

/// Shell CBT siswa — bottom nav banking style
/// Tab: Beranda · Ujian · Nilai · Profil
class StudentCbtShellPage extends ConsumerWidget {
  final Widget child;
  const StudentCbtShellPage({super.key, required this.child});

  int _index(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/student/cbt/exams')) return 1;
    if (loc.startsWith('/student/cbt/results')) return 2;
    if (loc.startsWith('/student/cbt/profil')) return 3;
    return 0;
  }

  void _onTap(int i, BuildContext context) {
    switch (i) {
      case 0: context.go('/student/cbt'); break;
      case 1: context.go('/student/cbt/exams'); break;
      case 2: context.go('/student/cbt/results'); break;
      case 3: context.go('/student/cbt/profil'); break;
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
            color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade200, width: 1)),
          boxShadow: [
            if (!isDark) BoxShadow(
              color: _blue.withAlpha(15), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(children: [
              _item(context, 0, idx, Icons.home_rounded, Icons.home_outlined, 'Beranda', isDark),
              _item(context, 1, idx, Icons.assignment_rounded, Icons.assignment_outlined, 'Ujian', isDark),
              _item(context, 2, idx, Icons.emoji_events_rounded, Icons.emoji_events_outlined, 'Nilai', isDark),
              _item(context, 3, idx, Icons.person_rounded, Icons.person_outlined, 'Profil', isDark),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int tabIdx, int currentIdx,
      IconData active, IconData inactive, String label, bool isDark) {
    final sel = tabIdx == currentIdx;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(tabIdx, context),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: sel ? _blue.withAlpha(isDark ? 40 : 25) : Colors.transparent,
              borderRadius: BorderRadius.circular(12)),
            child: Icon(sel ? active : inactive,
              color: sel ? (isDark ? _blueLight : _blue) : (isDark ? Colors.grey[500] : Colors.grey[400]),
              size: 22)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            fontSize: 10,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel ? (isDark ? _blueLight : _blue) : (isDark ? Colors.grey[500] : Colors.grey[400]))),
        ]),
      ),
    );
  }
}
