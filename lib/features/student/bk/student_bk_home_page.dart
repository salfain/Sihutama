import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';

const _purple = Color(0xFF7C3AED);
const _purpleLight = Color(0xFF8B5CF6);

class StudentBkHomePage extends StatefulWidget {
  const StudentBkHomePage({super.key});
  @override
  State<StudentBkHomePage> createState() => _StudentBkHomePageState();
}

class _StudentBkHomePageState extends State<StudentBkHomePage> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Future.wait([
        ApiClient().dio.get('/student/bk'),
        ApiClient().dio.get('/auth/me'),
      ]);
      setState(() { _data = res[0].data; _user = res[1].data; });
    } catch (_) {}
    setState(() => _loading = false);
  }

  String _fmt(dynamic d) {
    if (d == null) return '';
    final dt = DateTime.tryParse(d.toString());
    if (dt == null) return '';
    const m = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final vp = _data?['violationPoints'] ?? 0;
    final ap = _data?['achievementPoints'] ?? 0;
    final np = _data?['netPoints'] ?? 0;
    final cases = (_data?['cases'] as List?) ?? [];
    final achievements = (_data?['achievements'] as List?) ?? [];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F3FF),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _purple))
          : RefreshIndicator(
              onRefresh: _load,
              color: _purple,
              child: CustomScrollView(
                slivers: [
                  // ── Hero SliverAppBar ──────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : _purple,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF4C1D95), const Color(0xFF1E293B)]
                                : [const Color(0xFF5B21B6), _purpleLight],
                            begin: Alignment.topLeft, end: Alignment.bottomRight)),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 64, 20, 0),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.white.withAlpha(30),
                                  child: Text(
                                    (_user?['name'] ?? 'S')[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Halo, ${(_user?['name'] ?? '').split(' ').first} 👋',
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text(_user?['student']?['class']?['name'] ?? '',
                                      style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12)),
                                  ]),
                                ),
                              ]),
                              const SizedBox(height: 20),
                              Text('Bimbingan Konseling',
                                style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    title: const Text('SIBIKONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    titleSpacing: 20,
                  ),

                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(children: [
                          // ── Kartu Poin ────────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _purple.withAlpha(isDark ? 20 : 30),
                                  blurRadius: 20, offset: const Offset(0, 8))
                              ]),
                            child: Row(children: [
                              _pointBadge('Pelanggaran', '$vp', Colors.red, Icons.gpp_maybe_rounded, isDark),
                              _divider(isDark),
                              _pointBadge('Prestasi', '+$ap', Colors.green, Icons.emoji_events_rounded, isDark),
                              _divider(isDark),
                              _pointBadge('Poin Bersih', '$np', (np as int) < 0 ? Colors.red : Colors.blue, Icons.balance_rounded, isDark),
                            ]),
                          ),
                          const SizedBox(height: 20),

                          // ── Shortcut aksi ─────────────────────────────
                          _shortcutRow(context, isDark),
                          const SizedBox(height: 24),

                          // ── Konseling aktif ───────────────────────────
                          if (cases.isNotEmpty) ...[
                            _sectionHeader('Sesi Konseling Aktif', Icons.forum_rounded, _purple, isDark,
                              onTap: () => context.go('/student/bk-portal/konseling')),
                            const SizedBox(height: 10),
                            ...cases.take(2).map((c) => _caseCard(c, isDark)),
                            const SizedBox(height: 20),
                          ],

                          // ── Prestasi terbaru ──────────────────────────
                          if (achievements.isNotEmpty) ...[
                            _sectionHeader('Prestasi Terbaru', Icons.emoji_events_rounded, Colors.green, isDark),
                            const SizedBox(height: 10),
                            ...achievements.take(2).map((a) => _achievementCard(a, isDark)),
                            const SizedBox(height: 20),
                          ],

                          if (cases.isEmpty && achievements.isEmpty)
                            _welcomeCard(isDark),

                          const SizedBox(height: 100), // padding bottom nav
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _pointBadge(String label, String val, MaterialColor color, IconData icon, bool isDark) {
    return Expanded(
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? color.shade900.withAlpha(50) : color.shade50,
            borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 18, color: isDark ? color.shade300 : color.shade600)),
        const SizedBox(height: 8),
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
          color: isDark ? color.shade300 : color.shade700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey[400] : Colors.grey[500])),
      ]),
    );
  }

  Widget _divider(bool isDark) => Container(
    width: 1, height: 48,
    color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade200,
  );

  Widget _shortcutRow(BuildContext context, bool isDark) {
    final items = [
      _ShortcutItem('Ajukan Konseling', Icons.add_comment_rounded, const Color(0xFF7C3AED),
        () => context.go('/student/bk-portal/permohonan')),
      _ShortcutItem('Riwayat', Icons.history_rounded, const Color(0xFF0284C7),
        () => context.go('/student/bk-portal/konseling')),
      _ShortcutItem('Angket', Icons.assignment_rounded, const Color(0xFF059669),
        () => context.go('/student/bk-portal/permohonan')),
      _ShortcutItem('Prestasi', Icons.emoji_events_rounded, const Color(0xFFD97706),
        () => context.go('/student/bk-portal/konseling')),
    ];
    return Row(
      children: items.map((item) => Expanded(
        child: GestureDetector(
          onTap: item.onTap,
          child: Column(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: isDark ? item.color.withAlpha(30) : item.color.withAlpha(20),
                borderRadius: BorderRadius.circular(16)),
              child: Icon(item.icon, color: item.color, size: 22)),
            const SizedBox(height: 6),
            Text(item.label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700])),
          ]),
        ),
      )).toList(),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color, bool isDark, {VoidCallback? onTap}) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color)),
      const SizedBox(width: 8),
      Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
        color: isDark ? Colors.white : Colors.grey[900]))),
      if (onTap != null)
        GestureDetector(
          onTap: onTap,
          child: const Text('Lihat semua',
            style: TextStyle(fontSize: 12, color: _purple, fontWeight: FontWeight.w600))),
    ]);
  }

  Widget _caseCard(dynamic c, bool isDark) {
    const statusColors = {
      'OPEN': Color(0xFF3B82F6), 'IN_PROGRESS': Color(0xFF0EA5E9),
      'RESOLVED': Color(0xFF10B981), 'REFERRED': Color(0xFF8B5CF6),
    };
    const statusLabels = {
      'OPEN': 'Terbuka', 'IN_PROGRESS': 'Proses',
      'RESOLVED': 'Selesai', 'REFERRED': 'Rujukan',
    };
    final color = statusColors[c['status']] ?? Colors.grey;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(
          width: 4, height: 40,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c['title'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
            color: isDark ? Colors.white : Colors.grey[900])),
          const SizedBox(height: 3),
          Text(_fmt(c['sessionDate']), style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500])),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
          child: Text(statusLabels[c['status']] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color))),
      ]),
    );
  }

  Widget _achievementCard(dynamic a, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.green.shade900.withAlpha(80) : Colors.green.shade50,
            borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.emoji_events_rounded, size: 18, color: isDark ? Colors.green.shade400 : Colors.green.shade600)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a['title'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
            color: isDark ? Colors.white : Colors.grey[900])),
          const SizedBox(height: 3),
          Text('${a['level'] ?? ''} · ${_fmt(a['date'])}',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500])),
        ])),
        Text('+${a['points']}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
            color: isDark ? Colors.green.shade400 : Colors.green.shade600)),
      ]),
    );
  }

  Widget _welcomeCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF4C1D95).withAlpha(80), const Color(0xFF1E293B)]
              : [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? _purple.withAlpha(50) : const Color(0xFFDDD6FE))),
      child: Column(children: [
        Icon(Icons.favorite_rounded, size: 40, color: isDark ? _purpleLight : _purple),
        const SizedBox(height: 12),
        Text('Selamat Datang di SIBIKONS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
            color: isDark ? Colors.white : Colors.grey[900])),
        const SizedBox(height: 8),
        Text('Jangan ragu untuk mengajukan konseling.\nGuru BK siap membantu kamu.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600], height: 1.5)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => context.go('/student/bk-portal/permohonan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _purple, foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Ajukan Konseling', style: TextStyle(fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

class _ShortcutItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ShortcutItem(this.label, this.icon, this.color, this.onTap);
}
