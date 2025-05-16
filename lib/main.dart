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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase Messaging
  await NotificationService().initializeNotifications();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

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
            primarySwatch: Colors.grey,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            cardColor: Colors.white,
            dividerColor: const Color(0xFFE0E0E0),
            iconTheme: const IconThemeData(color: Color(0xFF757575)),
            colorScheme: ColorScheme.light(
              primary: Colors.black,
              secondary: const Color(0xFF424242),
              surface: Colors.white,
              background: Colors.white,
              error: const Color(0xFFB00020),
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Colors.black,
              onBackground: Colors.black,
              onError: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.grey,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            cardColor: const Color(0xFF121212),
            dividerColor: const Color(0xFF424242),
            iconTheme: const IconThemeData(color: Color(0xFFBDBDBD)),
            colorScheme: ColorScheme.dark(
              primary: Colors.white,
              secondary: const Color(0xFFBDBDBD),
              surface: const Color(0xFF121212),
              background: Colors.black,
              error: const Color(0xFFCF6679),
              onPrimary: Colors.black,
              onSecondary: Colors.black,
              onSurface: Colors.white,
              onBackground: Colors.white,
              onError: Colors.black,
            ),
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
