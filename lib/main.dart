import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:younifirst_app/widgets/bottom_navbar.dart';
import 'package:younifirst_app/services/input/notification_service.dart';
import 'package:younifirst_app/views/event/EventDetail_pages.dart';
import 'package:younifirst_app/views/team/TeamDetail_pages.dart';
import 'package:younifirst_app/views/announcement/Announcement_pages.dart';
import 'views/Splashscreen.dart';
import 'views/Login_pages.dart';
import 'package:provider/provider.dart';
import 'package:younifirst_app/viewmodels/announcement_viewmodel.dart';
import 'package:younifirst_app/viewmodels/event_viewmodel.dart';
import 'package:younifirst_app/viewmodels/team_viewmodel.dart';
import 'package:younifirst_app/viewmodels/barang_viewmodel.dart';
import 'package:younifirst_app/viewmodels/profil_viewmodel.dart';

/// Navigator key global untuk navigasi dari notifikasi
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Firebase
  await Firebase.initializeApp();

  // Daftarkan background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Init FCM + local notifications
  await NotificationService.initialize(navKey: navigatorKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AnnouncementViewModel()),
        ChangeNotifierProvider(create: (_) => EventViewModel()),
        ChangeNotifierProvider(create: (_) => TeamViewModel()),
        ChangeNotifierProvider(create: (_) => BarangViewModel()),
        ChangeNotifierProvider(create: (_) => ProfilViewModel()),
      ],
      child: const MyApp(),
    ),
  );
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
