import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

/// Bottom sheet untuk review jawaban siswa per attempt.
/// Dipakai oleh siswa (lihat jawaban sendiri) & guru (lihat jawaban siswa).
class AnswerReviewSheet extends StatefulWidget {
  final String attemptId;
  const AnswerReviewSheet({super.key, required this.attemptId});

  static void show(BuildContext context, String attemptId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AnswerReviewSheet(attemptId: attemptId),
    );
  }

  @override
  State<AnswerReviewSheet> createState() => _AnswerReviewSheetState();
}

class _AnswerReviewSheetState extends State<AnswerReviewSheet> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ApiClient().dio.get('/answers/${widget.attemptId}');
      setState(() { _data = res.data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        if (_loading) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
        }
        if (_data == null) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Gagal memuat jawaban')));
        }

        final questions = _data!['questions'] as List? ?? [];
        final student = _data!['student'];
        final exam = _data!['exam'];
        final score = _data!['score'];

        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(student?['name'] ?? 'Review Jawaban', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${exam?['title'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ])),
                if (score != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                    child: Text('$score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[700])),
                  ),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.all(16),
                itemCount: questions.length,
                itemBuilder: (_, i) => _questionCard(questions[i], i + 1),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _questionCard(dynamic q, int number) {
    final studentAnswer = q['studentAnswer'];
    final isCorrect = studentAnswer?['isCorrect'];
    final options = q['options'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Soal $number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500])),
              const Spacer(),
              _resultBadge(isCorrect, studentAnswer),
            ]),
            const SizedBox(height: 8),
            Text(q['questionText'] ?? '', style: const TextStyle(fontSize: 14, height: 1.4)),
            const SizedBox(height: 12),
            ...options.map((opt) {
              final isSelected = studentAnswer?['selectedOptionId'] == opt['id'];
              final isKey = opt['isCorrect'] == true;
              Color bg = Colors.white;
              Color border = Colors.grey.shade200;
              if (isKey) { bg = Colors.green[50]!; border = Colors.green.shade300; }
              if (isSelected && !isKey) { bg = Colors.red[50]!; border = Colors.red.shade300; }
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
                child: Row(children: [
                  Text('${opt['label']}. ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Expanded(child: Text(opt['text'] ?? '', style: const TextStyle(fontSize: 13))),
                  if (isSelected) Text('Jawaban', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  if (isKey) Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                ]),
              );
            }),
            // Essay answer
            if (options.isEmpty && studentAnswer?['answerText'] != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                child: Text(studentAnswer['answerText'] ?? '', style: const TextStyle(fontSize: 13)),
              ),
            ],
            // Explanation
            if (q['explanation'] != null && (q['explanation'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Pembahasan:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.indigo[700])),
                  const SizedBox(height: 4),
                  Text(q['explanation'], style: TextStyle(fontSize: 12, color: Colors.indigo[900])),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultBadge(dynamic isCorrect, dynamic studentAnswer) {
    if (studentAnswer == null) {
      return _badge('Kosong', Colors.grey);
    }
    if (isCorrect == true) return _badge('Benar', Colors.green);
    if (isCorrect == false) return _badge('Salah', Colors.red);
    return _badge('Belum Dinilai', Colors.orange);
  }

  Widget _badge(String text, MaterialColor c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c[50], borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c[700])),
    );
  }
}
