import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:younifirst_app/services/api/lostandfound_api_service.dart';
import 'package:younifirst_app/services/input/notification_service.dart';
import 'package:younifirst_app/utils/profanity_filter.dart';

class BarangHilangPage extends StatefulWidget {
  @override
  _BarangHilangPageState createState() => _BarangHilangPageState();
}

class _BarangHilangPageState extends State<BarangHilangPage> {
  String _selectedKategori = 'Hilang'; // default
  File? _imageFile;
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Pilih Sumber Gambar",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: "Kamera",
                  onTap: () {
                    Navigator.pop(context);
                    _handleImagePick(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.image_rounded,
                  label: "Galeri",
                  onTap: () {
                    Navigator.pop(context);
                    _handleImagePick(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImagePick(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Reduce size for better upload performance
      );
      
      if (!mounted) return;

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil gambar: $e')),
      );
    }
  }

  Widget _buildSourceOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF3D5AFE)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Future<void> _submitData() async {
    if (_namaBarangController.text.isEmpty || _lokasiController.text.isEmpty || _deskripsiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi semua data wajib')));
      return;
    }

    if (_selectedKategori == 'Ditemukan' && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap tambahkan gambar barang temuan')));
      return;
    }

    // ── PROFANITY FILTER CHECK ──
    List<String> badWordsInName = ProfanityFilter.check(_namaBarangController.text);
    List<String> badWordsInDesc = ProfanityFilter.check(_deskripsiController.text);
    List<String> badWordsInLoc = ProfanityFilter.check(_lokasiController.text);

    if (badWordsInName.isNotEmpty || badWordsInDesc.isNotEmpty || badWordsInLoc.isNotEmpty) {
      Set<String> allBadWords = {...badWordsInName, ...badWordsInDesc, ...badWordsInLoc};
      _showProfanityWarning(allBadWords.toList());
      return;
    }
    // ────────────────────────────

    setState(() {
      _isLoading = true;
    });

    try {
      String? resultId = await LostFoundApiService.addLostAndFound(
        type: _selectedKategori,
        itemName: _namaBarangController.text,
        location: _lokasiController.text,
        description: _deskripsiController.text,
        imageFile: _imageFile,
      );

      if (resultId != null) {
        // Tambahkan ke notifikasi lokal
        await NotificationService.addNotification(
          'Postingan Berhasil', 
          'Barang "${_namaBarangController.text}" telah berhasil diposting di Lost & Found.',
          type: 'post',
          targetId: resultId,
        );

        setState(() {
          _isLoading = false;
        });

        // Tampilkan feedback elegan
        await _showSuccessFeedback(_imageFile);
        
        if (mounted) {
          Navigator.pop(context, true); // return true to refresh list
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memposting: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showProfanityWarning(List<String> detectedWords) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            const Text("Peringatan Konten", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Postingan Anda mengandung kata-kata yang tidak pantas atau dilarang:",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Text(
                detectedWords.join(", "),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Mohon revisi kata-kata tersebut agar tetap sopan dan mematuhi standar komunitas kami sebelum memposting.",
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("SAYA MENGERTI", style: TextStyle(color: Color(0xFF3D5AFE), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).iconTheme.color ?? Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Posting Lost and Found",
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // ... (isi kolom sama)
              // Kategori
              const Text("Kategori Lost and Found", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                "(pilih salah satu kategori lost and found, apakah barang hilang atau ditemukan)",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildCategoryButton('Hilang'),
                  const SizedBox(width: 12),
                  _buildCategoryButton('Ditemukan'),
                ],
              ),
              const SizedBox(height: 24),

              // Gambar barang
              Row(
                children: [
                  const Text("Gambar barang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 4),
                  if (_selectedKategori == 'Hilang')
                    Text("(opsional)", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: CustomPaint(
                  painter: DashedRectPainter(color: Colors.blue.shade300, strokeWidth: 1, gap: 5.0),
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF), // light blue bg
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.image_outlined, size: 36, color: Color(0xFF3D5AFE)),
                              const SizedBox(height: 8),
                              const Text("Tambahkan Gambar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text("Format jpg/jpeg/png, Maks 2 GB", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Nama Barang
              const Text("Nama Barang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _namaBarangController,
                hint: "Masukkan nama barang...",
              ),
              const SizedBox(height: 24),

              // Lokasi Terakhir
              Row(
                children: const [
                  Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF3D5AFE)),
                  SizedBox(width: 4),
                  Text("Lokasi Terakhir", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _lokasiController,
                hint: "Masukkan lokasi barang hilang...",
              ),
              const SizedBox(height: 24),

              // Deskripsi
              const Text("Deksripsi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Stack(
                children: [
                  _buildTextField(
                    controller: _deskripsiController,
                    hint: "Ciri-ciri barang, kondisi, dll...",
                    maxLines: 6,
                    maxLength: 500,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // POSTING BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5AFE),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading 
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "POSTING",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      if (_isLoading)
        Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3D5AFE)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Menyebarkan informasi...",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Mohon tunggu sebentar",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  ),
);
  }

  Future<void> _showSuccessFeedback(File? imageFile) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageFile != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        imageFile,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
                  ),
                const Text(
                  "Berhasil Diposting!",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  "Barang Anda telah berhasil didaftarkan ke dalam sistem. Mahasiswa lain sekarang dapat melihat informasi ini.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D5AFE),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("LIHAT POSTINGAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    bool isSelected = _selectedKategori == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedKategori = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3D5AFE) : Colors.grey.shade200,
           borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black87, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3D5AFE), width: 1.5),
        ),
        counterText: maxLength != null ? null : '', // default show counter if maxLength is set
      ),
      onChanged: (val) {
        if (maxLength != null) {
          setState(() {}); // to update counter inside the textfield if needed
        }
      },
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // draw a round rect with dashed line manually
    RRect rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8));
    
    Path extractPath = Path()..addRRect(rrect);
    PathMetrics pathMetrics = extractPath.computeMetrics();
    Path dashedPath = Path();

    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < pathMetric.length) {
        double len = gap;
        if (distance + len > pathMetric.length) {
          len = pathMetric.length - distance;
        }
        if (draw) {
          dashedPath.addPath(pathMetric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
