import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:younifirst_app/services/input/api_client.dart';

class UserApiService {
  static const String endpoint = 'user';

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await ApiClient.get(endpoint);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') && decoded['data'] is Map) {
            return Map<String, dynamic>.from(decoded['data']);
          }
          return decoded;
        }
        throw Exception('Format response tidak sesuai');
      } else {
        throw Exception('Gagal mengambil data user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static final Map<String, Map<String, dynamic>?> _userCache = {};

  /// Ambil data profil user berdasarkan ID dengan Cache untuk UI Lists
  static Future<Map<String, dynamic>?> getUserByIdCached(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }
    final data = await getUserById(userId);
    _userCache[userId] = data;
    return data;
  }

  /// Ambil data profil user berdasarkan ID
  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    // Coba berbagai endpoint yang mungkin ada di backend
    final endpoints = [
      'users/$userId',
      'user/$userId',
      'users/profile/$userId',
      'profile/$userId',
    ];

    for (final ep in endpoints) {
      try {
        final response = await ApiClient.get(ep);
        debugPrint('🔍 GET /$ep → ${response.statusCode}');
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final result = decoded.containsKey('data') && decoded['data'] is Map
                ? Map<String, dynamic>.from(decoded['data'])
                : decoded;
            debugPrint('✅ Creator data dari /$ep: $result');
            return result;
          }
        }
      } catch (e) {
        debugPrint('❌ /$ep gagal: $e');
      }
    }
    debugPrint('⚠️ Semua endpoint user gagal untuk ID=$userId');
    return null;
  }

  static Future<bool> updateUser(Map<String, String> data, {File? imageFile}) async {
    final userId = AuthService.loggedInUserId;
    if (userId == null) return false;

    try {
      var request = ApiClient.multipartRequest('POST', 'users/profile');
      request.fields.addAll(data);

      debugPrint('📤 Update URL: ${request.url}');
      debugPrint('📤 Fields: ${request.fields}');

      if (imageFile != null && imageFile.existsSync()) {
        debugPrint('📤 File path: ${imageFile.path}');
        debugPrint('📤 File size: ${imageFile.lengthSync()} bytes');

        // Tentukan content type berdasarkan ekstensi
        final ext = imageFile.path.split('.').last.toLowerCase();
        final mimeSubtype = ext == 'png' ? 'png' : 'jpeg';

        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
          filename: 'profile_photo.$mimeSubtype',
          contentType: MediaType('image', mimeSubtype),
        ));
        debugPrint('📤 Files attached: ${request.files.length}');
      } else {
        debugPrint('📤 No image file provided');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('📤 Update profile status: ${response.statusCode}');
      debugPrint('📤 Update profile body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            if (decoded['success'] == false || decoded['status'] == 'error' || decoded.containsKey('errors')) {
              String errorMsg = decoded['message'] ?? 'Gagal memperbarui profil';
              if (decoded['errors'] != null) {
                 errorMsg += ' - ${decoded['errors'].toString()}';
              }
              throw Exception(errorMsg);
            }
          }
        } catch (e) {
           if (e is FormatException) {
             // Not JSON, assume success if 2xx
             return true;
           }
           rethrow;
        }
        return true;
      } else {
         String errorMsg = 'Error ${response.statusCode}';
         try {
           final decoded = jsonDecode(response.body);
           if (decoded is Map<String, dynamic> && decoded['message'] != null) {
              errorMsg = decoded['message'];
           }
         } catch (_) {}
         throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      throw Exception('Gagal menyimpan profil: $e');
    }
  }
}
