import 'package:flutter/material.dart';
import 'package:younifirst_app/views/Home_pages.dart';

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
    _otpControllers = List.generate(6, (index) => TextEditingController());
    _focusNodes = List.generate(6, (index) => FocusNode());
    _startResendTimer();
  }
  
  void _startResendTimer() {
    Future.delayed(Duration(seconds: 1), () {
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
    if (_otpCode.length != 6) {
      _showSnackBar('Masukkan kode verifikasi 6 digit', Colors.red);
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Simulasi verifikasi OTP
      await Future.delayed(Duration(seconds: 2));
      
      if (!mounted) return;
      
      // Contoh: kode benar = 123456
      if (_otpCode == '123456') {
        _showSnackBar('Verifikasi berhasil!', Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        _showSnackBar('Kode verifikasi salah', Colors.red);
        _clearOtp();
      }
    } catch (e) {
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
  
  void _resendCode() {
    if (!_canResend) return;
    
    setState(() {
      _canResend = false;
      _resendTime = 25;
      _clearOtp();
    });
    _startResendTimer();
    
    _showSnackBar('Kode verifikasi baru telah dikirim', Colors.blue);
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verifikasi Email',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              
              // Icon Email
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFF3D5AF1).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    size: 40,
                    color: Color(0xFF3D5AF1),
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Title
              Center(
                child: Text(
                  "Periksa Email",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              
              SizedBox(height: 12),
              
              // Email info
              Center(
                child: Text(
                  "Masukkan kode verifikasi yang dikirim ke",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              
              SizedBox(height: 4),
              
              Center(
                child: Text(
                  widget.email,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3D5AF1),
                  ),
                ),
              ),
              
              SizedBox(height: 40),
              
              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    height: 60,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF3D5AF1), width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.length == 1 && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        
                        // Auto verify when all fields filled
                        if (_otpCode.length == 6) {
                          _handleVerification();
                        }
                      },
                    ),
                  );
                }),
              ),
              
              SizedBox(height: 40),
              
              // Resend Section
              Center(
                child: Column(
                  children: [
                    Text(
                      "Tidak menerima kode?",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: _resendCode,
                      child: Text(
                        _canResend 
                          ? "Kirim Ulang Kode"
                          : "Kirim Ulang Kode ($_resendTime s)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _canResend 
                            ? Color(0xFF3D5AF1) 
                            : Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 30),
              
              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3D5AF1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          "VERIFIKASI",
                          style: TextStyle(
                            fontSize: 16,
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
    );
  }
}
