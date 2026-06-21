import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';

const counselorColor = Color(0xFF6D28D9);

class CounselorCaseDetailPage extends StatefulWidget {
  final String id;
  const CounselorCaseDetailPage({super.key, required this.id});
  @override
  State<CounselorCaseDetailPage> createState() => _State();
}

class _State extends State<CounselorCaseDetailPage> {
  Map<String, dynamic>? _case;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/counselor/cases/${widget.id}');
      if (mounted) setState(() => _case = res.data as Map<String, dynamic>?);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red));
        context.pop();
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _fmt(dynamic d) {
    if (d == null) return '—';
    final dt = DateTime.tryParse(d.toString());
    if (dt == null) return '—';
    return DateFormat('d MMM yyyy', 'id_ID').format(dt);
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await ApiClient().dio.patch('/counselor/cases/${widget.id}', data: {'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Status diperbarui'), backgroundColor: Colors.green));
        _load();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data['error'] ?? 'Gagal'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _case == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: counselorColor)));
    }

    final isDark = AppTheme.isDark(context);
    final c = _case!;
    const sl = {'OPEN': 'Terbuka', 'IN_PROGRESS': 'Proses', 'RESOLVED': 'Selesai', 'REFERRED': 'Rujukan'};
    const sc = {
      'OPEN': Color(0xFF3B82F6), 'IN_PROGRESS': Color(0xFF0EA5E9),
      'RESOLVED': Color(0xFF10B981), 'REFERRED': Color(0xFF8B5CF6),
    };
    const tl = {'PRIBADI': 'Pribadi', 'SOSIAL': 'Sosial', 'BELAJAR': 'Belajar', 'KARIR': 'Karir'};

    final statusColor = sc[c['status']] ?? Colors.grey;
    final sessions = (c['sessions'] as List?) ?? [];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => context.pop()),
        title: Text('Detail Konseling',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600, fontSize: 16)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white : Colors.black87),
            onSelected: _updateStatus,
            itemBuilder: (_) => sl.entries
              .where((e) => e.key != c['status'])
              .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6D28D9), Color(0xFF9333EA)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: counselorColor.withAlpha(60), blurRadius: 16, offset: const Offset(0, 6))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(c['title'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                if (c['isConfidential'] == true)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.lock_rounded, color: Colors.white, size: 14)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(sl[c['status']] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(20)),
                  child: Text(tl[c['type']] ?? c['type'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.person_outline_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text('${c['studentName'] ?? ''} · ${c['className'] ?? ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(_fmt(c['sessionDate']), style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // Deskripsi
          if ((c['description'] ?? '').toString().isNotEmpty) ...[
            _sectionLabel('Deskripsi', isDark),
            const SizedBox(height: 8),
            _infoCard(isDark, Text(c['description'],
              style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.5))),
            const SizedBox(height: 16),
          ],

          // Catatan
          if ((c['notes'] ?? '').toString().isNotEmpty) ...[
            _sectionLabel('Catatan Konselor', isDark),
            const SizedBox(height: 8),
            _infoCard(isDark, Text(c['notes'],
              style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.5))),
            const SizedBox(height: 16),
          ],

          // Riwayat sesi
          _sectionLabel('Riwayat Sesi (${sessions.length})', isDark),
          const SizedBox(height: 8),
          if (sessions.isEmpty)
            _infoCard(isDark, Text('Belum ada sesi.',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[500] : Colors.grey[400], fontStyle: FontStyle.italic)))
          else
            ...sessions.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(_fmt(s['date']), style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[500])),
                ]),
                if ((s['notes'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(s['notes'], style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.4)),
                ],
              ]),
            )),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) => Text(label,
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
      color: isDark ? Colors.white : const Color(0xFF1E293B)));

  Widget _infoCard(bool isDark, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100)),
    child: child);
}
