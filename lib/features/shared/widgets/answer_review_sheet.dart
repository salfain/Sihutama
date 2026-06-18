import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';

/// Bottom sheet untuk review jawaban siswa per attempt.
/// Dipakai oleh siswa (lihat jawaban sendiri) & guru (lihat jawaban siswa).
class AnswerReviewSheet extends StatefulWidget {
  final String attemptId;
  const AnswerReviewSheet({super.key, required this.attemptId});

  static void show(BuildContext context, String attemptId) {
    final isDark = AppTheme.isDark(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
    final isDark = AppTheme.isDark(context);
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dividerColor = isDark ? Colors.white.withAlpha(20) : Colors.grey.shade200;

    return DraggableScrollableSheet(
      initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        if (_loading) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
        if (_data == null) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Gagal memuat jawaban')));

        final questions = _data!['questions'] as List? ?? [];
        final student = _data!['student'];
        final exam = _data!['exam'];
        final score = _data!['score'];

        return Container(
          color: sheetBg,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(40) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(student?['name'] ?? 'Review Jawaban',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87)),
                    Text('${exam?['title'] ?? ''}',
                      style: TextStyle(fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
                  ])),
                  if (score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.blue.shade900.withAlpha(80) : Colors.blue[50],
                        borderRadius: BorderRadius.circular(10)),
                      child: Text('$score',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
                          color: isDark ? Colors.blue.shade300 : Colors.blue[700])),
                    ),
                ]),
              ),
              Divider(height: 1, color: dividerColor),
              Expanded(
                child: ListView.builder(
                  controller: controller, padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  itemBuilder: (_, i) => _questionCard(questions[i], i + 1, isDark),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _questionCard(dynamic q, int number, bool isDark) {
    final studentAnswer = q['studentAnswer'];
    final isCorrect = studentAnswer?['isCorrect'];
    final options = q['options'] as List? ?? [];
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? Colors.white.withAlpha(15) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSec = isDark ? Colors.grey[400]! : Colors.grey[500]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Soal $number',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSec)),
            const Spacer(),
            _resultBadge(isCorrect, studentAnswer),
          ]),
          const SizedBox(height: 8),
          Text(q['questionText'] ?? '',
            style: TextStyle(fontSize: 14, height: 1.4, color: textColor)),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final isSelected = studentAnswer?['selectedOptionId'] == opt['id'];
            final isKey = opt['isCorrect'] == true;
            Color bg;
            Color border;
            if (isDark) {
              if (isKey) { bg = Colors.green.shade900.withAlpha(80); border = Colors.green.shade700; }
              else if (isSelected && !isKey) { bg = Colors.red.shade900.withAlpha(80); border = Colors.red.shade700; }
              else { bg = const Color(0xFF1E293B); border = Colors.white.withAlpha(15); }
            } else {
              if (isKey) { bg = Colors.green[50]!; border = Colors.green.shade300; }
              else if (isSelected && !isKey) { bg = Colors.red[50]!; border = Colors.red.shade300; }
              else { bg = Colors.white; border = Colors.grey.shade200; }
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
              child: Row(children: [
                Text('${opt['label']}. ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                Expanded(child: Text(opt['text'] ?? '',
                  style: TextStyle(fontSize: 13, color: textColor))),
                if (isSelected) Text('Jawaban', style: TextStyle(fontSize: 10, color: textSec)),
                if (isKey) Icon(Icons.check_circle, size: 16,
                  color: isDark ? Colors.green.shade400 : Colors.green[600]),
              ]),
            );
          }),
          if (options.isEmpty && studentAnswer?['answerText'] != null) ...[
            Container(
              width: double.infinity, padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : Colors.grey[50],
                borderRadius: BorderRadius.circular(8)),
              child: Text(studentAnswer['answerText'] ?? '',
                style: TextStyle(fontSize: 13, color: textColor)),
            ),
          ],
          if (q['explanation'] != null && (q['explanation'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.indigo.shade900.withAlpha(60) : Colors.indigo[50],
                borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pembahasan:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.indigo.shade300 : Colors.indigo[700])),
                const SizedBox(height: 4),
                Text(q['explanation'],
                  style: TextStyle(fontSize: 12,
                    color: isDark ? Colors.indigo.shade200 : Colors.indigo[900])),
              ]),
            ),
          ],
        ]),
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
