import '../../config/transaction_formatters.dart';

abstract final class TransactionValidators {
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Tutar zorunludur.';
    final amount = TransactionFormatters.parseAmount(value);
    if (amount == null) return 'Geçerli bir tutar girin.';
    if (amount <= 0) return 'Tutar sıfırdan büyük olmalıdır.';
    return null;
  }

  static String? expenseDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Açıklama zorunludur.';
    }
    return null;
  }
}
