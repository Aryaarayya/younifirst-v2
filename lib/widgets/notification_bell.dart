import 'package:flutter/material.dart';
import 'package:younifirst_app/pages/announcement/Announcement_pages.dart';
import 'package:younifirst_app/services/notification_service.dart';

class NotificationBell extends StatefulWidget {
  final Color iconColor;

  const NotificationBell({Key? key, this.iconColor = Colors.white}) : super(key: key);

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) {
      setState(() => _unreadCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Buka halaman pengumuman, lalu refresh badge setelah kembali
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnnouncementPage()),
        );
        // Setelah user menutup halaman pengumuman, reset badge
        _fetchUnreadCount();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.notifications_none,
              color: widget.iconColor,
              size: 24,
            ),
          ),
          // Badge hanya tampil jika ada pengumuman baru
          if (_unreadCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

