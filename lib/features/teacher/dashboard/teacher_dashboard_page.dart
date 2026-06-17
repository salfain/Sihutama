import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});
  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/teacher/dashboard');
      setState(() => _data = res.data);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Guru'),
        actions: [
          IconButton(icon: const Icon(Icons.logout, size: 22), onPressed: () async {
            final router = GoRouter.of(context);
            await ApiClient().clearToken();
            router.go('/login');
          }),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stat cards
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6,
                  children: [
                    _statCard('Bank Soal', '${_data?['totalQuestions'] ?? 0}', Icons.quiz, Colors.blue),
                    _statCard('Ujian', '${_data?['totalExams'] ?? 0}', Icons.assignment, Colors.green),
                    _statCard('Esai Pending', '${_data?['pendingEssays'] ?? 0}', Icons.edit_note, Colors.orange),
                    _statCard('Peserta', '${_data?['totalParticipants'] ?? 0}', Icons.people, Colors.purple),
                  ],
                ),
                const SizedBox(height: 24),
                // Quick actions
                const Text('Menu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                _menuItem(Icons.quiz_outlined, 'Bank Soal', 'Kelola soal', () => context.push('/teacher/questions')),
                _menuItem(Icons.assignment_outlined, 'Paket Ujian', 'Buat & kelola ujian', () => context.push('/teacher/exams')),
                _menuItem(Icons.edit_note_outlined, 'Koreksi Esai', 'Nilai jawaban esai siswa', () => context.push('/teacher/essay-grading')),
                _menuItem(Icons.monitor_heart_outlined, 'Monitoring', 'Pantau peserta ujian', () => context.push('/teacher/exams')),
              ],
            ),
          ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String sub, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.green[700], size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
