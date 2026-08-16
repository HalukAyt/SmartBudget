abstract final class DashboardFormatters {
  static const _months = <String>[
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static String period(int year, int month) => '${monthName(month)} $year';

  static String monthName(int month) =>
      month >= 1 && month <= 12 ? _months[month - 1] : '';

  static String currency(double value) {
    final negative = value < 0;
    final fixed = value.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final digits = parts.first;
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[index]);
    }

    return '${negative ? '-' : ''}₺$buffer,${parts.last}';
  }

  static String percent(double value) {
    var formatted = value.toStringAsFixed(2);
    while (formatted.endsWith('0')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    if (formatted.endsWith('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    return formatted.replaceAll('.', ',');
  }
}
