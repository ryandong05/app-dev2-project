import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'models/settings_model.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Awesome Notifications
  await NotificationService().initializeNotifications();

  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsModel>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Twitter Clone',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFEEF2F5),
            cardColor: Colors.white,
            dividerColor: Colors.grey.shade300,
            iconTheme: const IconThemeData(color: Colors.grey),
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            dividerColor: Colors.grey.shade800,
            iconTheme: IconThemeData(color: Colors.grey.shade400),
          ),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const WelcomeScreen(),
            '/home': (context) => const HomeScreen(),
            '/search': (context) => const SearchScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
