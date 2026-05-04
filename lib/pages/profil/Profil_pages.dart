import 'package:flutter/material.dart';
import 'package:younifirst_app/services/lostandfound_api_service.dart';
import 'package:younifirst_app/services/auth_service.dart';
import 'package:younifirst_app/pages/Login_pages.dart';
import 'package:younifirst_app/pages/profil/EditProfil_pages.dart';
import 'package:younifirst_app/pages/profil/Notifikasi_pages.dart';
import 'package:younifirst_app/pages/profil/Keamanan_pages.dart';
import 'package:younifirst_app/pages/profil/Pengaturan_pages.dart';
import 'package:younifirst_app/pages/profil/PusatBantuan_pages.dart';

class ProfilPage extends StatefulWidget {
  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final data = await ApiService.getCurrentUser();
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error fetching user data: $e");
    }
  }

  void _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Login_pages()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = _userData?['name'] ?? 'User';
    final email = _userData?['email'] ?? 'No Email';
    final nim = _userData?['nim'] ?? '-';
    final prodi = _userData?['prodi'] ?? '-';
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // 🔵 HEADER
                profileHeader(),

                SizedBox(height: 32),

                // 🔵 CARD PROFILE
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // AVATAR
                      Stack(
                        children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFF3D5AF1),
                        backgroundImage: _userData?['photo'] != null
                            ? NetworkImage(ApiService.getFullUrl(_userData!['photo']))
                            : null,
                        child: _userData?['photo'] == null
                            ? Text(
                                initials,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.verified, color: Colors.blue, size: 24),
                            ),
                          )
                        ],
                      ),

                      SizedBox(height: 16),

                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),

                      SizedBox(height: 24),

                      // 🔵 INFO GRID
                      Row(
                        children: [
                          infoBox("NIM", nim),
                          SizedBox(width: 12),
                          infoBox("Program Studi", prodi),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // 🔵 MENU LIST
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      menuItem(Icons.person_outline, "Edit Profil", () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilPage(userData: _userData!))).then((_) => _fetchUserData());
                      }),
                      menuItem(Icons.notifications_none, "Pengaturan Notifikasi", () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => NotifikasiPage()));
                      }),
                      menuItem(Icons.security_outlined, "Keamanan Akun", () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => KeamananPage()));
                      }),
                      menuItem(Icons.settings_outlined, "Pengaturan", () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PengaturanPage()));
                      }),
                      menuItem(Icons.help_outline, "Pusat Bantuan", () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PusatBantuanPage()));
                      }),
                      Divider(height: 1, indent: 20, endIndent: 20),
                      menuItem(Icons.logout, "Keluar", _handleLogout, isLogout: true),
                    ],
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget profileHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Profil Saya",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.notifications_none, size: 24),
        )
      ],
    );
  }

  Widget infoBox(String title, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget menuItem(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLogout ? Colors.red.withValues(alpha: 0.1) : Color(0xFF3D5AF1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isLogout ? Colors.red : Color(0xFF3D5AF1), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red : Colors.black87,
        ),
      ),
      trailing: isLogout ? null : Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}