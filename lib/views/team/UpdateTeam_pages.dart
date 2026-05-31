import 'package:flutter/material.dart';
import 'package:younifirst_app/models/Teams_model.dart';
import 'package:younifirst_app/services/api/team_api_service.dart';

class UpdateTeamPage extends StatefulWidget {
  final TeamModel team;

  const UpdateTeamPage({Key? key, required this.team}) : super(key: key);

  @override
  _UpdateTeamPageState createState() => _UpdateTeamPageState();
}

class _UpdateTeamPageState extends State<UpdateTeamPage> {

  final _namaTimController = TextEditingController();
  final _namaLombaController = TextEditingController();
  final _maxAnggotaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaTimController.text = widget.team.name;
    _namaLombaController.text = widget.team.lombaName;
    _maxAnggotaController.text = widget.team.maxMembers.toString();
    _deskripsiController.text = widget.team.description;
  }

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
      await TeamApiService.updateTeam(widget.team.id, data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tim berhasil diperbarui')),
      );
      Navigator.pop(context, true); // Kembali ke halaman sebelumnya dengan hasil true
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).textTheme.bodyLarge?.color, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Edit Tim", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.w600)),
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

            _buildLabel("Deksripsi"), // Mengikuti ejaan asli di TambahTeams
            const SizedBox(height: 8),
            _buildMultilineTextField(
              "Masukkan deskripsi tim, peran yang dibutuhkan,\nserta kualifikasi atau keterampilan yang\ndiharapkan dari calon anggota.",
              _deskripsiController
            ),
            const SizedBox(height: 30),

            // SIMPAN button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitTeam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5BFE), // darker blue
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(
                  "SIMPAN",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.black.withValues(alpha: 0.6))
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.black.withValues(alpha: 0.6))
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3D5AFE), width: 1.5)
        ),
      ),
    );
  }

  Widget _buildMultilineTextField(String hint, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      maxLines: 8,
      maxLength: 500,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.black.withValues(alpha: 0.6))
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.black.withValues(alpha: 0.6))
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3D5AFE), width: 1.5)
        ),
      ),
    );
  }
}
