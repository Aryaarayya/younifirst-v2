import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:younifirst_app/services/input/auth_service.dart';

class ApiClient {
  static const String baseUrl = 'https://pointed-nanometer-slam.ngrok-free.dev/api';

  static Map<String, String> get headers {
    Map<String, String> h = {
      'ngrok-skip-browser-warning': '69420',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (AuthService.authToken != null) {
      h['Authorization'] = 'Bearer ${AuthService.authToken}';
    }
    return h;
  }

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await http.get(url, headers: headers);
  }

  static Future<http.Response> post(String endpoint, {Object? body}) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await http.post(url, headers: headers, body: body);
  }

  static Future<http.Response> put(String endpoint, {Object? body}) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await http.put(url, headers: headers, body: body);
  }

  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await http.delete(url, headers: headers);
  }

  /// Helper for Multipart Requests
  static http.MultipartRequest multipartRequest(String method, String endpoint) {
    final url = Uri.parse('$baseUrl/$endpoint');
    final request = http.MultipartRequest(method, url);
    request.headers.addAll(headers);
    return request;
  }
}
