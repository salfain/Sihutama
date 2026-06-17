import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Menyimpan pelanggaran yang terjadi saat offline.
/// Saat koneksi pulih, semua antrian dikirim ke server sekaligus.
class ViolationQueue {
  static const _storage = FlutterSecureStorage();
  static const _key = 'violation_queue';

  /// Tambah satu event pelanggaran ke antrian lokal.
  static Future<void> push(String examId, String reason) async {
    final list = await _load();
    list.add({'examId': examId, 'reason': reason, 'ts': DateTime.now().toIso8601String()});
    await _save(list);
  }

  /// Ambil semua event yang belum terkirim untuk examId tertentu.
  static Future<List<Map<String, dynamic>>> pendingFor(String examId) async {
    final list = await _load();
    return list.where((e) => e['examId'] == examId).toList();
  }

  /// Hapus semua event yang sudah berhasil dikirim untuk examId tertentu.
  static Future<void> clearFor(String examId) async {
    final list = await _load();
    list.removeWhere((e) => e['examId'] == examId);
    await _save(list);
  }

  /// Total jumlah event pending untuk examId.
  static Future<int> countFor(String examId) async {
    final pending = await pendingFor(examId);
    return pending.length;
  }

  static Future<List<Map<String, dynamic>>> _load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(List<Map<String, dynamic>> list) async {
    await _storage.write(key: _key, value: jsonEncode(list));
  }
}
