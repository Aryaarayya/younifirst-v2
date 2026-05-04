import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:younifirst_app/models/Event_model.dart';
import 'package:younifirst_app/services/auth_service.dart';

class ApiService {
  static const String baseUrl = 'https://enlighten-resupply-usable.ngrok-free.dev/api/events';

  static Future<List<EventModel>> getEvents() async {
    final url = Uri.parse(baseUrl);
    try {
      Map<String, String> headers = {
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
      };

      if (AuthService.authToken != null) {
        headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decodedData = jsonDecode(response.body);
        List<dynamic> jsonList = [];

        if (decodedData is Map<String, dynamic> && decodedData.containsKey('data')) {
          jsonList = decodedData['data'];
        } else if (decodedData is List) {
          jsonList = decodedData;
        }

        // Filter out pending events by checking multiple possible status keys
        var filteredList = jsonList.where((data) {
          if (data['deleted_at'] != null) {
            return false;
          }

          final statusVal = data['status'] ?? data['event_status'] ?? data['approval_status'] ?? data['is_published'] ?? data['is_approved'];
          final status = statusVal?.toString().toLowerCase().trim();
          
          // Jika status adalah 'pending', '0', 'menunggu', atau 'false', maka disembunyikan
          if (status == 'pending' || status == '0' || status == 'false' || status == 'menunggu' || status == 'review' || status == 'cancelled') {
            return false;
          }
          return true;
        }).toList();

        return filteredList.map((data) => EventModel.fromJson(data)).toList();
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal menghubungi server: $e');
    }
  }

  // ✅ UPDATE: Menambahkan parameter imageBytes dan menggunakan MultipartRequest
  static Future<bool> createEvent(Map<String, String> data, Uint8List? imageBytes) async {
    final url = Uri.parse('$baseUrl/add');
    try {
      var request = http.MultipartRequest('POST', url);

      // Headers
      request.headers.addAll({
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
      });
      
      if (AuthService.authToken != null) {
        request.headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      // Masukkan field teks
      request.fields.addAll(data);

      // Masukkan file gambar (Bytes) jika ada
      if (imageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'poster',
          imageBytes,
          filename: 'event_poster.jpg',
          contentType: MediaType('image', 'jpeg'), // 🌟 WAJIB: Laravel butuh deklarasi MIME Type
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
    final url = Uri.parse('$baseUrl/$id');
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
      throw Exception('Gagal menghapus event: $e');
    }
  }
}