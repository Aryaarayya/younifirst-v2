import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:younifirst_app/models/Event_model.dart';
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:younifirst_app/services/input/api_client.dart';

class EventApiService {
  static const String endpoint = 'events';

  static Future<List<EventModel>> getEvents() async {
    try {
      final response = await ApiClient.get(endpoint);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decodedData = jsonDecode(response.body);
        List<dynamic> jsonList = [];

        if (decodedData is Map<String, dynamic> && decodedData.containsKey('data')) {
          jsonList = decodedData['data'];
        } else if (decodedData is List) {
          jsonList = decodedData;
        }

        // Filter out pending events by checking multiple possible status keys
        var filteredList = jsonList.where((data) {
          if (data['deleted_at'] != null) return false;

          final statusVal = data['status'] ?? data['event_status'] ?? data['approval_status'] ?? data['is_published'] ?? data['is_approved'];
          final status = statusVal?.toString().toLowerCase().trim();
          
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

  static Future<List<EventModel>> getMyPendingEvents() async {
    try {
      final response = await ApiClient.get('$endpoint?status=pending');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decodedData = jsonDecode(response.body);
        List<dynamic> jsonList = [];

        if (decodedData is Map<String, dynamic> && decodedData.containsKey('data')) {
          jsonList = decodedData['data'];
        } else if (decodedData is List) {
          jsonList = decodedData;
        }

        final myUserId = AuthService.userId;
        
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
    try {
      var request = ApiClient.multipartRequest('POST', '$endpoint/add');
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
          if (decoded['message'] != null) errMsg = decoded['message'];
          if (decoded['errors'] != null) {
            final errors = decoded['errors'] as Map<String, dynamic>;
            if (errors.isNotEmpty) errMsg = errors.values.first[0].toString();
          }
        } catch (_) {}
        throw Exception(errMsg);
      }
    } catch (e) {
      throw Exception('Gagal membuat event: $e');
    }
  }

  static Future<Map<String, dynamic>> getEventDetail(String id) async {
    try {
      final response = await ApiClient.get('$endpoint/$id');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decodedData = jsonDecode(response.body);
        if (decodedData is List) {
          if (decodedData.isNotEmpty) return decodedData.first as Map<String, dynamic>;
          throw Exception('Data event kosong');
        } else if (decodedData is Map<String, dynamic>) {
          if (decodedData.containsKey('data')) {
            final dataField = decodedData['data'];
            if (dataField is List) return dataField.isNotEmpty ? dataField.first as Map<String, dynamic> : throw Exception('Data event kosong');
            if (dataField is Map<String, dynamic>) return dataField;
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
    try {
      var request = ApiClient.multipartRequest('POST', '$endpoint/$id');
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
    try {
      final response = await ApiClient.delete('$endpoint/$id');

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


