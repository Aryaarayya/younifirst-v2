import 'package:younifirst_app/services/input/api_client.dart';
import 'package:younifirst_app/services/api/lostandfound_api_service.dart';

class LostFoundModel {
  final String lostfoundId;
  final String? userId;
  final String userName;
  final String? userEmail;
  final String? userNim;
  final String? userProdi;
  final String? userAvatar;
  final String type; // "Hilang" or "Ditemukan"
  final int statusId;
  final String itemName;
  final String location;
  final String description;
  final String? imageUrl;
  final String? createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isCompleted;

  LostFoundModel({
    required this.lostfoundId,
    this.userId,
    required this.userName,
    this.userEmail,
    this.userNim,
    this.userProdi,
    this.userAvatar,
    required this.type,
    this.statusId = 1,
    required this.itemName,
    required this.location,
    required this.description,
    this.imageUrl,
    this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isCompleted = false,
  });

  // Helper getter for backward compatibility (int id)
  int get id {
    return int.tryParse(lostfoundId) ?? lostfoundId.hashCode;
  }

  factory LostFoundModel.fromJson(Map<String, dynamic> json) {
    // Determine type from status enum ('lost', 'found', 'claimed') or name_status
    String type = 'Hilang';
    if (json['status'] != null) {
      String statusStr = json['status'].toString().toLowerCase();
      if (statusStr == 'found') {
        type = 'Ditemukan';
      } else if (statusStr == 'claimed') {
        type = 'Diklaim';
      } else {
        type = 'Hilang';
      }
    } else if (json['name_status'] != null) {
      type = json['name_status'];
    } else if (json['type'] != null) {
      type = json['type'];
    }

    int statusId = 1;
    if (json['status_id'] != null) {
      statusId = json['status_id'] is int
          ? json['status_id']
          : int.tryParse(json['status_id'].toString()) ?? 1;
    }

    // Handle lostfound_id (could be string like "LFXXXXXXXX" or numeric)
    String lostfoundId = '';
    if (json['lostfound_id'] != null) {
      lostfoundId = json['lostfound_id'].toString();
    } else if (json['id'] != null) {
      lostfoundId = json['id'].toString();
    }

    // Get user name from various possible response structures
    String userName = json['reporter_name']
        ?? json['user']?['name']
        ?? json['user_name']
        ?? 'Unknown User';

    String? userAvatar = json['user']?['profile_picture']
        ?? json['reporter_avatar']
        ?? json['user_avatar'];

    // Handle photo: could be relative path, full URL, or null
    String? imageUrl;
    if (json['photo'] != null && json['photo'].toString().isNotEmpty) {
      imageUrl = LostFoundApiService.getFullUrl(json['photo'].toString());
    } else if (json['image_url'] != null) {
      imageUrl = LostFoundApiService.getFullUrl(json['image_url'].toString());
    } else if (json['image'] != null) {
      imageUrl = LostFoundApiService.getFullUrl(json['image'].toString());
    }

    return LostFoundModel(
      lostfoundId: lostfoundId,
      userId: json['reporter_id']?.toString() ?? json['user_id']?.toString(),
      userName: userName,
      userEmail: json['reporter_email'],
      userNim: json['reporter_nim'],
      userProdi: json['reporter_prodi'],
      userAvatar: userAvatar,
      type: type,
      statusId: statusId,
      itemName: json['item_name'] ?? json['title'] ?? '',
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      imageUrl: imageUrl,
      createdAt: json['created_at'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['total_comments'] ?? json['comments_count'] ?? 0,
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lostfound_id': lostfoundId,
      'item_name': itemName,
      'location': location,
      'description': description,
      'status_id': statusId,
      'photo': imageUrl,
    };
  }
}
