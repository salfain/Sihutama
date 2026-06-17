import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/violation_queue.dart';

class TakeExamPage extends StatefulWidget {
  final String examId;
  const TakeExamPage({super.key, required this.examId});
  @override
  State<TakeExamPage> createState() => _TakeExamPageState();
}

class _TakeExamPageState extends State<TakeExamPage> with WidgetsBindingObserver {
  List<dynamic> _questions = [];
  Map<String, dynamic> _answers = {};
  int _current = 0;
  int _timeLeft = 0;
  Timer? _timer;
  Timer? _heartbeatTimer;
  String _title = '';
  bool _loading = true;
  bool _submitting = false;
  late PageController _pageController;

  // ─── Anti-cheat state ───────────────────────────────────────────────────
  /// True saat app sedang di-background dan laporan pelanggaran belum selesai.
  bool _exitDetected = false;
  /// True saat sedang memproses laporan pelanggaran (blokir UI).
  bool _reportingViolation = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _current);
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _heartbeatTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ─── Lifecycle observer ─────────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_loading || _submitting) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Siswa keluar/minimize — tandai sebagai pelanggaran, simpan lokal
      if (!_exitDetected) {
        _exitDetected = true;
        // Simpan ke antrian offline (tetap terhitung meski tidak ada internet)
        ViolationQueue.push(widget.examId, 'Keluar aplikasi');
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_exitDetected) {
        // Blokir dan flush antrian pelanggaran ke server
        _flushViolations();
      }
    }
  }

  // ─── Flush offline violation queue saat koneksi tersedia ────────────────
  Future<void> _flushViolations() async {
    if (!_exitDetected) return;
    setState(() => _reportingViolation = true);

    final pending = await ViolationQueue.pendingFor(widget.examId);
    if (pending.isEmpty) {
      setState(() {
        _exitDetected = false;
        _reportingViolation = false;
      });
      return;
    }

    // Kirim ke server: jumlah pelanggaran sekaligus + alasan dari event terakhir
    final reason = pending.last['reason'] as String? ?? 'Keluar aplikasi';
    final count = pending.length;

    bool sent = false;
    for (int attempt = 0; attempt < 5; attempt++) {
      try {
        final res = await ApiClient().dio.post(
          '/student/exams/${widget.examId}/violation',
          data: {'reason': reason, 'offlineCount': count},
        );
        final d = res.data;
        // Berhasil — bersihkan antrian
        await ViolationQueue.clearFor(widget.examId);
        sent = true;

        if (!mounted) return;
        if (d['locked'] == true) {
          _timer?.cancel();
          _heartbeatTimer?.cancel();
          final r = Uri.encodeComponent(d['lockReason'] ?? reason);
          context.replace('/student/exams/${widget.examId}/locked?reason=$r');
          return;
        }
        // Tampilkan peringatan
        final v = d['violationCount'] ?? 0;
        final t = d['threshold'] ?? 3;
        final offlineNote = count > 1 ? ' ($count kali saat offline)' : '';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 5),
          content: Text(
            'Peringatan$offlineNote: terdeteksi keluar aplikasi ($v/$t). Setelah $t kali, ujian dikunci.',
            style: const TextStyle(color: Colors.white),
          ),
        ));
        break;
      } catch (_) {
        // Belum ada koneksi — tunggu 2 detik dan coba lagi
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (!sent) {
      // Setelah 5 kali gagal, tetap biarkan siswa lanjut tapi antrian masih ada
      // (akan dikirim saat koneksi pulih berikutnya)
    }

    if (mounted) {
      setState(() {
        _exitDetected = false;
        _reportingViolation = false;
      });
    }
  }

  // ─── Heartbeat ke server setiap 30 detik ────────────────────────────────
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_submitting) return;
      try {
        final res = await ApiClient().dio.post(
          '/student/exams/${widget.examId}/heartbeat',
        );
        final d = res.data;
        if (!mounted) return;
        if (d['locked'] == true) {
          _timer?.cancel();
          _heartbeatTimer?.cancel();
          final r = Uri.encodeComponent(d['lockReason'] ?? 'Akses dikunci');
          context.replace('/student/exams/${widget.examId}/locked?reason=$r');
        } else if (d['finished'] == true) {
          context.go('/student/exams/${widget.examId}/finish');
        }
      } catch (_) {
        // Gagal heartbeat — tidak mengunci, hanya dicatat tidak online
      }
    });
  }

  // ─── Load soal ───────────────────────────────────────────────────────────
  Future<void> _load() async {
    try {
      // Flush pelanggaran yang mungkin tersimpan dari sesi sebelumnya
      final pendingCount = await ViolationQueue.countFor(widget.examId);
      if (pendingCount > 0) {
        await _flushViolations();
        // Kalau setelah flush ternyata ujian terkunci, stop di sini
        if (!mounted) return;
      }

      // Cek status terkini
      final st = await ApiClient().dio.get(
        '/student/exams/${widget.examId}/status?_t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final sd = st.data;
      if (!mounted) return;
      if (sd['status'] == 'SUBMITTED' || sd['status'] == 'AUTO_SUBMITTED') {
        context.go('/student/exams/${widget.examId}/finish');
        return;
      }
      if (sd['isLocked'] == true) {
        final r = Uri.encodeComponent(sd['lockReason'] ?? 'Akses dikunci');
        context.replace('/student/exams/${widget.examId}/locked?reason=$r');
        return;
      }

      final res = await ApiClient().dio.get('/student/exams/${widget.examId}/questions');
      final d = res.data;
      setState(() {
        _questions = d['questions'] as List;
        _answers = Map<String, dynamic>.from(d['answers'] ?? {});
        _title = d['title'] ?? '';
        final expires = DateTime.parse(d['expiresAt']);
        _timeLeft = expires.difference(DateTime.now()).inSeconds.clamp(0, 999999);
        _loading = false;
      });
      _startTimer();
      _startHeartbeat();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft <= 0) {
        _timer?.cancel();
        _submit(auto: true);
        return;
      }
      setState(() => _timeLeft--);
    });
  }

  String get _formattedTime {
    final m = _timeLeft ~/ 60;
    final s = _timeLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _saveAnswer(String qId, {String? optionId, String? text, bool? doubtful}) async {
    final cur = _answers[qId] ?? {};
    _answers[qId] = {
      ...cur,
      if (optionId != null) 'selectedOptionId': optionId,
      if (text != null) 'answerText': text,
      if (doubtful != null) 'isDoubtful': doubtful,
    };
    setState(() {});
    try {
      await ApiClient().dio.post('/student/answers/save', data: {
        'examId': widget.examId,
        'questionId': qId,
        'selectedOptionId': _answers[qId]?['selectedOptionId'],
        'answerText': _answers[qId]?['answerText'],
        'isDoubtful': _answers[qId]?['isDoubtful'] ?? false,
      });
    } catch (_) {}
  }

  Future<void> _submit({bool auto = false}) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();
    _heartbeatTimer?.cancel();
    try {
      await ApiClient().dio.post(
        '/student/exams/${widget.examId}/submit',
        data: {'auto': auto},
      );
    } catch (_) {}
    if (mounted) context.go('/student/exams/${widget.examId}/finish');
  }

  void _showSubmitDialog() {
    final answered = _answers.values
        .where((a) => a['selectedOptionId'] != null || (a['answerText'] ?? '').isNotEmpty)
        .length;
    final doubtful = _answers.values.where((a) => a['isDoubtful'] == true).length;
    final unanswered = _questions.length - answered;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit Ujian?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _statRow('Dijawab', '$answered', Colors.green),
          _statRow('Ragu-ragu', '$doubtful', Colors.orange),
          _statRow('Belum dijawab', '$unanswered', Colors.red),
          if (unanswered > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Masih ada $unanswered soal kosong!',
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kembali')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _submit(); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Submit'),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String val, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: c)),
      ]),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Overlay blokir saat sedang melaporkan pelanggaran ke server
    if (_reportingViolation) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.security, size: 48, color: Colors.orange[800]),
              ),
              const SizedBox(height: 20),
              Text(
                'Menyinkronkan...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[900]),
              ),
              const SizedBox(height: 8),
              Text(
                'Terdeteksi keluar aplikasi. Melaporkan ke server, mohon tunggu.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ]),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Tidak ada soal')));
    }

    final isWarning  = _timeLeft < 600;
    final isCritical = _timeLeft < 180;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isCritical ? Colors.red : isWarning ? Colors.orange : Colors.white,
              child: Row(children: [
                Expanded(
                  child: Text(
                    _title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13,
                      color: isCritical || isWarning ? Colors.white : Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCritical ? Colors.red[800] : isWarning ? Colors.orange[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formattedTime,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 16,
                      color: isCritical || isWarning ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: isCritical || isWarning ? Colors.white : Colors.red,
                    size: 20,
                  ),
                  onPressed: _showSubmitDialog,
                  tooltip: 'Submit',
                ),
              ]),
            ),

            // ── Soal ────────────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                itemCount: _questions.length,
                controller: _pageController,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) {
                  final qi = _questions[i];
                  final qiId = qi['id'].toString();
                  final qAns = _answers[qiId];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(
                            'Soal ${i + 1}/${_questions.length}',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _saveAnswer(qiId, doubtful: !(qAns?['isDoubtful'] ?? false)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: qAns?['isDoubtful'] == true ? Colors.yellow[100] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: qAns?['isDoubtful'] == true ? Colors.yellow[700]! : Colors.grey[300]!,
                                ),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(
                                  Icons.flag, size: 14,
                                  color: qAns?['isDoubtful'] == true ? Colors.yellow[800] : Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Ragu',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: qAns?['isDoubtful'] == true ? Colors.yellow[800] : Colors.grey[600],
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(qi['questionText'] ?? '', style: const TextStyle(fontSize: 15, height: 1.5)),
                        ),
                        const SizedBox(height: 16),
                        // Opsi atau input teks
                        if ((qi['options'] as List?)?.isNotEmpty ?? false)
                          ...(qi['options'] as List).map((opt) {
                            final selected = qAns?['selectedOptionId'] == opt['id'];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => _saveAnswer(qiId, optionId: opt['id']),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: selected ? const Color(0xFFEFF6FF) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected ? const Color(0xFF3B82F6) : Colors.grey.shade200,
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(children: [
                                    Container(
                                      width: 30, height: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: selected ? const Color(0xFF3B82F6) : Colors.grey[100],
                                        border: Border.all(
                                          color: selected ? const Color(0xFF3B82F6) : Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: selected
                                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                                            : Text(
                                                opt['label'] ?? '',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        opt['text'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: selected ? const Color(0xFF1E40AF) : Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            );
                          })
                        else
                          TextField(
                            maxLines: qi['questionType'] == 'ESSAY' ? 8 : 2,
                            decoration: InputDecoration(
                              hintText: qi['questionType'] == 'ESSAY'
                                  ? 'Tulis jawaban esai...'
                                  : 'Jawaban singkat...',
                            ),
                            onChanged: (v) => _saveAnswer(qiId, text: v),
                            controller: TextEditingController(text: qAns?['answerText'] ?? ''),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Navigasi nomor soal ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _questions.length,
                  itemBuilder: (_, i) {
                    final qi = _questions[i];
                    final qiId = qi['id'].toString();
                    final a = _answers[qiId];
                    Color bg = Colors.grey[200]!;
                    Color fg = Colors.grey[600]!;
                    if (i == _current) {
                      bg = const Color(0xFF3B82F6);
                      fg = Colors.white;
                    } else if (a?['isDoubtful'] == true) {
                      bg = Colors.yellow[400]!;
                      fg = Colors.white;
                    } else if (a?['selectedOptionId'] != null ||
                        (a?['answerText'] ?? '').isNotEmpty) {
                      bg = Colors.green;
                      fg = Colors.white;
                    }
                    return GestureDetector(
                      onTap: () {
                        setState(() => _current = i);
                        _pageController.jumpToPage(i);
                      },
                      child: Container(
                        width: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
