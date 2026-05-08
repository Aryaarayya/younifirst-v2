class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String? category;    // 'event', 'team', 'barang', 'umum'
  final String? status;      // 'pending', 'confirmed'
  final String? userNama;
  final String? userAvatar;
  final String createdAt;
  final String updatedAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.category,
    this.status,
    this.userNama,
    this.userAvatar,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Mengembalikan berapa lama sejak pengumuman dibuat, dalam format singkat
  String get timeAgo {
    try {
      final DateTime created = DateTime.parse(createdAt);
      final Duration diff = DateTime.now().difference(created);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} mnt lalu';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} jam lalu';
      } else if (diff.inDays == 1) {
        return 'Kemarin';
      } else {
        return '${diff.inDays} hari lalu';
      }
    } catch (_) {
      return createdAt;
    }
  }

  /// Apakah pengumuman ini baru (< 1 jam)
  bool get isNew {
    try {
      final DateTime created = DateTime.parse(createdAt);
      return DateTime.now().difference(created).inHours < 1;
    } catch (_) {
      return false;
    }
  }

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id']?.toString() ??
          json['announcement_id']?.toString() ?? '',
      title: json['title'] ?? 'Tanpa Judul',
      content: json['content'] ?? json['message'] ?? json['body'] ?? '',
      category: json['category']?.toString(),
      status: json['status']?.toString(),
      userNama: json['user']?['name'] ??
          json['user_name'] ??
          json['created_by'],
      userAvatar: json['user']?['avatar'] ?? json['user_avatar'],
      createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      if (category != null) 'category': category,
    };
  }
}
