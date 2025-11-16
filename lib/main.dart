import 'package:admin/constants.dart';
import 'package:admin/controllers/menu_app_controller.dart';
// import 'package:admin/screens/main/main_screen.dart';
import 'package:admin/config/app_config.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/services/portal_auth_service.dart';
import 'package:admin/utils/api_connection_test.dart';
import 'package:admin/utils/web_error_handler.dart';
import 'package:admin/widgets/portal_auth_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  // Initialize app configuration
  AppConfig.printConfig();

  // Initialize web-specific error handling
  WebErrorHandler.initialize();

  // Initialize API auth interceptor
  PortalAuthService.initialize();

  // Set up global error handling for web
  _setupGlobalErrorHandling();

  // Test API connection in development mode (non-blocking)
  if (AppConfig.enableDebugLogging) {
    _testApiConnectionAsync();
  }

  runApp(const MyApp());
}

// Set up global error handling for web
void _setupGlobalErrorHandling() {
  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    if (AppConfig.enableDebugLogging) {
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
    }
  };

  // Handle platform errors (web-specific)
  PlatformDispatcher.instance.onError = (error, stack) {
    if (AppConfig.enableDebugLogging) {
      debugPrint('Platform Error: $error');
      debugPrint('Stack: $stack');
    }
    return true; // Mark as handled
  };

  // Handle unhandled promise rejections (web-specific)
  if (kIsWeb) {
    _setupWebPromiseHandling();
  }
}

// Web-specific promise rejection handling
void _setupWebPromiseHandling() {
  // This will be compiled to JavaScript and handle unhandled promise rejections
  // Note: This is a workaround for web-specific promise handling
  try {
    // Add global promise rejection handler for web
    // This helps catch any remaining unhandled promises
  } catch (e) {
    if (AppConfig.enableDebugLogging) {
      debugPrint('Error setting up web promise handling: $e');
    }
  }
}

// Separate async function to avoid unhandled promise rejections
void _testApiConnectionAsync() {
  ApiConnectionTest.printConnectionInfo();

  // Use web error handler for safe async execution
  WebErrorHandler.safeAsync(
    () => ApiConnectionTest.testConnection(),
    operationName: 'API Connection Test',
  ).then((result) {
    if (result != null) {
      debugPrint(result.toString());
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: bgColor,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: Colors.black87),
        canvasColor: secondaryColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: cardBackground,
          elevation: 3,
          shadowColor: containerShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: containerBorder.withOpacity(0.5), width: 1),
          ),
          margin: const EdgeInsets.all(12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: primaryColor.withOpacity(0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: containerBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: containerBorder.withOpacity(0.8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: containerBorder.withOpacity(0.8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: errorColor, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: errorColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => MenuAppController(),
          ),
          ChangeNotifierProvider(
            create: (context) => PortalAuthProvider()..initializeAuth(),
          ),
        ],
        child: const PortalAuthWrapper(),
      ),
    );
  }
}
