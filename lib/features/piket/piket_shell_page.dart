import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

const _amber = Color(0xFFF59E0B);
const _amberDark = Color(0xFFFBBF24);

/// Shell Guru Piket — bottom nav banking style
/// Tab: Dashboard · Terlambat · Izin · Guru · Profil
class PiketShellPage extends ConsumerWidget {
  final Widget child;
  const PiketShellPage({super.key, required this.child});

  int _index(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/piket/terlambat')) return 1;
    if (loc.startsWith('/piket/izin')) return 2;
    if (loc.startsWith('/piket/guru')) return 3;
    if (loc.startsWith('/piket/laporan')) return 4;
    if (loc.startsWith('/piket/profil')) return 5;
    return 0;
  }

  void _onTap(int i, BuildContext context) {
    switch (i) {
      case 0: context.go('/piket'); break;
      case 1: context.go('/piket/terlambat'); break;
      case 2: context.go('/piket/izin'); break;
      case 3: context.go('/piket/guru'); break;
      case 4: context.go('/piket/laporan'); break;
      case 5: context.go('/piket/profil'); break;
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
              color: _amber.withAlpha(15), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(children: [
              _item(context, 0, idx, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Dashboard', isDark),
              _item(context, 1, idx, Icons.alarm_rounded, Icons.alarm_outlined, 'Terlambat', isDark),
              _item(context, 2, idx, Icons.logout_rounded, Icons.logout_outlined, 'Izin', isDark),
              _item(context, 3, idx, Icons.people_alt_rounded, Icons.people_alt_outlined, 'Guru', isDark),
              _item(context, 4, idx, Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Laporan', isDark),
              _item(context, 5, idx, Icons.person_rounded, Icons.person_outlined, 'Profil', isDark),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sel ? _amber.withAlpha(isDark ? 40 : 25) : Colors.transparent,
              borderRadius: BorderRadius.circular(12)),
            child: Icon(sel ? active : inactive,
              color: sel ? (isDark ? _amberDark : _amber) : (isDark ? Colors.grey[500] : Colors.grey[400]),
              size: 20)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            fontSize: 9,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel ? (isDark ? _amberDark : _amber) : (isDark ? Colors.grey[500] : Colors.grey[400]))),
        ]),
      ),
    );
  }
}
