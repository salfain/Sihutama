import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

const teacherPrimaryColor = Color(0xFF1D4ED8); // Blue 700

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bank Soal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: teacherPrimaryColor))
        : RefreshIndicator(
            onRefresh: _load,
            color: teacherPrimaryColor,
            child: _questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.quiz_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Belum ada soal', style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _questions.length,
                  itemBuilder: (_, i) {
                    final q = _questions[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade700))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(q['questionText'] ?? '', maxLines: 3, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8, 
                              runSpacing: 8,
                              children: [
                                _badge(q['questionType'] ?? '', Colors.blue),
                                _badge(q['difficulty'] ?? '', q['difficulty'] == 'EASY' ? Colors.green : q['difficulty'] == 'HARD' ? Colors.red : Colors.orange),
                                _badge(q['subject']?['code'] ?? '', Colors.grey),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
    );
  }

  Widget _badge(String text, MaterialColor c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.shade50, 
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.shade100)
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: c.shade700, fontWeight: FontWeight.bold)),
    );
  }
}
