import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../config/dashboard_formatters.dart';
import '../../config/transaction_formatters.dart';
import '../../models/budget_models.dart';
import '../../services/api_client.dart';
import '../../services/budget_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../transactions/transaction_validators.dart';

class EditBudgetScreen extends StatefulWidget {
  const EditBudgetScreen({
    required this.budget,
    required this.budgetService,
    super.key,
  });

  final BudgetListItem budget;
  final BudgetDataService budgetService;

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _limitController = TextEditingController(
    text: widget.budget.limitAmount.toStringAsFixed(2).replaceAll('.', ','),
  );
  String? _submitError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    try {
      await widget.budgetService.update(
        widget.budget.id,
        UpdateBudgetRequest(
          limitAmount: TransactionFormatters.parseAmount(
            _limitController.text,
          )!,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error.type == ApiErrorType.notFound
            ? 'Bütçe kaydı bulunamadı veya artık mevcut değil.'
            : error.userMessage;
      });
    } on Object {
      if (mounted) {
        setState(() => _submitError = 'Bütçe güncellenemedi. Tekrar deneyin.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bütçeyi Güncelle')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _ReadOnlyValue(
              label: 'Kategori',
              value: widget.budget.category.name,
            ),
            const SizedBox(height: 12),
            _ReadOnlyValue(
              label: 'Ay',
              value: DashboardFormatters.monthName(widget.budget.month),
            ),
            const SizedBox(height: 12),
            _ReadOnlyValue(label: 'Yıl', value: '${widget.budget.year}'),
            const SizedBox(height: 16),
            AppTextField(
              controller: _limitController,
              label: 'Bütçe Limiti',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: TransactionValidators.amount,
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 12),
              Text(
                _submitError!,
                key: const Key('budget-update-error'),
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Limiti Güncelle',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ReadOnlyValue extends StatelessWidget {
  const _ReadOnlyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(labelText: label, enabled: false),
    child: Text(value),
  );
}
