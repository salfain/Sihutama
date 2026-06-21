import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';

/// [system] = 'CBT' atau 'BK'
/// CBT  → role: STUDENT, TEACHER
/// BK   → role: STUDENT, COUNSELOR
class LoginPage extends StatefulWidget {
  final String system; // 'CBT' | 'BK'
  const LoginPage({super.key, required this.system});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late String _role;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  bool get _isCbt => widget.system == 'CBT';
  bool get _isPiket => widget.system == 'PIKET';

  // Daftar role yang ditampilkan berdasarkan sistem
  List<String> get _roles {
    if (_isCbt) return ['STUDENT', 'TEACHER'];
    if (_isPiket) return ['TEACHER'];
    return ['STUDENT', 'COUNSELOR'];
  }

  // Warna aksen berdasarkan sistem
  Color get _accentColor {
    if (_isCbt) return const Color(0xFF1D4ED8);
    if (_isPiket) return const Color(0xFFF59E0B);
    return const Color(0xFF7C3AED);
  }

  List<Color> get _gradientColors {
    if (_isCbt) return [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)];
    if (_isPiket) return [const Color(0xFFF59E0B), const Color(0xFFFCD34D)];
    return [const Color(0xFF6D28D9), const Color(0xFF8B5CF6)];
  }

  @override
  void initState() {
    super.initState();
    _role = _roles.first; // default role pertama
  }

  String _roleLabel(String r) {
    if (r == 'STUDENT') return 'Siswa';
    if (_isPiket && r == 'TEACHER') return 'Guru Piket';
    if (r == 'TEACHER') return 'Guru';
    return 'Guru BK';
  }

  Color _buttonColor(String r) {
    if (_isPiket) return const Color(0xFFF59E0B);
    if (r == 'TEACHER') return const Color(0xFF059669);
    return _accentColor;
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient().dio.post('/auth/login', data: {
        'username': _usernameCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'role': _role,
        'system': widget.system,
      });
      final token = res.data['token'] as String;
      await ApiClient().setToken(token);
      await ApiClient().setLastSystem(widget.system);

      if (!mounted) return;

      if (_isPiket && _role == 'TEACHER') {
        context.go('/piket');
      } else if (_role == 'TEACHER') {
        context.go('/teacher');
      } else if (_role == 'COUNSELOR') {
        context.go('/counselor');
      } else {
        // STUDENT — arahkan berdasarkan sistem
        if (_isCbt) {
          context.go('/student/cbt');
        } else {
          context.go('/student/bk-portal');
        }
      }
    } catch (e) {
      setState(() {
        _error = (e is DioException && e.response != null)
            ? (e.response?.data['error'] ?? 'Login gagal')
            : 'Tidak dapat terhubung ke server';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header gradient (visual penanda sistem)
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 28, left: 24, right: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradientColors,
                begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Column(children: [
              // Back button + judul
              Row(children: [
                GestureDetector(
                  onTap: () => context.go('/portal'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_isCbt ? 'CBT — Ujian Online' : _isPiket ? 'Guru Piket' : 'SIBIKONS — BK',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(_isCbt ? 'Sistem Ujian Digital' : _isPiket ? 'Ketertiban Harian' : 'Bimbingan Konseling',
                      style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(14)),
                  child: Icon(_isCbt ? Icons.assignment_rounded : _isPiket ? Icons.assignment_ind_rounded : Icons.favorite_rounded,
                    color: Colors.white, size: 22),
                ),
              ]),
            ]),
          ),

          // Form login
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Masuk', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900])),
                  const SizedBox(height: 4),
                  Text('Pilih peran dan masukkan kredensial Anda',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                  const SizedBox(height: 28),

                  // Role selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: _roles.map((r) {
                        final selected = _role == r;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() { _role = r; _error = null; }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? (isDark ? const Color(0xFF334155) : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: selected && !isDark
                                    ? [BoxShadow(color: _accentColor.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2))]
                                    : null,
                              ),
                              child: Center(
                                child: Text(_roleLabel(r),
                                  style: TextStyle(
                                    fontSize: 14, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    color: selected
                                        ? (isDark ? Colors.white : _accentColor)
                                        : (isDark ? Colors.grey[500] : Colors.grey[500]),
                                  )),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input username
                  TextField(
                    controller: _usernameCtrl,
                    decoration: InputDecoration(
                      labelText: _role == 'STUDENT' ? 'NIS / Username' : 'Username',
                      hintText: _role == 'STUDENT' ? '2324001'
                          : _role == 'COUNSELOR' ? 'bk.hutama' : 'sari.dewi',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),

                  // Input password
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    onSubmitted: (_) => _login(),
                  ),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.red.shade900.withAlpha(80) : Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.red.shade700 : Colors.red.shade200)),
                      child: Row(children: [
                        Icon(Icons.error_outline, size: 16,
                          color: isDark ? Colors.red.shade300 : Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!,
                          style: TextStyle(
                            color: isDark ? Colors.red.shade300 : Colors.red[700], fontSize: 13))),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Tombol masuk
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonColor(_role),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(_role == 'STUDENT' ? Icons.school_rounded
                                  : _isPiket ? Icons.assignment_ind_rounded
                                  : _role == 'TEACHER' ? Icons.cast_for_education_rounded
                                  : Icons.favorite_rounded,
                                size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('Masuk sebagai ${_roleLabel(_role)}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            ]),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: Text('Lupa password? Hubungi admin.',
                      style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400], fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
