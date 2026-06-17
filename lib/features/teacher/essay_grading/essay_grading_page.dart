import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class EssayGradingPage extends StatefulWidget {
  const EssayGradingPage({super.key});
  @override
  State<EssayGradingPage> createState() => _EssayGradingPageState();
}

class _EssayGradingPageState extends State<EssayGradingPage> {
  List<dynamic> _essays = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/teacher/essay-grading');
      setState(() => _essays = res.data as List);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _grade(String answerId, int score) async {
    try {
      await ApiClient().dio.post('/teacher/essay-grading/$answerId', data: {'score': score});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nilai $score disimpan'), backgroundColor: Colors.green));
      }
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan nilai')));
      }
    }
  }

  void _openGradeDialog(dynamic essay) {
    final ctrl = TextEditingController(text: essay['score']?.toString() ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Beri Nilai', style: TextStyle(fontSize: 18)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(essay['studentName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Nilai (0–100)'),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            final v = int.tryParse(ctrl.text);
            if (v == null || v < 0 || v > 100) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Nilai harus 0–100')));
              return;
            }
            Navigator.pop(ctx);
            _grade(essay['id'], v);
          },
          child: const Text('Simpan'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pending = _essays.where((e) => e['score'] == null).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Koreksi Esai')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _essays.isEmpty
              ? const Center(child: Text('Tidak ada jawaban esai'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)),
                      child: Text('$pending jawaban belum dinilai dari ${_essays.length} total',
                        style: TextStyle(fontSize: 12, color: Colors.orange[800], fontWeight: FontWeight.w600)),
                    ),
                    ..._essays.map((e) => _essayCard(e)),
                  ],
                ),
          ),
    );
  }

  Widget _essayCard(dynamic e) {
    final graded = e['score'] != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e['studentName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text('${e['className'] ?? ''} · ${e['examTitle'] ?? ''}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ])),
              if (graded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                  child: Text('${e['score']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                ),
            ]),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
              child: Text(e['questionText'] ?? '', style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Jawaban siswa:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(e['answerText'] ?? '— Tidak ada jawaban —', style: const TextStyle(fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openGradeDialog(e),
                icon: const Icon(Icons.edit, size: 16),
                label: Text(graded ? 'Ubah Nilai' : 'Beri Nilai', style: const TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
