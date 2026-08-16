import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/screens/transactions/transaction_validators.dart';

void main() {
  test(
    'amount validation rejects empty, zero, negative and invalid values',
    () {
      expect(TransactionValidators.amount(''), 'Tutar zorunludur.');
      expect(
        TransactionValidators.amount('0'),
        'Tutar sıfırdan büyük olmalıdır.',
      );
      expect(
        TransactionValidators.amount('-1'),
        'Tutar sıfırdan büyük olmalıdır.',
      );
      expect(TransactionValidators.amount('abc'), 'Geçerli bir tutar girin.');
      expect(TransactionValidators.amount('12,50'), isNull);
      expect(TransactionValidators.amount('1.250,50'), isNull);
    },
  );

  test('expense description rejects empty and whitespace values', () {
    expect(TransactionValidators.expenseDescription(''), isNotNull);
    expect(TransactionValidators.expenseDescription('   '), isNotNull);
    expect(TransactionValidators.expenseDescription('Market'), isNull);
  });
}
