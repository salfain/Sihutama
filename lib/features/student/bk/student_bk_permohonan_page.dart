import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';

const _purple = Color(0xFF7C3AED);

/// Tab Permohonan — daftar + form ajukan konseling
class StudentBkPermohonanPage extends StatefulWidget {
  const StudentBkPermohonanPage({super.key});
  @override
  State<StudentBkPermohonanPage> createState() => _State();
}

class _State extends State<StudentBkPermohonanPage> {
  List _requests = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/student/bk');
      if (mounted) {
        setState(() => _requests = (res.data['requests'] as List?) ?? []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _fmt(dynamic d) {
    if (d == null) return '';
    final dt = DateTime.tryParse(d.toString());
    if (dt == null) return '';
    const m = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    const statusLabel = {
      'PENDING': 'Menunggu', 'APPROVED': 'Disetujui',
      'SCHEDULED': 'Dijadwalkan', 'DONE': 'Selesai', 'REJECTED': 'Ditolak',
    };
    const statusColor = {
      'PENDING': Color(0xFF94A3B8), 'APPROVED': Color(0xFF3B82F6),
      'SCHEDULED': Color(0xFF0EA5E9), 'DONE': Color(0xFF10B981), 'REJECTED': Color(0xFFEF4444),
    };

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text('Permohonan Konseling'),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showForm,
        backgroundColor: _purple,
        elevation: 4,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text('Ajukan Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _purple))
          : RefreshIndicator(
              onRefresh: _load,
              color: _purple,
              child: _requests.isEmpty
                  ? _emptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _requests.length,
                      itemBuilder: (_, i) {
                        final r = _requests[i];
                        final color = statusColor[r['status']] ?? Colors.grey;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100),
                            boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 2))]),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(r['topic'] ?? '',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                                    color: isDark ? Colors.white : Colors.grey[900]))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                                  child: Text(statusLabel[r['status']] ?? '',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color))),
                              ]),
                              if ((r['description'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(r['description'], style: TextStyle(fontSize: 13,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600])),
                              ],
                              if ((r['response'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity, padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.blue.shade900.withAlpha(50) : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12)),
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Icon(Icons.reply_rounded, size: 15, color: isDark ? Colors.blue.shade400 : Colors.blue.shade600),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(r['response'],
                                      style: TextStyle(fontSize: 12,
                                        color: isDark ? Colors.blue.shade200 : Colors.blue.shade800))),
                                  ])),
                              ],
                              const SizedBox(height: 10),
                              Row(children: [
                                Icon(Icons.access_time_rounded, size: 12,
                                  color: isDark ? Colors.grey[500] : Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text('Diajukan ${_fmt(r['createdAt'])}',
                                  style: TextStyle(fontSize: 11,
                                    color: isDark ? Colors.grey[500] : Colors.grey[400])),
                                const Spacer(),
                                // Badge urgensi
                                if ((r['urgency'] ?? '').toString().isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: r['urgency'] == 'TINGGI'
                                          ? Colors.red.withAlpha(20)
                                          : r['urgency'] == 'SEDANG'
                                              ? Colors.orange.withAlpha(20)
                                              : Colors.grey.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6)),
                                    child: Text(r['urgency'] ?? '',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                                        color: r['urgency'] == 'TINGGI' ? Colors.red
                                            : r['urgency'] == 'SEDANG' ? Colors.orange[700] : Colors.grey))),
                              ]),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? _purple.withAlpha(20) : const Color(0xFFF5F3FF),
            shape: BoxShape.circle),
          child: Icon(Icons.inbox_rounded, size: 48, color: isDark ? Colors.grey[600] : Colors.grey[300])),
        const SizedBox(height: 16),
        Text('Belum ada permohonan.',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600])),
        const SizedBox(height: 6),
        Text('Tekan tombol di bawah untuk mengajukan\nkonseling kepada Guru BK.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[500] : Colors.grey[400])),
      ]),
    );
  }

  void _showForm() {
    final topicCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String urgency = 'SEDANG';
    final isDark = AppTheme.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Handle
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(30) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _purple.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add_comment_rounded, color: _purple, size: 18)),
                  const SizedBox(width: 10),
                  Text('Ajukan Konseling',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900])),
                ]),
                const SizedBox(height: 20),
                TextField(controller: topicCtrl, decoration: const InputDecoration(labelText: 'Topik / Keperluan *')),
                const SizedBox(height: 14),
                TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Penjelasan Singkat')),
                const SizedBox(height: 14),
                Text('Tingkat Urgensi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[700])),
                const SizedBox(height: 8),
                Row(
                  children: ['RENDAH', 'SEDANG', 'TINGGI'].map((u) {
                    final sel = urgency == u;
                    final color = u == 'TINGGI' ? Colors.red : u == 'SEDANG' ? Colors.orange : Colors.grey;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setLocal(() => urgency = u),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? color.withAlpha(25) : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? color : (isDark ? Colors.white.withAlpha(15) : Colors.grey.shade200))),
                          child: Center(child: Text(u == 'TINGGI' ? '🔴 Tinggi' : u == 'SEDANG' ? '🟡 Sedang' : '🟢 Rendah',
                            style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                              color: sel ? color : (isDark ? Colors.grey[400] : Colors.grey[600])))))));
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (topicCtrl.text.trim().isEmpty) return;
                      final nav = Navigator.of(ctx);
                      final msg = ScaffoldMessenger.of(context);
                      try {
                        await ApiClient().dio.post('/student/bk/request', data: {
                          'topic': topicCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'urgency': urgency,
                        });
                        nav.pop();
                        msg.showSnackBar(const SnackBar(
                          backgroundColor: Color(0xFF10B981),
                          content: Row(children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Permohonan berhasil dikirim!', style: TextStyle(fontWeight: FontWeight.w600)),
                          ])));
                        _load();
                      } on DioException catch (e) {
                        msg.showSnackBar(SnackBar(content: Text(e.response?.data['error'] ?? 'Gagal')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple, foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Kirim Permohonan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)))),
              ]),
            ),
          );
        },
      ),
    );
  }
}
