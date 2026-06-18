import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../app/theme.dart';

const _primary = Color(0xFF1D4ED8);
const _gradient = LinearGradient(
  colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
  begin: Alignment.topLeft, end: Alignment.bottomRight,
);

class StudentCbtDashboardPage extends ConsumerStatefulWidget {
  const StudentCbtDashboardPage({super.key});
  @override
  ConsumerState<StudentCbtDashboardPage> createState() => _State();
}

class _State extends ConsumerState<StudentCbtDashboardPage> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final [dashRes, meRes] = await Future.wait([
        ApiClient().dio.get('/student/dashboard'),
        ApiClient().dio.get('/auth/me'),
      ]);
      setState(() { _data = dashRes.data; _user = meRes.data; });
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        title: Text('CBT — Siswa', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18,
          color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: _primary,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Hero card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: _gradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: _primary.withAlpha(80), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Selamat datang kembali 👋',
                        style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text(_user?['name'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          '${_user?['student']?['class']?['name'] ?? ''} • NIS: ${_user?['student']?['nis'] ?? ''}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 32),

                  _sectionTitle('Ujian Hari Ini', Icons.today_rounded, isDark),
                  const SizedBox(height: 12),
                  ...(_data?['todayExams'] as List? ?? []).map((e) => _examCard(e, isDark)),
                  if ((_data?['todayExams'] as List?)?.isEmpty ?? true) _emptyState('Belum ada jadwal ujian hari ini.', isDark),

                  const SizedBox(height: 32),
                  _sectionTitle('Jadwal Mendatang', Icons.calendar_month_rounded, isDark),
                  const SizedBox(height: 12),
                  ...(_data?['upcomingExams'] as List? ?? []).map((e) => _upcomingItem(e, isDark)),
                  if ((_data?['upcomingExams'] as List?)?.isEmpty ?? true) _emptyState('Tidak ada ujian mendatang.', isDark),

                  const SizedBox(height: 32),
                  _sectionTitle('Riwayat Terakhir', Icons.history_rounded, isDark),
                  const SizedBox(height: 12),
                  ...(_data?['history'] as List? ?? []).map((h) => _historyItem(h, isDark)),
                  if ((_data?['history'] as List?)?.isEmpty ?? true) _emptyState('Belum ada riwayat ujian.', isDark),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, bool isDark) => Row(children: [
    Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: _primary.withAlpha(isDark ? 50 : 30), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 18, color: _primary)),
    const SizedBox(width: 12),
    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
  ]);

  Widget _emptyState(String msg, bool isDark) => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.grey.shade200)),
    child: Column(children: [
      Icon(Icons.inbox_rounded, size: 40, color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
      const SizedBox(height: 12),
      Text(msg, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 13)),
    ]),
  );

  Widget _examCard(dynamic e, bool isDark) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
      border: isDark ? Border.all(color: Colors.white.withAlpha(20)) : null),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.green.shade900.withAlpha(100) : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(
                color: isDark ? Colors.green.shade400 : Colors.green.shade600, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('Tersedia', style: TextStyle(color: isDark ? Colors.green.shade400 : Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
            ])),
          const Spacer(),
          Text(e['subject']?['code'] ?? '', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        Text(e['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.timer, size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
          const SizedBox(width: 4),
          Text('${e['durationMinutes'] ?? 0} mnt', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.push('/student/exams/${e['id']}/token'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12)),
            child: const Text('Masuk Ujian', style: TextStyle(fontWeight: FontWeight.bold)))),
      ]),
    ),
  );

  Widget _upcomingItem(dynamic e, bool isDark) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.grey.shade200)),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: isDark ? Colors.blue.shade900.withAlpha(100) : Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.lock_clock, color: isDark ? Colors.blue.shade300 : Colors.blue.shade600, size: 20)),
      title: Text(e['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text('${e['subject']?['code'] ?? ''} • ${e['durationMinutes'] ?? 0} mnt', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
    ),
  );

  Widget _historyItem(dynamic h, bool isDark) {
    final score = h['score'];
    final isGood = (score ?? 0) >= 75;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: isDark ? Colors.purple.shade900.withAlpha(100) : Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.history_edu, color: isDark ? Colors.purple.shade300 : Colors.purple.shade600, size: 20)),
        title: Text(h['exam']?['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Text(h['exam']?['subject']?['code'] ?? '', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isGood ? (isDark ? Colors.green.shade900.withAlpha(100) : Colors.green.shade50)
                : (isDark ? Colors.red.shade900.withAlpha(100) : Colors.red.shade50),
            borderRadius: BorderRadius.circular(8)),
          child: Text(score != null ? '$score' : '—',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
              color: isGood ? (isDark ? Colors.green.shade400 : Colors.green.shade700)
                  : (isDark ? Colors.red.shade400 : Colors.red.shade700))),
        ),
      ),
    );
  }
}
