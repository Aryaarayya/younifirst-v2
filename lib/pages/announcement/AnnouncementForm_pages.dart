import 'package:flutter/material.dart';
import 'package:younifirst_app/models/Announcement_model.dart';
import 'package:younifirst_app/services/announcement_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:younifirst_app/services/auth_service.dart';

class AnnouncementFormPage extends StatefulWidget {
  final AnnouncementModel? existing; // null = tambah, ada data = edit

  const AnnouncementFormPage({Key? key, this.existing}) : super(key: key);

  @override
  State<AnnouncementFormPage> createState() => _AnnouncementFormPageState();
}

class _AnnouncementFormPageState extends State<AnnouncementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  String _selectedCategory = 'umum';
  bool _isLoading = false;

  final List<Map<String, String>> _categories = [
    {'value': 'umum', 'label': 'Umum'},
    {'value': 'event', 'label': 'Event'},
    {'value': 'team', 'label': 'Team'},
    {'value': 'barang', 'label': 'Barang'},
  ];

  bool get _isEdit => widget.existing != null;
  String? _userId;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _titleCtrl.text = widget.existing!.title;
      _contentCtrl.text = widget.existing!.content;
      _selectedCategory = widget.existing!.category ?? 'umum';
    }
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id') ?? AuthService.userId;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      bool ok;
      if (_isEdit) {
        ok = await AnnouncementApiService.updateAnnouncement(
          id: widget.existing!.id,
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          category: _selectedCategory,
        );
      } else {
        ok = await AnnouncementApiService.createAnnouncement(
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          category: _selectedCategory,
          createdBy: _userId ?? '',
        );
      }

      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit
              ? 'Pengumuman berhasil diperbarui'
              : 'Pengumuman berhasil dikirim, menunggu konfirmasi admin'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5AFE),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEdit ? 'Edit Pengumuman' : 'Buat Pengumuman',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Info box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3D5AFE).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Color(0xFF3D5AFE), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pengumuman yang dikirim akan muncul setelah dikonfirmasi oleh admin.',
                      style: TextStyle(
                        color: Color(0xFF3D5AFE),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Kategori
            const Text(
              'Kategori',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  borderRadius: BorderRadius.circular(12),
                  items: _categories
                      .map((cat) => DropdownMenuItem(
                            value: cat['value'],
                            child: Row(
                              children: [
                                Icon(_categoryIcon(cat['value']!),
                                    color: _categoryColor(cat['value']!), size: 18),
                                const SizedBox(width: 10),
                                Text(cat['label']!),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Judul
            const Text(
              'Judul Pengumuman',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'Masukkan judul pengumuman...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 20),

            // Isi
            const Text(
              'Isi Pengumuman',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contentCtrl,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Tulis isi pengumuman di sini...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Isi pengumuman wajib diisi' : null,
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D5AFE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Text(
                        _isEdit ? 'Simpan Perubahan' : 'Kirim Pengumuman',
                        style: const TextStyle(
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

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'event': return Icons.calendar_today;
      case 'team': return Icons.group;
      case 'barang': return Icons.inventory_2_outlined;
      default: return Icons.campaign_outlined;
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'event': return Colors.orange;
      case 'team': return Colors.green;
      case 'barang': return Colors.purple;
      default: return const Color(0xFF3D5AFE);
    }
  }
}