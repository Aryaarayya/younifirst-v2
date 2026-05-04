import 'package:flutter/material.dart';
import 'package:younifirst_app/pages/lupa_katasandi/VerifikasiKode.dart';


class Lupa_katasandi extends StatefulWidget {
  @override
  _Lupa_katasandiState createState() => _Lupa_katasandiState();
}

class _Lupa_katasandiState extends State<Lupa_katasandi> {

  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleKirim() {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Email tidak boleh kosong"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerifikasiKode(
          email: _emailController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [

            SizedBox(height: 20),

            // 🔵 ICON
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Color(0xFFE0E7FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 40,
                color: Color(0xFF3D5AF1),
              ),
            ),

            SizedBox(height: 20),

            // 🔥 TITLE
            Text(
              "Lupa Kata Sandi?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            // 🔥 DESKRIPSI
            Text(
              "Jangan khawatir! Masukkan email SSO Anda untuk menerima instruksi reset kata sandi.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            SizedBox(height: 30),

            // 🔥 EMAIL
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Email SSO"),
            ),

            SizedBox(height: 8),

            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "Masukkan email SSO Anda",
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),

            SizedBox(height: 25),

            // 🔥 BUTTON KIRIM
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleKirim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3D5AF1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "KIRIM",
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
    );
  }
}