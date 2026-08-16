import 'dashboard_formatters.dart';

abstract final class TransactionFormatters {
  static const _shortMonths = <String>[
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  static String currency(double value) => DashboardFormatters.currency(value);

  static String date(DateTime value) =>
      '${value.day} ${_shortMonths[value.month - 1]} ${value.year}';

  static double? parseAmount(String value) {
    var normalized = value.trim().replaceAll(' ', '');
    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(normalized);
  }
}
