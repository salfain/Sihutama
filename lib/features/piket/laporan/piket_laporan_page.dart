import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';

const _amber = Color(0xFFF59E0B);

class PiketLaporanPage extends StatefulWidget {
  const PiketLaporanPage({super.key});
  @override
  State<PiketLaporanPage> createState() => _State();
}

class _State extends State<PiketLaporanPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  DateTime _date = DateTime.now();

  @override
  void initState() { super.initState(); _load(); }

  String _dateStr() =>
    '${_date.year}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')}';

  String _fmtDate(DateTime d) {
    const days = ['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'];
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${days[d.weekday % 7]}, ${d.day} ${months[d.month-1]} ${d.year}';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/piket/dashboard?date=${_dateStr()}');
      if (mounted) setState(() => _data = res.data as Map<String, dynamic>?);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat laporan: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null) { setState(() => _date = picked); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final tardiness = _data?['tardiness'] ?? 0;
    final permits = _data?['permits'] ?? 0;
    final absences = _data?['absences'] ?? 0;
    final activePermits = (_data?['activePermits'] as List?) ?? [];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
      appBar: AppBar(
        title: const Text('Laporan Harian'),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, size: 20),
            onPressed: _pickDate),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _amber))
          : RefreshIndicator(
              onRefresh: _load,
              color: _amber,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header tanggal
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                          ? [const Color(0xFF78350F), const Color(0xFF1E293B)]
                          : [const Color(0xFFF59E0B), const Color(0xFFFCD34D)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(18)),
                    child: Row(children: [
                      const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(_fmtDate(_date),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Ringkasan statistik
                  _sectionTitle('Ringkasan', isDark),
                  const SizedBox(height: 10),
                  Row(children: [
                    _statCard('Terlambat', '$tardiness', Icons.alarm_rounded, Colors.orange, isDark),
                    const SizedBox(width: 10),
                    _statCard('Izin Keluar', '$permits', Icons.logout_rounded, Colors.red, isDark),
                    const SizedBox(width: 10),
                    _statCard('Guru Absen', '$absences', Icons.people_alt_rounded, Colors.blue, isDark),
                  ]),
                  const SizedBox(height: 20),

                  // Siswa masih keluar
                  _sectionTitle('Siswa Belum Kembali (${activePermits.length})', isDark),
                  const SizedBox(height: 10),
                  if (activePermits.isEmpty)
                    _emptyCard('Semua siswa sudah kembali.', Icons.check_circle_rounded, Colors.green, isDark)
                  else
                    ...activePermits.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100)),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.red.shade100, borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Text(
                            (p['studentName'] ?? 'S')[0].toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p['studentName'] ?? '',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                              color: isDark ? Colors.white : Colors.grey[900])),
                          Text('${p['className'] ?? ''} · ${p['reason'] ?? ''}',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500])),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Text('Keluar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700))),
                      ]),
                    )),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) => Text(title,
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
      color: isDark ? Colors.grey[300] : Colors.grey[700]));

  Widget _statCard(String label, String value, IconData icon, MaterialColor color, bool isDark) =>
    Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? color.shade900.withAlpha(60) : color.shade50,
              borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: isDark ? color.shade300 : color.shade700)),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[900])),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey[500])),
        ]),
      ),
    );

  Widget _emptyCard(String msg, IconData icon, MaterialColor color, bool isDark) =>
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100)),
      child: Row(children: [
        Icon(icon, color: isDark ? color.shade400 : color.shade600, size: 18),
        const SizedBox(width: 10),
        Text(msg, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[500])),
      ]),
    );
}
