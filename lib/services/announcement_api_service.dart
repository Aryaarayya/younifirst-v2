import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:younifirst_app/models/Announcement_model.dart';
import 'package:younifirst_app/services/auth_service.dart';

class AnnouncementApiService {
  static const String baseUrl =
      'https://enlighten-resupply-usable.ngrok-free.dev/api/announcements';

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'ngrok-skip-browser-warning': '69420',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (AuthService.authToken != null) {
      headers['Authorization'] = 'Bearer ${AuthService.authToken}';
    }
    return headers;
  }

  // ─── GET semua pengumuman ─────────────────────────────────────────────────
  static Future<List<AnnouncementModel>> getAnnouncements() async {
    final url = Uri.parse(baseUrl);
    try {
      final response = await http.get(url, headers: _headers);

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
    final url = Uri.parse('$baseUrl/$id');
    try {
      final response = await http.get(url, headers: _headers);

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
    final url = Uri.parse('$baseUrl/add');
    try {
      final body = jsonEncode({
        'title': title,
        'content': content,
        if (category != null) 'category': category,
        'created_by': createdBy,
      });

      final response = await http.post(url, headers: _headers, body: body);

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
    final url = Uri.parse('$baseUrl/$id');
    try {
      final body = jsonEncode({
        'title': title,
        'content': content,
        if (category != null) 'category': category,
      });

      final response = await http.put(url, headers: _headers, body: body);

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
    final url = Uri.parse('$baseUrl/$id');
    try {
      final headers = {..._headers}..remove('Content-Type');
      final response = await http.delete(url, headers: headers);

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
