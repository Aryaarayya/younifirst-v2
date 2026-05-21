import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:younifirst_app/services/input/api_client.dart';

class AuthService {
  static const String baseUrl = ApiClient.baseUrl;
  
  static String? authToken;
  static String? userId;
  static String? userName;

  static String? get loggedInUserId => userId;
  static String? get loggedInUserName => userName;

  static Future<void> loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('auth_token');
    userId = prefs.getString('user_id');
    userName = prefs.getString('user_name');
    debugPrint('🔐 Loaded Auth: UserID=$userId, Token=${authToken != null ? "Exist" : "Null"}');
  }

  static Future<void> logout() async {
    authToken = null;
    userId = null;
    userName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('auth_token');
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> loginWithFirebase({
    String name = "User Testing Firebase",
    required String email,
    required String password,
    String role = "user",
    String status = "active",
    String? fcmToken,
    bool remember = false,
  }) async {
    final url = Uri.parse('$baseUrl/login');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': '69420',
        },
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "role": role,
          "status": status,
          "remember": remember,
          if (fcmToken != null) "fcm_token": fcmToken,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['token'] != null) {
          authToken = data['token'];
        } else if (data['access_token'] != null) {
          authToken = data['access_token'];
        } else if (data['data'] != null && data['data']['token'] != null) {
          authToken = data['data']['token'];
        }

        final prefs = await SharedPreferences.getInstance();
        dynamic idToSave;

        if (data['data'] != null && data['data']['user'] != null && data['data']['user']['user_id'] != null) {
          idToSave = data['data']['user']['user_id'];
        } else if (data['user'] != null && data['user']['user_id'] != null) {
          idToSave = data['user']['user_id'];
        } else if (data['user'] != null && data['user']['id'] != null) {
          idToSave = data['user']['id'];
        }

        if (idToSave != null) {
          userId = idToSave.toString();
          await prefs.setString('user_id', userId!);
        }

        String? nameToSave;
        if (data['data'] != null && data['data']['user'] != null && data['data']['user']['name'] != null) {
          nameToSave = data['data']['user']['name'];
        } else if (data['user'] != null && data['user']['name'] != null) {
          nameToSave = data['user']['name'];
        } else if (data['name'] != null) {
          nameToSave = data['name'];
        }
        
        if (nameToSave != null) {
          userName = nameToSave;
          await prefs.setString('user_name', userName!);
        }

        String? userStatus;
        if (data['data'] != null && data['data']['user'] != null && data['data']['user']['status'] != null) {
          userStatus = data['data']['user']['status'];
        } else if (data['user'] != null && data['user']['status'] != null) {
          userStatus = data['user']['status'];
        } else if (data['status'] != null) {
          userStatus = data['status'];
        }

        if (userStatus != null && (userStatus.toLowerCase() == 'suspended' || userStatus.toLowerCase() == 'suspend')) {
          throw Exception('Akun Anda telah disuspend karena melanggar pedoman komunitas.');
        }

        return data;
      } else {
        String errorMessage = 'Gagal login: ${response.statusCode} - ${response.body}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (_) {}
        
        if (response.body.toLowerCase().contains('suspend')) {
          throw Exception('Akun Anda telah disuspend karena melanggar pedoman komunitas.');
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Koneksi bermasalah: $e');
    }
  }

  static Future<bool> updateFcmToken(String fcmToken) async {
    try {
      final response = await ApiClient.post(
        'users/fcm-token',
        body: jsonEncode({
          "fcm_token": fcmToken,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ FCM Token berhasil di-sync (Background Sync)');
        return true;
      } else {
        debugPrint('❌ Gagal sync FCM token: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Koneksi bermasalah saat sync FCM token: $e');
      return false;
    }
  }

  static Future<void> loginToFirebaseWithCustomToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (authToken == null) authToken = prefs.getString('auth_token');
    if (userId == null) userId = prefs.getString('user_id');
    if (userName == null) userName = prefs.getString('user_name') ?? 'User';

    if (authToken == null) throw Exception('Tidak ada token autentikasi (Sanctum).');

    if (FirebaseAuth.instance.currentUser != null) {
      debugPrint('✅ Sudah login di Firebase Auth.');
      return;
    }

    try {
      final response = await ApiClient.get('chat/token');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final firebaseToken = data['firebase_token'] ?? data['token'];

        if (firebaseToken != null) {
          await FirebaseAuth.instance.signInWithCustomToken(firebaseToken);
          debugPrint('✅ Berhasil login ke Firebase Auth dengan custom token.');
        } else {
          throw Exception('firebase_token tidak ditemukan di response.');
        }
      } else {
        throw Exception('Gagal mendapatkan token Firebase: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Gagal login ke Firebase Auth: $e');
      throw e;
    }
  }
}

