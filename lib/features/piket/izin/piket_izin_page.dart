import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/thermal_receipt.dart';

const _amber = Color(0xFFF59E0B);

class PiketIzinPage extends StatefulWidget {
  const PiketIzinPage({super.key});
  @override
  State<PiketIzinPage> createState() => _State();
}

class _State extends State<PiketIzinPage> {
  List _records = [];
  List _students = [];
  bool _loading = true;
  String? _returningId;
  DateTime _date = DateTime.now();

  @override
  void initState() { super.initState(); _load(); }

  String _dateStr() => '${_date.year}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')}';

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/piket/izin?date=${_dateStr()}');
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
      context: context, initialDate: _date,
      firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null) { setState(() => _date = picked); _load(); }
  }

  void _showForm() {
    String? studentId;
    final reasonCtrl = TextEditingController();
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
            builder: (ctx, setLocal) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(30) : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Catat Izin Keluar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900])),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Siswa *'),
                items: _students.map((s) => DropdownMenuItem<String>(
                  value: s['id'] as String,
                  child: Text('${s['name']} — ${s['className']}', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => setLocal(() => studentId = v),
              ),
              const SizedBox(height: 12),
              TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Alasan *')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (studentId == null || reasonCtrl.text.isEmpty) return;
                    final nav = Navigator.of(ctx);
                    final msg = ScaffoldMessenger.of(context);
                    try {
                      await ApiClient().dio.post('/piket/izin', data: {
                        'studentId': studentId,
                        'reason': reasonCtrl.text.trim(),
                      });
                      nav.pop();
                      if (!mounted) return;
                      msg.showSnackBar(const SnackBar(
                        backgroundColor: Color(0xFF10B981),
                        content: Text('Izin keluar dicatat', style: TextStyle(fontWeight: FontWeight.w600))));
                      _load();
                    } on DioException catch (e) {
                      msg.showSnackBar(SnackBar(content: Text(e.response?.data['error'] ?? 'Gagal')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Catat Keluar', style: TextStyle(fontWeight: FontWeight.bold)))),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _printReceipt(Map<String, dynamic> r) async {
    try {
      // Ambil info sekolah dari API (cached di server)
      final schoolRes = await ApiClient().dio.get('/auth/me');
      const schoolName = 'SMK Hutama Pondok Gede';
      final piketName = schoolRes.data['name'] ?? 'Guru Piket';

      final exitRaw = r['exitTime'];
      final exitTime = exitRaw != null ? DateTime.tryParse(exitRaw.toString()) : null;
      final dateRaw  = r['date'] ?? r['exitTime'];
      final date     = dateRaw != null ? (DateTime.tryParse(dateRaw.toString()) ?? DateTime.now()) : DateTime.now();

      final idStr = (r['id'] as String? ?? '').padLeft(4, '0');
      final nomorSurat = 'IZIN-${date.year}${date.month.toString().padLeft(2,'0')}${date.day.toString().padLeft(2,'0')}-${idStr.substring(idStr.length > 4 ? idStr.length - 4 : 0).toUpperCase()}';

      await printIzinKeluar(
        studentName: r['studentName'] ?? '',
        className:   r['className']   ?? '—',
        major:       r['major']       ?? '—',
        reason:      r['reason']      ?? '—',
        date:        date,
        exitTime:    exitTime,
        piketName:   piketName,
        schoolName:  schoolName,
        schoolAddress: null,
        nomorSurat:  nomorSurat,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat struk: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _markReturned(dynamic idValue) async {
    final id = idValue?.toString();
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ID izin tidak valid'),
        backgroundColor: Colors.red));
      return;
    }

    setState(() => _returningId = id);
    try {
      await ApiClient().dio.post(
        '/piket/izin/${Uri.encodeComponent(id)}/kembali',
        data: const {},
      );
      if (!mounted) return;
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Color(0xFF10B981),
        content: Text('Siswa sudah kembali', style: TextStyle(fontWeight: FontWeight.w600))));
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data is Map
          ? (e.response?.data['error'] ?? 'Gagal menandai siswa kembali')
          : 'Gagal menandai siswa kembali';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message.toString()),
        backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menandai siswa kembali: $e'),
        backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _returningId = null);
    }
  }

  Future<void> _delete(String id) async {
    try {
      await ApiClient().dio.delete('/piket/izin?id=$id');
      _load();
    } catch (_) {}
  }

  Map<String, String> _statusStyle(String status) {
    return switch (status) {
      'KELUAR' => {'label': 'Keluar', 'color': '0xFFEF4444'},
      'SUDAH_KEMBALI' => {'label': 'Kembali', 'color': '0xFF10B981'},
      _ => {'label': 'Tdk Kembali', 'color': '0xFF94A3B8'},
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final active = _records.where((r) => r['status'] == 'KELUAR').toList();
    final done = _records.where((r) => r['status'] != 'KELUAR').toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
      appBar: AppBar(
        title: const Text('Izin Keluar / Masuk'),
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
        label: const Text('Catat Izin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _amber))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date bar
                  Text('${_date.day}/${_date.month}/${_date.year}  ·  ${_records.length} catatan',
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 14),

                  // Sedang keluar
                  if (active.isNotEmpty) ...[
                    Row(children: [
                      const Icon(Icons.logout_rounded, size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      Text('Sedang Keluar (${active.length})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                    ]),
                    const SizedBox(height: 8),
                    ...active.map((r) {
                      final id = r['id']?.toString() ?? '';
                      final isReturning = _returningId == id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade200.withAlpha(isDark ? 60 : 255))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(r['studentName'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                              color: isDark ? Colors.white : Colors.grey[900])),
                            Text('${r['className'] ?? ''} · ${r['reason'] ?? ''}',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500])),
                          ])),
                          Text('Keluar ${_fmtTime(r['exitTime'])}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: ElevatedButton.icon(
                            onPressed: isReturning ? null : () => _markReturned(id),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), minimumSize: const Size(0, 36)),
                            icon: isReturning
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check_circle_rounded, size: 16),
                            label: Text(isReturning ? 'Memproses...' : 'Tandai Kembali',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _printReceipt(r),
                            icon: const Icon(Icons.receipt_long_rounded, size: 18, color: _amber),
                            tooltip: 'Cetak Struk',
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
                          IconButton(
                            onPressed: () => _delete(r['id']),
                            icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey[400]),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                          ]),
                        ]),
                      );
                    }),
                    const SizedBox(height: 10),
                  ],

                  // Riwayat
                  if (done.isNotEmpty) ...[
                    const Text('Riwayat Hari Ini',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...done.map((r) {
                      final st = _statusStyle(r['status'] ?? '');
                      final col = Color(int.parse(st['color']!));
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100)),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(r['studentName'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                              color: isDark ? Colors.white : Colors.grey[900])),
                            Text('${r['className'] ?? ''} · ${r['reason'] ?? ''}',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500])),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: col.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                            child: Text(st['label']!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: col))),
                        ]),
                      );
                    }),
                  ],

                  if (_records.isEmpty)
                    Center(child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(children: [
                        Icon(Icons.logout_rounded, size: 48, color: isDark ? Colors.grey[600] : Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text('Tidak ada catatan izin', style: TextStyle(color: Colors.grey)),
                      ]),
                    )),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}
