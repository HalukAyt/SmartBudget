import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../config/dashboard_formatters.dart';
import '../../config/transaction_formatters.dart';
import '../../models/recurring_models.dart';
import '../../models/transaction_models.dart';
import '../../services/ai_categorization_service.dart';
import '../../services/api_client.dart';
import '../../services/expense_service.dart';
import '../../services/recurring_rule_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/recurrence_fields.dart';
import 'transaction_validators.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    required this.categories,
    required this.expenseService,
    required this.aiService,
    required this.recurringRuleService,
    this.tutorialAiCategoryKey,
    super.key,
  });

  final List<CategoryModel> categories;
  final ExpenseDataService expenseService;
  final AiCategorizationDataService aiService;
  final RecurringRuleDataService recurringRuleService;
  final GlobalKey? tutorialAiCategoryKey;

  @override
  State<AddExpenseScreen> createState() => AddExpenseScreenState();
}

class AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryFieldKey = GlobalKey<FormFieldState<String>>();
  final _scrollController = ScrollController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedCategoryId;
  String? _dateError;
  String? _categoryError;
  String? _aiValidationError;
  String? _submitError;
  CategorizeExpenseResponse? _suggestion;
  bool _isSuggestionAccepted = false;
  bool _isAiLoading = false;
  bool _isSubmitting = false;
  RecurrenceOption _recurrenceOption = RecurrenceOption.oneTime;
  RecurrenceDuration _recurrenceDuration = RecurrenceDuration.sixMonths;
  DateTime? _recurrenceEndDate;
  String? _recurrenceEndDateError;

  @override
  void dispose() {
    _scrollController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> revealAiCategoryTarget() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      await WidgetsBinding.instance.endOfFrame;
    }
    final targetContext = widget.tutorialAiCategoryKey?.currentContext;
    if (targetContext != null && targetContext.mounted) {
      await Scrollable.ensureVisible(
        targetContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 120),
      );
    }
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

  Future<void> _requestSuggestion() async {
    if (_isAiLoading) return;
    final descriptionError = TransactionValidators.expenseDescription(
      _descriptionController.text,
    );
    if (descriptionError != null) {
      setState(() => _aiValidationError = descriptionError);
      return;
    }
    setState(() {
      _isAiLoading = true;
      _aiValidationError = null;
      _suggestion = null;
      _isSuggestionAccepted = false;
    });
    try {
      final response = await widget.aiService.categorize(
        _descriptionController.text.trim(),
      );
      if (!mounted) return;
      final matchesCategory =
          response.categoryId != null &&
          widget.categories.any((item) => item.id == response.categoryId);
      setState(() {
        _suggestion = response.success && matchesCategory ? response : null;
        if (!response.success || !matchesCategory) {
          _aiValidationError =
              'AI şu anda kategori öneremedi. Kategoriyi manuel olarak seçebilirsin.';
        }
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _aiValidationError =
            'AI şu anda kategori öneremedi. Kategoriyi manuel olarak seçebilirsin.';
      });
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  void _acceptSuggestion() {
    final categoryId = _suggestion?.categoryId;
    if (categoryId == null) return;
    _categoryFieldKey.currentState?.didChange(categoryId);
    setState(() {
      _selectedCategoryId = categoryId;
      _categoryError = null;
      _isSuggestionAccepted = true;
    });
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
      _categoryError = _selectedCategoryId == null
          ? 'Kategori seçmelisiniz.'
          : null;
      _recurrenceEndDateError = needsCustomEndDate && _recurrenceEndDate == null
          ? 'Bitiş tarihi zorunludur.'
          : null;
      _submitError = null;
    });
    if (!formValid ||
        _selectedDate == null ||
        _selectedCategoryId == null ||
        (needsCustomEndDate && _recurrenceEndDate == null)) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      if (isRecurring) {
        await widget.recurringRuleService.create(
          CreateRecurringRuleRequest(
            recordType: RecurringRecordType.expense,
            startDate: _selectedDate!,
            durationMonths: _recurrenceDuration.months,
            endDate: _recurrenceDuration == RecurrenceDuration.custom
                ? _recurrenceEndDate
                : null,
            amount: TransactionFormatters.parseAmount(_amountController.text),
            description: _descriptionController.text.trim(),
            categoryId: _selectedCategoryId,
          ),
        );
        if (mounted) {
          Navigator.of(context).pop(AddRecordOutcome.recurringRuleCreated);
        }
        return;
      }
      await widget.expenseService.create(
        CreateExpenseRequest(
          amount: TransactionFormatters.parseAmount(_amountController.text)!,
          description: _descriptionController.text.trim(),
          categoryId: _selectedCategoryId!,
          date: _selectedDate!,
          isAiCategorized:
              _isSuggestionAccepted &&
              _suggestion?.categoryId == _selectedCategoryId,
        ),
      );
      if (mounted) Navigator.of(context).pop(AddRecordOutcome.created);
    } on ApiException catch (error) {
      if (mounted) setState(() => _submitError = error.userMessage);
    } on Object {
      if (mounted) {
        setState(() => _submitError = 'Gider kaydedilemedi. Tekrar deneyin.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gider Ekle')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            controller: _scrollController,
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
                label: 'Açıklama',
                validator: TransactionValidators.expenseDescription,
              ),
              const SizedBox(height: 16),
              KeyedSubtree(
                key: const Key('expense-category'),
                child: DropdownButtonFormField<String>(
                  key: _categoryFieldKey,
                  initialValue: _selectedCategoryId,
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
                    _selectedCategoryId = value;
                    _categoryError = null;
                    _isSuggestionAccepted = false;
                  }),
                ),
              ),
              const SizedBox(height: 16),
              _DateField(
                selectedDate: _selectedDate,
                errorText: _dateError,
                onPressed: _pickDate,
              ),
              const SizedBox(height: 20),
              KeyedSubtree(
                key: widget.tutorialAiCategoryKey,
                child: OutlinedButton.icon(
                  key: const Key('ai-category-button'),
                  onPressed: _isAiLoading ? null : _requestSuggestion,
                  icon: _isAiLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_outlined),
                  label: const Text('AI ile Kategori Öner'),
                ),
              ),
              if (_suggestion != null) ...[
                const SizedBox(height: 12),
                _AiSuggestionCard(
                  suggestion: _suggestion!,
                  isAccepted: _isSuggestionAccepted,
                  onAccept: _acceptSuggestion,
                  onManual: () => setState(() {
                    _isSuggestionAccepted = false;
                    _selectedCategoryId = null;
                    _categoryFieldKey.currentState?.didChange(null);
                  }),
                ),
              ],
              if (_aiValidationError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _aiValidationError!,
                  key: const Key('ai-category-error'),
                  style: const TextStyle(color: AppColors.error),
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
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Gideri Kaydet',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.selectedDate,
    required this.errorText,
    required this.onPressed,
  });

  final DateTime? selectedDate;
  final String? errorText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const Key('expense-date'),
    onTap: onPressed,
    borderRadius: BorderRadius.circular(12),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: 'Tarih',
        errorText: errorText,
        suffixIcon: const Icon(Icons.calendar_month_outlined),
      ),
      child: Text(
        selectedDate == null
            ? 'Tarih seçin'
            : TransactionFormatters.date(selectedDate!),
      ),
    ),
  );
}

class _AiSuggestionCard extends StatelessWidget {
  const _AiSuggestionCard({
    required this.suggestion,
    required this.isAccepted,
    required this.onAccept,
    required this.onManual,
  });

  final CategorizeExpenseResponse suggestion;
  final bool isAccepted;
  final VoidCallback onAccept;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.primaryLight,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('AI Önerisi', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            suggestion.category ?? '',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (suggestion.confidence != null)
            Text(
              'Güven: ${DashboardFormatters.percent(suggestion.confidence!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                key: const Key('accept-ai-category'),
                onPressed: isAccepted ? null : onAccept,
                child: Text(
                  isAccepted ? 'Öneri Kullanılıyor' : 'Öneriyi Kullan',
                ),
              ),
              TextButton(
                key: const Key('manual-category'),
                onPressed: onManual,
                child: const Text('Başka Kategori Seç'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
