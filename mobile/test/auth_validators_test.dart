import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/services/auth_validators.dart';

void main() {
  test('login validation rejects empty email and password', () {
    expect(AuthValidators.email('  '), isNotNull);
    expect(AuthValidators.loginPassword(''), isNotNull);
    expect(AuthValidators.email('kullanici@example.com'), isNull);
    expect(AuthValidators.loginPassword('secret'), isNull);
  });

  test('register password must contain at least 8 characters', () {
    expect(AuthValidators.registerPassword('1234567'), isNotNull);
    expect(AuthValidators.registerPassword('12345678'), isNull);
  });

  test('password confirmation must match', () {
    expect(
      AuthValidators.passwordConfirmation('different', '12345678'),
      isNotNull,
    );
    expect(AuthValidators.passwordConfirmation('12345678', '12345678'), isNull);
  });
}
