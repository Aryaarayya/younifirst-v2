import 'package:flutter/material.dart';
import 'dart:async';
import 'package:younifirst_app/services/auth_service.dart';
import 'package:younifirst_app/services/notification_service.dart';

class Splashscreen extends StatefulWidget {
  @override
  _SplashscreenState createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  late Animation<Offset> topAnimation;
  late Animation<Offset> bottomAnimation;
  late Animation<Offset> rightAnimation;
  late Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );

    // 🎓 dari atas
    topAnimation = Tween<Offset>(
      begin: Offset(0, -3),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // 📝 dari bawah
    bottomAnimation = Tween<Offset>(
      begin: Offset(0, 3),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // ✨ dari kanan
    rightAnimation = Tween<Offset>(
      begin: Offset(3, 0),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // fade
    fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    // Sync FCM Token asli ke backend
    _syncFcmToken();

    // pindah ke login setelah 3 detik
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  /// Ambil FCM token asli dari Firebase lalu kirim ke backend
  Future<void> _syncFcmToken() async {
    try {
      final token = await NotificationService.getFcmToken();
      if (token != null && token.isNotEmpty) {
        await AuthService.updateFcmToken(token);
        debugPrint('✅ FCM Token berhasil di-sync: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      debugPrint('⚠️ Gagal sync FCM token: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;

    // Ukuran responsif berdasarkan lebar layar
    final double logoSize   = w * 0.40;   // lingkaran utama
    final double topiSize   = w * 0.38;   // topi wisuda (sedikit lebih lebar dari logo)
    final double bintangSize = w * 0.10;  // bintang kecil
    final double textWidth  = w * 0.50;   // teks Younifirst

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // ─── Grup Logo (Topi + Lingkaran + Bintang) ───
            SizedBox(
              width: logoSize + bintangSize,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [

                  // 🌐 Lingkaran dalam (center)
                  FadeTransition(
                    opacity: fadeAnimation,
                    child: Image.asset(
                      'assets/images/Lingkaran dalam.png',
                      width: logoSize,
                    ),
                  ),

                  // 🌐 Interaksi (center, sedikit lebih kecil)
                  FadeTransition(
                    opacity: fadeAnimation,
                    child: Image.asset(
                      'assets/images/Interaksi.png',
                      width: logoSize * 0.72,
                    ),
                  ),

                  // 🎓 Topi Wisuda — tepat di atas logo, overlap ke bawah
                  Positioned(
                    top: -(topiSize * 0.38),
                    child: SlideTransition(
                      position: topAnimation,
                      child: FadeTransition(
                        opacity: fadeAnimation,
                        child: Image.asset(
                          'assets/images/Topi Wisuda.png',
                          width: topiSize,
                        ),
                      ),
                    ),
                  ),

                  // ✨ Bintang — pojok kanan atas logo
                  Positioned(
                    top: logoSize * 0.05,
                    right: 0,
                    child: SlideTransition(
                      position: rightAnimation,
                      child: FadeTransition(
                        opacity: fadeAnimation,
                        child: Image.asset(
                          'assets/images/Bintang.png',
                          width: bintangSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // 📝 Younifirst (dari bawah)
            SlideTransition(
              position: bottomAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: Image.asset(
                  'assets/images/Younifirst.png',
                  width: textWidth,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
