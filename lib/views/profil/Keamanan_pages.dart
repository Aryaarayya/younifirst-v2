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
          'old_password': _currentPassCtrl.text,
          'new_password': _newPassCtrl.text,
          'new_password_confirmation': _confirmPassCtrl.text,
          'password': _newPassCtrl.text,
          'password_confirmation': _confirmPassCtrl.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();

        _showSnackBar('Kata sandi berhasil diubah.', isError: false);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Keamanan Akun',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Theme.of(context).dividerColor,
            height: 1.0,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info Card ──────────────────────────────────────
                _buildInfoCard(),
                const SizedBox(height: 32),

                // ── Kata Sandi Saat Ini ────────────────────────────
                _buildLabel('Kata Sandi Saat Ini'),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _currentPassCtrl,
                  hint: 'Masukkan kata sandi saat ini',
                  obscure: _obscureCurrent,
                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Masukkan kata sandi saat ini';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ── Kata Sandi Baru ────────────────────────────────
                _buildLabel('Kata Sandi Baru'),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _newPassCtrl,
                  hint: 'Masukkan kata sandi baru Anda',
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
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
                const SizedBox(height: 24),

                // ── Konfirmasi Kata Sandi ──────────────────────────
                _buildLabel('Konfirmasi Kata Sandi'),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _confirmPassCtrl,
                  hint: 'Konfirmasi kata sandi Anda',
                  obscure: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
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
                const SizedBox(height: 40),

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2138) : const Color(0xFFEEF0FF),
        borderRadius: BorderRadius.circular(12),
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
            child: const Icon(Icons.verified_user_outlined, color: _blue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jaga akun Anda tetap aman',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _blue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gunakan kata sandi yang kuat dan jangan bagikan ke siapapun.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : const Color(0xFF555555),
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
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF111111),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      obscuringCharacter: '•',
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.password],
      validator: validator,
      style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey[500] : const Color(0xFF888888), fontSize: 14),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFCCCCCC), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFCCCCCC), width: 1),
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
            color: isDark ? Colors.grey[500] : const Color(0xFF888888),
            size: 22,
          ),
          onPressed: onToggle,
          splashRadius: 24,
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        // BATAL
        Expanded(
          flex: 3,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // UBAH KATA SANDI
        Expanded(
          flex: 5,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _ubahKataSandi,
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
