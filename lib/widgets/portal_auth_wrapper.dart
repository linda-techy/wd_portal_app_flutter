import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/portal_auth_provider.dart';
import '../controllers/menu_app_controller.dart';
import '../screens/auth/portal_login_screen.dart';
import '../screens/main/main_screen.dart';
import '../widgets/splash_screen.dart';

class PortalAuthWrapper extends StatefulWidget {
  const PortalAuthWrapper({super.key});

  @override
  State<PortalAuthWrapper> createState() => _PortalAuthWrapperState();
}

class _PortalAuthWrapperState extends State<PortalAuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Schedule initialization for after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PortalAuthProvider>().initializeAuth(context);
        context.read<MenuAppController>().initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PortalAuthProvider>(
      builder: (context, authProvider, child) {
        // Show professional splash screen during initialization
        if (authProvider.isLoading) {
          return const SplashScreen();
        }

        if (authProvider.isAuthenticated) {
          return const MainScreen();
        }

        return const PortalLoginScreen();
      },
    );
  }
}

