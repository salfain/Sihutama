import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

const _teal = Color(0xFF059669);
const _tealLight = Color(0xFF10B981);

/// Shell Guru — bottom nav banking style
/// Tab: Beranda · Bank Soal · Ujian · Koreksi · Profil
class TeacherShellPage extends StatelessWidget {
  final Widget child;
  const TeacherShellPage({super.key, required this.child});

  int _index(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/teacher/questions')) return 1;
    if (loc.startsWith('/teacher/exams') || loc.startsWith('/teacher/monitoring')) return 2;
    if (loc.startsWith('/teacher/essay-grading')) return 3;
    if (loc.startsWith('/teacher/profil')) return 4;
    return 0;
  }

  void _onTap(int i, BuildContext context) {
    switch (i) {
      case 0: context.go('/teacher'); break;
      case 1: context.go('/teacher/questions'); break;
      case 2: context.go('/teacher/exams'); break;
      case 3: context.go('/teacher/essay-grading'); break;
      case 4: context.go('/teacher/profil'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              color: _teal.withAlpha(15), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(children: [
              _item(context, 0, idx, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Beranda', isDark),
              _item(context, 1, idx, Icons.quiz_rounded, Icons.quiz_outlined, 'Bank Soal', isDark),
              _item(context, 2, idx, Icons.assignment_rounded, Icons.assignment_outlined, 'Ujian', isDark),
              _item(context, 3, idx, Icons.edit_note_rounded, Icons.edit_note_outlined, 'Koreksi', isDark),
              _item(context, 4, idx, Icons.person_rounded, Icons.person_outlined, 'Profil', isDark),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: sel ? _teal.withAlpha(isDark ? 40 : 25) : Colors.transparent,
              borderRadius: BorderRadius.circular(12)),
            child: Icon(sel ? active : inactive,
              color: sel ? (isDark ? _tealLight : _teal) : (isDark ? Colors.grey[500] : Colors.grey[400]),
              size: 20)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            fontSize: 9,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel ? (isDark ? _tealLight : _teal) : (isDark ? Colors.grey[500] : Colors.grey[400]))),
        ]),
      ),
    );
  }
}
