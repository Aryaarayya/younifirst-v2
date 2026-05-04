import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:younifirst_app/models/Event_model.dart';
import 'package:younifirst_app/services/auth_service.dart';

class EventApiService {
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

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decodedData = jsonDecode(response.body);
        List<dynamic> jsonList = [];

        if (decodedData is Map<String, dynamic> && decodedData.containsKey('data')) {
          jsonList = decodedData['data'];
        } else if (decodedData is List) {
          jsonList = decodedData;
        }

        if (jsonList.isNotEmpty) {
          print('====================================');
          print('🔥 DEBUG EVENT PERTAMA DARI BACKEND 🔥');
          print(jsonList.first);
          print('====================================');
        }

        // Filter out pending events by checking multiple possible status keys
        var filteredList = jsonList.where((data) {
          // Jangan tampilkan jika deleted_at tidak null (sudah dihapus / soft-deleted)
          if (data['deleted_at'] != null) {
            return false;
          }

          final statusVal = data['status'] ?? data['event_status'] ?? data['approval_status'] ?? data['is_published'] ?? data['is_approved'];
          final status = statusVal?.toString().toLowerCase().trim();
          
          // Jika status adalah 'pending', '0', 'menunggu', atau 'false', maka disembunyikan
          if (status == 'pending' || status == '0' || status == 'false' || status == 'menunggu' || status == 'review' || status == 'cancelled') {
            return false;
          }
          return true; // Tampilkan yang lain
        }).toList();

        return filteredList.map((data) => EventModel.fromJson(data)).toList();
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal menghubungi server: $e');
    }
  }

  static Future<List<EventModel>> getMyPendingEvents() async {
    final url = Uri.parse('$baseUrl?status=pending');
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

        final myUserId = AuthService.userId;
        
        // Hanya ambil yang statusnya pending dan dibuat oleh user ini
        var filteredList = jsonList.where((data) {
          if (data['deleted_at'] != null) return false;
          final createdBy = data['created_by']?.toString();
          return createdBy == myUserId;
        }).toList();

        return filteredList.map((data) => EventModel.fromJson(data)).toList();
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print("Gagal mengambil pending events: $e");
      return [];
    }
  }

  static Future<bool> createEvent(Map<String, String> data, Uint8List? imageBytes) async {
    final url = Uri.parse('$baseUrl/add');
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
        String errMsg = 'Terjadi kesalahan pada server.';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded['message'] != null) {
            errMsg = decoded['message'];
          }
          if (decoded['errors'] != null) {
            final errors = decoded['errors'] as Map<String, dynamic>;
            if (errors.isNotEmpty) {
              errMsg = errors.values.first[0].toString();
            }
          }
        } catch (_) {
          errMsg = 'Status ${response.statusCode}: ${response.body}';
        }
        throw Exception(errMsg);
      }
    } catch (e) {
      throw Exception('Gagal membuat event: $e');
    }
  }

  static Future<Map<String, dynamic>> getEventDetail(String id) async {
    final url = Uri.parse('$baseUrl/$id');
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
        if (decodedData is List) {
          if (decodedData.isNotEmpty) {
            return decodedData.first as Map<String, dynamic>;
          } else {
            throw Exception('Data event kosong');
          }
        } else if (decodedData is Map<String, dynamic>) {
          if (decodedData.containsKey('data')) {
            final dataField = decodedData['data'];
            if (dataField is List) {
               return dataField.isNotEmpty ? dataField.first as Map<String, dynamic> : throw Exception('Data event kosong');
            } else if (dataField is Map<String, dynamic>) {
               return dataField;
            }
          }
          return decodedData;
        }
        throw Exception('Format data tidak sesuai');
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal memuat detail event: $e');
    }
  }

  static Future<bool> updateEvent(String id, Map<String, String> data, Uint8List? imageBytes) async {
    final url = Uri.parse('$baseUrl/$id');
    try {
      var request = http.MultipartRequest('POST', url); // Laravel uses POST + _method=PUT for multipart formData

      request.headers.addAll({
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
      });
      
      if (AuthService.authToken != null) {
        request.headers['Authorization'] = 'Bearer ${AuthService.authToken}';
      }

      // Add spoofing method PUT
      request.fields['_method'] = 'PUT';
      request.fields.addAll(data);

      if (imageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'poster',
          imageBytes,
          filename: 'event_poster_update.jpg',
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
      throw Exception('Gagal mengupdate event: $e');
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

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal menghapus event: $e');
    }
  }
}