import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../config/transaction_formatters.dart';
import '../../models/recurring_models.dart';
import '../../models/transaction_models.dart';
import '../../services/api_client.dart';
import '../../services/income_service.dart';
import '../../services/recurring_rule_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/recurrence_fields.dart';
import 'transaction_validators.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({
    required this.incomeService,
    required this.recurringRuleService,
    super.key,
  });

  final IncomeDataService incomeService;
  final RecurringRuleDataService recurringRuleService;

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String? _dateError;
  String? _submitError;
  bool _isSubmitting = false;
  RecurrenceOption _recurrenceOption = RecurrenceOption.oneTime;
  RecurrenceDuration _recurrenceDuration = RecurrenceDuration.sixMonths;
  DateTime? _recurrenceEndDate;
  String? _recurrenceEndDateError;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (selected != null) {
      setState(() {
        _selectedDate = DateTime(selected.year, selected.month, selected.day);
        _dateError = null;
      });
    }
  }

  Future<void> _pickRecurrenceEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (selected != null) {
      setState(() {
        _recurrenceEndDate = DateTime(
          selected.year,
          selected.month,
          selected.day,
        );
        _recurrenceEndDateError = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final formValid = _formKey.currentState?.validate() ?? false;
    final isRecurring = _recurrenceOption == RecurrenceOption.monthly;
    final needsCustomEndDate =
        isRecurring && _recurrenceDuration == RecurrenceDuration.custom;
    setState(() {
      _dateError = _selectedDate == null ? 'Tarih zorunludur.' : null;
      _recurrenceEndDateError = needsCustomEndDate && _recurrenceEndDate == null
          ? 'Bitiş tarihi zorunludur.'
          : null;
      _submitError = null;
    });
    if (!formValid ||
        _selectedDate == null ||
        (needsCustomEndDate && _recurrenceEndDate == null)) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final description = _descriptionController.text.trim();
      if (isRecurring) {
        await widget.recurringRuleService.create(
          CreateRecurringRuleRequest(
            recordType: RecurringRecordType.income,
            startDate: _selectedDate!,
            durationMonths: _recurrenceDuration.months,
            endDate: _recurrenceDuration == RecurrenceDuration.custom
                ? _recurrenceEndDate
                : null,
            amount: TransactionFormatters.parseAmount(_amountController.text),
            description: description.isEmpty ? null : description,
          ),
        );
        if (mounted) {
          Navigator.of(context).pop(AddRecordOutcome.recurringRuleCreated);
        }
        return;
      }
      await widget.incomeService.create(
        CreateIncomeRequest(
          amount: TransactionFormatters.parseAmount(_amountController.text)!,
          description: description.isEmpty ? null : description,
          date: _selectedDate!,
        ),
      );
      if (mounted) Navigator.of(context).pop(AddRecordOutcome.created);
    } on ApiException catch (error) {
      if (mounted) setState(() => _submitError = error.userMessage);
    } on Object {
      if (mounted) {
        setState(() => _submitError = 'Gelir kaydedilemedi. Tekrar deneyin.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Gelir Ekle')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            AppTextField(
              controller: _amountController,
              label: 'Tutar',
              hint: '0,00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: TransactionValidators.amount,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              label: 'Açıklama (opsiyonel)',
            ),
            const SizedBox(height: 16),
            InkWell(
              key: const Key('income-date'),
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Tarih',
                  errorText: _dateError,
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                ),
                child: Text(
                  _selectedDate == null
                      ? 'Tarih seçin'
                      : TransactionFormatters.date(_selectedDate!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            RecurrenceFields(
              option: _recurrenceOption,
              duration: _recurrenceDuration,
              customEndDate: _recurrenceEndDate,
              customEndDateError: _recurrenceEndDateError,
              onOptionChanged: (value) =>
                  setState(() => _recurrenceOption = value),
              onDurationChanged: (value) =>
                  setState(() => _recurrenceDuration = value),
              onPickCustomEndDate: _pickRecurrenceEndDate,
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 12),
              Text(
                _submitError!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Geliri Kaydet',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    ),
  );
}
