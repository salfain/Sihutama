import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/env.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'STUDENT';
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient().dio.post('/auth/login', data: {
        'username': _usernameCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'role': _role,
      });
      final token = res.data['token'] as String;
      await ApiClient().setToken(token);

      if (!mounted) return;
      if (_role == 'STUDENT') {
        context.go('/student');
      } else if (_role == 'COUNSELOR') {
        context.go('/counselor');
      } else {
        context.go('/teacher');
      }
    } catch (e) {
      setState(() {
        if (e is DioException && e.response != null) {
          _error = e.response?.data['error'] ?? 'Login gagal';
        } else {
          _error = 'Tidak dapat terhubung ke server';
        }
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo sekolah (dari server, fallback ke inisial)
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1D4ED8),
                      child: const Center(
                        child: Text('SH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Si Hutama', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Masuk ke sistem ujian', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 32),

                // Role selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: ['STUDENT', 'TEACHER', 'COUNSELOR'].map((r) {
                      final selected = _role == r;
                      final label = r == 'STUDENT' ? 'Siswa' : r == 'TEACHER' ? 'Guru' : 'Guru BK';
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _role = r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: selected ? [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4)] : null,
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                  color: selected ? Colors.grey[900] : Colors.grey[500],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Username
                TextField(
                  controller: _usernameCtrl,
                  decoration: InputDecoration(
                    labelText: _role == 'STUDENT' ? 'NIS / Username' : 'Username',
                    hintText: _role == 'STUDENT' ? '2324001' : _role == 'COUNSELOR' ? 'bk.hutama' : 'sari.dewi',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Password
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
                const SizedBox(height: 8),

                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _role == 'STUDENT'
                          ? const Color(0xFFF97316)
                          : _role == 'COUNSELOR'
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF059669),
                    ),
                    child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text('Masuk sebagai ${_role == 'STUDENT' ? 'Siswa' : _role == 'COUNSELOR' ? 'Guru BK' : 'Guru'}'),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Lupa password? Hubungi admin.', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
