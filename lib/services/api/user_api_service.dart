import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:younifirst_app/services/input/api_client.dart';

class UserApiService {
  static const String endpoint = 'user';

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await ApiClient.get(endpoint);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Laravel biasanya mengembalikan { "data": { ... } } atau langsung { ... }
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

  static Future<bool> updateUser(Map<String, String> data, {File? imageFile}) async {
    final userId = AuthService.loggedInUserId;
    if (userId == null) return false;

    try {
      var request = ApiClient.multipartRequest('POST', 'users/$userId');
      request.fields['_method'] = 'PUT';
      request.fields.addAll(data);

      debugPrint('📤 Update URL: ${request.url}');
      debugPrint('📤 Fields: ${request.fields}');
      debugPrint('📤 imageFile: $imageFile');

      if (imageFile != null) {
        debugPrint('📤 File exists: ${imageFile.existsSync()}');
        debugPrint('📤 File path: ${imageFile.path}');
        debugPrint('📤 File size: ${imageFile.lengthSync()} bytes');
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
        ));
        debugPrint('📤 Files attached: ${request.files.length}');
      } else {
        debugPrint('📤 No image file provided');
      }

      debugPrint('📤 Request headers: ${request.headers}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('📤 Update profile response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

}

