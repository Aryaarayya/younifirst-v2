import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:younifirst_app/services/event_api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:younifirst_app/services/auth_service.dart';

class UpdateEventPage extends StatefulWidget {
  final String eventId;

  const UpdateEventPage({Key? key, required this.eventId}) : super(key: key);

  @override
  _UpdateEventPageState createState() => _UpdateEventPageState();
}

class _UpdateEventPageState extends State<UpdateEventPage> {
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
  bool _isFetchingDetail = true;
  String? _userId;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;

  final Map<String, String> categoryMapping = {
    'Kompetisi': '1',
    'Seminar': '2',
    'Pameran': '3',
    'Turnamen': '4',
    'Konser': '5',
  };

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchEventDetail();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? idFromPrefs = prefs.getString('user_id');
    String? idFromMemory = AuthService.userId;

    setState(() {
      _userId = idFromPrefs ?? idFromMemory;
    });
  }

  Future<void> _fetchEventDetail() async {
    try {
      final data = await EventApiService.getEventDetail(widget.eventId);
      
      // Mengisi form dengan data dari server
      setState(() {
        _titleController.text = data['title'] ?? '';
        _locationController.text = data['location'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        
        // Memetakan category_id ke nama kategori
        String categoryId = data['category_id']?.toString() ?? '1';
        _selectedCategory = categoryMapping.entries
            .firstWhere((entry) => entry.value == categoryId, orElse: () => categoryMapping.entries.first)
            .key;

        // Memecah start_date menjadi tanggal dan waktu
        if (data['start_date'] != null) {
          try {
            DateTime start = DateTime.parse(data['start_date']);
            _dateStartController.text = "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
            _timeStartController.text = "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";
          } catch (e) {
            print("Format start_date salah: $e");
          }
        }

        // Memecah end_date menjadi tanggal dan waktu
        if (data['end_date'] != null) {
          try {
            DateTime end = DateTime.parse(data['end_date']);
            _dateEndController.text = "${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}";
            _timeEndController.text = "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}";
          } catch (e) {
             print("Format end_date salah: $e");
          }
        }

        String rawImage = data['image_url'] ?? data['poster'] ?? ''; 
        if (rawImage.isNotEmpty && !rawImage.startsWith('http') && !rawImage.startsWith('assets/')) {
           String path = rawImage.startsWith('/') ? rawImage.substring(1) : rawImage;
           if (!path.startsWith('storage/')) path = 'storage/$path';
           _existingImageUrl = 'https://enlighten-resupply-usable.ngrok-free.dev/$path';
        } else {
           _existingImageUrl = rawImage;
        }
        _isFetchingDetail = false;
      });
    } catch (e) {
      print("Gagal mengambil detail event: $e");
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        _showSnackBar("Gagal: $msg");
        setState(() {
          _isFetchingDetail = false;
        });
      }
    }
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

  Future<void> _submitUpdate() async {
    if (_titleController.text.isEmpty || _locationController.text.isEmpty || 
        _selectedCategory.isEmpty || _dateStartController.text.isEmpty || 
        _timeStartController.text.isEmpty || _dateEndController.text.isEmpty || 
        _timeEndController.text.isEmpty) {
      _showSnackBar('Harap isi semua field wajib!');
      return;
    }

    if (_userId == null) {
      _showSnackBar('User ID tidak ditemukan. Mohon login kembali.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final startDateTime = "${_dateStartController.text} ${_timeStartController.text}:00";
      final endDateTime = "${_dateEndController.text} ${_timeEndController.text}:00";

      final Map<String, String> data = {
        'title': _titleController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'category_id': categoryMapping[_selectedCategory] ?? '1',
        'start_date': startDateTime,
        'end_date': endDateTime,
        'created_by': _userId ?? '', 
      };

      // Jika tidak ada gambar baru, kita TIDAK MENGIRIM field 'poster'.
      // Biarkan backend tetap menyimpan foto yang lama.

      final success = await EventApiService.updateEvent(widget.eventId, data, _selectedImageBytes);
      
      if (success) {
        _showSnackBar('Event berhasil diupdate!', isError: false);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true);
      }
      
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('Gagal mengupdate event: ', '');
      _showSnackBar(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          "Update Event",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: _isFetchingDetail 
        ? const Center(child: CircularProgressIndicator()) 
        : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    border: Border.all(color: Colors.blue.shade300, width: 1.5),
                  ),
                  child: _selectedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                        )
                      : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _existingImageUrl!.startsWith('http') 
                                ? Image.network(_existingImageUrl!, fit: BoxFit.cover)
                                : Image.asset('assets/images/Younifirst.png', fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate_outlined, size: 40, color: Color(0xFF3D5AFE)),
                                const SizedBox(height: 12),
                                const Text(
                                  "Ubah Poster Event",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                ),
                              ],
                            ),
                ),
              ),

              const SizedBox(height: 24),
              const Text("Judul Event", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              _buildTextField("Masukkan judul event...", controller: _titleController),

              const SizedBox(height: 24),
              const Text("Kategori Event", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
              Row(
                children: const [
                  Icon(Icons.access_time, size: 16, color: Color(0xFF3D5AFE)),
                  SizedBox(width: 8),
                  Text("Tanggal dan Waktu Mulai", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDateTimePickerTextField("Mulai Tgl", Icons.calendar_today_outlined, controller: _dateStartController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateTimePickerTextField("Waktu", Icons.access_time, controller: _timeStartController)),
                ],
              ),

              const SizedBox(height: 24),
              Row(
                children: const [
                  Icon(Icons.access_time, size: 16, color: Color(0xFF3D5AFE)),
                  SizedBox(width: 8),
                  Text("Tanggal dan Waktu Selesai", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDateTimePickerTextField("Selesai Tgl", Icons.calendar_today_outlined, controller: _dateEndController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateTimePickerTextField("Waktu", Icons.access_time, controller: _timeEndController)),
                ],
              ),

              const SizedBox(height: 24),
              Row(
                children: const [
                  Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF3D5AFE)),
                  SizedBox(width: 8),
                  Text("Lokasi Event", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField("Masukkan lokasi event", controller: _locationController),

              const SizedBox(height: 24),
              const Text("Deskripsi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: "Jelaskan detail event...",
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3D5AFE), width: 2)),
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5AFE),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("UPDATE EVENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3D5AFE), width: 2)),
      ),
    );
  }

  Widget _buildDateTimePickerTextField(String hint, IconData icon, {required TextEditingController controller}) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        if (icon == Icons.calendar_today_outlined) await _selectDate(controller);
        else await _selectTime(controller);
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        suffixIcon: Icon(icon, size: 20, color: const Color(0xFF3D5AFE)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3D5AFE), width: 2)),
      ),
    );
  }
}
