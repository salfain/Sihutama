import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';

class ExamFinishPage extends StatelessWidget {
  final String examId;
  const ExamFinishPage({super.key, required this.examId});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: isDark ? Colors.green.shade900.withAlpha(100) : Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, size: 48, color: isDark ? Colors.green.shade400 : Colors.green[700]),
              ),
              const SizedBox(height: 24),
              Text('Ujian Selesai!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 8),
              Text('Jawaban Anda telah terkirim.', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/student/cbt/results'),
                  child: const Text('Lihat Riwayat Nilai'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/student/cbt'),
                  child: const Text('Kembali ke Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
