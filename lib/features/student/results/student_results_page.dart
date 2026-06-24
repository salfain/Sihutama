import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../shared/widgets/answer_review_sheet.dart';
import '../../../app/theme.dart';

const studentPrimaryColor = Color(0xFFEA580C);

class StudentResultsPage extends StatefulWidget {
  const StudentResultsPage({super.key});
  @override
  State<StudentResultsPage> createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends State<StudentResultsPage> {
  List<dynamic> _results = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/student/results');
      if (mounted) setState(() => _results = (res.data as List?) ?? []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat nilai: $e'), backgroundColor: Colors.red));
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
        title: Text('Riwayat Nilai', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: studentPrimaryColor))
        : RefreshIndicator(
            onRefresh: _load,
            color: studentPrimaryColor,
            child: _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 64, color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Belum ada nilai', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final r = _results[i];
                    final score = r['score'];
                    final passed = r['exam']?['passingScore'] != null && (score ?? 0) >= r['exam']['passingScore'];
                    final canReview = r['exam']?['showResult'] == true;
                    
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
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r['exam']?['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.menu_book, size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text('${r['exam']?['subject']?['code'] ?? ''}', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.check_circle_outline, size: 14, color: isDark ? Colors.green.shade400 : Colors.green.shade500),
                                          const SizedBox(width: 4),
                                          Text('Benar: ${r['correct']}', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                          const SizedBox(width: 12),
                                          Icon(Icons.cancel_outlined, size: 14, color: isDark ? Colors.red.shade400 : Colors.red.shade400),
                                          const SizedBox(width: 4),
                                          Text('Salah: ${r['wrong']}', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${score ?? '—'}',
                                      style: TextStyle(
                                        fontSize: 28, 
                                        fontWeight: FontWeight.bold, 
                                        color: (score ?? 0) >= 75 ? Colors.green.shade700 : Colors.red.shade600
                                      )
                                    ),
                                    if (r['exam']?['passingScore'] != null)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: passed ? (isDark ? Colors.green.shade900.withAlpha(100) : Colors.green.shade50) : (isDark ? Colors.red.shade900.withAlpha(100) : Colors.red.shade50),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(passed ? 'Lulus' : 'Tidak Lulus',
                                          style: TextStyle(fontSize: 11, color: passed ? (isDark ? Colors.green.shade400 : Colors.green.shade700) : (isDark ? Colors.red.shade400 : Colors.red.shade700), fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            if (canReview) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton.icon(
                                  onPressed: () => AnswerReviewSheet.show(context, r['id']),
                                  icon: const Icon(Icons.manage_search, size: 20),
                                  label: const Text('Lihat Detail Jawaban', style: TextStyle(fontWeight: FontWeight.w600)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: studentPrimaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
    );
  }
}
