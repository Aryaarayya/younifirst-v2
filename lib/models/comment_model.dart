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
    // Aggressively strip any [re:...] tag from the start of the comment
    if (comment.startsWith('[re:')) {
      return comment.replaceFirst(RegExp(r'\[re:[^\]]*\]'), '').trim();
    }
    return comment;
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    String? parentId = json['parent_id']?.toString();
    String commentText = json['comment'] ?? '';

    // If parentId is missing but present in the comment tag [re:ID] or [re: ID]
    if (parentId == null || parentId.isEmpty) {
      RegExp regExp = RegExp(r'\[re:\s*([^\]\s]+)\]');
      Match? match = regExp.firstMatch(commentText);
      if (match != null) {
        parentId = match.group(1);
      }
    }

    // Identify user name/identity (Priority: NIM -> Name -> Unknown)
    // Based on UserSeeder: nim, user_id, name are available.
    String identity = json['nim'] 
        ?? json['user_nim']
        ?? json['reporter_nim'] 
        ?? json['user']?['nim'] 
        ?? json['user']?['user_id']
        ?? json['user_name'] 
        ?? json['reporter_name'] 
        ?? json['user']?['name'] 
        ?? 'Unknown';

    // Identify comment ID (try various common keys)
    String commentId = json['id']?.toString() 
        ?? json['comment_id']?.toString() 
        ?? '';

    return CommentModel(
      id: commentId,
      parentId: parentId,
      userId: json['user_id']?.toString() ?? json['reporter_id']?.toString() ?? '',
      userName: identity,
      userAvatar: json['user_avatar'] ?? json['reporter_avatar'] ?? json['user']?['profile_picture'] ?? json['user']?['photo'],
      createdAt: json['created_at'] ?? '',
      comment: commentText,
    );
  }
}
