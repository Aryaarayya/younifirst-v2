import 'package:flutter/material.dart';

class NotifikasiPage extends StatefulWidget {
  @override
  _NotifikasiPageState createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _lostFoundAlerts = true;
  bool _eventReminders = true;

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
          'Pengaturan Notifikasi',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          sectionHeader("Umum"),
          buildSwitchTile(
            "Notifikasi Push",
            "Terima pemberitahuan langsung di perangkat Anda",
            _pushNotifications,
            (val) => setState(() => _pushNotifications = val),
          ),
          buildSwitchTile(
            "Notifikasi Email",
            "Terima ringkasan aktivitas melalui email",
            _emailNotifications,
            (val) => setState(() => _emailNotifications = val),
          ),
          
          SizedBox(height: 32),
          
          sectionHeader("Aktivitas"),
          buildSwitchTile(
            "Alert Barang Hilang",
            "Dapatkan info jika ada barang hilang/temuan baru",
            _lostFoundAlerts,
            (val) => setState(() => _lostFoundAlerts = val),
          ),
          buildSwitchTile(
            "Pengingat Event",
            "Notifikasi 1 jam sebelum event dimulai",
            _eventReminders,
            (val) => setState(() => _eventReminders = val),
          ),
        ],
      ),
    );
  }

  Widget sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: Color(0xFF3D5AF1),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}