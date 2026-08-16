import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../config/dashboard_formatters.dart';
import '../../config/transaction_formatters.dart';
import '../../models/budget_models.dart';
import '../../models/transaction_models.dart';
import '../../services/api_client.dart';
import '../../services/budget_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../transactions/transaction_validators.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({
    required this.categories,
    required this.budgetService,
    required this.initialYear,
    required this.initialMonth,
    super.key,
  });

  final List<CategoryModel> categories;
  final BudgetDataService budgetService;
  final int initialYear;
  final int initialMonth;

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  String? _categoryId;
  String? _categoryError;
  late int _month = widget.initialMonth;
  late int _year = widget.initialYear;
  String? _submitError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _categoryError = _categoryId == null ? 'Kategori seçmelisiniz.' : null;
      _submitError = null;
    });
    if (!formValid || _categoryId == null) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.budgetService.create(
        CreateBudgetRequest(
          categoryId: _categoryId!,
          limitAmount: TransactionFormatters.parseAmount(
            _limitController.text,
          )!,
          month: _month,
          year: _year,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error.type == ApiErrorType.conflict
            ? 'Bu kategori için seçilen dönemde zaten bir bütçe bulunuyor.'
            : error.userMessage;
      });
    } on Object {
      if (mounted) {
        setState(() => _submitError = 'Bütçe kaydedilemedi. Tekrar deneyin.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Yeni Bütçe')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            DropdownButtonFormField<String>(
              key: const Key('budget-category'),
              initialValue: _categoryId,
              decoration: InputDecoration(
                labelText: 'Kategori',
                errorText: _categoryError,
              ),
              items: widget.categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) => setState(() {
                _categoryId = value;
                _categoryError = null;
              }),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _limitController,
              label: 'Bütçe Limiti',
              hint: '0,00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: TransactionValidators.amount,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: const Key('budget-month'),
                    initialValue: _month,
                    decoration: const InputDecoration(labelText: 'Ay'),
                    items: [
                      for (var month = 1; month <= 12; month++)
                        DropdownMenuItem(
                          value: month,
                          child: Text(DashboardFormatters.monthName(month)),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _month = value ?? _month),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: const Key('budget-year'),
                    initialValue: _year,
                    decoration: const InputDecoration(labelText: 'Yıl'),
                    items: [
                      for (var year = 2000; year <= 2100; year++)
                        DropdownMenuItem(value: year, child: Text('$year')),
                    ],
                    onChanged: (value) =>
                        setState(() => _year = value ?? _year),
                  ),
                ),
              ],
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 12),
              Text(
                _submitError!,
                key: const Key('budget-submit-error'),
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Bütçeyi Kaydet',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    ),
  );
}
