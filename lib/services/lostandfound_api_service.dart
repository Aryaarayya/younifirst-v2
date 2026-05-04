import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:younifirst_app/models/Event_model.dart';
import 'package:younifirst_app/models/lost_found_model.dart';
import 'package:younifirst_app/models/comment_model.dart';
import 'package:younifirst_app/models/announcement_model.dart';
import 'package:younifirst_app/services/auth_service.dart';

class ApiService {
  // Base URLs
  static const String baseUrl = 'https://enlighten-resupply-usable.ngrok-free.dev/api';
  static const String eventsBaseUrl = '$baseUrl/events';
  static const String lostFoundBaseUrl = '$baseUrl/lostfound';
  static const String announcementsBaseUrl = '$baseUrl/announcements';

  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return 'https://enlighten-resupply-usable.ngrok-free.dev/storage/$path';
  }

  // ==================== EVENT APIs ====================
  
  static Future<List<EventModel>> getEvents() async {
    final url = Uri.parse(eventsBaseUrl);
    try {
      Map<String, String> headers = {
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
      };

      if (AuthService.authToken != null) {
        headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decodedData = jsonDecode(response.body);
        List<dynamic> jsonList = [];

        if (decodedData is Map<String, dynamic> && decodedData.containsKey('data')) {
          jsonList = decodedData['data'];
        } else if (decodedData is List) {
          jsonList = decodedData;
        }

        return jsonList.map((data) => EventModel.fromJson(data)).toList();
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal menghubungi server: $e');
    }
  }

  static Future<bool> createEvent(Map<String, String> data, Uint8List? imageBytes) async {
    final url = Uri.parse('$eventsBaseUrl/add');
    try {
      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
      });
      
      if (AuthService.authToken != null) {
        request.headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      request.fields.addAll(data);

      if (imageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'poster',
          imageBytes,
          filename: 'event_poster.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal membuat event: $e');
    }
  }

  static Future<bool> deleteEvent(String id) async {
    final url = Uri.parse('$eventsBaseUrl/$id');
    try {
      Map<String, String> headers = {
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
      };
      if (AuthService.authToken != null) {
        headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      final response = await http.delete(url, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal menghapus event: $e');
    }
  }

   // --- REST API LOST & FOUND ---

  // 1. Get List Lost and Found
  static Future<List<LostFoundModel>> getLostAndFound() async {
    final url = Uri.parse(lostFoundBaseUrl);
    try {
      Map<String, String> headers = {
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
      };
      if (AuthService.authToken != null) {
        headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        List<dynamic> jsonList = [];
        if (decodedData is Map<String, dynamic> && decodedData.containsKey('data')) {
           jsonList = decodedData['data'];
        } else if (decodedData is List) {
           jsonList = decodedData;
        }
        return jsonList.map((data) => LostFoundModel.fromJson(data)).toList();
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal menghubungi server: $e');
    }
  }

  // Helper: Generate random 10-char ID with prefix "LF" + 8 alphanumeric chars
  static String _generateLostFoundId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final suffix = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    return 'LF$suffix'; // e.g. "LFAB12CD34" — exactly 10 chars for char(10) column
  }

  // 2. Add Lost and Found (Support Multipart untuk Gambar)
  static Future<String?> addLostAndFound({
    required String type,
    required String itemName,
    required String location,
    required String description,
    File? imageFile,
  }) async {
    final url = Uri.parse('$lostFoundBaseUrl/add');
    try {
      var request = http.MultipartRequest('POST', url);
      
      request.headers.addAll({
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
      });
      if (AuthService.authToken != null) {
        request.headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      // Generate proper 10-char ID matching char(10) DB column
      String lostFoundId = _generateLostFoundId();

      // Map type ke status enum: Hilang = 'lost', Ditemukan = 'found'
      String status = type == 'Ditemukan' ? 'found' : 'lost';
      
      // Fields sesuai dengan tabel lostfound_items
      request.fields['lostfound_id'] = lostFoundId;
      request.fields['user_id'] = AuthService.loggedInUserId ?? ''; 
      request.fields['item_name'] = itemName;
      request.fields['description'] = description;
      request.fields['location'] = location;
      request.fields['status'] = status;

      if (imageFile != null) {
        // Determine content type from file extension
        String ext = imageFile.path.split('.').last.toLowerCase();
        String mimeSubtype = ext == 'png' ? 'png' : 'jpeg';
        
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo',
            imageFile.path,
            contentType: MediaType('image', mimeSubtype),
          ),
        );
      }

      debugPrint('📤 Posting Lost & Found:');
      debugPrint('   ID: $lostFoundId');
      debugPrint('   user_id: ${AuthService.loggedInUserId}');
      debugPrint('   item_name: $itemName');
      debugPrint('   location: $location');
      debugPrint('   status: $status (type: $type)');
      debugPrint('   has_photo: ${imageFile != null}');

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      debugPrint('📥 Response: ${response.statusCode}');
      debugPrint('   Body: $respStr');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return lostFoundId;
      } else {
        throw Exception('Status ${response.statusCode}: $respStr');
      }
    } catch (e) {
      throw Exception('Gagal mengirim data: $e');
    }
  }

  // 3. Get Comments for Lost and Found
  static Future<List<CommentModel>> getComments(String lostFoundId) async {
    final url = Uri.parse('$lostFoundBaseUrl/$lostFoundId/comments');
    try {
      Map<String, String> headers = {
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
      };
      if (AuthService.authToken != null) {
        headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        List<dynamic> jsonList = [];
        if (decodedData is Map<String, dynamic> && decodedData.containsKey('data')) {
           jsonList = decodedData['data'];
        } else if (decodedData is List) {
           jsonList = decodedData;
        }
        return jsonList.map((data) => CommentModel.fromJson(data)).toList();
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal mengambil komentar: $e');
    }
  }

  // 4. Add Comment
  static Future<bool> addComment(String lostFoundId, String commentMessage, {String? parentId}) async {
    final url = Uri.parse('$lostFoundBaseUrl/$lostFoundId/comments');
    try {
      Map<String, String> headers = {
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      if (AuthService.authToken != null) {
        headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      String finalMessage = parentId != null ? '[re:$parentId] $commentMessage' : commentMessage;

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'comment': finalMessage,
        })
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal mengirim komentar: $e');
    }
  }

  // 4a. Update Comment
  static Future<bool> updateComment(String commentId, String commentMessage) async {
    final url = Uri.parse('$lostFoundBaseUrl/comments/$commentId');
    try {
      Map<String, String> headers = {
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      if (AuthService.authToken != null) {
        headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          'comment': commentMessage,
        })
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal memperbarui komentar: $e');
    }
  }

  // 4b. Delete Comment
  static Future<bool> deleteComment(String commentId) async {
    final url = Uri.parse('$lostFoundBaseUrl/comments/$commentId');
    try {
      Map<String, String> headers = {
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
      };
      if (AuthService.authToken != null) {
        headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal menghapus komentar: $e');
    }
  }

  // 5. Delete Lost and Found
  static Future<bool> deleteLostFound(String lostFoundId) async {
    final url = Uri.parse('$lostFoundBaseUrl/$lostFoundId');
    try {
      Map<String, String> headers = {
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
      };
      if (AuthService.authToken != null) {
        headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      final response = await http.delete(url, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal menghapus postingan: $e');
    }
  }


  // ==================== ANNOUNCEMENT APIs ====================

  static Future<List<AnnouncementModel>> getAnnouncements() async {
    final url = Uri.parse(announcementsBaseUrl);
    try {
      Map<String, String> headers = {
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
      };

      if (AuthService.authToken != null) {
        headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decodedData = jsonDecode(response.body);
        List<dynamic> jsonList = [];

        if (decodedData is Map<String, dynamic> && decodedData.containsKey('data')) {
          jsonList = decodedData['data'];
        } else if (decodedData is List) {
          jsonList = decodedData;
        }

        return jsonList.map((data) => AnnouncementModel.fromJson(data)).toList();
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal mengambil pengumuman: $e');
    }
  }

  // 2. Get Single Announcement by ID
  static Future<AnnouncementModel> getAnnouncementById(String id) async {
    final url = Uri.parse('$announcementsBaseUrl/$id');
    try {
      Map<String, String> headers = {
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
      };
      if (AuthService.authToken != null) {
        headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        Map<String, dynamic> data;
        if (decodedData is Map<String, dynamic> && decodedData.containsKey('data')) {
           data = decodedData['data'];
        } else {
           data = decodedData;
        }
        return AnnouncementModel.fromJson(data);
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal mengambil pengumuman: $e');
    }
  }

  // 1b. Get Single Lost and Found by ID
  static Future<LostFoundModel> getLostFoundById(String id) async {
    final url = Uri.parse('$lostFoundBaseUrl/$id');
    try {
      Map<String, String> headers = {
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
      };
      if (AuthService.authToken != null) {
        headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        Map<String, dynamic> data;
        if (decodedData is Map<String, dynamic> && decodedData.containsKey('data')) {
           data = decodedData['data'];
        } else {
           data = decodedData;
        }
        return LostFoundModel.fromJson(data);
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal menghubungi server: $e');
    }
  }

  // ==================== USER APIs ====================

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final url = Uri.parse('$baseUrl/user');
    try {
      Map<String, String> headers = {
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
      };
      if (AuthService.authToken != null) {
        headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal mengambil data user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<bool> updateUser(Map<String, String> data, {File? imageFile}) async {
    final userId = AuthService.loggedInUserId;
    if (userId == null) return false;

    final url = Uri.parse('$baseUrl/users/$userId');
    try {
      var request = http.MultipartRequest('POST', url); // Backend often expects POST with _method=PUT for multipart
      
      request.headers.addAll({
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
      });
      
      if (AuthService.authToken != null) {
        request.headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      // Laravel specific: use _method field to spoof PUT request over POST multipart
      request.fields['_method'] = 'PUT';
      request.fields.addAll(data);

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
        ));
      }

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}