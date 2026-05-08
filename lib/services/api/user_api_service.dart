import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:younifirst_app/services/input/api_client.dart';

class UserApiService {
  static const String endpoint = 'user';

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await ApiClient.get(endpoint);
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

    try {
      var request = ApiClient.multipartRequest('POST', 'users/$userId');
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

