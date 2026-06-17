import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';

class TokenInputPage extends StatefulWidget {
  final String examId;
  const TokenInputPage({super.key, required this.examId});
  @override
  State<TokenInputPage> createState() => _TokenInputPageState();
}

class _TokenInputPageState extends State<TokenInputPage> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _validate() async {
    if (_ctrl.text.trim().isEmpty) { setState(() => _error = 'Token wajib diisi'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient().dio.post('/student/exams/validate-token', data: {
        'examId': widget.examId,
        'token': _ctrl.text.trim(),
      });
      if (mounted) context.push('/student/exams/${widget.examId}/confirm');
    } catch (e) {
      setState(() {
        _error = (e is DioException) ? (e.response?.data['error'] ?? 'Token gagal') : 'Koneksi error';
      });
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Token')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(20)),
                child: Icon(Icons.key, size: 36, color: Colors.orange[700]),
              ),
              const SizedBox(height: 20),
              const Text('Masukkan Token Ujian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Minta token kepada pengawas', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 24),
              TextField(
                controller: _ctrl,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4),
                decoration: const InputDecoration(hintText: 'MTK-7842'),
                onSubmitted: (_) => _validate(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _validate,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                  child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Validasi & Lanjutkan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
