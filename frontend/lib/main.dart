import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/api_client.dart';
import 'services/token_storage.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  ApiClient.onSessionExpired = () async {
    await TokenStorage.clear();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  };
  runApp(const HireReadyApp());
}

class HireReadyApp extends StatelessWidget {
  const HireReadyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HireReady',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
