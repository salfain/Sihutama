import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/theme_provider.dart';

const _purple = Color(0xFF7C3AED);

/// Tab Profil — info siswa + toggle tema + logout (pola banking)
class StudentBkProfilPage extends ConsumerStatefulWidget {
  const StudentBkProfilPage({super.key});
  @override
  ConsumerState<StudentBkProfilPage> createState() => _State();
}

class _State extends ConsumerState<StudentBkProfilPage> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ApiClient().dio.get('/auth/me');
      setState(() { _user = res.data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final themeMode = ref.watch(themeProvider);
    final name = _user?['name'] ?? '';
    final className = _user?['student']?['class']?['name'] ?? '—';
    final nis = _user?['student']?['nis'] ?? '—';
    final major = _user?['student']?['major']?['name'] ?? '—';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F3FF),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _purple))
          : CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF4C1D95), const Color(0xFF1E293B)]
                            : [const Color(0xFF5B21B6), const Color(0xFF7C3AED)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32))),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                        child: Column(children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('Profil', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(20)),
                              child: const Row(children: [
                                Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                                SizedBox(width: 6),
                                Text('SIBIKONS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                              ])),
                          ]),
                          const SizedBox(height: 24),
                          // Avatar
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                                begin: Alignment.topLeft, end: Alignment.bottomRight),
                              boxShadow: [BoxShadow(color: _purple.withAlpha(80), blurRadius: 16, offset: const Offset(0, 6))]),
                            child: Center(child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'S',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)))),
                          const SizedBox(height: 12),
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(className, style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
                        ]),
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(delegate: SliverChildListDelegate([
                    // Info card
                    _infoCard(isDark, [
                      _infoRow('NIS', nis, Icons.badge_rounded, isDark),
                      _divider(isDark),
                      _infoRow('Kelas', className, Icons.class_rounded, isDark),
                      _divider(isDark),
                      _infoRow('Jurusan', major, Icons.school_rounded, isDark),
                    ]),
                    const SizedBox(height: 16),

                    // Pengaturan
                    _sectionLabel('Pengaturan', isDark),
                    const SizedBox(height: 8),
                    _settingCard(isDark, [
                      _switchRow(
                        icon: themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        iconColor: themeMode == ThemeMode.dark ? Colors.amber : Colors.orange,
                        label: 'Mode Gelap',
                        subtitle: themeMode == ThemeMode.dark ? 'Aktif' : 'Nonaktif',
                        isDark: isDark,
                        value: themeMode == ThemeMode.dark,
                        onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Akun
                    _sectionLabel('Akun', isDark),
                    const SizedBox(height: 8),
                    _settingCard(isDark, [
                      _actionRow(
                        icon: Icons.info_outline_rounded,
                        iconColor: Colors.blue,
                        label: 'Tentang SIBIKONS',
                        isDark: isDark,
                        onTap: () => _showAbout(context, isDark),
                      ),
                      _divider(isDark),
                      _actionRow(
                        icon: Icons.logout_rounded,
                        iconColor: Colors.red,
                        label: 'Keluar',
                        labelColor: Colors.red,
                        isDark: isDark,
                        onTap: () => _confirmLogout(context, isDark),
                      ),
                    ]),
                    const SizedBox(height: 80),
                  ])),
                ),
              ],
            ),
    );
  }

  Widget _infoCard(bool isDark, List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100),
      boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))]),
    child: Column(children: children),
  );

  Widget _settingCard(bool isDark, List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100),
      boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))]),
    child: Column(children: children),
  );

  Widget _infoRow(String label, String value, IconData icon, bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: _purple.withAlpha(20), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 14, color: _purple)),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[500])),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.grey[900])),
    ]),
  );

  Widget _switchRow({required IconData icon, required Color iconColor, required String label,
      required String subtitle, required bool isDark, required bool value, required ValueChanged<bool> onChanged}) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: iconColor)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.grey[900])),
          Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500])),
        ])),
        Switch.adaptive(value: value, onChanged: onChanged, activeThumbColor: _purple),
      ]),
    );

  Widget _actionRow({required IconData icon, required Color iconColor, required String label,
      Color? labelColor, required bool isDark, required VoidCallback onTap}) =>
    InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: iconColor)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: labelColor ?? (isDark ? Colors.white : Colors.grey[900]))),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, size: 18,
            color: isDark ? Colors.grey[500] : Colors.grey[400]),
        ]),
      ),
    );

  Widget _divider(bool isDark) => Divider(
    height: 1, indent: 52,
    color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
  );

  Widget _sectionLabel(String label, bool isDark) => Text(label,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5,
      color: isDark ? Colors.grey[400] : Colors.grey[500]));

  void _showAbout(BuildContext context, bool isDark) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('SIBIKONS', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Sistem Informasi Bimbingan Konseling\nSMK Hutama Pondok Gede\n\nVersi 1.0',
        style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[600], height: 1.6)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
    ));
  }

  void _confirmLogout(BuildContext context, bool isDark) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Keluar?', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Anda akan keluar dari SIBIKONS.',
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    ));
  }
}
