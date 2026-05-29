import 'package:flutter/material.dart';
import 'package:younifirst_app/models/Announcement_model.dart';
import 'package:younifirst_app/views/team/TeamApplications_pages.dart';
import 'package:younifirst_app/views/team/TeamChat_pages.dart';
import 'package:younifirst_app/services/api/team_api_service.dart';
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:younifirst_app/views/event/EventDetail_pages.dart';
import 'package:younifirst_app/views/barang/BarangDetail_pages.dart';
import 'package:younifirst_app/views/team/TeamDetail_pages.dart';
import 'package:younifirst_app/services/input/api_client.dart';

class AnnouncementDetailPage extends StatefulWidget {
  final AnnouncementModel announcement;

  const AnnouncementDetailPage({Key? key, required this.announcement})
      : super(key: key);

  @override
  State<AnnouncementDetailPage> createState() => _AnnouncementDetailPageState();
}

class _AnnouncementDetailPageState extends State<AnnouncementDetailPage> {
  late AnnouncementModel _item;

  bool isEventNotification(AnnouncementModel item) {
    final cat = item.category?.toLowerCase() ?? 'umum';
    if (cat == 'event' || cat == 'pengajuan_event') return true;
    final title = item.title.toLowerCase();
    final content = item.content.toLowerCase();
    if (title.contains('event') || content.contains('event')) return true;
    return false;
  }

  bool isTeamNotification(AnnouncementModel item) {
    final cat = item.category?.toLowerCase() ?? 'umum';
    if (cat == 'team' || cat == 'pengajuan_tim') return true;
    final title = item.title.toLowerCase();
    final content = item.content.toLowerCase();
    if (title.contains('tim') || title.contains('team') || content.contains('tim') || content.contains('team')) return true;
    return false;
  }

  bool isBarangNotification(AnnouncementModel item) {
    final cat = item.category?.toLowerCase() ?? 'umum';
    if (cat == 'barang') return true;
    final title = item.title.toLowerCase();
    final content = item.content.toLowerCase();
    if (title.contains('barang') || content.contains('barang') || title.contains('lost') || content.contains('lost')) return true;
    return false;
  }

  String getEffectiveCategory(AnnouncementModel item) {
    if (isEventNotification(item)) return 'event';
    if (isTeamNotification(item)) return 'team';
    if (isBarangNotification(item)) return 'barang';
    return item.category?.toLowerCase() ?? 'umum';
  }

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('assets/')) return path;

    String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final storageBase = ApiClient.baseUrl.replaceAll('/api', '');
    if (!cleanPath.startsWith('storage/')) {
      cleanPath = 'storage/$cleanPath';
    }
    return '$storageBase/$cleanPath';
  }

  @override
  void initState() {
    super.initState();
    _item = widget.announcement;
  }

  @override
  Widget build(BuildContext context) {
    final category = getEffectiveCategory(_item);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          // Header biru
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3D5AFE), Color(0xFF1A237E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // AppBar custom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Detail Pengumuman',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 48), // placeholder agar judul tetap center
                    ],
                  ),
                ),

                // Card konten
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 12,
                                  offset: Offset(0, 6))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Info user + waktu (Header)
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFFE8EAFF),
                                    backgroundImage: _item.userAvatar != null && _item.userAvatar!.isNotEmpty
                                        ? NetworkImage(_item.userAvatar!.startsWith('http') 
                                            ? _item.userAvatar! 
                                            : _getFullImageUrl(_item.userAvatar))
                                        : null,
                                    child: _item.userAvatar == null || _item.userAvatar!.isEmpty
                                        ? Text(
                                            (_item.userNama ?? 'S').substring(0, 1).toUpperCase(),
                                            style: const TextStyle(
                                                color: Color(0xFF3D5AFE),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _item.userNama ?? 'Sistem Notifikasi',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _item.timeAgo,
                                          style: const TextStyle(
                                              fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Category/Status badge
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _CategoryBadge(category: category),
                                      if (_item.status != null) ...[
                                        const SizedBox(height: 4),
                                        _StatusBadge(status: _item.status!),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Colors.black12, height: 1, thickness: 1),
                              const SizedBox(height: 16),

                              // Judul
                              Text(
                                _item.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Gambar (Jika Ada)
                              if (_item.postImage != null && _item.postImage!.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    _item.postImage!.startsWith('http')
                                        ? _item.postImage!
                                        : _getFullImageUrl(_item.postImage),
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Isi konten
                              Text(
                                _item.content,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // ─── Tombol aksi khusus ───────────────────────
                        if (isEventNotification(_item))
                          _EventActionButtons(announcement: _item)
                        else if (isTeamNotification(_item))
                          _TeamActionButtons(announcement: _item)
                        else if (isBarangNotification(_item))
                          _BarangActionButtons(announcement: _item),
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
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, dynamic>> map = {
      'event': {'label': 'Event', 'color': Colors.orange, 'icon': Icons.calendar_today},
      'team': {'label': 'Team', 'color': Colors.green, 'icon': Icons.group},
      'barang': {'label': 'Barang', 'color': Colors.purple, 'icon': Icons.inventory_2_outlined},
      'umum': {'label': 'Umum', 'color': const Color(0xFF3D5AFE), 'icon': Icons.campaign_outlined},
    };
    final info = map[category] ?? map['umum']!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (info['color'] as Color).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info['icon'] as IconData, color: info['color'] as Color, size: 14),
          const SizedBox(width: 6),
          Text(
            info['label'] as String,
            style: TextStyle(
                color: info['color'] as Color,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isConfirmed = status == 'confirmed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isConfirmed
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isConfirmed ? '✓ Dikonfirmasi' : '⏳ Menunggu',
        style: TextStyle(
          color: isConfirmed ? Colors.green : Colors.orange,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─── Team Action Buttons ───────────────────────────────────────────────────────
class _TeamActionButtons extends StatelessWidget {
  final AnnouncementModel announcement;
  const _TeamActionButtons({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final teamId = announcement.targetId;
    if (teamId == null || teamId.isEmpty) {
      return const SizedBox.shrink();
    }
    final teamName = announcement.title
        .replaceAll('Pengajuan Tim: ', '')
        .trim();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeamApplicationsPage(
                    teamId: teamId,
                    teamName: teamName,
                  ),
                ),
              ),
              icon: const Icon(Icons.description_outlined,
                  color: Color(0xFF3D5AFE), size: 18),
              label: const Text(
                'Lihat Lamaran Masuk',
                style: TextStyle(
                    color: Color(0xFF3D5AFE),
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF3D5AFE)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeamChatPage(
                  teamId: teamId,
                  teamName: teamName,
                ),
              ),
            ),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF3D5AFE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Event Action Buttons ──────────────────────────────────────────────────────
class _EventActionButtons extends StatelessWidget {
  final AnnouncementModel announcement;
  const _EventActionButtons({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final eventId = announcement.targetId;
    if (eventId == null || eventId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailPage(eventId: eventId),
            ),
          ),
          icon: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
          label: const Text(
            'Lihat Detail Event',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3D5AFE),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

// ─── Barang Action Buttons ─────────────────────────────────────────────────────
class _BarangActionButtons extends StatelessWidget {
  final AnnouncementModel announcement;
  const _BarangActionButtons({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final lostFoundId = announcement.targetId;
    if (lostFoundId == null || lostFoundId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BarangDetailPage(lostFoundId: lostFoundId),
            ),
          ),
          icon: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 18),
          label: const Text(
            'Lihat Detail Barang',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3D5AFE),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
