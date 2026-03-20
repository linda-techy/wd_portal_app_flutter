/// Shared form-field validators used across the app.
class Validators {
  Validators._();

  /// Indian mobile number: 10 digits starting with 6-9, optional +91 / 91 prefix.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional field
    final digits = value.trim().replaceAll(RegExp(r'[\s\-]'), '');
    final pattern = RegExp(r'^(\+?91)?[6-9]\d{9}$');
    if (!pattern.hasMatch(digits)) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  /// GST Identification Number — 15-character alphanumeric with defined structure.
  /// Format: 2-digit state code + 5-letter PAN + 4-digit year + 1-letter entity
  ///         + 1-alphanumeric + Z + 1-alphanumeric check digit.
  static String? gst(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional field
    final v = value.trim().toUpperCase();
    final pattern =
        RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}Z[A-Z\d]{1}$');
    if (!pattern.hasMatch(v)) {
      return 'Enter a valid 15-character GST number';
    }
    return null;
  }

  /// Email address (basic RFC-style check).
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Required text field.
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  /// Password — 8 chars minimum, at least one letter and one digit.
  static String? password(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'Password is required' : null;
    }
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Password must contain at least one letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }
}
