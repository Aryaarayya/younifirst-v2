import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:younifirst_app/models/Teams_model.dart';
import 'package:younifirst_app/services/auth_service.dart';

class TeamApiService {
  static const String baseTeamsUrl =
      'https://enlighten-resupply-usable.ngrok-free.dev/api/teams';

  static Map<String, String> get _headers => {
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (AuthService.authToken != null)
          'Authorization': 'Bearer ${AuthService.authToken}',
      };

  static Map<String, String> get _getHeaders => {
        'ngrok-skip-browser-warning': '69420',
        'Accept': 'application/json',
        if (AuthService.authToken != null)
          'Authorization': 'Bearer ${AuthService.authToken}',
      };

  // ─── GET semua tim (publik, approved) ─────────────────────────────────────
  static Future<List<TeamModel>> getTeams() async {
    final url = Uri.parse(baseTeamsUrl);
    try {
      final response = await http.get(url, headers: _getHeaders);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> jsonList = [];
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          jsonList = decoded['data'];
        } else if (decoded is List) {
          jsonList = decoded;
        }
        if (jsonList.isNotEmpty) {
          print('====================================');
          print('🔥 DEBUG TEAM PERTAMA DARI BACKEND 🔥');
          print(jsonList.first);
          print('====================================');
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
  // Note: Backend index only returns 'approved' teams.
  // Tim baru yang masih 'pending' tidak akan muncul sampai admin approve.
  static Future<List<TeamModel>> getMyTeams() async {
    final url = Uri.parse(baseTeamsUrl);
    try {
      final response = await http.get(url, headers: _getHeaders);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> jsonList = [];
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          jsonList = decoded['data'];
        } else if (decoded is List) {
          jsonList = decoded;
        }
        if (jsonList.isNotEmpty) {
          print('====================================');
          print('🔥 DEBUG MY_TEAM PERTAMA DARI BACKEND 🔥');
          print(jsonList.first);
          print('====================================');
        }

        final uid = AuthService.loggedInUserId;
        print('MY TEAMS DEBUG - LOGGED IN UID: $uid');
        // Parse all teams and mark ownership
        final allTeams = jsonList
            .map((d) {
              final team = TeamModel.fromJson(d, currentUserId: uid);
              print('TEAM PARSED: id=${team.id}, name=${team.name}, createdBy/leaderId=${team.createdBy}, isOwner=${team.isOwner}, isMember=${team.isMember}');
              return team;
            })
            .toList();
        // Filter: tim yang user ini adalah leader/owner
        final myTeams = allTeams.where((t) => t.isOwner || t.isMember).toList();
        
        // If no teams found with isOwner (leader_id might be null for new teams),
        // show all teams as fallback (user can still see all approved teams)
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
    final url = Uri.parse('$baseTeamsUrl/$teamId');
    try {
      final response = await http.get(url, headers: _getHeaders);
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
      else if (status == 'diterima') query = '?status=approved'; // Try approved or accepted
      else if (status == 'ditolak') query = '?status=rejected';
      else query = '?status=$status';
    } else {
      // If 'semua', we might want to fetch all. We can omit the query.
      // But let's assume backend returns all if no status is provided.
    }

    final url = Uri.parse('$baseTeamsUrl/$teamId/members$query');
    try {
      final response = await http.get(url, headers: _getHeaders);
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
    final url = Uri.parse('$baseTeamsUrl/$teamId/join');
    try {
      final response = await http.post(url, headers: _headers);
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
    final url = Uri.parse('$baseTeamsUrl/add');
    try {
      final response = await http.post(
        url,
        headers: _headers,
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
    final url = Uri.parse('$baseTeamsUrl/$teamId/members/$memberId/respond');
    try {
      final statusVal = action == 'accept' ? 'approved' : 'rejected';
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'action': action, // 'accept' or 'reject'
          'status': statusVal, // fallback if backend expects 'status'
        }), 
      );
      print('RESPOND API RESPONSE [${response.statusCode}]: ${response.body}');
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
