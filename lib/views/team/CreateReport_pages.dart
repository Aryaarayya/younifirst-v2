import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:younifirst_app/models/Teams_model.dart';
import 'package:younifirst_app/services/api/team_api_service.dart';

class CreateReportPage extends StatefulWidget {
  final TeamModel team;

  const CreateReportPage({Key? key, required this.team}) : super(key: key);

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  int _currentStep = 1;

  final TextEditingController _lombaController = TextEditingController();
  final TextEditingController _timController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  String _tingkatLomba = '';
  String _tingkatJuara = 'Juara 1';

  final List<String> tingkatLombaOptions = ['Internasional', 'Nasional', 'Regional', 'Kampus'];
  final List<String> tingkatJuaraOptions = ['Juara 1', 'Juara 2', 'Juara 3', 'Harapan 1', 'Harapan 2', 'Harapan 3', 'Finalis'];

  bool _isSubmitting = false;

  // Multi-file support
  final List<PlatformFile> _buktiMenangFiles = [];
  final List<PlatformFile> _dokumentasiFiles = [];

  @override
  void initState() {
    super.initState();
    _lombaController.text = widget.team.lombaName;
    _timController.text = widget.team.name;
  }

  @override
  void dispose() {
    _lombaController.dispose();
    _timController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_tingkatLomba.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tingkat lomba terlebih dahulu')),
      );
      return;
    }
    if (_deskripsiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deskripsi tidak boleh kosong')),
      );
      return;
    }
    setState(() {
      _currentStep = 2;
    });
  }

  Future<void> _pickBuktiMenang() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        // Tambahkan file baru, hindari duplikat berdasarkan nama
        for (final f in result.files) {
          if (!_buktiMenangFiles.any((e) => e.name == f.name)) {
            _buktiMenangFiles.add(f);
          }
        }
      });
    }
  }

  Future<void> _pickDokumentasi() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (final f in result.files) {
          if (!_dokumentasiFiles.any((e) => e.name == f.name)) {
            _dokumentasiFiles.add(f);
          }
        }
      });
    }
  }

  void _submitReport() async {
    if (_buktiMenangFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap upload minimal 1 Bukti Menang')),
      );
      return;
    }
    if (_dokumentasiFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap upload minimal 1 Dokumentasi Kegiatan')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'competition_level': _tingkatLomba.toLowerCase(),
        'achievement_rank': _tingkatJuara,
        'description': _deskripsiController.text,
      };

      bool success = await TeamApiService.submitReport(
        widget.team.id,
        payload,
        _buktiMenangFiles,
        _dokumentasiFiles,
      );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan berhasil dibuat!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat laporan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: Theme.of(context).textTheme.bodyLarge?.color, size: 20),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Buat Laporan Juara',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Stepper Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _currentStep >= 1
                              ? const Color(0xFF3D5AFE)
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('1',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Informasi Kompetisi',
                        style: TextStyle(
                          color: _currentStep >= 1
                              ? const Color(0xFF3D5AFE)
                              : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentStep >= 2
                        ? const Color(0xFF3D5AFE)
                        : Colors.blue.shade100,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _currentStep >= 2
                              ? const Color(0xFF3D5AFE)
                              : Theme.of(context).cardColor,
                          border: Border.all(
                            color: const Color(0xFF3D5AFE),
                            width: 1.5,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '2',
                            style: TextStyle(
                              color: _currentStep >= 2
                                  ? Colors.white
                                  : const Color(0xFF3D5AFE),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload Bukti',
                        style: TextStyle(
                          color: const Color(0xFF3D5AFE),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade200, height: 1),

          // Form Content
          Expanded(
            child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
          ),
        ],
      ),
    );
  }

  // ─── STEP 1 ───────────────────────────────────────────────────────────────
  Widget _buildStep1() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nama Lomba
          const Text('Nama Lomba',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            controller: _lombaController,
            readOnly: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF3F6FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Nama Tim
          const Text('Nama Tim',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            controller: _timController,
            readOnly: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF3F6FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Anggota Tim
          const Text('Anggota Tim',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
            ),
            child: Column(
              children: List.generate(widget.team.memberNames.length, (index) {
                final memberName = widget.team.memberNames[index];
                String role = index == 0 ? 'Leader' : 'Member';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        child: Text(
                          memberName.isNotEmpty
                              ? memberName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              memberName + (role == 'Leader' ? ' (Anda)' : ''),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                            Text(role,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // Tingkat Lomba
          const Text('Tingkat Lomba',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('(pilih salah satu tingkat lomba yang sesuai)',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tingkatLombaOptions.map((tingkat) {
              final isSelected = _tingkatLomba == tingkat;
              return ChoiceChip(
                label: Text(
                  tingkat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF3D5AFE),
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                onSelected: (selected) {
                  setState(() {
                    _tingkatLomba = selected ? tingkat : '';
                  });
                },
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Tingkat Juara
          const Text('Tingkat Juara',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('(pilih hasil yang diperoleh tim)',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _tingkatJuara,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: tingkatJuaraOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _tingkatJuara = newValue;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Deskripsi Singkat
          const Text('Deskripsi Singkat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          TextField(
            controller: _deskripsiController,
            maxLines: 5,
            maxLength: 250,
            decoration: InputDecoration(
              hintText:
                  'Ceritakan hasil kompetisi dan kegiatan lomba secara singkat',
              hintStyle:
                  const TextStyle(color: Colors.grey, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
              ),
            ),
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D5AFE),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'SELANJUTNYA',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP 2 ───────────────────────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Bukti Menang ──────────────────────────────────────────────────
          _buildUploadSection(
            title: 'Bukti Menang',
            files: _buktiMenangFiles,
            onPick: _pickBuktiMenang,
            onRemove: (i) => setState(() => _buktiMenangFiles.removeAt(i)),
          ),
          const SizedBox(height: 28),

          // ── Dokumentasi Kegiatan ──────────────────────────────────────────
          _buildUploadSection(
            title: 'Dokumentasi Kegiatan',
            files: _dokumentasiFiles,
            onPick: _pickDokumentasi,
            onRemove: (i) => setState(() => _dokumentasiFiles.removeAt(i)),
          ),
          const SizedBox(height: 40),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D5AFE),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'KIRIM LAPORAN',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Upload Section Widget ────────────────────────────────────────────────
  Widget _buildUploadSection({
    required String title,
    required List<PlatformFile> files,
    required VoidCallback onPick,
    required void Function(int index) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        const Text('(Upload minimal 1 file)',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),

        // Upload Area
        GestureDetector(
          onTap: onPick,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF23253A) : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.shade200, width: 1.5),
            ),
            child: Column(
              children: [
                const Icon(Icons.add_photo_alternate_outlined,
                    color: Color(0xFF3D5AFE), size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Tambahkan Gambar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Format pdf/jpg/jpeg/png, Maks 2 GB',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ),

        // Daftar File Terlampir
        if (files.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'File Terlampir',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ...List.generate(files.length, (i) {
            final f = files[i];
            final isPdf = f.name.toLowerCase().endsWith('.pdf');
            final sizeStr = f.size > 0
                ? '${(f.size / (1024 * 1024)).toStringAsFixed(1)} MB'
                : '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  // Icon tipe file
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isPdf
                          ? (Theme.of(context).brightness == Brightness.dark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50)
                          : (Theme.of(context).brightness == Brightness.dark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_rounded,
                      color: isPdf ? Colors.red : Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nama & ukuran file
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (sizeStr.isNotEmpty)
                          Text(sizeStr,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  // Tombol hapus
                  GestureDetector(
                    onTap: () => onRemove(i),
                    child: Icon(Icons.close,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, size: 20),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
