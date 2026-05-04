import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // import kIsWeb
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static const String baseUrl = 'https://enlighten-resupply-usable.ngrok-free.dev/api/login';
  
  // Variabel untuk menyimpan token dan user ID secara sementara di memori aplikasi
  static String? authToken;
  static String? userId;
  static String? userName;

  static String? get loggedInUserId => userId;
  static String? get loggedInUserName => userName;

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

  // Endpoint login menggunakan Firebase (sesuai req payload)
  static Future<Map<String, dynamic>> loginWithFirebase({
    String name = "User Testing Firebase",
    required String email,
    required String password,
    String role = "user",
    String status = "active",
    String? fcmToken,
  }) async {
    final url = Uri.parse('$baseUrl');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "role": role,
          "status": status,
          if (fcmToken != null) "fcm_token": fcmToken,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('========================================');
        debugPrint('🔥 RESPONS LOGIN LENGKAP DARI BACKEND 🔥');
        debugPrint(data.toString());
        debugPrint('========================================');

        // Simpan token (sesuaikan dengan format response backend Laravel Anda)
        // Biasanya Laravel mengembalikan token di data['token'] atau data['access_token']
        if (data['token'] != null) {
          authToken = data['token'];
        } else if (data['access_token'] != null) {
          authToken = data['access_token'];
        } else if (data['data'] != null && data['data']['token'] != null) {
          authToken = data['data']['token'];
        }

        // Simpan user_id ke SharedPreferences
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
          debugPrint('✅ BErhasil menyimpan user_id STRING: $userId');
        } else {
          debugPrint('⚠️ WARNING: user_id tidak ditemukan dalam response! Response: $data');
        }

        // Simpan user_name
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

        // Cek apakah akun di-suspend dari respons API jika kode 200
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
        // Tangkap pesan error dari backend jika ada
        String errorMessage = 'Gagal login: ${response.statusCode} - ${response.body}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (_) {
          // Jika gagal parse json, tetap gunakan default error message
        }
        
        // Cek secara manual pada string response body (berjaga-jaga jika bukan json)
        if (response.body.toLowerCase().contains('suspend')) {
          throw Exception('Akun Anda telah disuspend karena melanggar pedoman komunitas.');
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Koneksi bermasalah: $e');
    }
  }

  // Method untuk Background Sync FCM Token saat aplikasi dibuka
  static Future<bool> updateFcmToken(String fcmToken) async {
    // Ambil token dari memory atau SharedPreferences
    String? token = authToken;
    final prefs = await SharedPreferences.getInstance();
    
    if (token == null) {
      token = prefs.getString('auth_token'); // Coba ambil dari prefs jika sudah diimplementasikan
    }

    if (token == null) {
      debugPrint('⚠️ Token Sanctum tidak ditemukan, lewati sync FCM token.');
      return false;
    }

    final url = Uri.parse('https://enlighten-resupply-usable.ngrok-free.dev/api/users/fcm-token');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
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

  // Method untuk mendapatkan Custom Token dari Laravel dan login ke Firebase Auth
  static Future<void> loginToFirebaseWithCustomToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (authToken == null) {
      authToken = prefs.getString('auth_token');
    }
    if (userId == null) {
      userId = prefs.getString('user_id');
    }
    if (userName == null) {
      userName = prefs.getString('user_name') ?? 'User';
    }

    if (authToken == null) {
      throw Exception('Tidak ada token autentikasi (Sanctum).');
    }

    // Hindari login berulang jika sudah login di Firebase dengan token yang valid
    if (FirebaseAuth.instance.currentUser != null) {
      debugPrint('✅ Sudah login di Firebase Auth.');
      return;
    }

    // Endpoint Laravel: GET /api/chat/token
    final url = Uri.parse('https://enlighten-resupply-usable.ngrok-free.dev/api/chat/token');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
          'ngrok-skip-browser-warning': '69420',
        },
      );

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
