import 'dart:convert';
import 'package:younifirst_app/models/Announcement_model.dart';
import 'package:younifirst_app/services/input/api_client.dart';

class AnnouncementApiService {
  static const String endpoint = 'announcements';

  // ─── GET semua pengumuman ─────────────────────────────────────────────────
  static Future<List<AnnouncementModel>> getAnnouncements() async {
    try {
      final response = await ApiClient.get(endpoint);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> jsonList = [];

        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          final data = decoded['data'];
          jsonList = data is List ? data : [];
        } else if (decoded is List) {
          jsonList = decoded;
        }

        return jsonList
            .map((e) => AnnouncementModel.fromJson(e))
            .toList();
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal memuat pengumuman: $e');
    }
  }

  // ─── GET detail pengumuman ────────────────────────────────────────────────
  static Future<AnnouncementModel> getAnnouncementDetail(String id) async {
    try {
      final response = await ApiClient.get('$endpoint/$id');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded.containsKey('data') ? decoded['data'] : decoded;
          return AnnouncementModel.fromJson(data);
        }
        throw Exception('Format data tidak sesuai');
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal memuat detail pengumuman: $e');
    }
  }

  // ─── POST buat pengumuman baru ────────────────────────────────────────────
  static Future<bool> createAnnouncement({
    required String title,
    required String content,
    String? category,
    required String createdBy,
  }) async {
    try {
      final body = jsonEncode({
        'title': title,
        'content': content,
        if (category != null) 'category': category,
        'created_by': createdBy,
      });

      final response = await ApiClient.post('$endpoint/add', body: body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal membuat pengumuman: $e');
    }
  }

  // ─── PUT update pengumuman ────────────────────────────────────────────────
  static Future<bool> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    String? category,
  }) async {
    try {
      final body = jsonEncode({
        'title': title,
        'content': content,
        if (category != null) 'category': category,
      });

      final response = await ApiClient.put('$endpoint/$id', body: body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal mengupdate pengumuman: $e');
    }
  }

  // ─── DELETE pengumuman ────────────────────────────────────────────────────
  static Future<bool> deleteAnnouncement(String id) async {
    try {
      final response = await ApiClient.delete('$endpoint/$id');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal menghapus pengumuman: $e');
    }
  }
}


