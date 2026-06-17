import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import 'package:intl/intl.dart';

const counselorColor = Color(0xFF6D28D9);

class CounselorStudentDetailPage extends StatefulWidget {
  final String id;
  const CounselorStudentDetailPage({super.key, required this.id});

  @override
  State<CounselorStudentDetailPage> createState() => _CounselorStudentDetailPageState();
}

class _CounselorStudentDetailPageState extends State<CounselorStudentDetailPage> {
  Map<String, dynamic>? _s;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/counselor/students/book/${widget.id}');
      if (mounted) setState(() => _s = res.data);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memuat data')));
        context.pop();
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _fmt(dynamic d) {
    if (d == null) return '';
    final dt = DateTime.tryParse(d.toString());
    if (dt == null) return '';
    return DateFormat('d MMM yyyy', 'id_ID').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: counselorColor)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87), onPressed: () => context.pop()),
        title: const Text('Detail Buku Siswa', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            // Profile Header
            Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6D28D9), Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: const Color(0xFF6D28D9).withAlpha(60), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withAlpha(50),
                    child: Text((_s!['name'] ?? 'S')[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  Text(_s!['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('${_s!['className']} · ${_s!['major']}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  Text('NIS: ${_s!['nis']} / NISN: ${_s!['nisn']}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),

            // Points Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _pointStat('Pelanggaran', _s!['violationPoints'], Colors.red),
                  const SizedBox(width: 12),
                  _pointStat('Prestasi', _s!['achievementPoints'], Colors.green),
                  const SizedBox(width: 12),
                  _pointStat('Bersih', _s!['netPoints'], Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sections
            _sectionTitle('Riwayat Konseling', Icons.chat_bubble_rounded, Colors.purple),
            _buildList(_s!['cases'], (c) => _itemCard(c['title'], '${c['type']} · ${_fmt(c['sessionDate'])}', null, null)),

            _sectionTitle('Catatan Pelanggaran', Icons.gpp_maybe_rounded, Colors.red),
            _buildList(_s!['violations'], (v) => _itemCard(v['typeName'] ?? v['description'], _fmt(v['date']), '${v['points']} pt', Colors.red)),

            _sectionTitle('Catatan Prestasi', Icons.emoji_events_rounded, Colors.green),
            _buildList(_s!['achievements'], (a) => _itemCard(a['title'], '${a['level']} · ${_fmt(a['date'])}', '+${a['points']}', Colors.green)),

            _sectionTitle('Kunjungan Rumah & Surat', Icons.home_rounded, Colors.orange),
            _buildList([
              ...(_s!['homeVisits'] as List).map((h) => {'title': h['purpose'], 'sub': 'Kunjungan · ${_fmt(h['visitDate'])}'}),
              ...(_s!['summons'] as List).map((s) => {'title': '${s['level']} — ${s['reason']}', 'sub': 'Surat · ${_fmt(s['createdAt'])}'}),
            ], (i) => _itemCard(i['title'], i['sub'], null, null)),
          ],
        ),
      ),
    );
  }

  Widget _pointStat(String label, dynamic value, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color[700])),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color[50], borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: color[600]),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildList(List items, Widget Function(dynamic) builder) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: const Text('Belum ada data.', style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: items.map((e) => builder(e)).toList()),
    );
  }

  Widget _itemCard(String title, String sub, String? badge, MaterialColor? badgeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(2), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          if (badge != null && badgeColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: badgeColor[50], borderRadius: BorderRadius.circular(12)),
              child: Text(badge, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor[700])),
            ),
        ],
      ),
    );
  }
}
