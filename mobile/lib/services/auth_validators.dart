abstract final class AuthValidators {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'E-posta adresinizi girin.';
    }
    if (!_emailPattern.hasMatch(email)) {
      return 'Geçerli bir e-posta adresi girin.';
    }
    return null;
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifrenizi girin.';
    }
    return null;
  }

  static String? registerPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifrenizi girin.';
    }
    if (value.length < 8) {
      return 'Şifre en az 8 karakter olmalıdır.';
    }
    return null;
  }

  static String? passwordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Şifrenizi tekrar girin.';
    }
    if (value != password) {
      return 'Şifreler eşleşmiyor.';
    }
    return null;
  }
}
