import 'package:flutter/material.dart';
import 'package:younifirst_app/services/team_api_service.dart';
import 'package:younifirst_app/services/auth_service.dart';
import 'package:younifirst_app/pages/announcement/Announcement_pages.dart';
import 'package:younifirst_app/services/announcement_api_service.dart';

class TambahTeamsPage extends StatefulWidget {
  @override
  _TambahTeamsPageState createState() => _TambahTeamsPageState();
}

class _TambahTeamsPageState extends State<TambahTeamsPage> {

  final _namaTimController = TextEditingController();
  final _namaLombaController = TextEditingController();
  final _maxAnggotaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _namaTimController.dispose();
    _namaLombaController.dispose();
    _maxAnggotaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _submitTeam() async {
    if (_namaTimController.text.isEmpty || _namaLombaController.text.isEmpty || 
        _maxAnggotaController.text.isEmpty || _deskripsiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap isi semua kolom!')));
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'team_name': _namaTimController.text,
      'competition_name': _namaLombaController.text,
      'max_member': int.tryParse(_maxAnggotaController.text) ?? 1,
      'description': _deskripsiController.text,
    };

    try {
      await TeamApiService.createTeam(data);

      // Buat announcement otomatis seperti halaman event
      try {
        await AnnouncementApiService.createAnnouncement(
          title: 'Pengajuan Tim: ${_namaTimController.text}',
          content: 'Tim Anda sedang ditinjau oleh admin.',
          category: 'team',
          createdBy: AuthService.loggedInUserId ?? '',
        );
      } catch (_) {}

      if (!mounted) return;

      // Tampilkan dialog sukses, lalu arahkan ke AnnouncementPage
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F3FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Color(0xFF3D5AFE),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Pengajuan Tim Berhasil\nDikirim',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tim Anda telah berhasil dikirim dan sedang dalam proses peninjauan oleh admin. Tim akan dipublikasikan setelah disetujui.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D5AFE),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext); // Tutup dialog
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const AnnouncementPage()),
                        );
                      },
                      child: const Text(
                        'Mengerti',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Buat Tim", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Nama Tim"),
            const SizedBox(height: 8),
            _buildTextField("Masukkan nama tim", _namaTimController),
            const SizedBox(height: 20),
            
            _buildLabel("Nama Lomba"),
            const SizedBox(height: 8),
            _buildTextField("Contoh ; GEMASTIK 2026", _namaLombaController),
            const SizedBox(height: 20),

            _buildLabel("Max Anggota"),
            const SizedBox(height: 8),
            _buildTextField("0", _maxAnggotaController, keyboardType: TextInputType.number),
            const SizedBox(height: 20),

            _buildLabel("Deksripsi"), // Using spelling from UI design
            const SizedBox(height: 8),
            _buildMultilineTextField(
              "Masukkan deskripsi tim, peran yang dibutuhkan,\nserta kualifikasi atau keterampilan yang\ndiharapkan dari calon anggota.",
              _deskripsiController
            ),
            const SizedBox(height: 30),

            // BUAT button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitTeam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5BFE), // darker blue like in image
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                  "BUAT",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // Info Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FE), // light blue background
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(6),
                     decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle
                     ),
                     child: const Icon(Icons.edit_document, color: Colors.orange, size: 16),
                   ),
                   const SizedBox(width: 12),
                   const Expanded(
                     child: Text(
                        "Submission tim akan ditinjau oleh admin sebelum dipublikasikan",
                        style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                     ),
                   )
                ],
              )
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.6))
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.6))
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3D5AFE), width: 1.5)
        ),
      ),
    );
  }

  Widget _buildMultilineTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      maxLines: 8,
      maxLength: 500,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.6))
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.6))
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3D5AFE), width: 1.5)
        ),
      ),
    );
  }
}