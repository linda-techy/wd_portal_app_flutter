import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/portal_auth_provider.dart';
import '../screens/auth/portal_login_screen.dart';
import '../screens/main/main_screen.dart';

class PortalAuthWrapper extends StatelessWidget {
  const PortalAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PortalAuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          return const MainScreen();
        }

        return const PortalLoginScreen();
      },
    );
  }
}
