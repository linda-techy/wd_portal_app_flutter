import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_models.dart';
import '../services/portal_auth_service.dart';
import '../services/notification_service.dart';
import '../utils/web_error_handler.dart';
import 'permission_provider.dart';

class PortalAuthProvider extends ChangeNotifier {
  UserInfo? _currentUser;
  List<String> _permissions = [];
  bool _isLoading = true;
  bool _isAuthenticated = false;

  // Getters
  UserInfo? get currentUser => _currentUser;
  UserInfo? get user => _currentUser;
  List<String> get permissions => _permissions;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  // Initialize auth state
  Future<void> initializeAuth(BuildContext? context) async {
    _setLoading(true);
    try {
      final isLoggedIn = await WebErrorHandler.safeAsyncWithDefault(
        () => PortalAuthService.isLoggedIn(),
        false,
        operationName: 'Check Login Status',
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Auth check timed out after 5 seconds');
          return false;
        },
      );

      if (isLoggedIn) {
        if (context != null && context.mounted) {
          await _loadUserData(context).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('Load user data timed out after 5 seconds');
              throw TimeoutException('Failed to load user data');
            },
          );
        }
      }
    } catch (e) {
      // Handle error silently during initialization but clear state
      debugPrint('Auth initialization error: $e');
      if (context != null && context.mounted) {
        _clearUserData(context);
      }
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login(String email, String password, BuildContext? context) async {
    _setLoading(true);
    
    // Capture provider early to ensure we can set permissions even if context unmounts
    PermissionProvider? permProvider;
    if (context != null && context.mounted) {
      permProvider = Provider.of<PermissionProvider>(context, listen: false);
    }

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await PortalAuthService.login(request);

      _currentUser = response.user;
      _permissions = response.permissions;
      _isAuthenticated = true;

      // Update PermissionProvider using captured reference
      if (permProvider != null) {
        permProvider.setPermissions(response.permissions, response.user.roleCode);
      } else if (context != null && context.mounted) {
        // Fallback to finding it again if initially missed but context valid now (unlikely scenario)
        Provider.of<PermissionProvider>(context, listen: false)
            .setPermissions(response.permissions, response.user.roleCode);
      }

      // Initialize Firebase push notifications after successful login
      NotificationService.initialize(
        onTokenReceived: (token) => PortalAuthService.registerFcmToken(token),
      ).catchError((e) {
        // FCM init failure must never break the login flow
        debugPrint('FCM init error: $e');
      });

      return true;
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout(BuildContext? context) async {
    _setLoading(true);
    
    // Capture provider early to ensure we can clear permissions even if context unmounts
    PermissionProvider? permProvider;
    if (context != null && context.mounted) {
      permProvider = Provider.of<PermissionProvider>(context, listen: false);
    }

    try {
      await PortalAuthService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      if (context != null && context.mounted) {
        _clearUserData(context, permissionProvider: permProvider);
      }
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    try {
      final user = await PortalAuthService.getCurrentUser();
      final permissions = await PortalAuthService.getPermissions();

      _currentUser = user;
      _permissions = permissions;
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  // Permission checking methods
  bool hasPermission(String permission) {
    return _permissions.contains(permission);
  }

  bool hasAnyPermission(List<String> requiredPermissions) {
    return requiredPermissions
        .any((permission) => _permissions.contains(permission));
  }

  bool hasAllPermissions(List<String> requiredPermissions) {
    return requiredPermissions
        .every((permission) => _permissions.contains(permission));
  }

  // Role checking methods
  bool hasRole(String roleCode) {
    return _currentUser?.roleCode == roleCode;
  }

  bool hasAnyRole(List<String> roleCodes) {
    return roleCodes.contains(_currentUser?.roleCode);
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearUserData(BuildContext? context, {PermissionProvider? permissionProvider}) {
    _currentUser = null;
    _permissions = [];
    _isAuthenticated = false;
    
    // Clear PermissionProvider
    if (permissionProvider != null) {
      permissionProvider.clearPermissions();
    } else if (context != null && context.mounted) {
      final provider = Provider.of<PermissionProvider>(context, listen: false);
      provider.clearPermissions();
    }
    
    notifyListeners();
  }

  Future<void> _loadUserData(BuildContext? context) async {
    // Capture provider early
    PermissionProvider? permProvider;
    if (context != null && context.mounted) {
      permProvider = Provider.of<PermissionProvider>(context, listen: false);
    }

    try {
      final user = await PortalAuthService.getCurrentUser();
      final permissions = await PortalAuthService.getPermissions();

      _currentUser = user;
      _permissions = permissions;
      _isAuthenticated = true;
      
      // Update PermissionProvider
      if (permProvider != null) {
        permProvider.setPermissions(permissions, user.roleCode);
      } else if (context != null && context.mounted) {
        Provider.of<PermissionProvider>(context, listen: false)
            .setPermissions(permissions, user.roleCode);
      }
      
      notifyListeners();
    } catch (e) {
      if (context != null && context.mounted) {
        _clearUserData(context, permissionProvider: permProvider);
      }
    }
  }
  // Change Password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    try {
      await PortalAuthService.changePassword(
        _currentUser!.id,
        currentPassword,
        newPassword,
      );
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
