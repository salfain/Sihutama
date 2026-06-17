import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExamFinishPage extends StatelessWidget {
  final String examId;
  const ExamFinishPage({super.key, required this.examId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, size: 48, color: Colors.green[700]),
              ),
              const SizedBox(height: 24),
              const Text('Ujian Selesai!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Jawaban Anda telah terkirim.', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/student/results'),
                  child: const Text('Lihat Riwayat Nilai'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/student'),
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
