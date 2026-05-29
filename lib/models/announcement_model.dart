class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String? category;    // 'event', 'team', 'barang', 'umum'
  final String? status;      // 'pending', 'confirmed'
  final String? userNama;
  final String? userAvatar;
  final String? postImage;
  final String? targetId;
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
    this.postImage,
    this.targetId,
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
    final titleLower = (json['title']?.toString() ?? '').toLowerCase();
    final contentLower = (json['content']?.toString() ?? '').toLowerCase();
    if (titleLower.contains('event') || contentLower.contains('event')) {
      // ignore: avoid_print
      print('🚨 EVENT NOTIFICATION JSON: $json');
    }
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
      postImage: json['post_image'] ?? json['image'] ?? json['photo'] ?? json['postImage'] ?? json['file_url'] ?? json['file'],
      targetId: json['target_id']?.toString() ??
          json['event_id']?.toString() ??
          json['team_id']?.toString() ??
          json['lost_found_id']?.toString() ??
          json['lostfound_id']?.toString() ??
          json['target']?.toString(),
      createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      if (category != null) 'category': category,
      if (postImage != null) 'post_image': postImage,
      if (targetId != null) 'target_id': targetId,
    };
  }
}
