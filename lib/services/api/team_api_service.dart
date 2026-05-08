import 'dart:convert';
import 'package:younifirst_app/models/Teams_model.dart';
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:younifirst_app/services/input/api_client.dart';

class TeamApiService {
  static const String endpoint = 'teams';

  // ─── GET semua tim (publik, approved) ─────────────────────────────────────
  static Future<List<TeamModel>> getTeams() async {
    try {
      final response = await ApiClient.get(endpoint);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> jsonList = [];
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          jsonList = decoded['data'];
        } else if (decoded is List) {
          jsonList = decoded;
        }

        final uid = AuthService.loggedInUserId;
        return jsonList
            .map((d) => TeamModel.fromJson(d, currentUserId: uid))
            .toList();
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal memuat tim: $e');
    }
  }

  // ─── GET tim milik user (filter client-side) ─────────────────────────────
  static Future<List<TeamModel>> getMyTeams() async {
    try {
      final response = await ApiClient.get(endpoint);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> jsonList = [];
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          jsonList = decoded['data'];
        } else if (decoded is List) {
          jsonList = decoded;
        }

        final uid = AuthService.loggedInUserId;
        final allTeams = jsonList
            .map((d) => TeamModel.fromJson(d, currentUserId: uid))
            .toList();
        
        final myTeams = allTeams.where((t) => t.isOwner || t.isMember).toList();
        return myTeams;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal memuat tim saya: $e');
    }
  }

  // ─── GET detail satu tim ──────────────────────────────────────────────────
  static Future<TeamModel> getTeamDetail(String teamId) async {
    try {
      final response = await ApiClient.get('$endpoint/$teamId');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map && decoded.containsKey('data')
            ? decoded['data']
            : decoded;
        final uid = AuthService.loggedInUserId;
        return TeamModel.fromJson(data, currentUserId: uid);
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal memuat detail tim: $e');
    }
  }

  // ─── GET lamaran masuk ke tim (pending members) ────────────────────────────
  static Future<List<Map<String, dynamic>>> getTeamApplications(
      String teamId, {String? status}) async {
    String query = '';
    if (status != null && status != 'semua') {
      if (status == 'menunggu') query = '?status=pending';
      else if (status == 'diterima') query = '?status=approved';
      else if (status == 'ditolak') query = '?status=rejected';
      else query = '?status=$status';
    }

    try {
      final response = await ApiClient.get('$endpoint/$teamId/members$query');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        List<dynamic> list = [];
        if (decoded is Map && decoded.containsKey('data')) {
          list = decoded['data'] is List ? decoded['data'] : [];
        } else if (decoded is List) {
          list = decoded;
        }
        return list.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal memuat lamaran: $e');
    }
  }

  // ─── POST daftar ke tim ───────────────────────────────────────────────────
  static Future<bool> applyToTeam(String teamId) async {
    try {
      final response = await ApiClient.post('$endpoint/$teamId/join');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal mendaftar tim: $e');
    }
  }

  // ─── POST buat tim baru ───────────────────────────────────────────────────
  static Future<bool> createTeam(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.post(
        '$endpoint/add',
        body: jsonEncode(data),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception(
            'Gagal membuat tim! Status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal membuat tim: $e');
    }
  }

  // ─── POST accept/reject lamaran ───────────────────────────────────────────
  static Future<bool> respondToJoin(String teamId, String memberId, String action) async {
    try {
      final statusVal = action == 'accept' ? 'approved' : 'rejected';
      final response = await ApiClient.post(
        '$endpoint/$teamId/members/$memberId/respond',
        body: jsonEncode({
          'action': action, 
          'status': statusVal,
        }), 
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal merespon lamaran: $e');
    }
  }
}


