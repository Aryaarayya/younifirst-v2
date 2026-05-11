import 'package:younifirst_app/services/input/api_client.dart';

class EventModel {
  final String id;
  final String title;
  final String date;
  final String time;
  final String location;
  final String imageUrl;
  final String likesCount;
  final String categoryId;
  final bool? _isLiked;
  bool get isLiked => _isLiked ?? false;

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.imageUrl,
    required this.likesCount,
    this.categoryId = '',
    bool isLiked = false,
  }) : _isLiked = isLiked;

  static String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return 'assets/images/Younifirst.png';
    if (path.startsWith('http')) return path;
    if (path.startsWith('assets/')) return path;

    String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    if (!cleanPath.startsWith('storage/')) {
      cleanPath = 'storage/$cleanPath';
    }
    final storageBase = ApiClient.baseUrl.replaceAll('/api', '');
    return '$storageBase/$cleanPath';
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
      isLiked: json['is_liked'] == true || json['is_liked'] == 1 || json['liked_by_user'] == true,
    );
  }

  EventModel copyWith({
    String? likesCount,
    bool? isLiked,
  }) {
    return EventModel(
      id: id,
      title: title,
      date: date,
      time: time,
      location: location,
      imageUrl: imageUrl,
      likesCount: likesCount ?? this.likesCount,
      categoryId: categoryId,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'time': time,
      'location': location,
      'image_url': imageUrl,
      'likes_count': likesCount,
      'category_id': categoryId,
    };
  }
}

