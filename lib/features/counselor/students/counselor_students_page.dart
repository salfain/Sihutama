import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';

const counselorColor = Color(0xFF6D28D9);

class CounselorStudentsPage extends StatefulWidget {
  const CounselorStudentsPage({super.key});
  @override
  State<CounselorStudentsPage> createState() => _CounselorStudentsPageState();
}

class _CounselorStudentsPageState extends State<CounselorStudentsPage> {
  List _students = [];
  List _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = _students.where((s) {
          return (s['name'] ?? '').toLowerCase().contains(q) ||
                 (s['className'] ?? '').toLowerCase().contains(q) ||
                 (s['nis'] ?? '').toLowerCase().contains(q);
        }).toList();
      });
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/counselor/students/book');
      if (mounted) {
        setState(() {
          _students = res.data as List;
          _filtered = _students;
        });
      }
    } catch (e) {
      debugPrint('Error fetch students: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Buku Siswa', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B), letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Pusat data rekam jejak konseling, pelanggaran, dan prestasi.', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B))),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchCtrl,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, NIS, atau kelas...',
                    hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: counselorColor))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.menu_book_rounded, size: 48, color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Siswa tidak ditemukan.', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 14)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: counselorColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final s = _filtered[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
                                border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.transparent),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => context.go('/counselor/students/${s['id']}'),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: isDark ? counselorColor.withAlpha(50) : counselorColor.withAlpha(20),
                                          child: Text(
                                            (s['name'] ?? 'S')[0].toUpperCase(),
                                            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.purple.shade300 : counselorColor, fontSize: 18),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(s['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                                              const SizedBox(height: 4),
                                              Text('${s['className']} · NIS: ${s['nis']}', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.w500)),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  if ((s['violationPoints'] ?? 0) > 0)
                                                    _badge('${s['violationPoints']}', Colors.red, Icons.gpp_maybe_rounded),
                                                  if ((s['achievementPoints'] ?? 0) > 0)
                                                    _badge('+${s['achievementPoints']}', Colors.green, Icons.emoji_events_rounded),
                                                  if ((s['cases'] ?? 0) > 0)
                                                    _badge('${s['cases']}', Colors.blue, Icons.chat_bubble_rounded),
                                                  if ((s['violationPoints'] ?? 0) == 0 && (s['achievementPoints'] ?? 0) == 0 && (s['cases'] ?? 0) == 0)
                                                    Text('Belum ada rekam jejak', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, fontStyle: FontStyle.italic)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right_rounded, color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, MaterialColor color, IconData icon) {
    final isDark = AppTheme.isDark(context);
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: isDark ? color.shade900.withAlpha(100) : color[50], borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 10, color: isDark ? color.shade300 : color[700]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? color.shade300 : color[700])),
        ],
      ),
    );
  }
}
