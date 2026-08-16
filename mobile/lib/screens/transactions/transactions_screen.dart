import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../config/dashboard_formatters.dart';
import '../../config/transaction_formatters.dart';
import '../../models/recurring_models.dart';
import '../../models/transaction_models.dart';
import '../../services/ai_categorization_service.dart';
import '../../services/category_service.dart';
import '../../services/expense_service.dart';
import '../../services/income_service.dart';
import '../../services/recurring_rule_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/app_help_button.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'transactions_view_model.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    required this.expenseService,
    required this.incomeService,
    required this.categoryService,
    required this.aiService,
    required this.recurringRuleService,
    this.onHelp,
    this.tutorialAddKey,
    this.tutorialAiCategoryKey,
    this.onFinancialDataChanged,
    super.key,
  });

  final ExpenseDataService expenseService;
  final IncomeDataService incomeService;
  final CategoryDataService categoryService;
  final AiCategorizationDataService aiService;
  final RecurringRuleDataService recurringRuleService;
  final VoidCallback? onHelp;
  final GlobalKey? tutorialAddKey;
  final GlobalKey? tutorialAiCategoryKey;
  final VoidCallback? onFinancialDataChanged;

  @override
  State<TransactionsScreen> createState() => TransactionsScreenState();
}

class TransactionsScreenState extends State<TransactionsScreen> {
  late final TransactionsViewModel _viewModel;
  final _tutorialExpenseScreenKey = GlobalKey<AddExpenseScreenState>();
  bool _showTutorialExpense = false;

  @override
  void initState() {
    super.initState();
    _viewModel = TransactionsViewModel(
      expenseService: widget.expenseService,
      incomeService: widget.incomeService,
      categoryService: widget.categoryService,
      recurringRuleService: widget.recurringRuleService,
    )..loadInitial();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> showTutorialExpensePreview() async {
    if (!_showTutorialExpense) {
      setState(() => _showTutorialExpense = true);
      await WidgetsBinding.instance.endOfFrame;
    }
    await _tutorialExpenseScreenKey.currentState?.revealAiCategoryTarget();
  }

  void hideTutorialExpensePreview() {
    if (_showTutorialExpense && mounted) {
      setState(() => _showTutorialExpense = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showTutorialExpense) {
      return AddExpenseScreen(
        key: _tutorialExpenseScreenKey,
        categories: _viewModel.categories,
        expenseService: widget.expenseService,
        aiService: widget.aiService,
        recurringRuleService: widget.recurringRuleService,
        tutorialAiCategoryKey: widget.tutorialAiCategoryKey,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlemler'),
        actions: [
          if (widget.onHelp != null) AppHelpButton(onPressed: widget.onHelp!),
        ],
      ),
      floatingActionButton: KeyedSubtree(
        key: widget.tutorialAddKey,
        child: FloatingActionButton.extended(
          key: const Key('add-transaction'),
          onPressed: _showAddOptions,
          icon: const Icon(Icons.add),
          label: const Text('İşlem Ekle'),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            final isPlanned =
                _viewModel.selectedFilter == TransactionFilter.planned;
            if (!isPlanned &&
                _viewModel.isLoading &&
                _viewModel.expenses.isEmpty &&
                _viewModel.incomes.isEmpty) {
              return const LoadingView(message: 'İşlemler yükleniyor…');
            }
            if (!isPlanned &&
                _viewModel.errorMessage != null &&
                _viewModel.expenses.isEmpty &&
                _viewModel.incomes.isEmpty) {
              return ErrorView(
                message: _viewModel.errorMessage!,
                onRetry: _viewModel.retry,
              );
            }
            final items = _viewModel.visibleTransactions;
            return RefreshIndicator(
              onRefresh: isPlanned
                  ? _viewModel.loadRecurringRules
                  : _viewModel.refresh,
              child: ListView(
                key: const Key('transactions-list'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _FilterBar(
                    selected: _viewModel.selectedFilter,
                    onSelected: _viewModel.setFilter,
                  ),
                  if (!isPlanned && _viewModel.isLoading) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  const SizedBox(height: 20),
                  if (isPlanned)
                    _RecurringSection(viewModel: _viewModel)
                  else if (_viewModel.expenses.isEmpty &&
                      _viewModel.incomes.isEmpty)
                    _EmptyTransactions(onAdd: _showAddOptions)
                  else if (items.isEmpty)
                    const _FilteredEmpty()
                  else
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TransactionCard(
                          item: item,
                          isDeleting: _viewModel.isDeleting(item.id),
                          onDelete: () => _confirmDelete(item),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showAddOptions() async {
    final type = await showModalBottomSheet<TransactionType>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Yeni İşlem', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              ListTile(
                key: const Key('add-expense-option'),
                leading: const Icon(Icons.remove_circle_outline),
                title: const Text('Gider Ekle'),
                subtitle: const Text('Kategori seçerek yeni gider kaydet'),
                onTap: () => Navigator.pop(context, TransactionType.expense),
              ),
              ListTile(
                key: const Key('add-income-option'),
                leading: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.success,
                ),
                title: const Text('Gelir Ekle'),
                subtitle: const Text('Yeni gelir kaydı oluştur'),
                onTap: () => Navigator.pop(context, TransactionType.income),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || type == null) return;
    final outcome = await Navigator.of(context).push<AddRecordOutcome>(
      MaterialPageRoute(
        builder: (_) => type == TransactionType.expense
            ? AddExpenseScreen(
                categories: _viewModel.categories,
                expenseService: widget.expenseService,
                aiService: widget.aiService,
                recurringRuleService: widget.recurringRuleService,
              )
            : AddIncomeScreen(
                incomeService: widget.incomeService,
                recurringRuleService: widget.recurringRuleService,
              ),
      ),
    );
    if (outcome == null || !mounted) return;
    if (outcome == AddRecordOutcome.created) {
      widget.onFinancialDataChanged?.call();
      await _viewModel.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem başarıyla kaydedildi.')),
        );
      }
    } else {
      // The rule may have been due today and already auto-realized by the
      // backend at create time (see RecurringRuleService.CreateAsync), so
      // the transaction list and Dashboard must refresh here too, not just
      // the recurring rules list — otherwise a just-created due Income/
      // Expense would stay invisible until some unrelated later refresh.
      widget.onFinancialDataChanged?.call();
      await _viewModel.refresh();
      await _viewModel.loadRecurringRules();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Planlanan kayıt oluşturuldu. Planlananlar sekmesinden görebilirsin.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(TransactionListItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İşlemi Sil'),
        content: const Text(
          'Bu işlem kaydını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            key: const Key('confirm-delete'),
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final message = await _viewModel.deleteTransaction(item);
    if (message == null) widget.onFinancialDataChanged?.call();
    if (message != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final TransactionFilter selected;
  final ValueChanged<TransactionFilter> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final entry in const [
        (TransactionFilter.all, 'Tümü'),
        (TransactionFilter.expenses, 'Giderler'),
        (TransactionFilter.incomes, 'Gelirler'),
        (TransactionFilter.planned, 'Planlananlar'),
      ])
        ChoiceChip(
          key: Key('filter-${entry.$1.name}'),
          label: Text(entry.$2),
          selected: selected == entry.$1,
          onSelected: (_) => onSelected(entry.$1),
        ),
    ],
  );
}

class _RecurringSection extends StatelessWidget {
  const _RecurringSection({required this.viewModel});

  final TransactionsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isRecurringLoading && viewModel.recurringRules.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (viewModel.recurringErrorMessage != null &&
        viewModel.recurringRules.isEmpty) {
      return Column(
        children: [
          Text(viewModel.recurringErrorMessage!),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('retry-recurring-rules'),
            onPressed: viewModel.loadRecurringRules,
            child: const Text('Tekrar Dene'),
          ),
        ],
      );
    }
    if (viewModel.recurringRules.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Henüz planlanan bir gelir veya gider bulunmuyor. Gider veya '
            'gelir eklerken "Her ay" seçeneğini kullanarak planlayabilirsin.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      children: viewModel.recurringRules
          .map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecurringRuleCard(rule: rule),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _RecurringRuleCard extends StatelessWidget {
  const _RecurringRuleCard({required this.rule});

  final RecurringRuleListItem rule;

  @override
  Widget build(BuildContext context) {
    final isIncome = rule.recordType == RecurringRecordType.income;
    final color = isIncome ? AppColors.success : AppColors.error;
    return Card(
      key: Key('recurring-rule-${rule.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isIncome ? Icons.south_west : Icons.north_east,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rule.displayTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (!rule.isActive)
                  const Text(
                    'Pasif',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              rule.amount == null
                  ? 'Her ayın ${rule.startDate.day}. günü'
                  : '${TransactionFormatters.currency(rule.amount!)} • Her ayın ${rule.startDate.day}. günü',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            _RecurringStatusLabel(rule: rule),
          ],
        ),
      ),
    );
  }
}

/// Presentation-only status derived from backend-authoritative fields
/// (`isRealizedThisMonth`, `nextDueDate`); no date/business math is done
/// here beyond formatting.
class _RecurringStatusLabel extends StatelessWidget {
  const _RecurringStatusLabel({required this.rule});

  final RecurringRuleListItem rule;

  @override
  Widget build(BuildContext context) {
    if (rule.isRealizedThisMonth) {
      return const Text(
        'Durum: Gerçekleşti',
        key: Key('recurring-status'),
        style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
      );
    }
    final nextDueDate = rule.nextDueDate;
    if (!rule.isActive || nextDueDate == null) {
      return const Text(
        'Durum: Tamamlandı',
        key: Key('recurring-status'),
        style: TextStyle(color: AppColors.textMuted),
      );
    }
    return Text(
      'Durum: Bekleniyor\n'
      'Sonraki: ${nextDueDate.day} ${DashboardFormatters.monthName(nextDueDate.month)} ${nextDueDate.year}',
      key: const Key('recurring-status'),
      style: const TextStyle(
        color: AppColors.warning,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.item,
    required this.isDeleting,
    required this.onDelete,
  });

  final TransactionListItem item;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == TransactionType.income;
    final typeLabel = isIncome ? 'Gelir' : 'Gider';
    final color = isIncome ? AppColors.success : AppColors.error;
    return Card(
      key: Key('transaction-${item.type.name}-${item.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isIncome ? Icons.south_west : Icons.north_east,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      typeLabel,
                      if (item.categoryName != null) item.categoryName!,
                      TransactionFormatters.date(item.date),
                    ].join(' • '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${TransactionFormatters.currency(item.amount)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                SizedBox(
                  width: 40,
                  height: 36,
                  child: isDeleting
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          tooltip: '$typeLabel kaydını sil',
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 20),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 44,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Henüz işlem kaydın bulunmuyor.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('İşlem Ekle'),
          ),
        ],
      ),
    ),
  );
}

class _FilteredEmpty extends StatelessWidget {
  const _FilteredEmpty();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text('Bu filtrede işlem bulunmuyor.'),
    ),
  );
}
