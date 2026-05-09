import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:younifirst_app/models/lost_found_model.dart';
import 'package:younifirst_app/models/comment_model.dart';
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:younifirst_app/services/input/api_client.dart';

class LostFoundApiService {
  static const String endpoint = 'lostfound';

  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Menggunakan base URL yang sama dengan ApiClient
    final storageBase = ApiClient.baseUrl.replaceAll('/api', '');
    return '$storageBase/storage/$path';
  }

   // --- REST API LOST & FOUND ---

  static Future<List<LostFoundModel>> getLostAndFound() async {
    try {
      final response = await ApiClient.get(endpoint);
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

  static String _generateLostFoundId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final suffix = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    return 'LF$suffix';
  }

  static Future<String?> addLostAndFound({
    required String type,
    required String itemName,
    required String location,
    required String description,
    File? imageFile,
  }) async {
    try {
      var request = ApiClient.multipartRequest('POST', '$endpoint/add');
      
      String lostFoundId = _generateLostFoundId();
      String status = type == 'Ditemukan' ? 'found' : 'lost';
      
      request.fields['lostfound_id'] = lostFoundId;
      request.fields['user_id'] = AuthService.loggedInUserId ?? ''; 
      request.fields['item_name'] = itemName;
      request.fields['description'] = description;
      request.fields['location'] = location;
      request.fields['status'] = status;

      if (imageFile != null) {
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

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return lostFoundId;
      } else {
        throw Exception('Status ${response.statusCode}: $respStr');
      }
    } catch (e) {
      throw Exception('Gagal mengirim data: $e');
    }
  }

  static Future<List<CommentModel>> getComments(String lostFoundId) async {
    try {
      final response = await ApiClient.get('$endpoint/$lostFoundId/comments');
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

  static Future<bool> addComment(String lostFoundId, String commentMessage, {String? parentId}) async {
    try {
      String finalMessage = parentId != null ? '[re:$parentId] $commentMessage' : commentMessage;
      final response = await ApiClient.post(
        '$endpoint/$lostFoundId/comments',
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

  static Future<bool> updateComment(String commentId, String commentMessage) async {
    try {
      final response = await ApiClient.put(
        '$endpoint/comments/$commentId',
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

  static Future<bool> deleteComment(String commentId) async {
    try {
      final response = await ApiClient.delete('$endpoint/comments/$commentId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal menghapus komentar: $e');
    }
  }

  static Future<bool> deleteLostFound(String lostFoundId) async {
    try {
      final response = await ApiClient.delete('$endpoint/$lostFoundId');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal menghapus postingan: $e');
    }
  }

  static Future<LostFoundModel> getLostFoundById(String id) async {
    try {
      final response = await ApiClient.get('$endpoint/$id');
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
}

