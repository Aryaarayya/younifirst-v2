import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:younifirst_app/services/input/api_client.dart';

class KeamananPage extends StatefulWidget {
  const KeamananPage({super.key});

  @override
  State<KeamananPage> createState() => _KeamananPageState();
}

class _KeamananPageState extends State<KeamananPage> {
  final _formKey = GlobalKey<FormState>();

  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  static const _blue = Color(0xFF3D5AFE);
  static const _bgColor = Color(0xFFF0F2F8);

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _ubahKataSandi() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.post(
        'change-password',
        body: jsonEncode({
          'current_password': _currentPassCtrl.text,
          'new_password': _newPassCtrl.text,
          'new_password_confirmation': _confirmPassCtrl.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();

        _showSnackBar(
          'Kata sandi berhasil diubah.',
          isError: false,
        );

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context);
      } else {
        String message = 'Gagal mengubah kata sandi.';
        try {
          final data = jsonDecode(response.body);
          if (data['message'] != null) {
            message = data['message'];
          } else if (data['error'] != null) {
            message = data['error'];
          }
        } catch (_) {}
        _showSnackBar(message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Koneksi bermasalah. Coba lagi.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Keamanan Akun',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info Card ──────────────────────────────────────
                _buildInfoCard(),
                const SizedBox(height: 24),

                // ── Kata Sandi Saat Ini ────────────────────────────
                _buildLabel('Kata Sandi Saat Ini'),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _currentPassCtrl,
                  hint: '',
                  obscure: _obscureCurrent,
                  onToggle: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Masukkan kata sandi saat ini';
                    }
                    return null;
                  },
                  prefillDots: true,
                ),
                const SizedBox(height: 16),

                // ── Kata Sandi Baru ────────────────────────────────
                _buildLabel('Kata Sandi Baru'),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _newPassCtrl,
                  hint: 'Masukkan kata sandi baru Anda',
                  obscure: _obscureNew,
                  onToggle: () =>
                      setState(() => _obscureNew = !_obscureNew),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Masukkan kata sandi baru';
                    }
                    if (v.length < 8) {
                      return 'Minimal 8 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Konfirmasi Kata Sandi ──────────────────────────
                _buildLabel('Konfirmasi Kata Sandi'),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _confirmPassCtrl,
                  hint: 'Konfirmasi kata sandi Anda',
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Konfirmasi kata sandi Anda';
                    }
                    if (v != _newPassCtrl.text) {
                      return 'Kata sandi tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ── Buttons ────────────────────────────────────────
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: _blue, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jaga akun Anda tetap aman',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _blue,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gunakan kata sandi yang kuat dan jangan bagikan ke siapapun.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555555),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    bool prefillDots = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      obscuringCharacter: '•',
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint.isEmpty ? null : hint,
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFFAAAAAA),
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        // BATAL
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: _blue, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'BATAL',
              style: TextStyle(
                color: _blue,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // UBAH KATA SANDI
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _ubahKataSandi,
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'UBAH KATA SANDI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
