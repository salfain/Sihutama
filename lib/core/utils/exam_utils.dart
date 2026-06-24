import 'package:flutter/material.dart';

/// Token ujian dikelola oleh admin, mengikuti aturan di website.
bool canTeacherCreateToken(String? _) {
  return false;
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
