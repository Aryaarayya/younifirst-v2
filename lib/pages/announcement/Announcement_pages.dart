import 'package:flutter/material.dart';
import 'package:younifirst_app/models/Announcement_model.dart';
import 'package:younifirst_app/services/announcement_api_service.dart';
import 'package:younifirst_app/services/event_api_service.dart';
import 'package:younifirst_app/services/notification_service.dart';
import 'package:younifirst_app/pages/announcement/AnnouncementDetail_pages.dart';
import 'package:younifirst_app/pages/event/EventDetail_pages.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({Key? key}) : super(key: key);

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    // Tandai semua pengumuman sudah dilihat saat halaman dibuka
    NotificationService.markAnnouncementsAsRead();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await AnnouncementApiService.getAnnouncements();
      
      // Ambil pending events
      final pendingEvents = await EventApiService.getMyPendingEvents();
      
      // Convert pendingEvents ke AnnouncementModel (Notifikasi)
      final pendingNotifs = pendingEvents.map((e) => AnnouncementModel(
        id: e.id, 
        title: e.title,
        content: 'Event Anda sedang ditinjau oleh admin. Silakan tunggu konfirmasi.',
        category: 'pengajuan_event',
        createdAt: DateTime.now().toIso8601String(), // EventModel tidak memiliki createdAt, gunakan waktu sekarang
        updatedAt: DateTime.now().toIso8601String(),
        userNama: 'Sistem',
      )).toList();

      if (mounted) {
        setState(() {
          _announcements = [...data, ...pendingNotifs];
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Kelompokkan pengumuman berdasarkan waktu
  Map<String, List<AnnouncementModel>> get _grouped {
    final Map<String, List<AnnouncementModel>> groups = {
      'Baru': [],
      'Hari ini': [],
      'Kemarin': [],
      'Sebelumnya': [],
    };

    for (final item in _announcements) {
      try {
        final created = DateTime.parse(item.createdAt);
        final now = DateTime.now();
        final diff = now.difference(created);

        if (diff.inHours < 1) {
          groups['Baru']!.add(item);
        } else if (diff.inHours < 24 &&
            created.day == now.day) {
          groups['Hari ini']!.add(item);
        } else if (diff.inDays == 1 ||
            (diff.inHours < 48 && created.day == now.subtract(const Duration(days: 1)).day)) {
          groups['Kemarin']!.add(item);
        } else {
          groups['Sebelumnya']!.add(item);
        }
      } catch (_) {
        groups['Sebelumnya']!.add(item);
      }
    }
    // Hapus grup kosong
    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {},
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeleton()
          : _error != null
              ? _buildError()
              : _announcements.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFF3D5AFE),
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 100),
                        children: [
                          for (final entry in _grouped.entries) ...[
                            _buildSectionHeader(entry.key),
                            for (final item in entry.value)
                              _buildNotifCard(item),
                          ]
                        ],
                      ),
                    ),
    );
  }

  // ─── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
    );
  }

  // ─── Notification Card ────────────────────────────────────────────────────
  Widget _buildNotifCard(AnnouncementModel item) {
    final category = item.category ?? 'umum';
    final isNew = item.isNew;

    return InkWell(
      onTap: () async {
        if (item.category == 'pengajuan_event') {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => EventDetailPage(eventId: item.id)),
          );
          if (result == true) _load();
        } else {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => AnnouncementDetailPage(announcement: item)),
          );
          if (result == true) _load();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        decoration: BoxDecoration(
          color: isNew
              ? const Color(0xFFF0F3FF)
              : Colors.white,
          border: const Border(
            bottom: BorderSide(color: Colors.black12, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar lingkaran dengan initial
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _categoryColor(category).withValues(alpha: 0.15),
                  child: Icon(
                    _categoryIcon(category),
                    color: _categoryColor(category),
                    size: 22,
                  ),
                ),
                if (isNew)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3D5AFE),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Konten teks
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black87, height: 1.4),
                      children: [
                        TextSpan(
                          text: _categoryLabel(category),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Deskripsi
                  Text(
                    '${item.userNama != null ? "${item.userNama}: " : ""}"${item.title}"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Waktu
                  Text(
                    item.timeAgo,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Thumbnail / ikon kategori besar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _categoryColor(category).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  _categoryIcon(category),
                  color: _categoryColor(category),
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Loading Skeleton ─────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 12,
                      width: 120,
                      color: Colors.grey.shade200),
                  const SizedBox(height: 6),
                  Container(
                      height: 12,
                      width: double.infinity,
                      color: Colors.grey.shade200),
                  const SizedBox(height: 4),
                  Container(
                      height: 10,
                      width: 60,
                      color: Colors.grey.shade100),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 52,
              height: 52,
              color: Colors.grey.shade200,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error state ──────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Gagal memuat notifikasi',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          )
        ],
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Belum ada pengumuman',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black54),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pengumuman baru akan muncul di sini',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Color _categoryColor(String cat) {
    switch (cat) {
      case 'event': return Colors.orange;
      case 'team': return Colors.green;
      case 'pengajuan_tim': return Colors.teal;
      case 'barang': return Colors.purple;
      case 'pengajuan_event': return Colors.blue;
      default: return const Color(0xFF3D5AFE);
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'event': return Icons.calendar_today;
      case 'team': return Icons.group;
      case 'pengajuan_tim': return Icons.group_add;
      case 'barang': return Icons.inventory_2_outlined;
      case 'pengajuan_event': return Icons.hourglass_top;
      default: return Icons.campaign;
    }
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'event': return 'Pengumuman Event';
      case 'team': return 'Pengumuman Tim';
      case 'pengajuan_tim': return 'Pengajuan Tim Dikirim';
      case 'barang': return 'Pengumuman Barang';
      case 'pengajuan_event': return 'Menunggu Persetujuan';
      default: return 'Pengumuman Umum';
    }
  }
}