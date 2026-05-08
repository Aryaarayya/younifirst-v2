import 'package:flutter/material.dart';

class PengaturanPage extends StatelessWidget {
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
          'Pengaturan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          buildSettingsItem(
            Icons.language,
            "Bahasa",
            "Bahasa Indonesia",
            () {},
          ),
          buildSettingsItem(
            Icons.dark_mode_outlined,
            "Tema",
            "Mode Terang",
            () {},
          ),
          buildSettingsItem(
            Icons.storage_outlined,
            "Penyimpanan",
            "124 MB digunakan",
            () {},
          ),
          
          SizedBox(height: 32),
          
          Text(
            "INFO APLIKASI",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 16),
          
          buildSettingsItem(
            Icons.info_outline,
            "Versi Aplikasi",
            "v2.0.4-stable",
            null,
          ),
          buildSettingsItem(
            Icons.description_outlined,
            "Syarat dan Ketentuan",
            "",
            () {},
          ),
          buildSettingsItem(
            Icons.privacy_tip_outlined,
            "Kebijakan Privasi",
            "",
            () {},
          ),
        ],
      ),
    );
  }

  Widget buildSettingsItem(IconData icon, String title, String value, VoidCallback? onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
