import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:younifirst_app/services/event_api_service.dart';
import 'package:younifirst_app/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:younifirst_app/pages/announcement/Announcement_pages.dart';
import 'package:younifirst_app/services/announcement_api_service.dart';

class TambahEventPage extends StatefulWidget {
  @override
  _TambahEventPageState createState() => _TambahEventPageState();
}

class _TambahEventPageState extends State<TambahEventPage> {
  String _selectedCategory = '';
  final List<String> _categories = [
    'Kompetisi', 'Seminar', 'Pameran',
    'Turnamen', 'Konser'
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateStartController = TextEditingController();
  final TextEditingController _timeStartController = TextEditingController();
  final TextEditingController _dateEndController = TextEditingController();
  final TextEditingController _timeEndController = TextEditingController();

  bool _isLoading = false;
  String? _userId; // Untuk menyimpan ID user (String, misal: USRBSEW4XN)

  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? idFromPrefs = prefs.getString('user_id');

    // Fallback: ambil dari AuthService jika SharedPreferences kosong
    String? idFromMemory = AuthService.userId;

    setState(() {
      _userId = idFromPrefs ?? idFromMemory;
    });

    // Debug
    print('🔍 user_id dari SharedPrefs: $idFromPrefs');
    print('🔍 user_id dari AuthService: $idFromMemory');
    print('✅ _userId yang dipakai: $_userId');
  }

  Future<void> _pickPoster() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _selectedImageBytes = bytes);
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _dateStartController.dispose();
    _timeStartController.dispose();
    _dateEndController.dispose();
    _timeEndController.dispose();
    super.dispose();
  }

  Future<void> _submitEvent() async {
    // Validasi form
    if (_titleController.text.isEmpty) {
      _showSnackBar('Harap isi judul event');
      return;
    }
    
    if (_locationController.text.isEmpty) {
      _showSnackBar('Harap isi lokasi event');
      return;
    }
    
    if (_selectedCategory.isEmpty) {
      _showSnackBar('Harap pilih kategori event');
      return;
    }
    
    if (_dateStartController.text.isEmpty) {
      _showSnackBar('Harap pilih tanggal mulai');
      return;
    }
    
    if (_timeStartController.text.isEmpty) {
      _showSnackBar('Harap pilih waktu mulai');
      return;
    }
    
    if (_dateEndController.text.isEmpty) {
      _showSnackBar('Harap pilih tanggal selesai');
      return;
    }
    
    if (_timeEndController.text.isEmpty) {
      _showSnackBar('Harap pilih waktu selesai');
      return; 
    }

    if (_userId == null) {
      _showSnackBar('User ID Anda kosong. Mohon logout, lalu login kembali agar ID tersimpan.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Format datetime
      final startDateTime = "${_dateStartController.text} ${_timeStartController.text}:00";
      final endDateTime = "${_dateEndController.text} ${_timeEndController.text}:00";

      // Validasi agar tanggal selesai tidak lebih awal dari tanggal mulai
      try {
        DateTime start = DateTime.parse(startDateTime);
        DateTime end = DateTime.parse(endDateTime);
        if (end.isBefore(start)) {
          setState(() => _isLoading = false);
          _showSnackBar("Tanggal dan Waktu Selesai tidak boleh lebih awal dari Tanggal Mulai!");
          return;
        }
      } catch (e) {
        print("Gagal parsing date untuk validasi: $e");
      }

      // Mapping kategori ke ID
      final Map<String, String> categoryMapping = {
        'Kompetisi': '1',
        'Seminar': '2',
        'Pameran': '3',
        'Turnamen': '4',
        'Konser': '5',
      };

      // ✅ Data lengkap dengan created_by
      final Map<String, String> data = {
        'title': _titleController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'category_id': categoryMapping[_selectedCategory] ?? '1',
        'start_date': startDateTime,
        'end_date': endDateTime,
        'created_by': _userId.toString(), // ✅ Mengirim ID secara benar
      };

      // Debug: Lihat data yang dikirim
      print('========================================');
      print('📤 DATA YANG DIKIRIM:');
      print(data);
      print('📸 IMAGE: ${_selectedImageBytes != null ? "ADA (${_selectedImageBytes!.length} bytes)" : "TIDAK ADA"}');
      print('========================================');

      // Panggil API
      final success = await EventApiService.createEvent(data, _selectedImageBytes);
      
      if (success) {
        // Buat notifikasi/pengumuman sementara di backend (karena backend belum punya tabel notif khusus)
        try {
          await AnnouncementApiService.createAnnouncement(
            title: 'Pengajuan Event: ${_titleController.text}',
            content: 'Event Anda sedang ditinjau oleh admin.',
            category: 'event',
            createdBy: _userId ?? '',
          );
        } catch (e) {
          print('Gagal membuat notifikasi otomatis: $e');
        }

        if (mounted) {
          // Tampilkan custom pop-up dialog sesuai desain (Gambar 1)
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
                      // Menggunakan icon centang besar sebagai pengganti ilustrasi
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F3FF),
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
                        'Pengajuan Event Berhasil\nDikirim',
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
                        'Event Anda telah berhasil dikirim dan sedang dalam proses peninjauan oleh admin. Event akan dipublikasikan setelah disetujui.',
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
        }
      }
      
    } catch (e) {
      print('❌ ERROR LENGKAP: $e');
      String errorMessage = e.toString();
      errorMessage = errorMessage.replaceAll('Exception: ', '');
      errorMessage = errorMessage.replaceAll('Gagal membuat event: ', '');
      _showSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Posting Event",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // POSTER EVENT
              const Text(
                "Poster Event",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickPoster,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedImageBytes == null 
                          ? Colors.blue.shade300 
                          : Colors.green.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: _selectedImageBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined, size: 40, color: Color(0xFF3D5AFE)),
                            const SizedBox(height: 12),
                            const Text(
                              "Tambahkan Poster Event",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Format jpg/jpeg/png",
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // JUDUL EVENT
              const Text(
                "Judul Event",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildTextField("Masukkan judul event...", controller: _titleController),

              const SizedBox(height: 24),

              // KATEGORI EVENT
              const Text(
                "Kategori Event",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                "(pilih salah satu kategori yang paling sesuai dengan event)",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _categories.map((cat) {
                  bool isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF3D5AFE) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // TANGGAL & WAKTU MULAI
              Row(
                children: const [
                  Icon(Icons.access_time, size: 16, color: Color(0xFF3D5AFE)),
                  SizedBox(width: 8),
                  Text(
                    "Tanggal dan Waktu Mulai",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDateTimePickerTextField("2024-01-01", Icons.calendar_today_outlined, controller: _dateStartController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateTimePickerTextField("14:30", Icons.access_time, controller: _timeStartController)),
                ],
              ),

              const SizedBox(height: 24),

              // TANGGAL & WAKTU SELESAI
              Row(
                children: const [
                  Icon(Icons.access_time, size: 16, color: Color(0xFF3D5AFE)),
                  SizedBox(width: 8),
                  Text(
                    "Tanggal dan Waktu Selesai",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDateTimePickerTextField("2024-01-01", Icons.calendar_today_outlined, controller: _dateEndController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateTimePickerTextField("18:00", Icons.access_time, controller: _timeEndController)),
                ],
              ),

              const SizedBox(height: 24),

              // LOKASI EVENT
              Row(
                children: const [
                  Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF3D5AFE)),
                  SizedBox(width: 8),
                  Text(
                    "Lokasi Event",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  )
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField("Masukkan lokasi event", controller: _locationController),

              const SizedBox(height: 24),

              // DESKRIPSI
              const Text(
                "Deskripsi",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: "Jelaskan detail event...",
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3D5AFE), width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // POSTING BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5AFE),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "POSTING",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // INFO BANNER
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9E2F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_document, color: Color(0xFFB5701B), size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Submission event akan ditinjau oleh admin sebelum dipublikasikan.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, {TextEditingController? controller}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3D5AFE), width: 2),
        ),
      ),
    );
  }

  Widget _buildDateTimePickerTextField(String hint, IconData icon, {required TextEditingController controller}) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        if (icon == Icons.calendar_today_outlined) {
          await _selectDate(controller);
        } else {
          await _selectTime(controller);
        }
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        suffixIcon: Icon(icon, size: 20, color: const Color(0xFF3D5AFE)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3D5AFE), width: 2),
        ),
      ),
    );
  }
}