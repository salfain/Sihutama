import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});
  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final [dashRes, meRes] = await Future.wait([
        ApiClient().dio.get('/student/dashboard'),
        ApiClient().dio.get('/auth/me'),
      ]);
      setState(() {
        _data = dashRes.data;
        _user = meRes.data;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 22),
            onPressed: () async {
              final router = GoRouter.of(context);
              await ApiClient().clearToken();
              router.go('/login');
            },
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Welcome card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selamat datang,', style: TextStyle(color: Colors.orange[100], fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(_user?['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '${_user?['student']?['class']?['name'] ?? ''} · NIS: ${_user?['student']?['nis'] ?? ''}',
                        style: TextStyle(color: Colors.orange[100], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Ujian Hari Ini
                _sectionTitle('Ujian Hari Ini', Icons.today),
                const SizedBox(height: 8),
                ...(_data?['todayExams'] as List? ?? []).map((e) => _examCard(e, true)),

                if ((_data?['todayExams'] as List?)?.isEmpty ?? true)
                  _emptyCard('Tidak ada ujian hari ini'),

                const SizedBox(height: 20),
                _sectionTitle('Jadwal Mendatang', Icons.calendar_month),
                const SizedBox(height: 8),
                ...(_data?['upcomingExams'] as List? ?? []).map((e) => _upcomingItem(e)),

                const SizedBox(height: 20),
                _sectionTitle('Riwayat Terakhir', Icons.history),
                const SizedBox(height: 8),
                ...(_data?['history'] as List? ?? []).map((h) => _historyItem(h)),
              ],
            ),
          ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          if (i == 1) context.go('/student/exams');
          if (i == 2) context.go('/student/results');
          if (i == 3) context.go('/student/bk');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Ujian'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Nilai'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Konseling'),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 20, color: Colors.orange[700]),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
    ]);
  }

  Widget _emptyCard(String msg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(msg, style: TextStyle(color: Colors.grey[500], fontSize: 13))),
      ),
    );
  }

  Widget _examCard(dynamic e, bool showButton) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(6)),
                  child: Text('● Tersedia', style: TextStyle(color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Text(e['subject']?['code'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(e['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            Text('${e['subject']?['name'] ?? ''} · ${e['_count']?['questions'] ?? 0} soal · ${e['durationMinutes'] ?? 0} menit',
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            if (showButton) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/student/exams/${e['id']}/token'),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Masuk Ujian'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _upcomingItem(dynamic e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(e['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('${e['subject']?['code'] ?? ''} · ${e['durationMinutes'] ?? 0} mnt', style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.lock_clock, color: Colors.blue, size: 20),
      ),
    );
  }

  Widget _historyItem(dynamic h) {
    final score = h['score'];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(h['exam']?['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(h['exam']?['subject']?['code'] ?? '', style: const TextStyle(fontSize: 12)),
        trailing: Text(
          score != null ? '$score' : '—',
          style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 18,
            color: (score ?? 0) >= 75 ? Colors.green[700] : Colors.red[500],
          ),
        ),
      ),
    );
  }
}
