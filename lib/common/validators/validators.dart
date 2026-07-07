class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{10,14}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (value.trim().length != 6) {
      return 'OTP must be exactly 6 digits';
    }
    if (int.tryParse(value) == null) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  static String? validateGovId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Government ID is required';
    }
    if (value.trim().length < 5) {
      return 'Please enter a valid Government ID';
    }
    return null;
  }

  static String? validateWorkerId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Worker ID is required';
    }
    final idRegex = RegExp(r'^[a-zA-Z0-9]{6}$');
    if (!idRegex.hasMatch(value.trim())) {
      return 'Worker ID must be exactly 6 characters (alphanumeric)';
    }
    return null;
  }
}
