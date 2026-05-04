import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart'; // Temporarily disabled
// import 'package:firebase_messaging/firebase_messaging.dart'; // Temporarily disabled
import 'package:younifirst_app/widgets/bottom_navbar.dart';
// import 'package:younifirst_app/services/notification_service.dart'; // Temporarily disabled
import 'package:younifirst_app/pages/event/EventDetail_pages.dart';
import 'package:younifirst_app/pages/team/TeamDetail_pages.dart';
import 'package:younifirst_app/pages/announcement/Announcement_pages.dart';
import 'pages/Splashscreen.dart';
import 'pages/Login_pages.dart';

/// Navigator key global untuk navigasi dari notifikasi
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // // Init Firebase (Temporarily disabled)
  // await Firebase.initializeApp();

  // // Daftarkan background message handler
  // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // // Init FCM + local notifications
  // await NotificationService.initialize(navKey: navigatorKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => Splashscreen(),
        '/login': (context) => Login_pages(),
        '/home': (context) => BottomNavbar(),
        '/announcements': (context) => const AnnouncementPage(),
      },
      onGenerateRoute: (settings) {
        // Handle routes dengan arguments (event-detail, team-detail, dll)
        switch (settings.name) {
          case '/event-detail':
            final eventId = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => EventDetailPage(eventId: eventId),
            );
          case '/team-detail':
            final teamId = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => TeamDetailPage(teamId: teamId),
            );
          default:
            return null;
        }
      },
    );
  }
}