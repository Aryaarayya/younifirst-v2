import 'package:flutter/material.dart';
import 'package:younifirst_app/pages/announcement/Announcement_pages.dart';

class NotificationBell extends StatelessWidget {
  final Color iconColor;

  const NotificationBell({Key? key, this.iconColor = Colors.black}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.notifications_none, color: iconColor),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnnouncementPage()),
        );
      },
    );
  }
}
