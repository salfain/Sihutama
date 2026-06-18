import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/theme_provider.dart';

const _teal = Color(0xFF059669);

class TeacherProfilPage extends ConsumerStatefulWidget {
  const TeacherProfilPage({super.key});
  @override
  ConsumerState<TeacherProfilPage> createState() => _State();
}

class _State extends ConsumerState<TeacherProfilPage> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ApiClient().dio.get('/auth/me');
      if (mounted) setState(() { _user = res.data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final themeMode = ref.watch(themeProvider);
    final name = _user?['name'] ?? '';
    final nip = _user?['teacher']?['nip'] ?? '—';
    final subject = _user?['teacher']?['subject']?['name'] ?? '—';
    final subjectCode = _user?['teacher']?['subject']?['code'] ?? '';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF064E3B), const Color(0xFF1E293B)]
                          : [const Color(0xFF059669), const Color(0xFF10B981)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32))),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Profil Guru', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(20)),
                            child: const Row(children: [
                              Icon(Icons.circle, size: 8, color: Color(0xFFFBBF24)),
                              SizedBox(width: 6),
                              Text('GURU', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            ])),
                        ]),
                        const SizedBox(height: 24),
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF059669)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight),
                            boxShadow: [BoxShadow(color: _teal.withAlpha(80), blurRadius: 16, offset: const Offset(0, 6))]),
                          child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'G',
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)))),
                        const SizedBox(height: 12),
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        if (subjectCode.isNotEmpty)
                          Text(subjectCode, style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
                      ]),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  _card(isDark, [
                    _infoRow('NIP', nip, Icons.badge_rounded, _teal, isDark),
                    _div(isDark),
                    _infoRow('Mata Pelajaran', subject, Icons.menu_book_rounded, _teal, isDark),
                  ]),
                  const SizedBox(height: 16),
                  _label('Pengaturan', isDark),
                  const SizedBox(height: 8),
                  _card(isDark, [
                    _switchRow(
                      icon: themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: Colors.amber,
                      label: 'Mode Gelap',
                      sub: themeMode == ThemeMode.dark ? 'Aktif' : 'Nonaktif',
                      isDark: isDark,
                      value: themeMode == ThemeMode.dark,
                      onChanged: (_) => ref.read(themeProvider.notifier).toggle()),
                  ]),
                  const SizedBox(height: 16),
                  _label('Akun', isDark),
                  const SizedBox(height: 8),
                  _card(isDark, [
                    _actionRow(Icons.info_outline_rounded, Colors.blue, 'Tentang Aplikasi', null, isDark,
                      () => _about(context, isDark)),
                    _div(isDark),
                    _actionRow(Icons.logout_rounded, Colors.red, 'Keluar', Colors.red, isDark,
                      () => _logout(context, isDark)),
                  ]),
                  const SizedBox(height: 80),
                ])),
              ),
            ]),
    );
  }

  Widget _card(bool isDark, List<Widget> c) => Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100),
      boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))]),
    child: Column(children: c));

  Widget _infoRow(String label, String val, IconData icon, Color color, bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 14, color: color)),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[500])),
      const Spacer(),
      Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey[900])),
    ]));

  Widget _switchRow({required IconData icon, required Color color, required String label,
      required String sub, required bool isDark, required bool value, required ValueChanged<bool> onChanged}) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey[900])),
          Text(sub, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500])),
        ])),
        Switch.adaptive(value: value, onChanged: onChanged, activeThumbColor: _teal),
      ]));

  Widget _actionRow(IconData icon, Color iconColor, String label, Color? labelColor, bool isDark, VoidCallback onTap) =>
    InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: iconColor)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: labelColor ?? (isDark ? Colors.white : Colors.grey[900]))),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? Colors.grey[500] : Colors.grey[400]),
        ])));

  Widget _div(bool isDark) => Divider(height: 1, indent: 52,
    color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100);
  Widget _label(String t, bool isDark) => Text(t,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5,
      color: isDark ? Colors.grey[400] : Colors.grey[500]));

  void _about(BuildContext context, bool isDark) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('SiHutama — Guru', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Sistem CBT SMK Hutama\nVersi 1.0',
        style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[600], height: 1.6)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
    ));
  }

  void _logout(BuildContext context, bool isDark) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Keluar?', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Anda akan keluar dari aplikasi.',
        style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[600])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: Text('Batal', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]))),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final router = GoRouter.of(context);
            await ApiClient().clearToken();
            router.go('/portal');
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    ));
  }
}
