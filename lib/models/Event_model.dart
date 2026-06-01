import 'package:younifirst_app/services/input/api_client.dart';
import 'package:younifirst_app/services/input/auth_service.dart';

class EventModel {
  final String id;
  final String title;
  final String date;
  final String time;
  final String location;
  final String imageUrl;
  final String likesCount;
  final String categoryId;
  final String createdBy;
  final String status;
  final String? rejectionReason;
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
    this.createdBy = '',
    this.status = 'Open',
    this.rejectionReason,
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

    String formattedDate = json['date']?.toString() ?? '';
    String formattedTime = json['time']?.toString() ?? '';
    final startDateStr = json['start_date']?.toString();

    if (formattedDate.isEmpty && startDateStr != null && startDateStr.isNotEmpty) {
      try {
        DateTime dt = DateTime.parse(startDateStr);
        List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
        formattedDate = "${dt.day} ${months[dt.month - 1]} ${dt.year}";
        if (formattedTime.isEmpty) {
          formattedTime = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB";
        }
      } catch (e) {
        formattedDate = startDateStr;
      }
    }

    if (formattedDate.isEmpty) {
      formattedDate = 'Tanggal tidak diketahui';
    }

    return EventModel(
      id: parsedId,
      title: json['title'] ?? 'Tanpa Judul',
      date: formattedDate,
      time: formattedTime,
      location: json['location'] ?? 'Lokasi tidak diketahui',
      imageUrl: _getFullImageUrl(json['poster_url'] ?? json['poster']),
      likesCount: () {
        final rawLikes = json['likes'];
        if (rawLikes is List) {
          return rawLikes.length.toString();
        }
        return (json['likes_count'] ?? json['likesCount'] ?? '0').toString();
      }(),
      categoryId: json['category_id']?.toString() ?? '',
      status: () {
        final statusVal = json['status'] ?? json['event_status'] ?? json['approval_status'] ?? json['is_published'] ?? json['is_approved'];
        final statusStr = statusVal?.toString().toLowerCase().trim() ?? 'open';
        if (statusStr == '0' || statusStr == 'false') return 'pending';
        if (statusStr == '1' || statusStr == 'true') return 'approved';
        return statusVal?.toString() ?? 'Open';
      }(),
      rejectionReason: json['rejection_reason']?.toString() ?? json['reason']?.toString() ?? json['alasan']?.toString() ?? json['admin_note']?.toString() ?? json['catatan_admin']?.toString() ?? json['alasan_penolakan']?.toString(),
      createdBy: () {
        final rawCreatorId = json['creator_id'];
        if (rawCreatorId != null) return rawCreatorId.toString();
        
        final rawCreatedBy = json['created_by'];
        if (rawCreatedBy != null) {
          if (rawCreatedBy is Map) {
            return (rawCreatedBy['id'] ?? rawCreatedBy['user_id'] ?? rawCreatedBy['uid'] ?? '').toString();
          }
          return rawCreatedBy.toString();
        }
        final rawUser = json['user'];
        if (rawUser != null && rawUser is Map) {
          return (rawUser['id'] ?? rawUser['user_id'] ?? rawUser['uid'] ?? '').toString();
        }
        final rawCreator = json['creator'];
        if (rawCreator != null && rawCreator is Map) {
          return (rawCreator['id'] ?? rawCreator['user_id'] ?? rawCreator['uid'] ?? '').toString();
        }
        return (json['userId'] ?? json['user_id'] ?? '').toString();
      }(),
      isLiked: () {
        final rawIsLiked = json['is_liked'] ?? json['liked_by_user'] ?? json['isLiked'];
        if (rawIsLiked == true || rawIsLiked == 1 || rawIsLiked == '1') return true;
        
        final rawLikes = json['likes'];
        if (rawLikes is List && AuthService.userId != null) {
          final myId = AuthService.userId.toString();
          return rawLikes.any((like) {
            if (like is Map) {
              final uid = (like['user_id'] ?? like['id'] ?? like['uid'] ?? '').toString();
              return uid == myId;
            }
            return like.toString() == myId;
          });
        }
        return false;
      }(),
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
      createdBy: createdBy,
      status: status,
      rejectionReason: rejectionReason,
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
      'created_by': createdBy,
      'status': status,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
    };
  }
}

