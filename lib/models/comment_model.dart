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
    if (parentId != null && comment.startsWith('[re:$parentId]')) {
      return comment.replaceFirst('[re:$parentId]', '').trim();
    }
    return comment;
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id']?.toString() ?? '',
      parentId: json['parent_id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] ?? json['user']?['name'] ?? 'Unknown',
      userAvatar: json['user_avatar'] ?? json['user']?['profile_picture'],
      createdAt: json['created_at'] ?? '',
      comment: json['comment'] ?? '',
    );
  }
}
