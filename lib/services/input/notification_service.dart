import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:younifirst_app/services/api/announcement_api_service.dart';
import 'package:younifirst_app/models/Announcement_model.dart';

// ─── Background message handler (HARUS top-level function) ───────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 [BG] Notif diterima: ${message.notification?.title}');
  await NotificationService.savePushNotification(message);
}

/// NotificationService — mengelola FCM dan local notifications
class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  /// Channel ID untuk Android 8+
  static const String _channelId = 'younifirst_channel';
  static const String _channelName = 'Younifirst Notifikasi';
  static const String _channelDesc =
      'Notifikasi untuk event, tim, dan barang hilang yang telah disetujui.';

  static const String _prefsKey = 'local_push_notifs';

  /// Global navigator key — digunakan untuk navigasi dari notifikasi
  static GlobalKey<NavigatorState>? navigatorKey;

  // ─── Initialize ────────────────────────────────────────────────────────────
  static Future<void> initialize({
    required GlobalKey<NavigatorState> navKey,
  }) async {
    navigatorKey = navKey;

    // 1. Setup local notifications channel (Android)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const initAndroid =
        AndroidInitializationSettings('@mipmap/logo_aplikasi');
    const initSettings = InitializationSettings(android: initAndroid);

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // User tap notif saat app foreground
        final payload = response.payload;
        if (payload != null) {
          _handleNavigationFromPayload(payload);
        }
      },
    );

    // 2. Minta izin notifikasi (Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint(
        '🔔 Izin notifikasi: ${settings.authorizationStatus}');

    // 3. Handler pesan saat app FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint(
          '🔔 [FG] Notif diterima: ${message.notification?.title}');
      await savePushNotification(message);
      _showLocalNotification(message);
    });

    // 4. Handler saat user tap notif & app di BACKGROUND (tapi tidak terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 [BG→OPEN] Notif di-tap: ${message.notification?.title}');
      _handleNavigationFromMessage(message);
    });

    // 5. Cek apakah app dibuka dari notifikasi saat TERMINATED
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
          '🔔 [TERMINATED] App dibuka dari notif: ${initialMessage.notification?.title}');
      // Delay sedikit agar navigator sudah siap
      await Future.delayed(const Duration(milliseconds: 500));
      _handleNavigationFromMessage(initialMessage);
    }

    // 6. Get & log FCM token
    final token = await getFcmToken();
    debugPrint('📱 FCM Token: $token');
  }

  // ─── Get FCM Token ─────────────────────────────────────────────────────────
  static Future<String?> getFcmToken() async {
    try {
      final token = await _fcm.getToken();
      return token;
    } catch (e) {
      debugPrint('❌ Gagal ambil FCM token: $e');
      return null;
    }
  }

  // ─── Tampilkan local notification (saat foreground) ──────────────────────
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;
    final payload = jsonEncode(data);

    // Tentukan ikon & warna berdasarkan kategori
    final category = data['category'] ?? 'umum';
    final Color color;
    switch (category) {
      case 'event':
        color = Colors.orange;
        break;
      case 'team':
        color = Colors.green;
        break;
      case 'barang':
        color = Colors.purple;
        break;
      default:
        color = const Color(0xFF3D5AFE);
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      color: color,
      icon: '@mipmap/logo_aplikasi',
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        contentTitle: notification.title,
        summaryText: _categoryLabel(category),
      ),
      ticker: notification.title,
    );

    await _localNotif.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  // ─── Navigasi dari payload JSON (foreground tap) ──────────────────────────
  static void _handleNavigationFromPayload(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigate(data);
    } catch (e) {
      debugPrint('❌ Gagal parse payload: $e');
    }
  }

  // ─── Navigasi dari RemoteMessage (background/terminated tap) ─────────────
  static void _handleNavigationFromMessage(RemoteMessage message) {
    _navigate(message.data);
  }

  // ─── Routing berdasarkan data payload ────────────────────────────────────
  static void _navigate(Map<String, dynamic> data) {
    final category = data['category']?.toString() ?? '';
    final id = data['id']?.toString() ?? '';

    debugPrint('🗺️ Navigate: category=$category, id=$id');

    final navigator = navigatorKey?.currentState;
    if (navigator == null) {
      debugPrint('⚠️ Navigator belum siap');
      return;
    }

    switch (category) {
      case 'event':
        if (id.isNotEmpty) {
          navigator.pushNamed('/home');
          navigator.pushNamed('/event-detail', arguments: id);
        }
        break;
      case 'team':
        if (id.isNotEmpty) {
          navigator.pushNamed('/home');
          navigator.pushNamed('/team-detail', arguments: id);
        }
        break;
      case 'barang':
        if (id.isNotEmpty) {
          navigator.pushNamed('/home');
          navigator.pushNamed('/barang-detail', arguments: id);
        }
        break;
      default:
        // Buka halaman announcement
        navigator.pushNamed('/home');
        navigator.pushNamed('/announcements');
        break;
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  static String _categoryLabel(String cat) {
    switch (cat) {
      case 'event':
        return 'Event';
      case 'team':
        return 'Tim';
      case 'barang':
        return 'Barang Hilang';
      default:
        return 'Younifirst';
    }
  }

  // ─── Unread count ─────────────────────────────────────────────────────────
  // Menghitung pengumuman baru sejak terakhir user membuka halaman Announcement
  static Future<int> getUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeenCount = prefs.getInt('last_seen_announcement_count') ?? 0;
      final announcements = await AnnouncementApiService.getAnnouncements();
      final currentCount = announcements.length;
      final unread = currentCount - lastSeenCount;
      return unread > 0 ? unread : 0;
    } catch (e) {
      return 0;
    }
  }

  // ─── Tandai semua pengumuman sudah dibaca ─────────────────────────────────
  // Dipanggil saat user membuka halaman Announcement
  static Future<void> markAnnouncementsAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final announcements = await AnnouncementApiService.getAnnouncements();
      await prefs.setInt('last_seen_announcement_count', announcements.length);
    } catch (e) {
      debugPrint('Gagal menandai pengumuman sebagai dibaca: $e');
    }
  }

  static Future<void> addNotification(String title, String body,
      {String? type, String? targetId}) async {
    // Tidak diperlukan — FCM yang mengelola
  }

  // ─── Simpan & Ambil Notifikasi Lokal (dari FCM) ───────────────────────────
  static Future<void> savePushNotification(RemoteMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listStr = prefs.getStringList(_prefsKey) ?? [];

      final notifMap = {
        'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': message.notification?.title ?? 'Notifikasi Baru',
        'content': message.notification?.body ?? '',
        'category': message.data['category'],
        'created_at': DateTime.now().toIso8601String(),
      };

      listStr.insert(0, jsonEncode(notifMap));

      // Batasi maksimal 50 notifikasi tersimpan
      if (listStr.length > 50) {
        listStr.removeLast();
      }

      await prefs.setStringList(_prefsKey, listStr);
    } catch (e) {
      debugPrint('❌ Gagal menyimpan notif lokal: $e');
    }
  }

  static Future<List<AnnouncementModel>> getLocalPushNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listStr = prefs.getStringList(_prefsKey) ?? [];

      return listStr.map((e) {
        final map = jsonDecode(e);
        return AnnouncementModel(
          id: map['id']?.toString() ?? '',
          title: map['title'] ?? 'Tanpa Judul',
          content: map['content'] ?? '',
          category: map['category'],
          createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
          updatedAt: map['created_at'] ?? DateTime.now().toIso8601String(),
          userNama: 'Sistem Notifikasi',
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Gagal mengambil notif lokal: $e');
      return [];
    }
  }
}
