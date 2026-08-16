import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../config/transaction_formatters.dart';

enum RecurrenceOption { oneTime, monthly }

enum RecurrenceDuration {
  threeMonths(3),
  sixMonths(6),
  twelveMonths(12),
  custom(null);

  const RecurrenceDuration(this.months);

  final int? months;
}

/// Shared "Tekrarlama" section used by the Expense / Income / Bill add
/// forms. Purely presentational: state lives in the parent screen, mirroring
/// the existing `_DateField` pattern used across the app.
class RecurrenceFields extends StatelessWidget {
  const RecurrenceFields({
    required this.option,
    required this.duration,
    required this.customEndDate,
    required this.customEndDateError,
    required this.onOptionChanged,
    required this.onDurationChanged,
    required this.onPickCustomEndDate,
    super.key,
  });

  final RecurrenceOption option;
  final RecurrenceDuration duration;
  final DateTime? customEndDate;
  final String? customEndDateError;
  final ValueChanged<RecurrenceOption> onOptionChanged;
  final ValueChanged<RecurrenceDuration> onDurationChanged;
  final VoidCallback onPickCustomEndDate;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Tekrarlama', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            key: const Key('recurrence-one-time'),
            label: const Text('Tek seferlik'),
            selected: option == RecurrenceOption.oneTime,
            onSelected: (_) => onOptionChanged(RecurrenceOption.oneTime),
          ),
          ChoiceChip(
            key: const Key('recurrence-monthly'),
            label: const Text('Her ay'),
            selected: option == RecurrenceOption.monthly,
            onSelected: (_) => onOptionChanged(RecurrenceOption.monthly),
          ),
        ],
      ),
      if (option == RecurrenceOption.monthly) ...[
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in const [
              (RecurrenceDuration.threeMonths, '3 Ay'),
              (RecurrenceDuration.sixMonths, '6 Ay'),
              (RecurrenceDuration.twelveMonths, '12 Ay'),
              (RecurrenceDuration.custom, 'Bitiş Tarihi'),
            ])
              ChoiceChip(
                key: Key('recurrence-duration-${entry.$1.name}'),
                label: Text(entry.$2),
                selected: duration == entry.$1,
                onSelected: (_) => onDurationChanged(entry.$1),
              ),
          ],
        ),
        if (duration == RecurrenceDuration.custom) ...[
          const SizedBox(height: 12),
          InkWell(
            key: const Key('recurrence-end-date'),
            onTap: onPickCustomEndDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Bitiş Tarihi',
                errorText: customEndDateError,
                suffixIcon: const Icon(Icons.event_outlined),
              ),
              child: Text(
                customEndDate == null
                    ? 'Bitiş tarihi seçin'
                    : TransactionFormatters.date(customEndDate!),
              ),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'Her ay seçildiğinde bu kayıt gerçek bir işlem oluşturmaz; '
          'Planlananlar bölümünden onaylayarak gerçekleştirebilirsin.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ],
  );
}
