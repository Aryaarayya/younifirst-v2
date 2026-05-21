import 'package:flutter/material.dart';
import 'package:younifirst_app/services/api/forgot_password_service.dart';
import 'package:younifirst_app/views/lupa_katasandi/AturUlangKatasandi.dart';

class VerifikasiKode extends StatefulWidget {
  final String email;
  
  const VerifikasiKode({Key? key, required this.email}) : super(key: key);

  @override
  _VerifikasiKodeState createState() => _VerifikasiKodeState();
}

class _VerifikasiKodeState extends State<VerifikasiKode> {
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _focusNodes;
  bool _isLoading = false;
  int _resendTime = 25;
  bool _canResend = false;
  
  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(4, (index) => TextEditingController());
    _focusNodes = List.generate(4, (index) => FocusNode());
    _startResendTimer();
  }
  
  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTime > 0) {
        setState(() {
          _resendTime--;
        });
        _startResendTimer();
      } else if (mounted && _resendTime == 0) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }
  
  String get _otpCode {
    return _otpControllers.map((c) => c.text).join();
  }
  
  void _handleVerification() async {
    final otp = _otpCode;
    if (otp.length != 4) {
      _showSnackBar('Masukkan kode verifikasi 4 digit', Colors.red);
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await ForgotPasswordService.verifyOtp(widget.email, otp);
      
      if (!mounted) return;
      
      if (result['success']) {
        _showSnackBar(result['message'], Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AturUlangKatasandi(
              email: widget.email,
              otp: otp,
            ),
          ),
        );
      } else {
        _showSnackBar(result['message'], Colors.red);
        _clearOtp();
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Terjadi kesalahan: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _clearOtp() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }
  
  void _resendCode() async {
    if (!_canResend) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await ForgotPasswordService.sendOtp(widget.email);
      if (!mounted) return;
      
      if (result['success']) {
        setState(() {
          _canResend = false;
          _resendTime = 25;
          _clearOtp();
        });
        _startResendTimer();
        _showSnackBar(result['message'], Colors.green);
      } else {
        _showSnackBar(result['message'], Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal mengirim ulang kode: $e', Colors.red);
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
  
  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // 🔵 ICON matching Mockup 2
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E7FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mail_outline,
                      size: 40,
                      color: Color(0xFF3D5AF1),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  "Periksa Email",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Subtitle / Email Info
                const Text(
                  "Masukkan kode verifikasi yang dikirim ke",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // OTP Input Fields (4 rounded boxes matching mockup)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    return SizedBox(
                      width: 60,
                      height: 60,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        enabled: !_isLoading,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          hintText: '-',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF3D5AF1), width: 1.5),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.length == 1 && index < 3) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          
                          // Auto verify when all fields filled
                          if (_otpCode.length == 4) {
                            _handleVerification();
                          }
                        },
                      ),
                    );
                  }),
                ),
                
                const SizedBox(height: 40),
                
                // Resend Section
                Column(
                  children: [
                    const Text(
                      "Tidak menerima kode?",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _isLoading ? null : _resendCode,
                      child: Text(
                        _canResend 
                          ? "Kirim Ulang Kode"
                          : "Kirim Ulang Kode ( ${_resendTime}s )",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _canResend 
                            ? const Color(0xFF3D5AF1) 
                            : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 30.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3D5AF1)),
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
