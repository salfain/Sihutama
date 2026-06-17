import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Ujian Saya')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: Column(
              children: [
                // Filter chips
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    ? Center(child: Text('Tidak ada ujian', style: TextStyle(color: Colors.grey[500])))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
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
    final sel = _filter == val;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w500)),
        selected: sel,
        onSelected: (_) => setState(() => _filter = val),
        selectedColor: const Color(0xFFDDEAFF),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _examCard(dynamic e) {
    final attempt = e['attempt'];
    final isDone = attempt != null && (attempt['status'] == 'SUBMITTED' || attempt['status'] == 'AUTO_SUBMITTED');
    final now = DateTime.now();
    final start = DateTime.tryParse(e['startAt'] ?? '') ?? now;
    final end = DateTime.tryParse(e['endAt'] ?? '') ?? now;
    final isAvailable = e['status'] == 'ACTIVE' && now.isAfter(start) && now.isBefore(end) && !isDone;

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
              Expanded(child: Text(e['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 6),
            Text('${e['subject']?['name'] ?? ''} · ${e['questionCount'] ?? 0} soal · ${e['durationMinutes']} mnt', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 10),
            if (isAvailable)
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () => context.push('/student/exams/${e['id']}/token'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
                child: const Text('Masuk Ujian'),
              ))
            else if (isDone)
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                onPressed: () => context.push('/student/results'),
                icon: const Icon(Icons.check_circle, size: 18),
                label: Text('Nilai: ${attempt['score'] ?? '—'}'),
              ))
            else
              SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: null,
                child: Text(now.isBefore(start) ? 'Belum Dimulai' : 'Tidak Tersedia'),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withAlpha(25), borderRadius: BorderRadius.circular(4), border: Border.all(color: c.withAlpha(80))),
      child: Text(type ?? '—', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }
}
