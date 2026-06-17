import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

const counselorColor = Color(0xFF6D28D9); // Lebih premium/gelap dari sebelumnya

class CounselorDashboardPage extends StatefulWidget {
  const CounselorDashboardPage({super.key});
  @override
  State<CounselorDashboardPage> createState() => _CounselorDashboardPageState();
}

class _CounselorDashboardPageState extends State<CounselorDashboardPage> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _user;
  List _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Future.wait([
        ApiClient().dio.get('/counselor/dashboard'),
        ApiClient().dio.get('/auth/me'),
        ApiClient().dio.get('/counselor/students'),
      ]);
      if (mounted) {
        setState(() {
          _data = res[0].data;
          _user = res[1].data;
          _students = res[2].data as List;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    const typeLabel = {'PRIBADI': 'Pribadi', 'SOSIAL': 'Sosial', 'BELAJAR': 'Belajar', 'KARIR': 'Karir'};
    final recent = (_data?['recentCases'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: counselorColor))
          : RefreshIndicator(
              onRefresh: _load,
              color: counselorColor,
              child: ListView(
                padding: const EdgeInsets.only(top: 20, bottom: 30),
                children: [
                  // Greeting Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6D28D9), Color(0xFF9333EA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF6D28D9).withAlpha(60), blurRadius: 24, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Selamat datang,', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                const SizedBox(height: 6),
                                Text(_user?['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                                const SizedBox(height: 4),
                                const Text('Guru Bimbingan Konseling', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withAlpha(50), shape: BoxShape.circle),
                            child: const Icon(Icons.person, color: Colors.white, size: 32),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _actionBtn(context, 'Buku Siswa', Icons.menu_book_rounded, Colors.blue, () => context.go('/counselor/students')),
                        _actionBtn(context, '+ Pelanggaran', Icons.gpp_maybe_rounded, Colors.red, _showAddViolation),
                        _actionBtn(context, '+ Prestasi', Icons.emoji_events_rounded, Colors.green, _showAddAchievement),
                        _actionBtn(context, 'Angket', Icons.poll_rounded, Colors.orange, () => context.go('/counselor/surveys')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Stats Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ringkasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B), letterSpacing: -0.5)),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.5,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _stat('Kasus Aktif', _data?['openCases'] ?? 0, Icons.folder_open_rounded, Colors.blue),
                            _stat('Permohonan', _data?['pendingRequests'] ?? 0, Icons.inbox_rounded, Colors.pink),
                            _stat('Pelanggaran', _data?['totalViolations'] ?? 0, Icons.gpp_maybe_rounded, Colors.red),
                            _stat('Prestasi', _data?['totalAchievements'] ?? 0, Icons.emoji_events_rounded, Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Recent Counseling
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history_rounded, size: 22, color: counselorColor),
                            SizedBox(width: 8),
                            Text('Sesi Konseling Terbaru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B), letterSpacing: -0.5)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (recent.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                            child: const Center(child: Text('Belum ada sesi konseling.', style: TextStyle(color: Colors.grey, fontSize: 14))),
                          )
                        else
                          ...recent.map((c) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => context.go('/counselor/counseling'),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(12)),
                                        child: const Icon(Icons.chat_bubble_outline_rounded, color: counselorColor, size: 20),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(c['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B))),
                                            const SizedBox(height: 4),
                                            Text('${c['studentName']} · ${c['className']}', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                                        child: Text(typeLabel[c['type']] ?? c['type'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _actionBtn(BuildContext context, String label, IconData icon, MaterialColor color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withAlpha(20), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: color[600], size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _stat(String label, dynamic value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color[50], borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color[600], size: 20),
          ),
          const Spacer(),
          Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showAddViolation() {
    _showFormSheet(
      title: 'Catat Pelanggaran',
      icon: Icons.gpp_maybe_rounded,
      color: Colors.red,
      fields: ['Deskripsi', 'Poin', 'Sanksi'],
      onSubmit: (studentId, data) async {
        await ApiClient().dio.post('/counselor/violations', data: {
          'studentId': studentId,
          'description': data[0],
          'points': int.tryParse(data[1]) ?? 0,
          'sanction': data[2],
        });
      },
    );
  }

  void _showAddAchievement() {
    _showFormSheet(
      title: 'Catat Prestasi',
      icon: Icons.emoji_events_rounded,
      color: Colors.green,
      fields: ['Judul Prestasi', 'Poin', 'Tingkat'],
      onSubmit: (studentId, data) async {
        await ApiClient().dio.post('/counselor/achievements', data: {
          'studentId': studentId,
          'title': data[0],
          'points': int.tryParse(data[1]) ?? 0,
          'level': data[2],
        });
      },
    );
  }

  void _showFormSheet({
    required String title,
    required IconData icon,
    required MaterialColor color,
    required List<String> fields,
    required Future<void> Function(String studentId, List<String> data) onSubmit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FormSheet(
        title: title, icon: icon, color: color, fields: fields, students: _students,
        onSubmit: (sid, data) async {
          Navigator.pop(ctx);
          final messenger = ScaffoldMessenger.of(context);
          try {
            await onSubmit(sid, data);
            messenger.showSnackBar(SnackBar(content: Text('$title berhasil dicatat!'), backgroundColor: Colors.green));
            _load(); // Reload dashboard stats
          } on DioException catch (e) {
            messenger.showSnackBar(SnackBar(content: Text(e.response?.data['error'] ?? 'Gagal menyimpan'), backgroundColor: Colors.red));
          }
        },
      ),
    );
  }
}

class _FormSheet extends StatefulWidget {
  final String title;
  final IconData icon;
  final MaterialColor color;
  final List<String> fields;
  final List students;
  final void Function(String studentId, List<String> data) onSubmit;

  const _FormSheet({required this.title, required this.icon, required this.color, required this.fields, required this.students, required this.onSubmit});

  @override
  State<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<_FormSheet> {
  String? _selectedStudentId;
  late List<TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(widget.fields.length, (_) => TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: widget.color[50], shape: BoxShape.circle), child: Icon(widget.icon, color: widget.color[600])),
                  const SizedBox(width: 16),
                  Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedStudentId,
                decoration: InputDecoration(
                  labelText: 'Siswa *',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                isExpanded: true,
                items: widget.students.map((s) => DropdownMenuItem(value: s['id'].toString(), child: Text('${s['name']} — ${s['className']}', overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _selectedStudentId = v),
              ),
              const SizedBox(height: 16),
              ...List.generate(widget.fields.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: _ctrls[i],
                  keyboardType: widget.fields[i].toLowerCase() == 'poin' ? TextInputType.number : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: widget.fields[i] + (i == 0 ? ' *' : ''),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedStudentId == null || _ctrls[0].text.trim().isEmpty) return;
                    widget.onSubmit(_selectedStudentId!, _ctrls.map((c) => c.text.trim()).toList());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
