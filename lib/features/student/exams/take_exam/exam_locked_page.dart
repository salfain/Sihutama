import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';

class ExamLockedPage extends StatefulWidget {
  final String examId;
  final String? reason;
  const ExamLockedPage({super.key, required this.examId, this.reason});
  @override
  State<ExamLockedPage> createState() => _ExamLockedPageState();
}

class _ExamLockedPageState extends State<ExamLockedPage> {
  Timer? _poll;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // Polling otomatis tiap 8 detik untuk cek apakah pengawas sudah membuka kunci
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking || !mounted) return;
    setState(() => _checking = true);
    try {
      final res = await ApiClient().dio.get('/student/exams/${widget.examId}/status?_t=${DateTime.now().millisecondsSinceEpoch}');
      final d = res.data;
      if (!mounted) return;
      if (d['status'] == 'SUBMITTED' || d['status'] == 'AUTO_SUBMITTED') {
        context.go('/student/exams/${widget.examId}/finish');
        return;
      }
      if (d['isLocked'] == false) {
        // Sudah dibuka pengawas — kembali ke pengerjaan
        context.replace('/student/exams/${widget.examId}/test');
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C0A0A) : const Color(0xFFFEF2F2),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.red.shade900.withAlpha(80) : Colors.red[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock, size: 56, color: isDark ? Colors.red.shade300 : Colors.red[700]),
                ),
                const SizedBox(height: 20),
                Text('Ujian Terkunci',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.red.shade300 : Colors.red[800])),
                const SizedBox(height: 8),
                Text(
                  widget.reason ?? 'Anda terdeteksi keluar aplikasi beberapa kali.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14,
                    color: isDark ? Colors.red.shade200 : Colors.red[900]),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.red.shade800 : Colors.red.shade200),
                  ),
                  child: Column(children: [
                    Icon(Icons.support_agent, size: 36,
                      color: isDark ? Colors.red.shade400 : const Color(0xFFB91C1C)),
                    const SizedBox(height: 8),
                    Text('Hubungi Pengawas',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 4),
                    Text(
                      'Mintalah pengawas membuka kunci dari halaman Monitoring. Halaman ini akan otomatis lanjut bila kunci sudah dibuka.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _checking ? null : _check,
                    icon: _checking
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh, size: 18),
                    label: Text(_checking ? 'Memeriksa...' : 'Periksa Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    final router = GoRouter.of(context);
                    await ApiClient().clearToken();
                    router.go('/login');
                  },
                  child: const Text('Keluar Akun'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
