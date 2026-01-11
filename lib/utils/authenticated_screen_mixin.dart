import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/utils/motion_toast.dart';

/// Mixin to add authentication guards and data loading helpers to screens
/// 
/// Usage:
/// ```dart
/// class MyScreen extends StatefulWidget {
///   ...
/// }
/// class _MyScreenState extends State<MyScreen> with AuthenticatedScreen {
///   @override
///   void initState() {
///     super.initState();
///     loadDataWithAuthCheck(() async {
///       // Your data loading logic here
///       await _myService.loadData();
///     });
///   }
/// }
/// ```
mixin AuthenticatedScreen<T extends StatefulWidget> on State<T> {
  
  /// Check if user is authenticated before loading data
  /// Redirects to login if not authenticated
  Future<void> loadDataWithAuthCheck(Future<void> Function() loadDataCallback) async {
    if (!mounted) return;
    
    final authProvider = Provider.of<PortalAuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      if (mounted) {
        MotionToast.show(
          context,
          message: 'Please login to continue',
          isError: true,
        );
        
        // Navigate to login after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        });
      }
      return;
    }
    
    // User is authenticated, proceed with data loading
    await loadDataCallback();
  }
  
  /// Check authentication status without redirecting
  bool get isAuthenticated {
    if (!mounted) return false;
    final authProvider = Provider.of<PortalAuthProvider>(context, listen: false);
    return authProvider.isAuthenticated;
  }
  
  /// Redirect to login with optional message
  void redirectToLogin([String message = 'Please login to continue']) {
    if (!mounted) return;
    
    MotionToast.show(
      context,
      message: message,
      isError: true,
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }
}
