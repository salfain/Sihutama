import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';

class ExamConfirmPage extends StatefulWidget {
  final String examId;
  const ExamConfirmPage({super.key, required this.examId});
  @override
  State<ExamConfirmPage> createState() => _ExamConfirmPageState();
}

class _ExamConfirmPageState extends State<ExamConfirmPage> {
  bool _loading = false;

  Future<void> _start() async {
    setState(() => _loading = true);
    try {
      await ApiClient().dio.post('/student/exams/start', data: {'examId': widget.examId});
      if (mounted) context.go('/student/exams/${widget.examId}/test');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((e is DioException) ? (e.response?.data['error'] ?? 'Gagal') : 'Error')),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Ujian')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.assignment, size: 48, color: Color(0xFF1D4ED8)),
            const SizedBox(height: 16),
            const Text('Siap Memulai Ujian?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _infoTile(Icons.timer, 'Timer berjalan setelah klik Mulai'),
            _infoTile(Icons.save, 'Jawaban tersimpan otomatis'),
            _infoTile(Icons.warning_amber, 'Jangan tutup aplikasi saat ujian'),
            _infoTile(Icons.send, 'Klik Selesai untuk submit'),
            _infoTile(Icons.timer_off, 'Auto submit jika waktu habis'),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _start,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                child: _loading
                  ? const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)
                  : const Text('Mulai Ujian Sekarang', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.amber[700]),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }
}
