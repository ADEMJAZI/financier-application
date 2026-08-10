class Validators {
  /// Returns null if valid, or an error message string
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String fieldName = 'Amount'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) {
      return '$fieldName must be a valid number';
    }
    if (parsed <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  static String? nonNegativeNumber(String? value,
      {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) {
      return '$fieldName must be a valid number';
    }
    if (parsed < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }

  static String? minLength(String? value, int min,
      {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  /// Helper: parse a string input safely to double
  static double parseDouble(String value, {double fallback = 0}) {
    return double.tryParse(value.replaceAll(',', '.')) ?? fallback;
  }
}
