import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../config/transaction_formatters.dart';
import '../../models/bill_models.dart';
import '../../models/recurring_models.dart';
import '../../services/api_client.dart';
import '../../services/bill_service.dart';
import '../../services/recurring_rule_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/recurrence_fields.dart';
import '../transactions/transaction_validators.dart';

class AddBillScreen extends StatefulWidget {
  const AddBillScreen({
    required this.service,
    required this.recurringRuleService,
    super.key,
  });
  final BillDataService service;
  final RecurringRuleDataService recurringRuleService;
  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _consumptionController = TextEditingController();
  BillType? _billType;
  DateTime? _billingDate;
  String? _billTypeError;
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
    _consumptionController.dispose();
    super.dispose();
  }

  String? _validateConsumption(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final amount = TransactionFormatters.parseAmount(value);
    if (amount == null) return 'Geçerli bir tüketim miktarı girin.';
    if (amount <= 0) return 'Tüketim miktarı sıfırdan büyük olmalıdır.';
    return null;
  }

  String? _validateAmount(String? value) {
    final isRecurring = _recurrenceOption == RecurrenceOption.monthly;
    if (isRecurring && (value == null || value.trim().isEmpty)) {
      return null;
    }
    return TransactionValidators.amount(value);
  }

  Future<void> _pickRecurrenceEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? _billingDate ?? DateTime.now(),
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

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _billingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (selected != null) {
      setState(() {
        _billingDate = DateTime(selected.year, selected.month, selected.day);
        _dateError = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final valid = _formKey.currentState?.validate() ?? false;
    final isRecurring = _recurrenceOption == RecurrenceOption.monthly;
    final needsCustomEndDate =
        isRecurring && _recurrenceDuration == RecurrenceDuration.custom;
    setState(() {
      _billTypeError = _billType == null ? 'Fatura türü seçmelisiniz.' : null;
      _dateError = _billingDate == null ? 'Fatura tarihi zorunludur.' : null;
      _recurrenceEndDateError = needsCustomEndDate && _recurrenceEndDate == null
          ? 'Bitiş tarihi zorunludur.'
          : null;
      _submitError = null;
    });
    if (!valid ||
        _billType == null ||
        _billingDate == null ||
        (needsCustomEndDate && _recurrenceEndDate == null)) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final consumption = _consumptionController.text.trim();
      final amountText = _amountController.text.trim();
      final amount = amountText.isEmpty
          ? null
          : TransactionFormatters.parseAmount(amountText);
      if (isRecurring) {
        await widget.recurringRuleService.create(
          CreateRecurringRuleRequest(
            recordType: RecurringRecordType.bill,
            startDate: _billingDate!,
            durationMonths: _recurrenceDuration.months,
            endDate: _recurrenceDuration == RecurrenceDuration.custom
                ? _recurrenceEndDate
                : null,
            amount: amount,
            billType: _billType,
          ),
        );
        if (mounted) {
          Navigator.of(context).pop(AddRecordOutcome.recurringRuleCreated);
        }
        return;
      }
      await widget.service.create(
        CreateBillRequest(
          billType: _billType!,
          amount: amount!,
          consumptionValue: consumption.isEmpty
              ? null
              : TransactionFormatters.parseAmount(consumption),
          billingDate: _billingDate!,
        ),
      );
      if (mounted) Navigator.of(context).pop(AddRecordOutcome.created);
    } on ApiException catch (error) {
      if (mounted) setState(() => _submitError = error.userMessage);
    } on Object {
      if (mounted) {
        setState(() => _submitError = 'Fatura kaydedilemedi. Tekrar deneyin.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Yeni Fatura')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            DropdownButtonFormField<BillType>(
              key: const Key('bill-type'),
              initialValue: _billType,
              decoration: InputDecoration(
                labelText: 'Fatura Türü',
                errorText: _billTypeError,
              ),
              items: BillType.values
                  .where((type) => type != BillType.unknown)
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(growable: false),
              onChanged: (value) => setState(() {
                _billType = value;
                _billTypeError = null;
              }),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _amountController,
              label: _recurrenceOption == RecurrenceOption.monthly
                  ? 'Tutar (opsiyonel şablon)'
                  : 'Tutar',
              hint: '0,00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _validateAmount,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _consumptionController,
              label: _billType == null
                  ? 'Tüketim Miktarı (opsiyonel)'
                  : 'Tüketim Miktarı (${_billType!.defaultUnit})',
              hint: 'Opsiyonel',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _validateConsumption,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('bill-date'),
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                _billingDate == null
                    ? 'Fatura Tarihi Seç'
                    : TransactionFormatters.date(_billingDate!),
              ),
            ),
            if (_dateError != null) ...[
              const SizedBox(height: 6),
              Text(
                _dateError!,
                key: const Key('bill-date-error'),
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
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
                key: const Key('bill-submit-error'),
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Faturayı Kaydet',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    ),
  );
}
