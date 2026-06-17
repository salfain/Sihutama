import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

const teacherPrimaryColor = Color(0xFF1D4ED8); // Blue 700

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Beri Nilai', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Icon(Icons.person, size: 16, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Text(essay['studentName'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue.shade900)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Nilai (0–100)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: Colors.grey.shade600))),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: teacherPrimaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Simpan Nilai', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pending = _essays.where((e) => e['score'] == null).length;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Koreksi Esai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: teacherPrimaryColor))
        : RefreshIndicator(
            onRefresh: _load,
            color: teacherPrimaryColor,
            child: _essays.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.done_all_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Tidak ada jawaban esai', style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (pending > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50, 
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('$pending jawaban belum dinilai dari ${_essays.length} total',
                                style: TextStyle(fontSize: 13, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ..._essays.map((e) => _essayCard(e)),
                  ],
                ),
          ),
    );
  }

  Widget _essayCard(dynamic e) {
    final graded = e['score'] != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.person, color: Colors.blue.shade600, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e['studentName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('${e['className'] ?? ''} • ${e['examTitle'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ])),
                if (graded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text('${e['score']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 16)),
                  ),
              ]
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50, 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text('Pertanyaan:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(e['questionText'] ?? '', style: TextStyle(fontSize: 13, color: Colors.blue.shade900, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50, 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  children: [
                    Icon(Icons.short_text, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text('Jawaban Siswa:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(e['answerText'] ?? '— Tidak ada jawaban —', style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openGradeDialog(e),
                icon: const Icon(Icons.edit_note, size: 18),
                label: Text(graded ? 'Ubah Nilai' : 'Beri Nilai', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: teacherPrimaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
