import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class MonitoringPage extends StatefulWidget {
  final String examId;
  const MonitoringPage({super.key, required this.examId});
  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/teacher/monitoring/${widget.examId}');
      setState(() => _data = res.data);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_data?['exam']?['title'] ?? 'Monitoring')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Summary
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _stat('Total', '${(_data?['participants'] as List?)?.length ?? 0}', Colors.grey),
                      _stat('Mengerjakan', '${(_data?['participants'] as List?)?.where((p) => p['status'] == 'IN_PROGRESS').length ?? 0}', Colors.green),
                      _stat('Selesai', '${(_data?['participants'] as List?)?.where((p) => p['status'] == 'SUBMITTED' || p['status'] == 'AUTO_SUBMITTED').length ?? 0}', Colors.blue),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                ...(_data?['participants'] as List? ?? []).map((p) {
                  final status = p['status'] ?? 'NOT_STARTED';
                  final progress = (p['answeredCount'] ?? 0) / ((_data?['exam']?['totalQuestions'] ?? 1) as int);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['studentName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(p['className'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              ],
                            )),
                            _statusChip(status),
                          ]),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            backgroundColor: Colors.grey[200],
                            color: status == 'IN_PROGRESS' ? Colors.green : Colors.blue,
                          ),
                          const SizedBox(height: 4),
                          Text('${p['answeredCount']}/${_data?['exam']?['totalQuestions']} soal',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
    );
  }

  Widget _stat(String label, String val, Color c) {
    return Column(children: [
      Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c)),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ]);
  }

  Widget _statusChip(String status) {
    final c = status == 'IN_PROGRESS' ? Colors.green : (status == 'SUBMITTED' || status == 'AUTO_SUBMITTED') ? Colors.blue : Colors.grey;
    final l = status == 'IN_PROGRESS' ? 'Mengerjakan' : (status == 'SUBMITTED' || status == 'AUTO_SUBMITTED') ? 'Selesai' : 'Belum';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withAlpha(25), borderRadius: BorderRadius.circular(6)),
      child: Text(l, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c)),
    );
  }
}
