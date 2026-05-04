class EventModel {
  final String id;
  final String title;
  final String date;
  final String time;
  final String location;
  final String imageUrl;
  final String likesCount;
  final String categoryId;

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.imageUrl,
    required this.likesCount,
    this.categoryId = '',
  });

  static String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return 'assets/images/Younifirst.png';
    if (path.startsWith('http')) return path;
    if (path.startsWith('assets/')) return path;

    String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    if (!cleanPath.startsWith('storage/')) {
      cleanPath = 'storage/$cleanPath';
    }
    return 'https://enlighten-resupply-usable.ngrok-free.dev/$cleanPath';
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Coba berbagai kemungkinan nama key ID dari backend
    final rawId = json['id'] ?? json['event_id'] ?? json['eventId'] ?? json['_id'];
    final parsedId = rawId?.toString() ?? '';

    if (parsedId.isEmpty) {
      // ignore: avoid_print
      print('⚠️ WARNING: Event ID kosong! Keys tersedia: ${json.keys.toList()}');
    }

    return EventModel(
      id: parsedId,
      title: json['title'] ?? 'Tanpa Judul',
      date: json['date'] ?? 'Tanggal tidak diketahui',
      time: json['time'] ?? '',
      location: json['location'] ?? 'Lokasi tidak diketahui',
      imageUrl: _getFullImageUrl(json['poster_url'] ?? json['poster']),
      likesCount: json['likes_count']?.toString() ?? '0',
      categoryId: json['category_id']?.toString() ?? '',
    );
  }
}
