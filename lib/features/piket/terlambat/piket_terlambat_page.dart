import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';

const _amber = Color(0xFFF59E0B);

class PiketTerlambatPage extends StatefulWidget {
  const PiketTerlambatPage({super.key});
  @override
  State<PiketTerlambatPage> createState() => _State();
}

class _State extends State<PiketTerlambatPage> {
  List _records = [];
  List _students = [];
  bool _loading = true;
  DateTime _date = DateTime.now();

  @override
  void initState() { super.initState(); _load(); }

  String _dateStr() {
    return '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/piket/terlambat?date=${_dateStr()}');
      if (mounted) {
        setState(() {
          _records = (res.data['records'] as List?) ?? [];
          _students = (res.data['students'] as List?) ?? [];
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

  String _fmtTime(dynamic d) {
    if (d == null) return '—';
    final dt = DateTime.tryParse(d.toString());
    if (dt == null) return '—';
    return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) { setState(() => _date = picked); _load(); }
  }

  void _showForm() {
    String? studentId;
    final reasonCtrl = TextEditingController();
    final sanctionCtrl = TextEditingController();
    TimeOfDay arrivalTime = TimeOfDay.now();
    final isDark = AppTheme.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(30) : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Catat Terlambat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900])),
              const SizedBox(height: 16),
              // Pilih siswa
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Siswa *'),
                items: _students.map((s) => DropdownMenuItem<String>(
                  value: s['id'] as String,
                  child: Text('${s['name']} — ${s['className']}', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => setLocal(() => studentId = v),
              ),
              const SizedBox(height: 12),
              // Waktu tiba
              GestureDetector(
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: arrivalTime);
                  if (t != null) setLocal(() => arrivalTime = t);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Waktu Tiba: ${arrivalTime.format(ctx)}',
                      style: TextStyle(color: isDark ? Colors.white : Colors.grey[800])),
                  ])),
              ),
              const SizedBox(height: 12),
              TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Alasan (opsional)')),
              const SizedBox(height: 12),
              TextField(controller: sanctionCtrl, decoration: const InputDecoration(labelText: 'Sanksi (opsional)')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (studentId == null) return;
                    final nav = Navigator.of(ctx);
                    final msg = ScaffoldMessenger.of(context);
                    try {
                      await ApiClient().dio.post('/piket/terlambat', data: {
                        'studentId': studentId,
                        'date': _dateStr(),
                        'arrivalTime': '${arrivalTime.hour.toString().padLeft(2,'0')}:${arrivalTime.minute.toString().padLeft(2,'0')}',
                        'reason': reasonCtrl.text.trim(),
                        'sanction': sanctionCtrl.text.trim(),
                      });
                      nav.pop();
                      msg.showSnackBar(const SnackBar(
                        backgroundColor: Color(0xFF10B981),
                        content: Text('Berhasil dicatat', style: TextStyle(fontWeight: FontWeight.w600))));
                      _load();
                    } on DioException catch (e) {
                      msg.showSnackBar(SnackBar(content: Text(e.response?.data['error'] ?? 'Gagal')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)))),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(String id) async {
    try {
      await ApiClient().dio.delete('/piket/terlambat?id=$id');
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
      appBar: AppBar(
        title: const Text('Keterlambatan Siswa'),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, size: 20),
            onPressed: _pickDate,
            tooltip: 'Pilih Tanggal'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showForm,
        backgroundColor: _amber,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Catat Terlambat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _amber))
          : Column(children: [
              // Date indicator
              Container(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('${_date.day}/${_date.month}/${_date.year}  ·  ${_records.length} catatan',
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                ])),
              // List
              Expanded(child: _records.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.alarm_off_rounded, size: 48, color: isDark ? Colors.grey[600] : Colors.grey[300]),
                    const SizedBox(height: 12),
                    const Text('Tidak ada keterlambatan', style: TextStyle(color: Colors.grey)),
                  ]))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _records.length,
                      itemBuilder: (_, i) {
                        final r = _records[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100)),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: Colors.amber.shade100.withAlpha(isDark ? 50 : 255), borderRadius: BorderRadius.circular(10)),
                              child: Center(child: Text(
                                (r['studentName'] ?? 'S')[0].toUpperCase(),
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade700)))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(r['studentName'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                                color: isDark ? Colors.white : Colors.grey[900])),
                              Text(r['className'] ?? '', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500])),
                              if ((r['reason'] ?? '').toString().isNotEmpty)
                                Text('Alasan: ${r['reason']}', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(_fmtTime(r['arrivalTime']),
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade600)),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _delete(r['id']),
                                child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey[400])),
                            ]),
                          ]),
                        );
                      },
                    ),
                  )),
            ]),
    );
  }
}


