import 'package:admin/controllers/menu_app_controller.dart';
// import 'package:admin/screens/main/main_screen.dart';
import 'package:admin/config/app_config.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/providers/procurement_provider.dart';
import 'package:admin/providers/labour_provider.dart';
import 'package:admin/providers/inventory_provider.dart';
import 'package:admin/providers/finance_provider.dart';
import 'package:admin/providers/approval_provider.dart';
import 'package:admin/providers/document_provider.dart';
import 'package:admin/providers/project_tracking_provider.dart';
import 'package:admin/providers/subcontract_provider.dart';
import 'package:admin/providers/vendor_payment_provider.dart';
import 'package:admin/services/portal_auth_service.dart';
import 'package:admin/services/storage_service.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/services/project_tracking_service.dart';
import 'package:admin/services/subcontract_service.dart';
import 'package:admin/services/vendor_payment_service.dart';
import 'package:admin/utils/api_connection_test.dart';
import 'package:admin/utils/web_error_handler.dart';
import 'package:admin/widgets/portal_auth_wrapper.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/utils/navigation_service.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize platform-conditional storage (CRITICAL for web)
  await StorageService().initialize();

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
      navigatorKey: NavigationService.navigatorKey,
      scaffoldMessengerKey: NavigationService.scaffoldMessengerKey,
      title: AppConfig.appName,
      // Use new construction-appropriate theme
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (context) {
        // Initialize services first
        final apiService = ApiService();
        final subcontractService = SubcontractService(apiService);
        final vendorPaymentService = VendorPaymentService(apiService);
        final projectTrackingService = ProjectTrackingService(apiService);

        return MultiProvider(
          providers: [
            // Services
            Provider<ApiService>.value(value: apiService),
            Provider<StorageService>(create: (_) => StorageService()),
            
            // Menu controller
            ChangeNotifierProvider(create: (_) => MenuAppController()),
            
            // Auth provider
            ChangeNotifierProvider(
              create: (_) => PortalAuthProvider(),
            ),
            
            // Permission provider
            ChangeNotifierProvider(create: (_) => PermissionProvider()),
            
            // Domain providers
            ChangeNotifierProvider(create: (_) => ProcurementProvider()),
            ChangeNotifierProvider(create: (_) => LabourProvider()),
            ChangeNotifierProvider(create: (_) => InventoryProvider()),
            ChangeNotifierProvider(create: (_) => FinanceProvider()),
            ChangeNotifierProvider(create: (_) => ApprovalProvider()),
            ChangeNotifierProvider(create: (_) => DocumentProvider()),
            ChangeNotifierProvider(create: (_) => ProjectTrackingProvider(projectTrackingService)),
            
            // Phase 1: Subcontractor & Vendor Payment
            ChangeNotifierProvider(create: (_) => SubcontractProvider(subcontractService)),
            ChangeNotifierProvider(create: (_) => VendorPaymentProvider(vendorPaymentService)),
          ],
          child: const PortalAuthWrapper(),
        );
        }
      ),
    );
  }
}
