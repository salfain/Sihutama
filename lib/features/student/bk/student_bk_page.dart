import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../../app/theme.dart';

const studentPrimaryColor = Color(0xFFEA580C);

class StudentBkPage extends StatefulWidget {
  const StudentBkPage({super.key});
  @override
  State<StudentBkPage> createState() => _StudentBkPageState();
}

class _StudentBkPageState extends State<StudentBkPage> {
  Map<String, dynamic>? _data;
  List _surveys = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Future.wait([
        ApiClient().dio.get('/student/bk'),
        ApiClient().dio.get('/student/surveys'),
      ]);
      setState(() {
        _data = res[0].data;
        _surveys = res[1].data as List;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  String _fmt(dynamic d) {
    if (d == null) return '';
    final dt = DateTime.tryParse(d.toString());
    if (dt == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final cases = (_data?['cases'] as List?) ?? [];
    final violations = (_data?['violations'] as List?) ?? [];
    final achievements = (_data?['achievements'] as List?) ?? [];
    final requests = (_data?['requests'] as List?) ?? [];

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
        appBar: AppBar(
          title: Text('Bimbingan Konseling', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
          bottom: _loading
              ? null
              : TabBar(
                  isScrollable: true,
                  indicatorColor: studentPrimaryColor,
                  labelColor: studentPrimaryColor,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Konseling'),
                    Tab(text: 'Pelanggaran'),
                    Tab(text: 'Prestasi'),
                    Tab(text: 'Permohonan'),
                    Tab(text: 'Angket'),
                  ],
                ),
        ),
        floatingActionButton: _loading
            ? null
            : FloatingActionButton.extended(
                onPressed: _showRequestDialog,
                backgroundColor: studentPrimaryColor,
                elevation: 4,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Ajukan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: studentPrimaryColor))
            : Column(
                children: [
                  _pointsBar(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _casesTab(cases),
                        _violationsTab(violations),
                        _achievementsTab(achievements),
                        _requestsTab(requests),
                        _surveysTab(_surveys),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _pointsBar() {
    final isDark = AppTheme.isDark(context);
    final vp = _data?['violationPoints'] ?? 0;
    final ap = _data?['achievementPoints'] ?? 0;
    final np = _data?['netPoints'] ?? 0;
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
      child: Row(
        children: [
          _pointCard('Pelanggaran', '$vp', Colors.red),
          const SizedBox(width: 8),
          _pointCard('Prestasi', '$ap', Colors.green),
          const SizedBox(width: 8),
          _pointCard('Poin Bersih', '$np', Colors.blue),
        ],
      ),
    );
  }

  Widget _pointCard(String label, String value, MaterialColor color) {
    final isDark = AppTheme.isDark(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? color.shade900.withAlpha(50) : color.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? color.shade900.withAlpha(100) : color.shade100),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? color.shade300 : color.shade700)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: isDark ? color.shade200 : color.shade800, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _empty(String msg, IconData icon) {
    final isDark = AppTheme.isDark(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      )
    );
  }

  Widget _cardWrapper(Widget child) {
    final isDark = AppTheme.isDark(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.grey.shade100),
      ),
      child: child,
    );
  }

  Widget _casesTab(List items) {
    if (items.isEmpty) return _empty('Belum ada sesi konseling.', Icons.forum_outlined);
    const typeLabel = {'PRIBADI': 'Pribadi', 'SOSIAL': 'Sosial', 'BELAJAR': 'Belajar', 'KARIR': 'Karir'};
    const statusLabel = {'OPEN': 'Terbuka', 'IN_PROGRESS': 'Proses', 'RESOLVED': 'Selesai', 'REFERRED': 'Rujukan'};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: items.map((c) => _cardWrapper(
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(children: [
            Expanded(child: Text(c['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.isDark(context) ? Colors.white : Colors.black87))),
            if (c['isConfidential'] == true) Icon(Icons.lock, size: 16, color: Colors.grey.shade400),
          ]),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(Icons.label_outline, size: 14, color: AppTheme.isDark(context) ? Colors.grey.shade400 : Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('${typeLabel[c['type']] ?? c['type']}', style: TextStyle(fontSize: 12, color: AppTheme.isDark(context) ? Colors.grey.shade400 : Colors.grey.shade600)),
                const SizedBox(width: 12),
                Icon(Icons.info_outline, size: 14, color: AppTheme.isDark(context) ? Colors.grey.shade400 : Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('${statusLabel[c['status']] ?? c['status']}', style: TextStyle(fontSize: 12, color: AppTheme.isDark(context) ? Colors.grey.shade400 : Colors.grey.shade600)),
              ],
            ),
          ),
          trailing: Text(_fmt(c['sessionDate']), style: TextStyle(fontSize: 12, color: AppTheme.isDark(context) ? Colors.grey.shade400 : Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ),
      )).toList(),
    );
  }

  Widget _violationsTab(List items) {
    if (items.isEmpty) return _empty('Tidak ada catatan pelanggaran.\nPertahankan!', Icons.verified_user_outlined);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: items.map((v) => _cardWrapper(
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(v['typeName'] ?? v['description'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.isDark(context) ? Colors.white : Colors.black87)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${v['description'] ?? ''}\n${_fmt(v['date'])}', style: TextStyle(fontSize: 13, color: AppTheme.isDark(context) ? Colors.grey.shade400 : Colors.grey.shade600)),
          ),
          isThreeLine: true,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.isDark(context) ? Colors.red.shade900.withAlpha(100) : Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text('${v['points']}', style: TextStyle(color: AppTheme.isDark(context) ? Colors.red.shade400 : Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      )).toList(),
    );
  }

  Widget _achievementsTab(List items) {
    if (items.isEmpty) return _empty('Belum ada catatan prestasi.', Icons.emoji_events_outlined);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: items.map((a) => _cardWrapper(
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.isDark(context) ? Colors.green.shade900.withAlpha(100) : Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.emoji_events, color: AppTheme.isDark(context) ? Colors.green.shade400 : Colors.green.shade600),
          ),
          title: Text(a['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.isDark(context) ? Colors.white : Colors.black87)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${a['level'] ?? '-'} · ${_fmt(a['date'])}', style: TextStyle(fontSize: 13, color: AppTheme.isDark(context) ? Colors.grey.shade400 : Colors.grey.shade600)),
          ),
          trailing: Text('+${a['points']}', style: TextStyle(color: AppTheme.isDark(context) ? Colors.green.shade400 : Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      )).toList(),
    );
  }

  Widget _requestsTab(List items) {
    if (items.isEmpty) return _empty('Belum ada permohonan konseling.\nTekan "Ajukan" untuk membuat.', Icons.edit_document);
    const statusLabel = {'PENDING': 'Menunggu', 'APPROVED': 'Disetujui', 'SCHEDULED': 'Dijadwalkan', 'DONE': 'Selesai', 'REJECTED': 'Ditolak'};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: items.map((r) => _cardWrapper(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(r['topic'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.isDark(context) ? Colors.white : Colors.black87))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.isDark(context) ? Colors.orange.shade900.withAlpha(100) : Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(statusLabel[r['status']] ?? r['status'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.isDark(context) ? Colors.orange.shade400 : Colors.orange.shade700)),
                ),
              ]),
              if ((r['description'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(r['description'], style: TextStyle(fontSize: 13, color: AppTheme.isDark(context) ? Colors.grey.shade400 : Colors.grey.shade600)),
              ],
              if ((r['response'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.isDark(context) ? Colors.blue.shade900.withAlpha(100) : Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.reply, size: 16, color: AppTheme.isDark(context) ? Colors.blue.shade400 : Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${r['response']}', style: TextStyle(fontSize: 13, color: AppTheme.isDark(context) ? Colors.blue.shade200 : Colors.blue.shade800))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: AppTheme.isDark(context) ? Colors.grey.shade500 : Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text('Diajukan ${_fmt(r['createdAt'])}', style: TextStyle(fontSize: 11, color: AppTheme.isDark(context) ? Colors.grey.shade500 : Colors.grey.shade500)),
                ],
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _surveysTab(List items) {
    if (items.isEmpty) return _empty('Belum ada angket yang tersedia.', Icons.assignment_outlined);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: items.map((s) => _cardWrapper(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.isDark(context) ? Colors.white : Colors.black87)),
                    if ((s['description'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(s['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: AppTheme.isDark(context) ? Colors.grey.shade400 : Colors.grey.shade600)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.quiz_outlined, size: 14, color: AppTheme.isDark(context) ? Colors.grey.shade500 : Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('${s['questionCount'] ?? 0} pertanyaan', style: TextStyle(fontSize: 12, color: AppTheme.isDark(context) ? Colors.grey.shade500 : Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (s['answered'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.isDark(context) ? Colors.green.shade900.withAlpha(100) : Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.check, size: 14, color: AppTheme.isDark(context) ? Colors.green.shade400 : Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text('Selesai', style: TextStyle(color: AppTheme.isDark(context) ? Colors.green.shade400 : Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    context.push('/student/bk/survey/${s['id']}').then((_) => _load());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: studentPrimaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('Isi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  void _showRequestDialog() {
    final topicCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String urgency = 'SEDANG';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Ajukan Konseling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: topicCtrl, 
                  decoration: InputDecoration(
                    labelText: 'Topik / Keperluan *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl, 
                  maxLines: 3, 
                  decoration: InputDecoration(
                    labelText: 'Penjelasan Singkat',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: urgency,
                  decoration: InputDecoration(
                    labelText: 'Tingkat Urgensi',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'RENDAH', child: Text('Rendah')),
                    DropdownMenuItem(value: 'SEDANG', child: Text('Sedang')),
                    DropdownMenuItem(value: 'TINGGI', child: Text('Tinggi (Darurat)')),
                  ],
                  onChanged: (v) => setLocal(() => urgency = v ?? 'SEDANG'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: Text('Batal', style: TextStyle(color: Colors.grey.shade600))
            ),
            ElevatedButton(
              onPressed: () async {
                if (topicCtrl.text.trim().isEmpty) return;
                final nav = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ApiClient().dio.post('/student/bk/request', data: {
                    'topic': topicCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'urgency': urgency,
                  });
                  nav.pop();
                  messenger.showSnackBar(const SnackBar(content: Text('Permohonan terkirim')));
                  _load();
                } on DioException catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text(e.response?.data['error'] ?? 'Gagal mengirim')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: studentPrimaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Kirim', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
