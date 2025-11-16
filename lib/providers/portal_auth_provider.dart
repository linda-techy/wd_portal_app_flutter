import 'package:flutter/material.dart';
import '../models/auth_models.dart';
import '../services/portal_auth_service.dart';
import '../utils/web_error_handler.dart';

class PortalAuthProvider extends ChangeNotifier {
  UserInfo? _currentUser;
  List<String> _permissions = [];
  bool _isLoading = false;
  bool _isAuthenticated = false;

  // Getters
  UserInfo? get currentUser => _currentUser;
  List<String> get permissions => _permissions;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  // Initialize auth state
  Future<void> initializeAuth() async {
    _setLoading(true);
    try {
      final isLoggedIn = await WebErrorHandler.safeAsyncWithDefault(
        () => PortalAuthService.isLoggedIn(),
        false,
        operationName: 'Check Login Status',
      );

      if (isLoggedIn) {
        await _loadUserData();
      }
    } catch (e) {
      // Handle error silently during initialization
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await PortalAuthService.login(request);

      _currentUser = response.user;
      _permissions = response.permissions;
      _isAuthenticated = true;

      return true;
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      await PortalAuthService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      _clearUserData();
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

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearUserData() {
    _currentUser = null;
    _permissions = [];
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await PortalAuthService.getCurrentUser();
      final permissions = await PortalAuthService.getPermissions();

      _currentUser = user;
      _permissions = permissions;
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _clearUserData();
    }
  }
}
