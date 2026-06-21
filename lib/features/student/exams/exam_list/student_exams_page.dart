import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';

const studentPrimaryColor = Color(0xFFEA580C);

class StudentExamsPage extends StatefulWidget {
  const StudentExamsPage({super.key});
  @override
  State<StudentExamsPage> createState() => _StudentExamsPageState();
}

class _StudentExamsPageState extends State<StudentExamsPage> {
  List<dynamic> _exams = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/student/exams');
      setState(() => _exams = res.data as List);
    } catch (_) {}
    setState(() => _loading = false);
  }

  List<dynamic> get _filtered => _filter == 'all'
    ? _exams
    : _exams.where((e) => e['examType'] == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        title: Text('Ujian Saya', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: studentPrimaryColor))
        : RefreshIndicator(
            onRefresh: _load,
            color: studentPrimaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter chips
                Container(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      _chip('all', 'Semua'),
                      _chip('UH', 'UH'),
                      _chip('UTS', 'UTS'),
                      _chip('UAS', 'UAS'),
                      _chip('US', 'US'),
                      _chip('TRYOUT', 'Tryout'),
                    ],
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_turned_in_outlined, size: 48, color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Belum ada ujian', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _examCard(_filtered[i]),
                      ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _chip(String val, String label) {
    final isDark = AppTheme.isDark(context);
    final sel = _filter == val;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ChoiceChip(
          label: Text(label, style: TextStyle(
            fontSize: 13, 
            fontWeight: sel ? FontWeight.bold : FontWeight.w500,
            color: sel ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          )),
          selected: sel,
          onSelected: (_) => setState(() => _filter = val),
          selectedColor: studentPrimaryColor,
          backgroundColor: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: sel ? studentPrimaryColor : (isDark ? Colors.transparent : Colors.grey.shade200)),
          ),
          elevation: sel ? 2 : 0,
          showCheckmark: false,
        ),
      ),
    );
  }

  Widget _examCard(dynamic e) {
    final isDark = AppTheme.isDark(context);
    final attempt = e['attempt'];
    final isDone = attempt != null && (attempt['status'] == 'SUBMITTED' || attempt['status'] == 'AUTO_SUBMITTED');
    final now = DateTime.now();
    final start = DateTime.tryParse(e['startAt'] ?? '') ?? now;
    final end = DateTime.tryParse(e['endAt'] ?? '') ?? now;
    final isAvailable = e['status'] == 'ACTIVE' && now.isAfter(start) && now.isBefore(end) && !isDone;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
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
              Expanded(child: Text(e['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.menu_book, size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(e['subject']?['name'] ?? '', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13)),
                const SizedBox(width: 12),
                Icon(Icons.quiz, size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('${e['questionCount'] ?? 0} soal', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer, size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('${e['durationMinutes']} mnt', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),
            if (isAvailable)
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () => context.push('/student/exams/${e['id']}/token'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Masuk Ujian', style: TextStyle(fontWeight: FontWeight.bold)),
              ))
            else if (isDone)
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                onPressed: () => context.go('/student/cbt/results'),
                icon: Icon(Icons.check_circle, size: 18, color: Colors.green.shade600),
                label: Text('Selesai • Nilai: ${attempt['score'] ?? '—'}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.green.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ))
            else
              SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
                  side: isDark ? BorderSide.none : null,
                ),
                child: Text(now.isBefore(start) ? 'Belum Dimulai' : 'Waktu Habis', style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade500, fontWeight: FontWeight.bold)),
              )),
          ],
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
}
