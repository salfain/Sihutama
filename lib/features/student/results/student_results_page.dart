import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../shared/widgets/answer_review_sheet.dart';

class StudentResultsPage extends StatefulWidget {
  const StudentResultsPage({super.key});
  @override
  State<StudentResultsPage> createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends State<StudentResultsPage> {
  List<dynamic> _results = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/student/results');
      setState(() => _results = res.data as List);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Nilai')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _results.isEmpty
              ? const Center(child: Text('Belum ada nilai'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final r = _results[i];
                    final score = r['score'];
                    final passed = r['exam']?['passingScore'] != null && (score ?? 0) >= r['exam']['passingScore'];
                    final canReview = r['exam']?['showResult'] == true;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r['exam']?['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Text('${r['exam']?['subject']?['code'] ?? ''} · Benar: ${r['correct']} · Salah: ${r['wrong']}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text('${score ?? '—'}',
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: (score ?? 0) >= 75 ? Colors.green[700] : Colors.red)),
                                    if (r['exam']?['passingScore'] != null)
                                      Text(passed ? 'Lulus' : 'Tidak Lulus',
                                        style: TextStyle(fontSize: 10, color: passed ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                            if (canReview) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => AnswerReviewSheet.show(context, r['id']),
                                  icon: const Icon(Icons.visibility, size: 16),
                                  label: const Text('Lihat Jawaban', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
    );
  }
}
