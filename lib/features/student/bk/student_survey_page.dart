import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

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
            .map((e) => {'questionId': e.key, 'value': e.value})
            .toList(),
      });
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Berhasil'),
          content: const Text('Terima kasih! Jawaban kamu sudah tersimpan.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
              child: const Text('OK'),
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
    return Scaffold(
      appBar: AppBar(title: Text(_survey?['title'] ?? 'Angket')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _answered
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'Sudah diisi',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kamu sudah mengisi angket ini sebelumnya.',
                          style: TextStyle(color: Colors.grey[600]),
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
                        padding: const EdgeInsets.all(14),
                        color: Colors.purple[50],
                        child: Text(
                          _survey!['description'],
                          style: TextStyle(fontSize: 13, color: Colors.purple[800]),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _questions.length,
                        itemBuilder: (_, i) => _questionCard(i, _questions[i]),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Kirim Jawaban', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _questionCard(int index, dynamic q) {
    final qId = q['id'] as String;
    final selectedValue = _answers[qId];
    const labels = {
      1: 'Tidak Butuh',
      2: 'Cukup',
      3: 'Butuh',
      4: 'Sangat Butuh',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${q['text']}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: labels.entries.map((e) {
                final isSelected = selectedValue == e.key;
                return ChoiceChip(
                  label: Text(e.value),
                  selected: isSelected,
                  selectedColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? const Color(0xFF7C3AED) : Colors.grey[700],
                  ),
                  onSelected: (_) {
                    setState(() => _answers[qId] = e.key);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
