import 'package:flutter/material.dart';
import 'package:younifirst_app/models/Announcement_model.dart';
import 'package:younifirst_app/services/api/announcement_api_service.dart';
import 'package:younifirst_app/services/api/event_api_service.dart';
import 'package:younifirst_app/services/input/notification_service.dart';

class AnnouncementViewModel extends ChangeNotifier {
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = true;
  String? _error;

  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AnnouncementViewModel() {
    loadAnnouncements();
    NotificationService.markAnnouncementsAsRead();
  }

  Future<void> loadAnnouncements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await AnnouncementApiService.getAnnouncements();

      // Ambil pending events
      final pendingEvents = await EventApiService.getMyPendingEvents();

      // Convert pendingEvents ke AnnouncementModel (Notifikasi)
      final pendingNotifs = pendingEvents.map((e) => AnnouncementModel(
            id: e.id,
            title: e.title,
            content: 'Event Anda sedang ditinjau oleh admin. Silakan tunggu konfirmasi.',
            category: 'pengajuan_event',
            targetId: e.id,
            postImage: e.imageUrl,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
            userNama: 'Sistem',
          )).toList();

      // Ambil push notifikasi lokal yang tersimpan (dari FCM)
      final localPushNotifs = await NotificationService.getLocalPushNotifications();

      // Ambil notifikasi in-app (komentar, balasan, dll.)
      final inAppNotifs = await NotificationService.getLocalInAppNotifications();

      _announcements = [...data, ...pendingNotifs, ...localPushNotifs, ...inAppNotifs];

      // Urutkan berdasarkan tanggal terbaru
      _announcements.sort((a, b) {
        try {
          final dateA = DateTime.parse(a.createdAt);
          final dateB = DateTime.parse(b.createdAt);
          return dateB.compareTo(dateA);
        } catch (_) {
          return 0;
        }
      });

      // Reset unread badge untuk in-app notifikasi
      await NotificationService.markInAppNotifsAsRead();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kelompokkan pengumuman berdasarkan waktu
  Map<String, List<AnnouncementModel>> get groupedAnnouncements {
    final Map<String, List<AnnouncementModel>> groups = {
      'Baru': [],
      'Hari ini': [],
      'Kemarin': [],
      'Sebelumnya': [],
    };

    for (final item in _announcements) {
      try {
        final created = DateTime.parse(item.createdAt);
        final now = DateTime.now();
        final diff = now.difference(created);

        if (diff.inHours < 1) {
          groups['Baru']!.add(item);
        } else if (diff.inHours < 24 && created.day == now.day) {
          groups['Hari ini']!.add(item);
        } else if (diff.inDays == 1 ||
            (diff.inHours < 48 &&
                created.day == now.subtract(const Duration(days: 1)).day)) {
          groups['Kemarin']!.add(item);
        } else {
          groups['Sebelumnya']!.add(item);
        }
      } catch (_) {
        groups['Sebelumnya']!.add(item);
      }
    }
    // Hapus grup kosong
    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }
}
