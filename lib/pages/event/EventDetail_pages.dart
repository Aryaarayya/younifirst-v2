import 'package:flutter/material.dart';
import 'package:younifirst_app/pages/event/UpdateEvent_pages.dart';
import 'package:younifirst_app/services/event_api_service.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;

  const EventDetailPage({Key? key, required this.eventId}) : super(key: key);

  @override
  _EventDetailPageState createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? eventData;

  @override
  void initState() {
    super.initState();
    _fetchEventDetail();
  }

  Future<void> _fetchEventDetail() async {
    try {
      final data = await EventApiService.getEventDetail(widget.eventId);
      setState(() {
        eventData = data;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (eventData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: Text("Data event tidak ditemukan.")),
      );
    }

    String rawImage = eventData!['image_url'] ?? eventData!['poster'] ?? '';
    if (rawImage.isNotEmpty && !rawImage.startsWith('http') && !rawImage.startsWith('assets/')) {
        String path = rawImage.startsWith('/') ? rawImage.substring(1) : rawImage;
        if (!path.startsWith('storage/')) path = 'storage/$path';
        rawImage = 'https://enlighten-resupply-usable.ngrok-free.dev/$path';
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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400.0,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                    onSelected: (value) async {
                      if (value == 'update') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdateEventPage(eventId: widget.eventId),
                          ),
                        );
                        if (result == true) {
                          _fetchEventDetail();
                        }
                      } else if (value == 'hapus') {
                        _deleteEvent();
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'update',
                        child: Row(
                          children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Update Event')],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'hapus',
                        child: Row(
                          children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Hapus Event', style: TextStyle(color: Colors.red))],
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
                  
                  // Curved bottom container overlay
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 30, // overlap effect
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar (aesthetic)
                  Center(
                    child: Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, height: 1.3),
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
                  const Divider(color: Colors.black12, height: 1),
                  const SizedBox(height: 24),

                  // Date
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFE8EAFF), shape: BoxShape.circle),
                        child: const Icon(Icons.calendar_today, color: Color(0xFF3D5AFE), size: 18),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(eventData!['start_date']),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(eventData!['start_date'], eventData!['end_date']),
                              style: const TextStyle(color: Colors.black54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFE8EAFF), shape: BoxShape.circle),
                        child: const Icon(Icons.location_on, color: Color(0xFF3D5AFE), size: 18),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Area lokasi detail event", // Fallback atau ambil text tambahan
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black54, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3D5AFE),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.location_on, color: Colors.white, size: 14),
                                  SizedBox(width: 6),
                                  Text("Lihat lokasi di Maps", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: Colors.black12, height: 1),
                  const SizedBox(height: 24),

                  // Description
                  const Text("Tentang Event", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      text: description.length > 200 ? description.substring(0, 200) + "... " : description,
                      style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5),
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
                  const Text("Lokasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  
                  // Map placeholder
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.blue.shade50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.map, size: 100, color: Colors.blue.shade100),
                          // Custom Pin
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3D5AFE),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundImage: isNetworkImage ? NetworkImage(imageUrl) : const AssetImage('assets/images/Younifirst.png') as ImageProvider,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Color(0xFF3D5AFE), size: 30),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // Author profile
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=150'), // dummy
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("rona_naa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text("1 jam lalu", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Icon(Icons.favorite, color: Colors.red, size: 20),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(color: Colors.black12, height: 1),
                  const SizedBox(height: 24),

                  // Related Events Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Lebih banyak Events seperti ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text("LIHAT SEMUA", style: TextStyle(color: Color(0xFF3D5AFE), fontWeight: FontWeight.bold, fontSize: 11)),
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
              color: Colors.white,
              height: 250,
              padding: const EdgeInsets.only(bottom: 20),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildRelatedEventCard(
                    title: "Nama Seminar",
                    dateText: "Tanggal - Tanggal • Jam",
                    locationText: "Lokasi Acaraaaaaaaaaaaaaaaaaa",
                    likes: "10",
                    imageUrl: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?q=80&w=600&auto=format&fit=crop",
                  ),
                  _buildRelatedEventCard(
                    title: "Nama Seminar 2",
                    dateText: "Tanggal - Tanggal • Jam",
                    locationText: "Lokasi Acaraaaaaaaaaaaaaaaaaa",
                    likes: "10",
                    imageUrl: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=600&auto=format&fit=crop",
                  ),
                ],
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
    required String title,
    required String dateText,
    required String locationText,
    required String likes,
    required String imageUrl,
  }) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            child: Image.network(imageUrl, height: 110, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Color(0xFF3D5AFE)),
                    const SizedBox(width: 4),
                    Expanded(child: Text(dateText, style: const TextStyle(color: Colors.black54, fontSize: 10))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF3D5AFE)),
                    const SizedBox(width: 4),
                    Expanded(child: Text(locationText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, fontSize: 10))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(likes, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF3D5AFE), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: const [
                          Text("Mulai", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 12),
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
