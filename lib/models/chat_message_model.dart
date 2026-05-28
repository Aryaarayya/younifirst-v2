class ChatMessageModel {
  final String id;
  final String teamId;
  final String senderId;
  final String senderName;
  final String message;
  final String createdAt;
  final bool isEdited;

  ChatMessageModel({
    required this.id,
    required this.teamId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
    this.isEdited = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    String createdAtStr;
    final rawCreatedAt = json['created_at'];
    
    if (rawCreatedAt is int) {
      // Jika integer (milliseconds from ChatService), ubah ke ISO8601
      createdAtStr = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt, isUtc: true).toIso8601String();
    } else if (rawCreatedAt is String) {
      createdAtStr = rawCreatedAt;
    } else {
      createdAtStr = DateTime.now().toIso8601String();
    }

    return ChatMessageModel(
      id: json['id']?.toString() ?? json['message_id']?.toString() ?? '',
      teamId: json['team_id']?.toString() ?? '',
      senderId: json['user_id']?.toString() ??
          json['sender_id']?.toString() ?? '',
      senderName: json['user']?['name'] ??
          json['sender_name'] ??
          json['user_name'] ??
          'Anggota',
      message: json['message']?.toString() ?? json['content']?.toString() ?? '',
      createdAt: createdAtStr,
      isEdited: json['is_edited'] == true || json['is_edited'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'team_id': teamId,
        'message': message,
      };

  /// Waktu relatif
  String get timeAgo {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      return '${diff.inDays} hari lalu';
    } catch (_) {
      return '';
    }
  }

  /// Format jam HH:mm
  String get timeLabel {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}
