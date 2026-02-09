import 'package:flutter/material.dart';
import 'package:admin/config/app_config.dart';

/// Splash screen shown during app initialization
/// Displays a professional loading indicator while the app initializes
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1B2E), // Dark professional background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Company Logo/Name
            Icon(
              Icons.business,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              AppConfig.appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 48),
            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
