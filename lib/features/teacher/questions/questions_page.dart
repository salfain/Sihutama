import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class QuestionsPage extends StatefulWidget {
  const QuestionsPage({super.key});
  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  List<dynamic> _questions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/teacher/questions');
      setState(() => _questions = res.data as List);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bank Soal')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _questions.isEmpty
              ? const Center(child: Text('Belum ada soal'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _questions.length,
                  itemBuilder: (_, i) {
                    final q = _questions[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 26, height: 26,
                                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                                child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600]))),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(q['questionText'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13)),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Wrap(spacing: 6, children: [
                              _badge(q['questionType'] ?? '', Colors.blue),
                              _badge(q['difficulty'] ?? '', q['difficulty'] == 'EASY' ? Colors.green : q['difficulty'] == 'HARD' ? Colors.red : Colors.orange),
                              _badge(q['subject']?['code'] ?? '', Colors.grey),
                            ]),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
    );
  }

  Widget _badge(String text, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withAlpha(20), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w600)),
    );
  }
}
