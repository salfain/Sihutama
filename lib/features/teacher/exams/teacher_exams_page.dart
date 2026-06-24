import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';

const teacherPrimaryColor = Color(0xFF1D4ED8); // Blue 700

class TeacherExamsPage extends StatefulWidget {
  const TeacherExamsPage({super.key});
  @override
  State<TeacherExamsPage> createState() => _TeacherExamsPageState();
}

class _TeacherExamsPageState extends State<TeacherExamsPage> {
  List<dynamic> _exams = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/teacher/exams');
      if (mounted) setState(() => _exams = (res.data as List?) ?? []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat ujian: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        title: Text('Jadwal Ujian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: teacherPrimaryColor))
        : RefreshIndicator(
            onRefresh: _load,
            color: teacherPrimaryColor,
            child: _exams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 64, color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Belum ada ujian yang dijadwalkan admin.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _exams.length,
                  itemBuilder: (_, i) {
                    final e = _exams[i];
                    final status = e['status'] ?? 'DRAFT';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                        border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.grey.shade100),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              _typeBadge(e['examType']),
                              const SizedBox(width: 8),
                              _statusBadge(status),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade50, borderRadius: BorderRadius.circular(6)),
                                child: Text('${e['questionCount'] ?? 0} soal', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.bold)),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            Text(e['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.menu_book, size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text('${e['subject']?['name'] ?? ''}', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                const SizedBox(width: 12),
                                Icon(Icons.people_outline, size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text('${e['attemptCount'] ?? 0} peserta', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                              ],
                            ),
                            if ((e['classes'] as List?)?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.class_outlined, size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Kelas: ${(e['classes'] as List).join(', ')}',
                                      style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (status == 'ACTIVE')
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push('/teacher/monitoring/${e['id']}'),
                                  icon: const Icon(Icons.monitor_heart, size: 16),
                                  label: const Text('Monitoring', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                                    side: BorderSide(color: isDark ? Colors.blue.shade900 : Colors.blue.shade200),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                alignment: Alignment.center,
                                child: Text('Jadwal dan token dikelola admin', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
    );
  }

  Widget _typeBadge(String? type) {
    final colors = {'UH': Colors.blue, 'UTS': Colors.purple, 'UAS': Colors.orange, 'US': Colors.red, 'TRYOUT': Colors.teal};
    final c = colors[type] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withAlpha(25), borderRadius: BorderRadius.circular(6), border: Border.all(color: c.withAlpha(50))),
      child: Text(type ?? '—', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c)),
    );
  }

  Widget _statusBadge(String status) {
    final c = status == 'ACTIVE' ? Colors.green : status == 'DRAFT' ? Colors.amber : Colors.grey;
    final label = status == 'ACTIVE' ? 'Aktif' : status == 'DRAFT' ? 'Draft' : 'Selesai';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withAlpha(25), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c[700])),
    );
  }
}
