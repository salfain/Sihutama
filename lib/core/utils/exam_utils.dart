import 'package:flutter/material.dart';

/// Aturan: UTS, UAS, US hanya bisa dibuat token oleh Admin.
/// UH, TRYOUT, LAINNYA boleh dibuat token oleh Guru.
bool canTeacherCreateToken(String? examType) {
  const adminOnly = ['UTS', 'UAS', 'US'];
  return !adminOnly.contains(examType);
}

Color examTypeColor(String? type) {
  switch (type) {
    case 'UH': return Colors.blue;
    case 'UTS': return Colors.purple;
    case 'UAS': return Colors.orange;
    case 'US': return Colors.red;
    case 'TRYOUT': return Colors.teal;
    default: return Colors.grey;
  }
}
