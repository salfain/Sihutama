import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';

const _amber = Color(0xFFF59E0B);

class PiketGuruPage extends StatefulWidget {
  const PiketGuruPage({super.key});
  @override
  State<PiketGuruPage> createState() => _State();
}

class _State extends State<PiketGuruPage> {
  List _records = [];
  List _teachers = [];
  List _classes = [];
  bool _loading = true;
  DateTime _date = DateTime.now();

  @override
  void initState() { super.initState(); _load(); }

  String _dateStr() => '${_date.year}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')}';

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/piket/guru?date=${_dateStr()}');
      if (mounted) {
        setState(() {
          _records = (res.data['records'] as List?) ?? [];
          _teachers = (res.data['teachers'] as List?) ?? [];
          _classes = (res.data['classes'] as List?) ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red));
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

  void _showForm() {
    String? teacherId;
    String? classId;
    String status = 'HADIR';
    final periodCtrl = TextEditingController();
    final substituteCtrl = TextEditingController();
    final isDark = AppTheme.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: StatefulBuilder(
            builder: (ctx, setLocal) => SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(30) : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Catat Kehadiran Guru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[900])),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Guru *'),
                  items: _teachers.map((t) => DropdownMenuItem<String>(
                    value: t['id'] as String, child: Text(t['name'] ?? ''))).toList(),
                  onChanged: (v) => setLocal(() => teacherId = v)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Kelas *'),
                  items: _classes.map((c) => DropdownMenuItem<String>(
                    value: c['id'] as String, child: Text(c['name'] ?? ''))).toList(),
                  onChanged: (v) => setLocal(() => classId = v)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status *'),
                  items: const [
                    DropdownMenuItem(value: 'HADIR', child: Text('Hadir')),
                    DropdownMenuItem(value: 'TIDAK_HADIR', child: Text('Tidak Hadir')),
                    DropdownMenuItem(value: 'DIGANTIKAN', child: Text('Digantikan')),
                    DropdownMenuItem(value: 'TUGAS_LUAR', child: Text('Tugas Luar')),
                  ],
                  onChanged: (v) => setLocal(() => status = v ?? 'HADIR')),
                const SizedBox(height: 12),
                TextField(controller: periodCtrl, decoration: const InputDecoration(labelText: 'Jam ke- (opsional)', hintText: 'mis. Jam 1-2')),
                if (status == 'DIGANTIKAN') ...[
                  const SizedBox(height: 12),
                  TextField(controller: substituteCtrl, decoration: const InputDecoration(labelText: 'Nama Pengganti')),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (teacherId == null || classId == null) return;
                      final nav = Navigator.of(ctx);
                      final msg = ScaffoldMessenger.of(context);
                      try {
                        await ApiClient().dio.post('/piket/guru', data: {
                          'teacherId': teacherId,
                          'classId': classId,
                          'date': _dateStr(),
                          'status': status,
                          'period': periodCtrl.text.trim(),
                          'substitute': substituteCtrl.text.trim(),
                        });
                        nav.pop();
                        msg.showSnackBar(const SnackBar(
                          backgroundColor: Color(0xFF10B981),
                          content: Text('Kehadiran dicatat', style: TextStyle(fontWeight: FontWeight.w600))));
                        _load();
                      } on DioException catch (e) {
                        msg.showSnackBar(SnackBar(content: Text(e.response?.data['error'] ?? 'Gagal')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    icon: const Icon(Icons.people_alt_rounded),
                    label: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)))),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(String id) async {
    try {
      await ApiClient().dio.delete('/piket/guru?id=$id');
      _load();
    } catch (_) {}
  }

  Map<String, dynamic> _statusInfo(String status) {
    return switch (status) {
      'HADIR' => {'label': 'Hadir', 'color': const Color(0xFF10B981)},
      'TIDAK_HADIR' => {'label': 'Tdk Hadir', 'color': const Color(0xFFEF4444)},
      'DIGANTIKAN' => {'label': 'Digantikan', 'color': const Color(0xFFF59E0B)},
      'TUGAS_LUAR' => {'label': 'Tugas Luar', 'color': const Color(0xFF3B82F6)},
      _ => {'label': status, 'color': Colors.grey},
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
      appBar: AppBar(
        title: const Text('Kehadiran Guru'),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today_rounded, size: 20), onPressed: _pickDate),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showForm,
        backgroundColor: _amber,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Catat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _amber))
          : RefreshIndicator(
              onRefresh: _load,
              child: _records.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.people_alt_outlined, size: 48, color: isDark ? Colors.grey[600] : Colors.grey[300]),
                      const SizedBox(height: 12),
                      const Text('Belum ada catatan kehadiran', style: TextStyle(color: Colors.grey)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _records.length,
                      itemBuilder: (_, i) {
                        final r = _records[i];
                        final si = _statusInfo(r['status'] ?? '');
                        final col = si['color'] as Color;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100)),
                          child: Row(children: [
                            Container(
                              width: 4, height: 44,
                              decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(4))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(r['teacherName'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                                color: isDark ? Colors.white : Colors.grey[900])),
                              Text('${r['className'] ?? ''}${(r['period'] ?? '').toString().isNotEmpty ? ' · ${r['period']}' : ''}',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500])),
                              if ((r['substitute'] ?? '').toString().isNotEmpty)
                                Text('Pengganti: ${r['substitute']}', style: const TextStyle(fontSize: 11, color: Colors.orange)),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: col.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                                child: Text(si['label'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: col))),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => _delete(r['id']),
                                child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey[400])),
                            ]),
                          ]),
                        );
                      },
                    ),
            ),
    );
  }
}
