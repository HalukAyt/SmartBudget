class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, Object?> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  const RegisterRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, Object?> toJson() => {'email': email, 'password': password};
}

class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.userId,
    required this.email,
  });

  final String accessToken;
  final String userId;
  final String email;

  factory AuthResponse.fromJson(Map<String, Object?> json) {
    final accessToken = json['accessToken'];
    final userId = json['userId'];
    final email = json['email'];

    if (accessToken is! String ||
        accessToken.isEmpty ||
        userId is! String ||
        userId.isEmpty ||
        email is! String ||
        email.isEmpty) {
      throw const FormatException('Invalid authentication response.');
    }

    return AuthResponse(accessToken: accessToken, userId: userId, email: email);
  }
}
