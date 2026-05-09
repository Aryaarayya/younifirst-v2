import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:younifirst_app/models/chat_message_model.dart';
import 'package:younifirst_app/services/input/auth_service.dart';

/// ChatService menggunakan Firebase Realtime Database untuk real-time chat.
class ChatService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ─── Real-time stream ────────────────────────────────────────────────────────
  /// Menghasilkan Stream pesan dari Realtime Database.
  static Stream<List<ChatMessageModel>> getMessagesStream(String teamId) {
    final ref = _db.ref('chat_rooms/$teamId/messages');

    return ref.orderByChild('created_at').onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final List<ChatMessageModel> messages = [];
      
      // Menggunakan children agar urutan dari orderByChild tetap terjaga
      for (final child in snapshot.children) {
        if (child.value == null) continue;
        
        final Map<String, dynamic> msgData =
            Map<String, dynamic>.from(child.value as Map);

        // Gunakan key dokumen sebagai ID
        msgData['id'] = child.key;

        // Pastikan field 'message' ada
        if (msgData['text'] != null && msgData['message'] == null) {
          msgData['message'] = msgData['text'];
        }

        messages.add(ChatMessageModel.fromJson(msgData));
      }

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

      final ref = _db.ref('chat_rooms/$teamId/messages');
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
