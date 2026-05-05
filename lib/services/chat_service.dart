import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:younifirst_app/models/chat_message_model.dart';
import 'package:younifirst_app/services/auth_service.dart';

/// ChatService menggunakan Firebase Realtime Database untuk real-time chat.
class ChatService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ─── Real-time stream ────────────────────────────────────────────────────────
  /// Menghasilkan Stream pesan dari Realtime Database.
  static Stream<List<ChatMessageModel>> getMessagesStream(String teamId) {
    final ref = _db.ref('rooms/$teamId/messages');

    return ref.orderByChild('created_at').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<dynamic, dynamic> rawMap = data as Map<dynamic, dynamic>;

      final List<ChatMessageModel> messages = rawMap.entries.map((entry) {
        final Map<String, dynamic> msgData =
            Map<String, dynamic>.from(entry.value as Map);

        // Gunakan key dokumen sebagai ID
        msgData['id'] = entry.key.toString();

        // Pastikan field 'message' ada (support field 'text' juga)
        if (msgData['text'] != null && msgData['message'] == null) {
          msgData['message'] = msgData['text'];
        }

        return ChatMessageModel.fromJson(msgData);
      }).toList();

      // Urutkan berdasarkan created_at ascending
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return messages;
    });
  }

  // ─── POST message (Realtime Database push) ───────────────────────────────────
  static Future<void> sendMessage(String teamId, String message) async {
    try {
      final userId = AuthService.loggedInUserId;
      final userName = AuthService.loggedInUserName ?? 'User';

      if (userId == null) {
        throw Exception('Anda belum login.');
      }

      final ref = _db.ref('rooms/$teamId/messages');
      final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;

      await ref.push().set({
        'message': message,
        'text': message,
        'sender_id': userId,
        'sender_name': userName,
        'team_id': teamId,
        'created_at': timestamp, // Milliseconds epoch untuk sorting
      });
    } catch (e) {
      throw Exception('Gagal mengirim pesan: $e');
    }
  }
}
