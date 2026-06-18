import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';

const teacherPrimaryColor = Color(0xFF1D4ED8); // Blue 700
const teacherGradient = LinearGradient(
  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class TeacherDashboardPage extends ConsumerStatefulWidget {
  const TeacherDashboardPage({super.key});
  @override
  ConsumerState<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends ConsumerState<TeacherDashboardPage> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final [dashRes, meRes] = await Future.wait([
        ApiClient().dio.get('/teacher/dashboard'),
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
    final isDark = AppTheme.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        title: Text('CBT — Guru', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18,
          color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: teacherPrimaryColor))
        : RefreshIndicator(
            onRefresh: _load,
            color: teacherPrimaryColor,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Premium Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: teacherGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: teacherPrimaryColor.withAlpha(80),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang,',
                        style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _user?['name'] ?? 'Guru',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Stat cards
                GridView.count(
                  crossAxisCount: 2, 
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16, 
                  mainAxisSpacing: 16, 
                  childAspectRatio: 1.4,
                  children: [
                    _statCard('Bank Soal', '${_data?['totalQuestions'] ?? 0}', Icons.quiz_outlined, Colors.indigo),
                    _statCard('Ujian Aktif', '${_data?['totalExams'] ?? 0}', Icons.assignment_outlined, Colors.green),
                    _statCard('Koreksi Esai', '${_data?['pendingEssays'] ?? 0}', Icons.edit_note_outlined, Colors.orange),
                    _statCard('Peserta', '${_data?['totalParticipants'] ?? 0}', Icons.people_outline, Colors.purple),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Quick actions
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: isDark ? teacherPrimaryColor.withAlpha(50) : teacherPrimaryColor.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.grid_view_rounded, size: 18, color: isDark ? Colors.blue.shade300 : teacherPrimaryColor),
                    ),
                    const SizedBox(width: 12),
                    Text('Aksi Cepat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                  ],
                ),
                const SizedBox(height: 16),
                _menuItem(Icons.quiz_outlined, 'Kelola Bank Soal', 'Buat & edit soal pilihan ganda / esai', () => context.push('/teacher/questions')),
                _menuItem(Icons.assignment_outlined, 'Jadwal & Paket Ujian', 'Atur sesi ujian untuk siswa', () => context.push('/teacher/exams')),
                _menuItem(Icons.edit_note_outlined, 'Koreksi Jawaban Esai', 'Beri nilai untuk jawaban uraian', () => context.push('/teacher/essay-grading')),
                _menuItem(Icons.monitor_heart_outlined, 'Live Monitoring', 'Pantau peserta yang sedang ujian', () => context.push('/teacher/exams')), // They choose exam first
              ],
            ),
          ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, MaterialColor color) {
    final isDark = AppTheme.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: isDark ? color.shade900.withAlpha(100) : color.shade50, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: isDark ? color.shade300 : color.shade600, size: 20),
              ),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
            ],
          ),
          Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String sub, VoidCallback onTap) {
    final isDark = AppTheme.isDark(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: isDark ? Colors.blue.shade900.withAlpha(100) : Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: isDark ? Colors.blue.shade300 : teacherPrimaryColor, size: 24),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(sub, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade50, shape: BoxShape.circle),
          child: Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
        ),
        onTap: onTap,
      ),
    );
  }
}
