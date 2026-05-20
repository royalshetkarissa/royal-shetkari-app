class FormValidators {
  static String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  static String? fullName(String? value) {
    final required = requiredText(value, 'Full name');
    if (required != null) return required;

    if (value!.trim().length < 2) {
      return 'Enter your full name.';
    }
    return null;
  }

  static String? mobile(String? value) {
    final required = requiredText(value, 'Mobile number');
    if (required != null) return required;

    if (!RegExp(r'^\d{10,15}$').hasMatch(value!.trim())) {
      return 'Enter a valid mobile number.';
    }
    return null;
  }

  static String? email(String? value) {
    final required = requiredText(value, 'Email');
    if (required != null) return required;

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? loginIdentifier(String? value) {
    final required = requiredText(value, 'Mobile or email');
    if (required != null) return required;

    final text = value!.trim();
    if (text.contains('@')) {
      return email(text);
    }
    return mobile(text);
  }

  static String? password(String? value) {
    final required = requiredText(value, 'Password');
    if (required != null) return required;

    if (value!.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final required = requiredText(value, 'Confirm password');
    if (required != null) return required;

    if (value != original) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? village(String? value) {
    return requiredText(value, 'Village');
  }

  static String? otp(String? value) {
    final required = requiredText(value, 'OTP');
    if (required != null) return required;

    if (!RegExp(r'^\d{6}$').hasMatch(value!.trim())) {
      return 'Enter the 6-digit OTP.';
    }
    return null;
  }
}
