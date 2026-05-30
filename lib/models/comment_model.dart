class CommentModel {
  final String id;
  final String? parentId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String createdAt;
  final String comment;
  List<CommentModel> replies = [];

  CommentModel({
    required this.id,
    this.parentId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.createdAt,
    required this.comment,
  });

  String get commentTextOnly {
    if (comment.startsWith('[re:')) {
      return comment.replaceFirst(RegExp(r'\[re:[^\]]*\]'), '').trim();
    }
    return comment;
  }

  /// Returns a friendly label for web users based on their user_id prefix.
  static String _roleFromUserId(String userId) {
    final id = userId.toUpperCase();
    if (id.startsWith('ADM')) return 'Admin';
    if (id.startsWith('STP')) return 'Staff';
    if (id.startsWith('OPR')) return 'Operator';
    return 'Pengguna';
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    String? parentId = json['parent_id']?.toString();
    String commentText = json['comment'] ?? '';

    // If parentId is missing but present in the comment tag [re:ID]
    if (parentId == null || parentId.isEmpty) {
      RegExp regExp = RegExp(r'\[re:\s*([^\]\s]+)\]');
      Match? match = regExp.firstMatch(commentText);
      if (match != null) {
        parentId = match.group(1);
      }
    }

    // --- Extract NIM (for students) ---
    String? nim = json['nim']?.toString().trim();
    if (nim == null || nim.isEmpty || nim == '-') {
      nim = json['user_nim']?.toString().trim();
    }
    if (nim == null || nim.isEmpty || nim == '-') {
      nim = json['reporter_nim']?.toString().trim();
    }
    if (nim == null || nim.isEmpty || nim == '-') {
      nim = json['user']?['nim']?.toString().trim();
    }

    // --- Extract Name (for web/admin users) ---
    String? name = json['name']?.toString().trim();
    if (name == null || name.isEmpty) name = json['nama']?.toString().trim();
    if (name == null || name.isEmpty) name = json['username']?.toString().trim();
    if (name == null || name.isEmpty) name = json['full_name']?.toString().trim();
    if (name == null || name.isEmpty) name = json['user_name']?.toString().trim();
    if (name == null || name.isEmpty) name = json['reporter_name']?.toString().trim();
    if (name == null || name.isEmpty) name = json['user']?['name']?.toString().trim();
    if (name == null || name.isEmpty) name = json['user']?['username']?.toString().trim();
    if (name == null || name.isEmpty) name = json['user']?['nama']?.toString().trim();
    if (name == null || name.isEmpty) name = json['user']?['full_name']?.toString().trim();

    // Priority: Name > NIM (student) > Role from user_id prefix
    String identity;
    if (name != null && name.isNotEmpty) {
      identity = name;
    } else if (nim != null && nim.isNotEmpty) {
      identity = nim;
    } else {
      // Fallback: derive role from user_id pattern (e.g., ADM0000001 → Admin)
      final rawUserId = json['user_id']?.toString()
          ?? json['reporter_id']?.toString()
          ?? json['user']?['id']?.toString()
          ?? '';
      identity = rawUserId.isNotEmpty ? _roleFromUserId(rawUserId) : 'Pengguna';
    }

    // --- Extract Avatar ---
    String? avatar = json['photo']?.toString();
    if (avatar == null || avatar.isEmpty) avatar = json['photo_url']?.toString();
    if (avatar == null || avatar.isEmpty) avatar = json['user_avatar']?.toString();
    if (avatar == null || avatar.isEmpty) avatar = json['reporter_avatar']?.toString();
    if (avatar == null || avatar.isEmpty) avatar = json['creator_photo']?.toString();
    if (avatar == null || avatar.isEmpty) avatar = json['creator_avatar']?.toString();
    if (avatar == null || avatar.isEmpty) avatar = json['avatar']?.toString();
    if (avatar == null || avatar.isEmpty) avatar = json['user']?['photo']?.toString();
    if (avatar == null || avatar.isEmpty) avatar = json['user']?['photo_url']?.toString();
    if (avatar == null || avatar.isEmpty) avatar = json['user']?['avatar']?.toString();
    if (avatar == null || avatar.isEmpty) avatar = json['user']?['profile_picture']?.toString();
    if (avatar == null || avatar.isEmpty) avatar = json['created_by_user']?['photo']?.toString();
    if (avatar == null || avatar.isEmpty) avatar = json['created_by_user']?['photo_url']?.toString();
    if (avatar != null && avatar.isEmpty) avatar = null;

    // --- Identify comment ID ---
    String commentId = json['id']?.toString()
        ?? json['comment_id']?.toString()
        ?? '';

    return CommentModel(
      id: commentId,
      parentId: parentId,
      userId: json['user_id']?.toString()
          ?? json['reporter_id']?.toString()
          ?? json['user']?['id']?.toString()
          ?? '',
      userName: identity,
      userAvatar: avatar,
      createdAt: json['created_at'] ?? '',
      comment: commentText,
    );
  }
}
