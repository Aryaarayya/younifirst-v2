import 'package:flutter/material.dart';
import 'package:younifirst_app/views/event/UpdateEvent_pages.dart';
import 'package:younifirst_app/services/api/event_api_service.dart';
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
  List<Map<String, dynamic>> relatedEvents = [];
  bool _isLiked = false;
  int _likesCount = 0;

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

      setState(() {
        eventData = data;
        relatedEvents = related;
        _likesCount = int.tryParse(data['likes_count']?.toString() ?? '0') ?? 0;
        _isLiked = data['is_liked'] == true || data['is_liked'] == 1;
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
    if (eventData!['category_id']?.toString() == "1") category = "Kompetisi";
    if (eventData!['category_id']?.toString() == "2") category = "Seminar";
    if (eventData!['category_id']?.toString() == "3") category = "Pameran";
    if (eventData!['category_id']?.toString() == "4") category = "Turnamen";
    if (eventData!['category_id']?.toString() == "5") category = "Konser";

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
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [Icon(Icons.edit_outlined, size: 18, color: Colors.black87), SizedBox(width: 8), Text('Edit', style: TextStyle(color: Colors.black87))],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'hapus',
                        child: Row(
                          children: [Icon(Icons.delete_outline, size: 18, color: Colors.black87), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.black87))],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'bagikan',
                        child: Row(
                          children: [Icon(Icons.share_outlined, size: 18, color: Colors.black87), SizedBox(width: 8), Text('Bagikan', style: TextStyle(color: Colors.black87))],
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
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.unfold_more, color: Colors.white, size: 20),
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
                  
                  const SizedBox(height: 24),
                  Divider(color: Theme.of(context).dividerColor, height: 1),
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
                                decoration: const BoxDecoration(color: Color(0xFFF3F6FF), shape: BoxShape.circle),
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
                                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54, fontSize: 14),
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
                            decoration: const BoxDecoration(color: Color(0xFFF3F6FF), shape: BoxShape.circle),
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
                                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54, fontSize: 14),
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
                            decoration: const BoxDecoration(color: Color(0xFFF3F6FF), shape: BoxShape.circle),
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
                  Divider(color: Theme.of(context).dividerColor, height: 1),
                  const SizedBox(height: 24),

                  // Description
                  const Text("Tentang Event", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      text: description.length > 200 ? description.substring(0, 200) + "... " : description,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14, height: 1.5),
                      children: [
                        if (description.length > 200)
                          const TextSpan(
                            text: "Lebih banyak...",
                            style: TextStyle(color: Color(0xFF3D5AFE), fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Divider(color: Theme.of(context).dividerColor, height: 1),
                  const SizedBox(height: 24),

                  // Author profile
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=150'),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                eventData!['creator_name'] ?? "rona_naa",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimeAgo(eventData!['created_at'] ?? eventData!['createdAt']),
                                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          // Toggle like
                          final wasLiked = _isLiked;
                          setState(() {
                            _isLiked = !wasLiked;
                            _likesCount = wasLiked 
                                ? (_likesCount - 1).clamp(0, 999999) 
                                : _likesCount + 1;
                          });
                          try {
                            final result = await EventApiService.toggleLike(widget.eventId);
                            if (mounted && result['success'] == true) {
                              setState(() {
                                _isLiked = result['is_liked'] ?? _isLiked;
                                _likesCount = int.tryParse(result['likes_count']?.toString() ?? '') ?? _likesCount;
                              });
                            }
                            // Juga update di viewModel agar sinkron
                            if (mounted) {
                              context.read<EventViewModel>().toggleLike(widget.eventId);
                            }
                          } catch (e) {
                            // Revert
                            if (mounted) {
                              setState(() {
                                _isLiked = wasLiked;
                                _likesCount = wasLiked ? _likesCount + 1 : (_likesCount - 1).clamp(0, 999999);
                              });
                            }
                          }
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).cardColor,
                            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                              child: Icon(
                                _isLiked ? Icons.favorite : Icons.favorite_border,
                                key: ValueKey(_isLiked),
                                color: _isLiked ? Colors.redAccent : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  Divider(color: Theme.of(context).dividerColor, height: 1),
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
              ),
            ),
          ),

          // Related Events List View
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
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54, fontSize: 12),
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
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Theme.of(context).dividerColor, thickness: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite_border, size: 22, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                          const SizedBox(width: 8),
                          Text(
                            likes,
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
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
