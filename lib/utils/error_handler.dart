import 'package:flutter/material.dart';

class ErrorHandler {
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    String message = 'An error occurred';

    if (error is Exception) {
      message = error.toString().replaceFirst('Exception: ', '');
    } else if (error is String) {
      message = error;
    }

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
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    } else if (error is String) {
      return error;
    }
    return 'An unexpected error occurred';
  }

  static bool isPermissionError(dynamic error) {
    final message = getErrorMessage(error).toLowerCase();
    return message.contains('forbidden') ||
        message.contains('permission') ||
        message.contains('403');
  }

  static bool isAuthenticationError(dynamic error) {
    final message = getErrorMessage(error).toLowerCase();
    return message.contains('unauthorized') ||
        message.contains('401') ||
        message.contains('login');
  }

  static bool isNetworkError(dynamic error) {
    final message = getErrorMessage(error).toLowerCase();
    return message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('network');
  }
}
