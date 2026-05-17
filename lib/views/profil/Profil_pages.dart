import 'package:flutter/material.dart';
import 'package:younifirst_app/services/api/lostandfound_api_service.dart';
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:younifirst_app/views/Login_pages.dart';
import 'package:younifirst_app/views/profil/EditProfil_pages.dart';
import 'package:younifirst_app/views/profil/Notifikasi_pages.dart';
import 'package:younifirst_app/views/profil/Keamanan_pages.dart';
import 'package:younifirst_app/views/profil/Pengaturan_pages.dart';
import 'package:younifirst_app/views/profil/PusatBantuan_pages.dart';
import 'package:provider/provider.dart';
import 'package:younifirst_app/viewmodels/profil_viewmodel.dart';

class ProfilPage extends StatefulWidget {
  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfilViewModel>().fetchUserData();
    });
  }

  void _handleLogout() async {
    await context.read<ProfilViewModel>().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Login_pages()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfilViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return Scaffold(
            backgroundColor: Color(0xFFF3F4F6),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final _userData = viewModel.userData;
        final name = _userData?['name'] ?? 'User';
        final email = _userData?['email'] ?? 'No Email';
        final nim = _userData?['nim'] ?? '-';
        final prodi = _userData?['prodi'] ?? '-';
        final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
        
        // Parse Angkatan and Bergabung
        String angkatan = '-';
        if (nim.length >= 5) {
          angkatan = '20${nim.substring(3, 5)}';
        }
        
        String bergabung = '-';
        if (_userData?['created_at'] != null) {
          try {
            DateTime dt = DateTime.parse(_userData!['created_at']);
            List<String> months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
            bergabung = '${months[dt.month - 1]} ${dt.year}';
          } catch (_) {}
        }

        return Scaffold(
          backgroundColor: Color(0xFFF3F4F6),
          body: Stack(
            children: [
              // Blue background at the top
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Color(0xFF3D5AF1),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.school_outlined, color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Text(
                                "Profil",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.notifications_none, color: Colors.white, size: 24),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Color(0xFF3D5AF1), width: 2),
                                  ),
                                  child: Text(
                                    "2",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Column(
                          children: [
                            // CARD PROFILE
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  )
                                ],
                              ),
                              child: Column(
                                children: [
                                  // AVATAR
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: (_userData?['photo'] == null || _userData!['photo'].toString().isEmpty)
                                          ? LinearGradient(
                                              colors: [Colors.cyan.shade300, Colors.purple.shade400],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      image: (_userData?['photo'] != null && _userData!['photo'].toString().isNotEmpty)
                                          ? DecorationImage(
                                              image: NetworkImage('${LostFoundApiService.getFullUrl(_userData!['photo'])}?v=${DateTime.now().millisecondsSinceEpoch}'),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: (_userData?['photo'] == null || _userData!['photo'].toString().isEmpty)
                                        ? Center(
                                            child: Text(
                                              initials,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),

                                  SizedBox(height: 20),

                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  SizedBox(height: 6),

                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 15,
                                    ),
                                  ),

                                  SizedBox(height: 24),

                                  // INFO GRID (2x2)
                                  Row(
                                    children: [
                                      infoBox("NIM", nim),
                                      SizedBox(width: 12),
                                      infoBox("Program Studi", prodi),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      infoBox("Angkatan", angkatan),
                                      SizedBox(width: 12),
                                      infoBox("Bergabung", bergabung),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 24),

                            // MENU LIST
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  )
                                ],
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: 8),
                                  menuItem(Icons.edit_outlined, "Edit Profil", () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilPage(userData: _userData!))).then((_) => viewModel.fetchUserData());
                                  }),
                                  menuItem(Icons.feed_outlined, "Postingan Anda", () {
                                    // TODO: Implement navigasi Postingan Anda
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
                                  SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                    child: Divider(height: 1, color: Colors.grey[200]),
                                  ),
                                  SizedBox(height: 8),
                                  menuItem(Icons.logout, "Keluar", _handleLogout, isLogout: true),
                                  SizedBox(height: 8),
                                ],
                              ),
                            ),
                            SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget infoBox(String title, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget menuItem(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : Colors.grey[700],
        size: 26,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isLogout ? Colors.red : Colors.black87,
        ),
      ),
      trailing: isLogout ? null : Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
      onTap: onTap,
    );
  }
}
