import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:younifirst_app/widgets/bottom_navbar.dart';
import 'package:younifirst_app/services/input/notification_service.dart';
import 'package:younifirst_app/services/input/auth_service.dart';
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
import 'package:younifirst_app/viewmodels/settings_viewmodel.dart';

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

  // Load Auth data (UserID, Token)
  await AuthService.loadStoredAuth();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AnnouncementViewModel()),
        ChangeNotifierProvider(create: (_) => EventViewModel()),
        ChangeNotifierProvider(create: (_) => TeamViewModel()),
        ChangeNotifierProvider(create: (_) => BarangViewModel()),
        ChangeNotifierProvider(create: (_) => ProfilViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, settings, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Younifirst',
          themeMode: settings.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF3D5AF1),
            scaffoldBackgroundColor: const Color(0xFFF3F4F6),
            fontFamily: 'Inter',
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF3D5AF1),
            scaffoldBackgroundColor: const Color(0xFF121212),
            fontFamily: 'Inter',
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(settings.textScaleFactor),
              ),
              child: child!,
            );
          },
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
      },
    );
  }
}
