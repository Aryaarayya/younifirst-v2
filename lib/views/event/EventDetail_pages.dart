import 'package:flutter/material.dart';
import 'package:younifirst_app/views/event/UpdateEvent_pages.dart';
import 'package:younifirst_app/services/api/event_api_service.dart';
import 'package:younifirst_app/services/api/user_api_service.dart';
import 'package:younifirst_app/services/input/api_client.dart';
import 'package:provider/provider.dart';
import 'package:younifirst_app/viewmodels/event_viewmodel.dart';
import 'package:share_plus/share_plus.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;

  const EventDetailPage({Key? key, required this.eventId}) : super(key: key);

  @override
  _EventDetailPageState createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? eventData;
  Map<String, dynamic>? _creatorData;
  List<Map<String, dynamic>> relatedEvents = [];
  bool _isDescExpanded = false; // state expand deskripsi

  @override
  void initState() {
    super.initState();
    _fetchEventDetail();
  }

  Future<void> _fetchEventDetail() async {
    try {
      final data = await EventApiService.getEventDetail(widget.eventId);
      
      // Fetch related events (same category)
      List<Map<String, dynamic>> related = [];
      try {
        final allEvents = await EventApiService.getEvents();
        final categoryId = data['category_id']?.toString();
        related = allEvents
            .map((e) => e.toJson())
            .where((e) => e['category_id']?.toString() == categoryId && e['id']?.toString() != widget.eventId)
            .toList()
            .cast<Map<String, dynamic>>();
      } catch (e) {
        print("Gagal mengambil related events: $e");
      }

      // Fetch profil creator berdasarkan creator_id (field dari backend)
      Map<String, dynamic>? creatorProfile;
      final creatorId = data['creator_id']?.toString();
      if (creatorId != null && creatorId.isNotEmpty) {
        creatorProfile = await UserApiService.getUserById(creatorId);
        debugPrint('📋 Creator profile (id=$creatorId): $creatorProfile');
      }

      setState(() {
        eventData = data;
        _creatorData = creatorProfile;
        relatedEvents = related;
        _isLoading = false;
      });
    } catch (e) {
      print("Gagal mengambil detail event: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat event: ${e.toString().replaceAll('Exception: ', '')}")),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteEvent() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Event'),
        content: const Text('Apakah Anda yakin ingin menghapus event ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      await EventApiService.deleteEvent(widget.eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event berhasil dihapus')),
        );
        Navigator.pop(context, true); // Return true so previous page can refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "Tanggal Belum Ditentukan";
    try {
      DateTime dt = DateTime.parse(dateStr);
      // Hardcode format untuk mockup (Bisa pakai package intl jika butuh dinamis)
      List<String> months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      List<String> days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      
      String dayName = days[dt.weekday == 7 ? 0 : dt.weekday];
      return "$dayName, ${dt.day} ${months[dt.month - 1]} ${dt.year}";
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? start, String? end) {
    try {
      String startTime = "";
      String endTime = "";

      if (start != null && start.isNotEmpty) {
        DateTime dt = DateTime.parse(start);
        startTime = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      }
      if (end != null && end.isNotEmpty) {
        DateTime dt = DateTime.parse(end);
        endTime = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      }

      if (startTime.isNotEmpty && endTime.isNotEmpty) {
        return "$startTime - $endTime WIB";
      } else if (startTime.isNotEmpty) {
        return "$startTime WIB";
      }
      return "Waktu Belum Ditentukan";
    } catch (e) {
      return "-";
    }
  }

  String _formatTimeAgo(dynamic rawDate) {
    if (rawDate == null) return "Baru saja";
    try {
      final DateTime created = DateTime.parse(rawDate.toString());
      final Duration diff = DateTime.now().difference(created);

      if (diff.inMinutes < 1) {
        return 'Baru saja';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} menit lalu';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} jam lalu';
      } else if (diff.inDays == 1) {
        return 'Kemarin';
      } else {
        return '${diff.inDays} hari lalu';
      }
    } catch (_) {
      return "Baru saja";
    }
  }

  void _showFullScreenImage(BuildContext context, bool isNetworkImage, String imageUrl) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: isNetworkImage
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey, size: 100),
                  )
                : Image.asset(
                    'assets/images/Younifirst.png', // Fallback
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (eventData == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: Theme.of(context).scaffoldBackgroundColor, elevation: 0),
        body: const Center(child: Text("Data event tidak ditemukan.")),
      );
    }

    String rawImage = eventData!['image_url'] ?? eventData!['poster'] ?? '';
    if (rawImage.isNotEmpty && !rawImage.startsWith('http') && !rawImage.startsWith('assets/')) {
        String path = rawImage.startsWith('/') ? rawImage.substring(1) : rawImage;
        if (!path.startsWith('storage/')) path = 'storage/$path';
        rawImage = '${ApiClient.baseUrl.replaceAll('/api', '')}/$path';
    }
    String imageUrl = rawImage;
    bool isNetworkImage = imageUrl.toLowerCase().startsWith('http');
    String title = eventData!['title'] ?? 'Tanpa Judul';
    String location = eventData!['location'] ?? 'Lokasi belum ditentukan';
    String description = eventData!['description'] ?? 'Belum ada deskripsi untuk event ini.';
    
    // Parse category name (jika ada, sesuaikan kalau dari backend beda)
    String category = "Event";
    if (eventData!['category_id']?.toString() == "1") category = "Seminar";
    if (eventData!['category_id']?.toString() == "2") category = "Workshop";
    if (eventData!['category_id']?.toString() == "3") category = "Kompetisi";
    if (eventData!['category_id']?.toString() == "4") category = "Festival";
    if (eventData!['category_id']?.toString() == "5") category = "Olahraga";
    if (eventData!['category_id']?.toString() == "6") category = "Seni & Budaya";
    if (eventData!['category_id']?.toString() == "7") category = "Akademik";
    if (eventData!['category_id']?.toString() == "8") category = "Sosial";

    final String eventStatus = eventData!['status']?.toString().toLowerCase() ?? 'open';
    final String? eventRejectionReason = eventData!['rejection_reason']?.toString() ?? eventData!['reason']?.toString() ?? eventData!['alasan']?.toString() ?? eventData!['admin_note']?.toString();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400.0,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateEventPage(eventId: widget.eventId)));
                      } else if (value == 'hapus') {
                        _deleteEvent();
                      } else if (value == 'bagikan') {
                        final String eventLink = 'https://younifirst.com/event/${widget.eventId}';
                        final String shareText = 'Yuk ikuti event menarik ini: $title!\n\nLihat detailnya dan daftar sekarang melalui link berikut:\n$eventLink';
                        Share.share(shareText, subject: 'Event: $title');
                      }
                    },
                    color: Theme.of(context).cardColor,
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [Icon(Icons.edit_outlined, size: 18, color: Theme.of(context).textTheme.bodyLarge?.color), const SizedBox(width: 8), Text('Edit', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'hapus',
                        child: Row(
                          children: [Icon(Icons.delete_outline, size: 18, color: Theme.of(context).textTheme.bodyLarge?.color), const SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'bagikan',
                        child: Row(
                          children: [Icon(Icons.share_outlined, size: 18, color: Theme.of(context).textTheme.bodyLarge?.color), const SizedBox(width: 8), Text('Bagikan', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  isNetworkImage
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => _buildPlaceholder())
                    : _buildPlaceholder(),
                  
                  // Expand icon bottom right
                  Positioned(
                    bottom: 50,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => _showFullScreenImage(context, isNetworkImage, imageUrl),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.unfold_more, color: Colors.white, size: 24),
                      ),
                    ),
                  ),

                  // Curved bottom container overlay
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar (aesthetic)
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title and badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, height: 1.3, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D5AFE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  // Status rejected info
                  if (eventStatus == 'rejected' && eventRejectionReason != null && eventRejectionReason.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.red.withValues(alpha: 0.3) : Colors.red.shade200, width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Theme.of(context).brightness == Brightness.dark ? Colors.red.shade400 : Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Alasan Penolakan',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.red.shade400 : Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  eventRejectionReason,
                                  style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.red.shade400 : Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  const Divider(color: Colors.black12, height: 1),
                  const SizedBox(height: 24),

                  // Date and Location Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Start Date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF23253A) : const Color(0xFFF3F6FF), shape: BoxShape.circle),
                                child: const Icon(Icons.calendar_month, color: Color(0xFF3D5AFE), size: 20),
                              ),
                              // Dotted line
                              Container(
                                height: 20,
                                width: 2,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(4, (index) => Container(width: 2, height: 3, color: const Color(0xFF3D5AFE))),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(eventData!['start_date']),
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(eventData!['start_date'], eventData!['end_date']),
                                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // End Date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF23253A) : const Color(0xFFF3F6FF), shape: BoxShape.circle),
                            child: const Icon(Icons.calendar_month, color: Color(0xFF3D5AFE), size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(eventData!['end_date']),
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(eventData!['start_date'], eventData!['end_date']),
                                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),

                      // Location
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF23253A) : const Color(0xFFF3F6FF), shape: BoxShape.circle),
                            child: const Icon(Icons.location_on_rounded, color: Color(0xFF3D5AFE), size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Divider(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.black12, height: 1),
                  const SizedBox(height: 24),

                  // Description
                  Text("Tentang Event", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 12),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: _isDescExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description.length > 200
                              ? '${description.substring(0, 200)}...'
                              : description,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        if (description.length > 200)
                          GestureDetector(
                            onTap: () => setState(() => _isDescExpanded = true),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: const [
                                  Text(
                                    "Lihat lebih banyak",
                                    style: TextStyle(
                                      color: Color(0xFF3D5AFE),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_down_rounded,
                                      color: Color(0xFF3D5AFE), size: 18),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        if (description.length > 200)
                          GestureDetector(
                            onTap: () => setState(() => _isDescExpanded = false),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: const [
                                  Text(
                                    "Lebih sedikit",
                                    style: TextStyle(
                                      color: Color(0xFF3D5AFE),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_up_rounded,
                                      color: Color(0xFF3D5AFE), size: 18),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: Colors.black12, height: 1),
                  const SizedBox(height: 24),

                  // Author profile — data dari creator event (user yang membuat postingan)
                  _buildCreatorSection(),
                  
                  if (eventStatus != 'rejected') ...[
                    const SizedBox(height: 32),
                    const Divider(color: Colors.black12, height: 1),
                    const SizedBox(height: 24),

                    // Related Events Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Event Lainnya",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "LIHAT SEMUA",
                            style: TextStyle(color: Color(0xFF3D5AFE), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // Related Events List View
          if (eventStatus != 'rejected')
            SliverToBoxAdapter(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              height: 450, // Match list height from Event_pages
              padding: const EdgeInsets.only(bottom: 30),
              child: relatedEvents.isEmpty
                ? const Center(child: Text("Tidak ada event serupa", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: relatedEvents.length,
                    itemBuilder: (context, index) {
                      final ev = relatedEvents[index];
                      return _buildRelatedEventCard(
                        id: ev['id']?.toString() ?? '',
                        title: ev['title'] ?? '',
                        dateText: ev['start_date'] != null ? _formatDate(ev['start_date']) : 'Tanggal Belum Ditentukan',
                        locationText: ev['location'] ?? 'Lokasi Belum Ditentukan',
                        likes: ev['likes_count']?.toString() ?? '0',
                        imageUrl: ev['image_url'] ?? ev['poster'] ?? '',
                      );
                    },
                  ),
            ),
          ),
          
          SliverPadding(padding: EdgeInsets.only(bottom: 40)), // Safe area bottom
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Image.asset('assets/images/Younifirst.png', fit: BoxFit.cover),
    );
  }

  /// Ambil URL foto creator — dari _creatorData (hasil fetch API) atau field di eventData
  String? _getCreatorPhotoUrl() {
    // Prioritas 1: dari data profil creator yang sudah di-fetch
    if (_creatorData != null) {
      final candidates = [
        _creatorData!['photo'],
        _creatorData!['photo_url'],
        _creatorData!['avatar'],
        _creatorData!['profile_photo'],
      ];
      for (final raw in candidates) {
        final url = raw?.toString();
        if (url != null && url.isNotEmpty) {
          if (url.startsWith('http')) return url;
          String cleanPath = url.startsWith('/') ? url.substring(1) : url;
          if (!cleanPath.startsWith('storage/')) cleanPath = 'storage/$cleanPath';
          return '${ApiClient.baseUrl.replaceAll('/api', '')}/$cleanPath';
        }
      }
    }

    // Prioritas 2: dari field langsung di eventData
    if (eventData != null) {
      final candidates = [
        eventData!['creator_photo'],
        eventData!['creator_avatar'],
        eventData!['user']?['photo'],
        eventData!['user']?['photo_url'],
        eventData!['creator']?['photo'],
      ];
      for (final raw in candidates) {
        final url = raw?.toString();
        if (url != null && url.isNotEmpty) {
          if (url.startsWith('http')) return url;
          String cleanPath = url.startsWith('/') ? url.substring(1) : url;
          if (!cleanPath.startsWith('storage/')) cleanPath = 'storage/$cleanPath';
          return '${ApiClient.baseUrl.replaceAll('/api', '')}/$cleanPath';
        }
      }
    }
    return null;
  }

  /// Section profil creator event
  Widget _buildCreatorSection() {
    // Nama dari _creatorData (hasil fetch) atau fallback ke creator_name di eventData
    final String creatorName = _creatorData?['name']?.toString()
        ?? eventData?['creator_name']?.toString()
        ?? 'Penyelenggara';
    final String initials = creatorName.isNotEmpty ? creatorName.substring(0, 1).toUpperCase() : 'P';
    final String? photoUrl = _getCreatorPhotoUrl();

    return Row(
      children: [
        // Avatar creator
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: photoUrl == null
                ? LinearGradient(
                    colors: [const Color(0xFF3D5AFE), Colors.purple.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            image: photoUrl != null
                ? DecorationImage(
                    image: NetworkImage(photoUrl),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  )
                : null,
          ),
          child: photoUrl == null
              ? Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              creatorName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimeAgo(eventData?['created_at'] ?? eventData?['createdAt']),
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRelatedEventCard({
    required String id,
    required String title,
    required String dateText,
    required String locationText,
    required String likes,
    required String imageUrl,
  }) {
    bool isNetworkImage = imageUrl.toLowerCase().startsWith('http');
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http') && !imageUrl.startsWith('assets/')) {
        String path = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
        if (!path.startsWith('storage/')) path = 'storage/$path';
        imageUrl = '${ApiClient.baseUrl.replaceAll('/api', '')}/$path';
        isNetworkImage = true;
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EventDetailPage(eventId: id)),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16, bottom: 10, top: 5, left: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: isNetworkImage
                      ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => _buildPlaceholder())
                      : _buildPlaceholder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 16, color: Color(0xFF3D5AFE)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dateText,
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black.withOpacity(0.6), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF3D5AFE)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black.withOpacity(0.6), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey.withOpacity(0.2), thickness: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite_border, size: 22, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black.withOpacity(0.7)),
                          const SizedBox(width: 8),
                          Text(
                            likes,
                            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D5AFE),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: const [
                            Text("Mulai", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
