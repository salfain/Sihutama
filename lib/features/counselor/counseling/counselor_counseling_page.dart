import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'package:intl/intl.dart';

const counselorColor = Color(0xFF6D28D9);
const _typeLabel = {'PRIBADI': 'Pribadi', 'SOSIAL': 'Sosial', 'BELAJAR': 'Belajar', 'KARIR': 'Karir'};
const _reqStatusLabel = {'PENDING': 'Menunggu', 'APPROVED': 'Disetujui', 'SCHEDULED': 'Dijadwalkan', 'DONE': 'Selesai', 'REJECTED': 'Ditolak'};
const _caseStatusLabel = {'OPEN': 'Terbuka', 'IN_PROGRESS': 'Proses', 'RESOLVED': 'Selesai', 'REFERRED': 'Rujukan'};

class CounselorCounselingPage extends StatefulWidget {
  const CounselorCounselingPage({super.key});
  @override
  State<CounselorCounselingPage> createState() => _CounselorCounselingPageState();
}

class _CounselorCounselingPageState extends State<CounselorCounselingPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List _requests = [];
  List _cases = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Future.wait([
        ApiClient().dio.get('/counselor/requests'),
        ApiClient().dio.get('/counselor/cases'),
      ]);
      if (mounted) {
        setState(() {
          _requests = res[0].data as List;
          _cases = res[1].data as List;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _fmt(dynamic d) {
    if (d == null) return '';
    final dt = DateTime.tryParse(d.toString());
    if (dt == null) return '';
    return DateFormat('d MMM yyyy', 'id_ID').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Konseling', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), letterSpacing: -0.5)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                  child: TabBar(
                    controller: _tabs,
                    indicator: BoxDecoration(color: counselorColor, borderRadius: BorderRadius.circular(12)),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Permohonan'),
                      Tab(text: 'Sesi Berjalan'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: counselorColor))
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _buildRequests(),
                      _buildCases(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequests() {
    if (_requests.isEmpty) return _empty('Belum ada permohonan masuk.', Icons.inbox_rounded);
    return RefreshIndicator(
      onRefresh: _load,
      color: counselorColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _requests.length,
        itemBuilder: (context, i) {
          final r = _requests[i];
          final statusColor = r['status'] == 'PENDING' ? Colors.orange : (r['status'] == 'APPROVED' || r['status'] == 'DONE' ? Colors.green : Colors.blue);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.mark_email_unread_rounded, color: counselorColor, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(r['topic'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(20)),
                        child: Text(_reqStatusLabel[r['status']] ?? r['status'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('${r['studentName']} · ${r['className']}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('Urgensi: ${r['urgency']}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    ],
                  ),
                  if ((r['description'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(r['description'], style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
                  ],
                  if ((r['response'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tanggapan Anda:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(r['response'], style: const TextStyle(fontSize: 13, color: counselorColor, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _respond(r),
                      icon: const Icon(Icons.reply_rounded, size: 16),
                      label: const Text('Tanggapi'),
                      style: OutlinedButton.styleFrom(foregroundColor: counselorColor, side: const BorderSide(color: counselorColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCases() {
    if (_cases.isEmpty) return _empty('Belum ada sesi konseling berjalan.', Icons.forum_rounded);
    return RefreshIndicator(
      onRefresh: _load,
      color: counselorColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _cases.length,
        itemBuilder: (context, i) {
          final c = _cases[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.support_agent_rounded, color: counselorColor, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(child: Text(c['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)))),
                            if (c['isConfidential'] == true) ...[const SizedBox(width: 6), const Icon(Icons.lock_rounded, size: 14, color: Colors.grey)],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                        child: Text(_caseStatusLabel[c['status']] ?? c['status'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('${c['studentName']} · ${c['className']}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.category_rounded, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(_typeLabel[c['type']] ?? c['type'], style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                      const SizedBox(width: 16),
                      Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(_fmt(c['sessionDate']), style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _empty(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }

  void _respond(dynamic r) {
    final responseCtrl = TextEditingController(text: r['response'] ?? '');
    String status = r['status'] ?? 'PENDING';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.purple.shade50, shape: BoxShape.circle), child: const Icon(Icons.reply_rounded, color: counselorColor)),
                      const SizedBox(width: 16),
                      const Text('Tanggapi Permohonan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: _reqStatusLabel.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (v) => setLocal(() => status = v ?? 'PENDING'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: responseCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Tanggapan untuk siswa',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await ApiClient().dio.post('/counselor/requests/${r['id']}', data: {
                            'status': status, 'response': responseCtrl.text.trim(),
                          });
                          nav.pop();
                          messenger.showSnackBar(const SnackBar(content: Text('Tanggapan tersimpan'), backgroundColor: Colors.green));
                          _load();
                        } on DioException catch (e) {
                          messenger.showSnackBar(SnackBar(content: Text(e.response?.data['error'] ?? 'Gagal menyimpan'), backgroundColor: Colors.red));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: counselorColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                      child: const Text('Simpan Tanggapan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
