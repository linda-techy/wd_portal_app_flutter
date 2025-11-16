/// Validators for lead form fields
class LeadFormValidators {
  /// Validates required text field
  static String? required(String? value, String fieldName) {
    if (value?.isEmpty == true) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates email format
  static String? email(String? value) {
    if (value?.isNotEmpty == true) {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
        return 'Enter a valid email';
      }
    }
    return null;
  }

  /// Validates phone number
  static String? phone(String? value, {bool required = true}) {
    if (required && value?.isEmpty == true) {
      return 'Phone is required';
    }
    if (value?.isNotEmpty == true && value!.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    return null;
  }

  /// Validates WhatsApp number
  static String? whatsappNumber(String? value) {
    if (value?.isNotEmpty == true && value!.length < 10) {
      return 'WhatsApp number must be at least 10 digits';
    }
    return null;
  }

  /// Validates numeric value
  static String? numeric(String? value, String fieldName,
      {bool required = false}) {
    if (required && value?.isEmpty == true) {
      return '$fieldName is required';
    }
    if (value?.isNotEmpty == true) {
      final numericValue = double.tryParse(value!);
      if (numericValue == null) {
        return 'Enter a valid $fieldName';
      }
      if (numericValue < 0) {
        return '$fieldName cannot be negative';
      }
    }
    return null;
  }

  /// Validates budget amount
  static String? budget(String? value) {
    return numeric(value, 'budget amount');
  }

  /// Validates project area
  static String? projectArea(String? value) {
    return numeric(value, 'project area');
  }

  /// Validates dropdown selection
  static String? dropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please select a $fieldName';
    }
    return null;
  }

  /// Validates rating (1-5)
  static String? rating(int value) {
    if (value < 1 || value > 5) {
      return 'Rating must be between 1 and 5';
    }
    return null;
  }

  /// Validates probability (0-100)
  static String? probability(int value) {
    if (value < 0 || value > 100) {
      return 'Probability must be between 0 and 100';
    }
    return null;
  }
}
