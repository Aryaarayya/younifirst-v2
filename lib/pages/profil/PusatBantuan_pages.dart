import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PusatBantuanPage extends StatelessWidget {
  final String _whatsappNumber = "6285812749419"; // Format internasional tanpa '+' atau '0' di depan '8'

  Future<void> _launchWhatsApp() async {
    final String message = "Halo Younifirst Support, saya butuh bantuan...";
    final Uri url = Uri.parse("https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent(message)}");
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
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
          'Pusat Bantuan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Cari bantuan...",
                  border: InputBorder.none,
                ),
              ),
            ),
            
            SizedBox(height: 32),
            
            Text(
              "Kategori Populer",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                buildCategoryCard(Icons.account_circle_outlined, "Akun"),
                SizedBox(width: 12),
                buildCategoryCard(Icons.payment_outlined, "Pembayaran"),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                buildCategoryCard(Icons.security, "Keamanan"),
                SizedBox(width: 12),
                buildCategoryCard(Icons.info_outline, "Lainnya"),
              ],
            ),
            
            SizedBox(height: 32),
            
            Text(
              "FAQ",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            buildFaqItem(
              "Bagaimana cara melaporkan barang hilang?",
              "Anda dapat pergi ke tab 'Barang' lalu klik tombol 'Lapor Barang Hilang'. Isi formulir dengan lengkap beserta foto barang jika ada.",
            ),
            buildFaqItem(
              "Berapa lama verifikasi akun berlangsung?",
              "Proses verifikasi akun biasanya memakan waktu 1-2 hari kerja setelah pendaftaran dilakukan.",
            ),
            buildFaqItem(
              "Bagaimana cara mengubah alamat email?",
              "Anda dapat mengubah alamat email melalui menu 'Edit Profil' di halaman Profil Saya.",
            ),
            buildFaqItem(
              "Apakah data saya aman di Younifirst?",
              "Tentu saja. Kami menggunakan enkripsi standar industri untuk melindungi semua data pribadi dan aktivitas pengguna kami.",
            ),
            
            SizedBox(height: 40),
            
            // Contact Support
            GestureDetector(
              onTap: _launchWhatsApp,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF3D5AF1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF3D5AF1).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.headset_mic_outlined, color: Colors.white, size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Butuh bantuan lebih lanjut?",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            "Hubungi admin via WhatsApp",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget buildCategoryCard(IconData icon, String title) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFF1F1F1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Color(0xFF3D5AF1), size: 30),
            SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget buildFaqItem(String question, String answer) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          children: [
            Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(
                answer,
                style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}