import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../app/theme.dart';

const studentPrimaryColor = Color(0xFFEA580C);

class StudentSurveyPage extends StatefulWidget {
  final String surveyId;
  const StudentSurveyPage({super.key, required this.surveyId});
  @override
  State<StudentSurveyPage> createState() => _StudentSurveyPageState();
}

class _StudentSurveyPageState extends State<StudentSurveyPage> {
  Map<String, dynamic>? _survey;
  List _questions = [];
  bool _loading = true;
  bool _submitting = false;
  bool _answered = false;
  final Map<String, int> _answers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/student/surveys/${widget.surveyId}');
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _survey = data;
        _questions = (data['questions'] as List?) ?? [];
        _answered = data['answered'] == true;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    // Check all questions answered
    if (_answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap jawab semua pertanyaan')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiClient().dio.post('/student/surveys/${widget.surveyId}', data: {
        'answers': _answers.entries
            .map((e) => {'questionId': int.tryParse(e.key) ?? e.key, 'value': e.value})
            .toList(),
      });
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Berhasil', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green.shade500),
              const SizedBox(height: 16),
              const Text('Terima kasih! Jawaban kamu sudah tersimpan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: studentPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data['error'] ?? 'Gagal mengirim')),
      );
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        title: Text(_survey?['title'] ?? 'Angket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: studentPrimaryColor))
          : _answered
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 80, color: isDark ? Colors.green.shade500 : Colors.green.shade400),
                        const SizedBox(height: 24),
                        Text(
                          'Sudah diisi',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Kamu sudah mengisi angket ini sebelumnya.',
                          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    if (_survey?['description'] != null &&
                        (_survey!['description'] as String).isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.orange.shade900.withAlpha(100) : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.orange.shade900.withAlpha(50) : Colors.orange.shade100),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, color: isDark ? Colors.orange.shade400 : Colors.orange.shade600, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _survey!['description'],
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.orange.shade200 : Colors.orange.shade900, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                          left: 16, 
                          right: 16, 
                          bottom: 16, 
                          top: _survey?['description'] != null && (_survey!['description'] as String).isNotEmpty ? 0 : 16
                        ),
                        itemCount: _questions.length,
                        itemBuilder: (_, i) => _questionCard(i, _questions[i]),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        boxShadow: [
                          if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, -5)),
                        ],
                        border: Border(top: BorderSide(color: isDark ? Colors.white.withAlpha(20) : Colors.transparent)),
                      ),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: studentPrimaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Kirim Jawaban', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _questionCard(int index, dynamic q) {
    final isDark = AppTheme.isDark(context);
    final qId = q['id'].toString();
    final selectedValue = _answers[qId];
    const labels = {
      1: 'Tidak Butuh',
      2: 'Cukup',
      3: 'Butuh',
      4: 'Sangat Butuh',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.grey.shade100),
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
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: isDark ? Colors.orange.shade900.withAlpha(100) : Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.orange.shade400 : studentPrimaryColor))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q['text'],
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87, height: 1.4),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: labels.entries.map((e) {
                final isSelected = selectedValue == e.key;
                return InkWell(
                  onTap: () => setState(() => _answers[qId] = e.key),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? studentPrimaryColor : (isDark ? Colors.white.withAlpha(10) : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? studentPrimaryColor : (isDark ? Colors.white.withAlpha(20) : Colors.grey.shade200)),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
