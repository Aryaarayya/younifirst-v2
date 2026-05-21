import 'package:flutter/material.dart';
import 'package:younifirst_app/services/api/forgot_password_service.dart';

class AturUlangKatasandi extends StatefulWidget {
  final String email;
  final String otp;

  const AturUlangKatasandi({Key? key, required this.email, required this.otp}) : super(key: key);

  @override
  _AturUlangKatasandiState createState() => _AturUlangKatasandiState();
}

class _AturUlangKatasandiState extends State<AturUlangKatasandi> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar("Semua bidang harus diisi", Colors.red);
      return;
    }

    if (password.length < 8) {
      _showSnackBar("Kata sandi harus terdiri dari minimal 8 karakter", Colors.red);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("Kata sandi dan konfirmasi kata sandi tidak cocok", Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ForgotPasswordService.resetPassword(
        email: widget.email,
        otp: widget.otp,
        password: password,
        passwordConfirmation: confirmPassword,
      );

      if (!mounted) return;

      if (result['success']) {
        _showSuccessDialog(result['message']);
      } else {
        _showSnackBar(result['message'], Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Terjadi kesalahan: $e", Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => Container(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final scale = 1.0 - (1.0 - anim1.value) * 0.15;
        final opacity = anim1.value;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Align(
              alignment: Alignment.center,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Elegant success icon with double circular design and sparkles
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glowing rings
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF3D5AF1).withOpacity(0.08),
                              ),
                            ),
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF3D5AF1).withOpacity(0.12),
                              ),
                            ),
                            // Inner gradient circle with checkmark
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3D5AF1), Color(0xFF1A365D)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3D5AF1).withOpacity(0.35),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                            // Decorative sparkles (small gold stars and dots) around the check
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Icon(Icons.star_rounded, color: const Color(0xFFFFD700).withOpacity(0.8), size: 16),
                            ),
                            Positioned(
                              bottom: 12,
                              right: 4,
                              child: Icon(Icons.star_rounded, color: const Color(0xFFFFD700).withOpacity(0.8), size: 20),
                            ),
                            Positioned(
                              top: 20,
                              right: 8,
                              child: Icon(Icons.circle, color: const Color(0xFF3D5AF1).withOpacity(0.4), size: 8),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 12,
                              child: const Icon(Icons.circle, color: Color(0xFFFFE082), size: 6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Modern, bold title
                      const Text(
                        "Kata Sandi Diperbarui!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Beautiful message text
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Full-width premium gradient action button
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3D5AF1), Color(0xFF2563EB)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3D5AF1).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                            },
                            child: const Center(
                              child: Text(
                                "Masuk Sekarang",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // 🔵 ICON matching Mockup 3
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E7FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 40,
                      color: Color(0xFF3D5AF1),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                const Center(
                  child: Text(
                    "Atur Ulang Kata Sandi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Subtitle
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      "Buat kata sandi baru. Kata sandi baru Anda harus berbeda dari kata sandi yang sebelumnya pernah digunakan.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Label: Kata Sandi
                const Text(
                  "Kata Sandi",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Input Field: Kata Sandi
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: "Masukkan kata sandi baru Anda",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Label: Konfirmasi Kata Sandi
                const Text(
                  "Konfirmasi Kata Sandi",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Input Field: Konfirmasi Kata Sandi
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: "Konfirmasi kata sandi Anda",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Button: RESET KATA SANDI
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D5AF1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "RESET KATA SANDI",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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
