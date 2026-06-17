import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

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
    final cases = (_data?['cases'] as List?) ?? [];
    final violations = (_data?['violations'] as List?) ?? [];
    final achievements = (_data?['achievements'] as List?) ?? [];
    final requests = (_data?['requests'] as List?) ?? [];

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bimbingan Konseling'),
          bottom: _loading
              ? null
              : const TabBar(
                  isScrollable: true,
                  tabs: [
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
                backgroundColor: const Color(0xFF7C3AED),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Ajukan', style: TextStyle(color: Colors.white)),
              ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
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
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 3,
          type: BottomNavigationBarType.fixed,
          onTap: (i) {
            if (i == 0) context.go('/student');
            if (i == 1) context.go('/student/exams');
            if (i == 2) context.go('/student/results');
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Ujian'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Nilai'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Konseling'),
          ],
        ),
      ),
    );
  }

  Widget _pointsBar() {
    final vp = _data?['violationPoints'] ?? 0;
    final ap = _data?['achievementPoints'] ?? 0;
    final np = _data?['netPoints'] ?? 0;
    return Padding(
      padding: const EdgeInsets.all(12),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.shade100),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color[700])),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _empty(String msg) => Center(child: Text(msg, style: TextStyle(color: Colors.grey[500], fontSize: 13)));

  Widget _casesTab(List items) {
    if (items.isEmpty) return _empty('Belum ada sesi konseling.');
    const typeLabel = {'PRIBADI': 'Pribadi', 'SOSIAL': 'Sosial', 'BELAJAR': 'Belajar', 'KARIR': 'Karir'};
    const statusLabel = {'OPEN': 'Terbuka', 'IN_PROGRESS': 'Proses', 'RESOLVED': 'Selesai', 'REFERRED': 'Rujukan'};
    return ListView(
      padding: const EdgeInsets.all(12),
      children: items.map((c) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Row(children: [
            Expanded(child: Text(c['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
            if (c['isConfidential'] == true) Icon(Icons.lock, size: 14, color: Colors.grey[400]),
          ]),
          subtitle: Text('${typeLabel[c['type']] ?? c['type']} · ${statusLabel[c['status']] ?? c['status']} · ${_fmt(c['sessionDate'])}', style: const TextStyle(fontSize: 12)),
        ),
      )).toList(),
    );
  }

  Widget _violationsTab(List items) {
    if (items.isEmpty) return _empty('Tidak ada catatan pelanggaran. Pertahankan!');
    return ListView(
      padding: const EdgeInsets.all(12),
      children: items.map((v) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(v['typeName'] ?? v['description'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text('${v['description'] ?? ''}\n${_fmt(v['date'])}', style: const TextStyle(fontSize: 12)),
          isThreeLine: true,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(20)),
            child: Text('${v['points']}', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
          ),
        ),
      )).toList(),
    );
  }

  Widget _achievementsTab(List items) {
    if (items.isEmpty) return _empty('Belum ada catatan prestasi.');
    return ListView(
      padding: const EdgeInsets.all(12),
      children: items.map((a) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: Colors.green[50], child: Icon(Icons.emoji_events, color: Colors.green[600])),
          title: Text(a['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text('${a['level'] ?? '-'} · ${_fmt(a['date'])}', style: const TextStyle(fontSize: 12)),
          trailing: Text('+${a['points']}', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
        ),
      )).toList(),
    );
  }

  Widget _requestsTab(List items) {
    if (items.isEmpty) return _empty('Belum ada permohonan konseling.\nTekan "Ajukan" untuk membuat.');
    const statusLabel = {'PENDING': 'Menunggu', 'APPROVED': 'Disetujui', 'SCHEDULED': 'Dijadwalkan', 'DONE': 'Selesai', 'REJECTED': 'Ditolak'};
    return ListView(
      padding: const EdgeInsets.all(12),
      children: items.map((r) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(r['topic'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                  child: Text(statusLabel[r['status']] ?? r['status'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
              if ((r['description'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(r['description'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
              if ((r['response'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                  child: Text('Tanggapan BK: ${r['response']}', style: TextStyle(fontSize: 12, color: Colors.blue[800])),
                ),
              ],
              const SizedBox(height: 4),
              Text('Diajukan ${_fmt(r['createdAt'])}', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _surveysTab(List items) {
    if (items.isEmpty) return _empty('Belum ada angket yang tersedia.');
    return ListView(
      padding: const EdgeInsets.all(12),
      children: items.map((s) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    if ((s['description'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(s['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                    const SizedBox(height: 4),
                    Text('${s['questionCount'] ?? 0} pertanyaan', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (s['answered'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20)),
                  child: Text('Sudah diisi', style: TextStyle(color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.bold)),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    context.push('/student/bk/survey/${s['id']}').then((_) => _load());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Isi', style: TextStyle(fontSize: 12)),
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
          title: const Text('Ajukan Konseling'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: topicCtrl, decoration: const InputDecoration(labelText: 'Topik / Keperluan *')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Penjelasan')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: urgency,
                  decoration: const InputDecoration(labelText: 'Urgensi'),
                  items: const [
                    DropdownMenuItem(value: 'RENDAH', child: Text('Rendah')),
                    DropdownMenuItem(value: 'SEDANG', child: Text('Sedang')),
                    DropdownMenuItem(value: 'TINGGI', child: Text('Tinggi')),
                  ],
                  onChanged: (v) => setLocal(() => urgency = v ?? 'SEDANG'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }
}
