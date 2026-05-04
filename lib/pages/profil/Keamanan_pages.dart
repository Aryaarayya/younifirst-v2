import 'package:flutter/material.dart';

class KeamananPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Keamanan Akun',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield, color: Colors.blue, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Akun Terlindungi",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "Terakhir diperbarui 2 hari yang lalu",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            SizedBox(height: 32),
            
            buildSecurityItem(
              Icons.lock_outline,
              "Ganti Kata Sandi",
              "Ubah kata sandi Anda secara berkala",
              () {
                // Navigate to change password
              },
            ),
            buildSecurityItem(
              Icons.phonelink_setup_outlined,
              "Verifikasi Dua Langkah",
              "Lapisan keamanan tambahan",
              () {},
              trailing: Switch(value: true, onChanged: (v){}, activeThumbColor: Color(0xFF3D5AF1)),
            ),
            buildSecurityItem(
              Icons.devices_outlined,
              "Perangkat Terhubung",
              "Lihat di mana saja Anda login",
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSecurityItem(IconData icon, String title, String subtitle, VoidCallback onTap, {Widget? trailing}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Color(0xFF3D5AF1), size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
        trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
