import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';

const _purple = Color(0xFF7C3AED);

/// Tab Konseling: riwayat sesi + pelanggaran + prestasi + angket
class StudentBkKonselingPage extends StatefulWidget {
  const StudentBkKonselingPage({super.key});
  @override
  State<StudentBkKonselingPage> createState() => _State();
}

class _State extends State<StudentBkKonselingPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  Map<String, dynamic>? _data;
  List _surveys = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Future.wait([
        ApiClient().dio.get('/student/bk'),
        ApiClient().dio.get('/student/surveys'),
      ]);
      setState(() { _data = res[0].data; _surveys = res[1].data as List; });
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
    final cases = (_data?['cases'] as List?) ?? [];
    final violations = (_data?['violations'] as List?) ?? [];
    final achievements = (_data?['achievements'] as List?) ?? [];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text('Riwayat & Data'),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: _purple,
          labelColor: _purple,
          unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[500],
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          isScrollable: false,
          tabs: const [
            Tab(text: 'Konseling'),
            Tab(text: 'Pelanggaran'),
            Tab(text: 'Prestasi'),
            Tab(text: 'Angket'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _purple))
          : RefreshIndicator(
              onRefresh: _load,
              color: _purple,
              child: TabBarView(
                controller: _tab,
                children: [
                  _casesTab(cases, isDark),
                  _violationsTab(violations, isDark),
                  _achievementsTab(achievements, isDark),
                  _surveysTab(_surveys, isDark),
                ],
              ),
            ),
    );
  }

  Widget _empty(String msg, IconData icon, bool isDark) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? _purple.withAlpha(20) : const Color(0xFFF5F3FF),
            shape: BoxShape.circle),
          child: Icon(icon, size: 40, color: isDark ? Colors.grey[600] : Colors.grey[300])),
        const SizedBox(height: 16),
        Text(msg, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[500])),
      ]),
    );
  }

  Widget _card(Widget child, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 2)),
        ]),
      child: child,
    );
  }

  Widget _casesTab(List items, bool isDark) {
    if (items.isEmpty) return _empty('Belum ada sesi konseling.', Icons.forum_outlined, isDark);
    const sl = {'OPEN': 'Terbuka', 'IN_PROGRESS': 'Proses', 'RESOLVED': 'Selesai', 'REFERRED': 'Rujukan'};
    const sc = {
      'OPEN': Color(0xFF3B82F6), 'IN_PROGRESS': Color(0xFF0EA5E9),
      'RESOLVED': Color(0xFF10B981), 'REFERRED': Color(0xFF8B5CF6),
    };
    const tl = {'PRIBADI': 'Pribadi', 'SOSIAL': 'Sosial', 'BELAJAR': 'Belajar', 'KARIR': 'Karir'};

    final widgets = <Widget>[];
    for (final c in items) {
      final color = sc[c['status']] ?? Colors.grey;
      widgets.add(_card(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(c['title'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                color: isDark ? Colors.white : Colors.grey[900]))),
              if (c['isConfidential'] == true) ...[
                const SizedBox(width: 6),
                Icon(Icons.lock_rounded, size: 14, color: Colors.grey[400]),
              ],
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                child: Text(sl[c['status']] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6)),
                child: Text(tl[c['type']] ?? c['type'] ?? '', style: TextStyle(fontSize: 11,
                  color: isDark ? Colors.grey[300] : Colors.grey[600]))),
              const Spacer(),
              Text(_fmt(c['sessionDate']), style: TextStyle(fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[500])),
            ]),
          ]),
        ), isDark));
    }
    return ListView(padding: const EdgeInsets.all(16), children: widgets);
  }

  Widget _violationsTab(List items, bool isDark) {
    if (items.isEmpty) return _empty('Tidak ada pelanggaran.\nPertahankan! 🎉', Icons.verified_user_rounded, isDark);

    final widgets = <Widget>[];
    for (final v in items) {
      widgets.add(_card(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 4, height: 44,
              decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v['typeName'] ?? v['description'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                color: isDark ? Colors.white : Colors.grey[900])),
              const SizedBox(height: 3),
              Text(_fmt(v['date']), style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500])),
              if ((v['sanction'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text('Sanksi: ${v['sanction']}', style: TextStyle(fontSize: 11,
                  color: isDark ? Colors.orange[300] : Colors.orange[700])),
              ],
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.red.shade900.withAlpha(60) : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10)),
              child: Text('${v['points']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                color: isDark ? Colors.red.shade300 : Colors.red.shade600))),
          ]),
        ), isDark));
    }
    return ListView(padding: const EdgeInsets.all(16), children: widgets);
  }

  Widget _achievementsTab(List items, bool isDark) {
    if (items.isEmpty) return _empty('Belum ada catatan prestasi.', Icons.emoji_events_outlined, isDark);

    final widgets = <Widget>[];
    for (final a in items) {
      widgets.add(_card(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.green.shade900.withAlpha(60) : Colors.green.shade50,
                borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.emoji_events_rounded,
                color: isDark ? Colors.green.shade400 : Colors.green.shade600, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a['title'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                color: isDark ? Colors.white : Colors.grey[900])),
              const SizedBox(height: 3),
              Text('${a['level'] ?? '-'} · ${_fmt(a['date'])}',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500])),
            ])),
            Text('+${a['points']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
              color: isDark ? Colors.green.shade400 : Colors.green.shade600)),
          ]),
        ), isDark));
    }
    return ListView(padding: const EdgeInsets.all(16), children: widgets);
  }

  Widget _surveysTab(List items, bool isDark) {
    if (items.isEmpty) return _empty('Belum ada angket.', Icons.assignment_outlined, isDark);

    final widgets = <Widget>[];
    for (final s in items) {
      widgets.add(_card(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? _purple.withAlpha(30) : const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.assignment_rounded,
                color: isDark ? Colors.purple.shade300 : _purple, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s['title'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                color: isDark ? Colors.white : Colors.grey[900])),
              if ((s['description'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(s['description'], maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[500])),
              ],
              const SizedBox(height: 6),
              Text('${s['questionCount'] ?? 0} pertanyaan',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[500] : Colors.grey[500])),
            ])),
            const SizedBox(width: 10),
            s['answered'] == true
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.green.shade900.withAlpha(60) : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10)),
                  child: Text('✓ Selesai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.green.shade400 : Colors.green.shade600)))
              : ElevatedButton(
                  onPressed: () => context.push('/student/bk/survey/${s['id']}').then((_) => _load()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple, foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(56, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12)),
                  child: const Text('Isi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          ]),
        ), isDark));
    }
    return ListView(padding: const EdgeInsets.all(16), children: widgets);
  }
}
