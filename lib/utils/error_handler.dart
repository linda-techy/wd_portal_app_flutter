import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:admin/utils/motion_toast.dart';

class ErrorHandler {
  /// Handle API errors with detailed Dio exception support
  /// Returns true if should redirect to login
  static Future<bool> handleApiError(
    BuildContext context,
    dynamic error, {
    String defaultMessage = 'An error occurred',
    bool showToast = true,
  }) async {
    String message = defaultMessage;
    bool shouldRedirectToLogin = false;
    
    if (error is DioException) {
      final e = error;
      
      if (e.response?.statusCode == 401) {
        message = 'Session expired. Please login again.';
        shouldRedirectToLogin = true;
      } else if (e.response?.statusCode == 403) {
        message = 'You do not have permission to perform this action.';
      } else if (e.response?.statusCode == 404) {
        message = 'Requested resource not found.';
      } else if (e.response?.statusCode == 500) {
        message = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout. Please check your network connection.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        message = 'Server response timeout. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Could not connect to server. Please check if API is running.';
      } else if (e.response != null) {
        // Try to extract message from response
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          message = responseData['message'];
        } else {
          message = 'Server error: ${e.response?.statusCode}';
        }
      } else {
        message = 'Network error: ${e.message ?? 'Unknown error'}';
      }
    } else if (error is Exception) {
      message = error.toString().replaceFirst('Exception: ', '');
    } else if (error is String) {
      message = error;
    } else {
      message = '$defaultMessage: ${error.toString()}';
    }
    
    if (showToast && context.mounted) {
      MotionToast.show(
        context,
        message: message,
        isError: true,
      );
    }
    
    // Handle login redirect
    if (shouldRedirectToLogin && context.mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        unawaited(Navigator.of(context).pushReplacementNamed('/login'));
      }
    }
    
    return shouldRedirectToLogin;
  }

  static Future<void> handleAuthError(BuildContext context) async {
    if (context.mounted) {
      MotionToast.show(
        context,
        message: 'Session expired. Please login again.',
        isError: true,
      );
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        unawaited(Navigator.of(context).pushReplacementNamed('/login'));
      }
    }
  }

  // Legacy methods for backward compatibility
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    String message = getErrorMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      final e = error;
      
      if (e.response?.statusCode == 401) {
        return 'Session expired. Please login again.';
      } else if (e.response?.statusCode == 403) {
        return 'You do not have permission to perform this action.';
      } else if (e.response?.statusCode == 404) {
        return 'Requested resource not found.';
      } else if (e.response?.statusCode == 500) {
        return 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        return 'Connection timeout. Please check your network connection.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return 'Server response timeout. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        return 'Could not connect to server.';
      } else if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          return responseData['message'];
        }
        return 'Server error: ${e.response?.statusCode}';
      }
      return 'Network error: ${e.message ?? 'Unknown error'}';
    } else if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    } else if (error is String) {
      return error;
    }
    return 'An unexpected error occurred';
  }

  static bool isPermissionError(dynamic error) {
    if (error is DioException) {
      return error.response?.statusCode == 403;
    }
    final message = getErrorMessage(error).toLowerCase();
    return message.contains('forbidden') ||
        message.contains('permission') ||
        message.contains('403');
  }

  static bool isAuthenticationError(dynamic error) {
    if (error is DioException) {
      return error.response?.statusCode == 401;
    }
    final message = getErrorMessage(error).toLowerCase();
    return message.contains('unauthorized') ||
        message.contains('401') ||
        message.contains('login');
  }

  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.receiveTimeout ||
             error.type == DioExceptionType.connectionError;
    }
    final message = getErrorMessage(error).toLowerCase();
    return message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('network');
  }
}
