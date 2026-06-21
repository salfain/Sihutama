import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';

class PortalPage extends StatelessWidget {
  const PortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),

                  // Logo
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20)),
                        child: const Center(
                          child: Text('SH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28))),
                      )),
                  ),
                  const SizedBox(height: 20),

                  Text('SiHutama',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                      letterSpacing: -0.5, color: isDark ? Colors.white : Colors.grey[900])),
                  const SizedBox(height: 6),
                  Text('SMK Hutama Pondok Gede',
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600])),

                  const SizedBox(height: 48),

                  Text('Pilih Sistem',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      letterSpacing: 1, color: isDark ? Colors.grey[400] : Colors.grey[500])),
                  const SizedBox(height: 16),

                  // Kartu CBT
                  _SystemCard(
                    system: 'CBT',
                    title: 'CBT — Ujian Online',
                    subtitle: 'Untuk Admin, Guru & Siswa',
                    description: 'Ujian digital, token, monitoring, dan laporan nilai.',
                    icon: Icons.assignment_rounded,
                    gradientColors: const [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                    iconBg: const Color(0xFF1E40AF),
                    features: const ['Ujian CBT & soal pilihan ganda', 'Token ujian aman', 'Autosave jawaban', 'Laporan & analisis nilai'],
                    onTap: () => context.go('/login?system=CBT'),
                  ),

                  const SizedBox(height: 16),

                  // Kartu SIBIKONS
                  _SystemCard(
                    system: 'BK',
                    title: 'SIBIKONS — Bimbingan Konseling',
                    subtitle: 'Untuk Guru BK & Siswa',
                    description: 'Konseling, poin pelanggaran, prestasi, dan angket kebutuhan.',
                    icon: Icons.favorite_rounded,
                    gradientColors: const [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
                    iconBg: const Color(0xFF5B21B6),
                    features: const ['Sesi & catatan konseling', 'Poin pelanggaran & prestasi', 'Ajukan permohonan konseling', 'Angket kebutuhan (AKPD)'],
                    onTap: () => context.go('/login?system=BK'),
                  ),

                  const SizedBox(height: 16),

                  // Kartu PIKET
                  _SystemCard(
                    system: 'PIKET',
                    title: 'Guru Piket',
                    subtitle: 'Untuk guru terjadwal piket',
                    description: 'Pencatatan ketertiban harian: keterlambatan, izin keluar, dan kehadiran guru.',
                    icon: Icons.assignment_ind_rounded,
                    gradientColors: const [Color(0xFFF59E0B), Color(0xFFFCD34D)],
                    iconBg: const Color(0xFFD97706),
                    features: const ['Catat keterlambatan siswa', 'Pantau izin keluar/masuk', 'Rekap kehadiran guru', 'Dashboard harian'],
                    onTap: () => context.go('/login?system=PIKET'),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SystemCard extends StatelessWidget {
  final String system;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final Color iconBg;
  final List<String> features;
  final VoidCallback onTap;

  const _SystemCard({
    required this.system,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.iconBg,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade200),
          boxShadow: [
            if (!isDark) BoxShadow(
              color: gradientColors[0].withAlpha(25),
              blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24), topRight: Radius.circular(24))),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title.split('—').first.trim(),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                      style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12, fontWeight: FontWeight.w500)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ),
              ]),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                  const SizedBox(height: 14),
                  ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: gradientColors[0], shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Text(f, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[700])),
                    ]),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
