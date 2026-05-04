import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:younifirst_app/models/chat_message_model.dart';
import 'package:younifirst_app/services/auth_service.dart';

/// ChatService menggunakan Firebase Firestore untuk real-time chat.
class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Real-time stream (onSnapshot) ──────────────────────────────────────────
  /// Menghasilkan Stream pesan dari Firestore.
  static Stream<List<ChatMessageModel>> getMessagesStream(String teamId) {
    return _db
        .collection('rooms')
        .doc(teamId)
        .collection('messages')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Menyimpan ID dokumen
        
        // Konversi Timestamp dari Firestore menjadi String ISO 8601
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
        } else if (data['created_at'] == null) {
          data['created_at'] = DateTime.now().toIso8601String(); // Fallback jika pesan baru saja dikirim dan belum di-sync
        }

        // Support untuk mapping 'text' -> 'message' karena model mungkin mencari 'message'
        if (data['text'] != null && data['message'] == null) {
          data['message'] = data['text'];
        }

        return ChatMessageModel.fromJson(data);
      }).toList();
    });
  }

  // ─── POST message (Firestore add) ──────────────────────────────────────────
  static Future<void> sendMessage(String teamId, String message) async {
    try {
      final userId = AuthService.loggedInUserId;
      final userName = AuthService.loggedInUserName ?? 'User';

      if (userId == null) {
        throw Exception('Anda belum login.');
      }

      await _db
          .collection('rooms')
          .doc(teamId)
          .collection('messages')
          .add({
        'message': message, // Field pesan
        'text': message, // Opsional, sesuai contoh yang Anda berikan
        'sender_id': userId,
        'sender_name': userName,
        'team_id': teamId,
        'created_at': FieldValue.serverTimestamp(), // Waktu server
      });
    } catch (e) {
      throw Exception('Gagal mengirim pesan: $e');
    }
  }
}
