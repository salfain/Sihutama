import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';

const _amber = Color(0xFFF59E0B);

class PiketDashboardPage extends StatefulWidget {
  const PiketDashboardPage({super.key});
  @override
  State<PiketDashboardPage> createState() => _State();
}

class _State extends State<PiketDashboardPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/piket/dashboard');
      if (mounted) setState(() => _data = res.data as Map<String, dynamic>?);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _fmt(dynamic d) {
    if (d == null) return '—';
    final dt = DateTime.tryParse(d.toString());
    if (dt == null) return '—';
    return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  String _todayStr() {
    final now = DateTime.now();
    const days = ['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'];
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month-1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final activePermits = (_data?['activePermits'] as List?) ?? [];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _amber))
          : RefreshIndicator(
              onRefresh: _load,
              color: _amber,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 140,
                    pinned: true,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : _amber,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF78350F), const Color(0xFF1E293B)]
                                : [const Color(0xFFF59E0B), const Color(0xFFFCD34D)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight)),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Dashboard Piket',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(_todayStr(),
                                style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    title: const Text('Piket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(delegate: SliverChildListDelegate([
                      // Summary cards
                      Row(children: [
                        _summaryCard('Terlambat', '${_data?['tardiness'] ?? 0}', Icons.alarm_rounded, Colors.orange, isDark),
                        const SizedBox(width: 10),
                        _summaryCard('Izin Aktif', '${_data?['permits'] ?? 0}', Icons.logout_rounded, Colors.red, isDark),
                        const SizedBox(width: 10),
                        _summaryCard('Guru Absen', '${_data?['absences'] ?? 0}', Icons.people_alt_rounded, Colors.blue, isDark),
                      ]),
                      const SizedBox(height: 20),

                      // Siswa belum kembali
                      Row(children: [
                        Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red[600]),
                        const SizedBox(width: 6),
                        Text('Siswa Belum Kembali',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                            color: isDark ? Colors.white : Colors.grey[900])),
                        const SizedBox(width: 8),
                        if (activePermits.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                            child: Text('${activePermits.length} aktif',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700))),
                      ]),
                      const SizedBox(height: 10),

                      if (activePermits.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade200)),
                          child: const Center(child: Text('Tidak ada siswa yang sedang izin keluar.',
                            style: TextStyle(fontSize: 13, color: Colors.grey))))
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100)),
                          child: Column(
                            children: activePermits.asMap().entries.map((entry) {
                              final i = entry.key;
                              final p = entry.value;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: i < activePermits.length - 1
                                    ? Border(bottom: BorderSide(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100))
                                    : null),
                                child: Row(children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(10)),
                                    child: Center(child: Text(
                                      (p['studentName'] ?? 'S')[0].toUpperCase(),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)))),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(p['studentName'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                                      color: isDark ? Colors.white : Colors.grey[900])),
                                    Text('${p['className'] ?? ''} · ${p['reason'] ?? ''}',
                                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500])),
                                  ])),
                                  Text(_fmt(p['exitTime']),
                                    style: TextStyle(fontSize: 12, color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                                ]),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ])),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, MaterialColor color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.shade100.withAlpha(isDark ? 50 : 255), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: isDark ? color.shade300 : color.shade700)),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[900])),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey[500])),
        ]),
      ),
    );
  }
}
