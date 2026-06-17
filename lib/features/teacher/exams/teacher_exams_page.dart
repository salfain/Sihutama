import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/exam_utils.dart';

class TeacherExamsPage extends StatefulWidget {
  const TeacherExamsPage({super.key});
  @override
  State<TeacherExamsPage> createState() => _TeacherExamsPageState();
}

class _TeacherExamsPageState extends State<TeacherExamsPage> {
  List<dynamic> _exams = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/teacher/exams');
      setState(() => _exams = res.data as List);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _generateToken(String examId, String title) async {
    String duration = '60';
    String? generatedToken;
    bool generating = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Generate Token', style: TextStyle(fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 16),
              const Text('Durasi token:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: duration,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: '30', child: Text('30 menit')),
                  DropdownMenuItem(value: '60', child: Text('1 jam')),
                  DropdownMenuItem(value: '120', child: Text('2 jam')),
                  DropdownMenuItem(value: '240', child: Text('4 jam')),
                ],
                onChanged: (v) => duration = v ?? '60',
              ),
              if (generatedToken != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(children: [
                    Text('Token berhasil dibuat', style: TextStyle(fontSize: 11, color: Colors.green[700], fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(generatedToken!, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 3, color: Colors.green[800])),
                  ]),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
            if (generatedToken == null)
              ElevatedButton(
                onPressed: generating ? null : () async {
                  setDialog(() => generating = true);
                  try {
                    final res = await ApiClient().dio.post(
                      '/teacher/exams/$examId/token',
                      data: {'durationMinutes': int.parse(duration)},
                    );
                    setDialog(() { generatedToken = res.data['token']; generating = false; });
                  } catch (_) {
                    setDialog(() => generating = false);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Gagal generate token')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: generating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Generate'),
              ),
          ],
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paket Ujian')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _exams.isEmpty
              ? const Center(child: Text('Belum ada ujian'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _exams.length,
                  itemBuilder: (_, i) {
                    final e = _exams[i];
                    final status = e['status'] ?? 'DRAFT';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              _typeBadge(e['examType']),
                              const SizedBox(width: 6),
                              _statusBadge(status),
                              const Spacer(),
                              Text('${e['questionCount'] ?? 0} soal', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            ]),
                            const SizedBox(height: 8),
                            Text(e['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('${e['subject']?['name'] ?? ''} · ${e['attemptCount'] ?? 0} peserta',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            const SizedBox(height: 10),
                            Row(children: [
                              if (status == 'ACTIVE')
                                Expanded(child: OutlinedButton.icon(
                                  onPressed: () => context.push('/teacher/monitoring/${e['id']}'),
                                  icon: const Icon(Icons.monitor, size: 16),
                                  label: const Text('Monitor', style: TextStyle(fontSize: 12)),
                                )),
                              if (status == 'ACTIVE' && canTeacherCreateToken(e['examType'])) ...[
                                const SizedBox(width: 8),
                                Expanded(child: ElevatedButton.icon(
                                  onPressed: () => _generateToken(e['id'], e['title'] ?? ''),
                                  icon: const Icon(Icons.key, size: 16),
                                  label: const Text('Token', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                                )),
                              ],
                              if (status == 'ACTIVE' && !canTeacherCreateToken(e['examType']))
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text('Token oleh Admin', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                ),
                            ]),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
    );
  }

  Widget _typeBadge(String? type) {
    final colors = {'UH': Colors.blue, 'UTS': Colors.purple, 'UAS': Colors.orange, 'US': Colors.red, 'TRYOUT': Colors.teal};
    final c = colors[type] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withAlpha(25), borderRadius: BorderRadius.circular(4), border: Border.all(color: c.withAlpha(80))),
      child: Text(type ?? '—', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }

  Widget _statusBadge(String status) {
    final c = status == 'ACTIVE' ? Colors.green : status == 'DRAFT' ? Colors.amber : Colors.grey;
    final label = status == 'ACTIVE' ? 'Aktif' : status == 'DRAFT' ? 'Draft' : 'Selesai';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withAlpha(25), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c[700])),
    );
  }
}
