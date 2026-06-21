import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/network/api_client.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _scale = Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final token = await ApiClient().getToken();
    if (!mounted) return;
    if (token != null) {
      // Cek role dari /auth/me
      try {
        final res = await ApiClient().dio.get('/auth/me');
        final role = res.data['role'] as String?;
        if (!mounted) return;
        if (role == 'TEACHER') {
          final lastSystem = await ApiClient().getLastSystem();
          if (!mounted) return;
          context.go(lastSystem == 'PIKET' ? '/piket' : '/teacher');
        } else if (role == 'COUNSELOR') {
          context.go('/counselor');
        } else if (role == 'PIKET') {
          context.go('/piket');
        } else if (role == 'STUDENT') {
          // Baca sistem terakhir yang dipakai siswa
          final lastSystem = await ApiClient().getLastSystem();
          if (!mounted) return;
          context.go(lastSystem == 'BK' ? '/student/bk-portal' : '/student/cbt');
        } else {
          context.go('/portal');
        }
      } catch (_) {
        if (mounted) context.go('/portal');
      }
    } else {
      context.go('/portal');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.isDark(context) ? const Color(0xFF0F172A) : Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1D4ED8),
                      child: const Center(
                        child: Text('SH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Si Hutama',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.grey[400]!),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
