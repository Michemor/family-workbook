class PasswordValidator {
  static bool isValid(String password) {
    return password.length >= 6 &&
        _hasUppercase(password) &&
        _hasLowercase(password) &&
        _hasNumber(password) &&
        _hasSymbol(password);
  }

  static bool _hasUppercase(String password) {
    return password.contains(RegExp(r'[A-Z]'));
  }

  static bool _hasLowercase(String password) {
    return password.contains(RegExp(r'[a-z]'));
  }

  static bool _hasNumber(String password) {
    return password.contains(RegExp(r'[0-9]'));
  }

  static bool _hasSymbol(String password) {
    return password.contains(RegExp(r"[!@#$%^&*()_+\-=\[\]{};:'<>?,./\\|`~]"));
  }

  static Map<String, bool> getRequirements(String password) {
    return {
      'length': password.length >= 6,
      'uppercase': _hasUppercase(password),
      'lowercase': _hasLowercase(password),
      'number': _hasNumber(password),
      'symbol': _hasSymbol(password),
    };
  }
}
