import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../config/dashboard_formatters.dart';
import '../../models/budget_models.dart';
import '../../models/dashboard_models.dart';
import '../../services/budget_service.dart';
import '../../services/category_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/app_help_button.dart';
import '../dashboard/dashboard_widgets.dart';
import 'add_budget_screen.dart';
import 'budgets_view_model.dart';
import 'edit_budget_screen.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({
    required this.budgetService,
    required this.categoryService,
    this.initialYear,
    this.initialMonth,
    this.onHelp,
    this.tutorialAddKey,
    super.key,
  });

  final BudgetDataService budgetService;
  final CategoryDataService categoryService;
  final int? initialYear;
  final int? initialMonth;
  final VoidCallback? onHelp;
  final GlobalKey? tutorialAddKey;

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late final BudgetsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BudgetsViewModel(
      budgetService: widget.budgetService,
      categoryService: widget.categoryService,
      initialYear: widget.initialYear,
      initialMonth: widget.initialMonth,
    )..loadInitial();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Bütçeler'),
      actions: [
        if (widget.onHelp != null) AppHelpButton(onPressed: widget.onHelp!),
      ],
    ),
    floatingActionButton: KeyedSubtree(
      key: widget.tutorialAddKey,
      child: FloatingActionButton.extended(
        key: const Key('add-budget'),
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Bütçe Ekle'),
      ),
    ),
    body: SafeArea(
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.budgets.isEmpty) {
            return const LoadingView(message: 'Bütçeler yükleniyor…');
          }
          if (_viewModel.errorMessage != null && _viewModel.budgets.isEmpty) {
            return ErrorView(
              message: _viewModel.errorMessage!,
              onRetry: _viewModel.retry,
            );
          }
          final budgets = _viewModel.visibleBudgets;
          return RefreshIndicator(
            onRefresh: _viewModel.refresh,
            child: ListView(
              key: const Key('budgets-list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: PeriodSelector(
                    year: _viewModel.selectedYear,
                    month: _viewModel.selectedMonth,
                    onPressed: _showPeriodPicker,
                  ),
                ),
                if (_viewModel.isLoading) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                const SizedBox(height: 20),
                if (budgets.isEmpty)
                  _EmptyBudgets(onAdd: _openCreate)
                else
                  ...budgets.map(
                    (budget) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BudgetCard(
                        budget: budget,
                        isDeleting: _viewModel.isDeleting(budget.id),
                        onEdit: () => _openEdit(budget),
                        onDelete: () => _confirmDelete(budget),
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

  Future<void> _showPeriodPicker() async {
    var year = _viewModel.selectedYear;
    var month = _viewModel.selectedMonth;
    final selected = await showModalBottomSheet<({int year, int month})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bütçe Dönemi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: const Key('budget-period-month'),
                        initialValue: month,
                        decoration: const InputDecoration(labelText: 'Ay'),
                        items: [
                          for (var value = 1; value <= 12; value++)
                            DropdownMenuItem(
                              value: value,
                              child: Text(DashboardFormatters.monthName(value)),
                            ),
                        ],
                        onChanged: (value) =>
                            setModalState(() => month = value ?? month),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: const Key('budget-period-year'),
                        initialValue: year,
                        decoration: const InputDecoration(labelText: 'Yıl'),
                        items: [
                          for (var value = 2000; value <= 2100; value++)
                            DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                        ],
                        onChanged: (value) =>
                            setModalState(() => year = value ?? year),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('apply-budget-period'),
                    onPressed: () =>
                        Navigator.pop(context, (year: year, month: month)),
                    child: const Text('Dönemi Göster'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null) {
      _viewModel.selectPeriod(year: selected.year, month: selected.month);
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddBudgetScreen(
          categories: _viewModel.categories,
          budgetService: widget.budgetService,
          initialYear: _viewModel.selectedYear,
          initialMonth: _viewModel.selectedMonth,
        ),
      ),
    );
    if (created == true && mounted) {
      await _viewModel.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bütçe başarıyla oluşturuldu.')),
        );
      }
    }
  }

  Future<void> _openEdit(BudgetListItem budget) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditBudgetScreen(
          budget: budget,
          budgetService: widget.budgetService,
        ),
      ),
    );
    if (updated == true && mounted) {
      await _viewModel.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bütçe limiti güncellendi.')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BudgetListItem budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bütçeyi Sil'),
        content: const Text(
          'Bu bütçe kaydını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            key: const Key('confirm-budget-delete'),
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final message = await _viewModel.deleteBudget(budget);
    if (message != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetListItem budget;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (budget.alertStatus) {
      BudgetAlertStatus.normal => (
        'Normal',
        AppColors.success,
        AppColors.successBackground,
      ),
      BudgetAlertStatus.warning => (
        'Limite Yakın',
        AppColors.warning,
        AppColors.warningBackground,
      ),
      BudgetAlertStatus.exceeded => (
        'Limit Aşıldı',
        AppColors.error,
        AppColors.errorBackground,
      ),
      BudgetAlertStatus.unknown => (
        'Durum Bilinmiyor',
        AppColors.textSecondary,
        AppColors.border,
      ),
    };
    final visualProgress = (budget.usagePercent / 100).clamp(0.0, 1.0);
    return Card(
      key: Key('budget-${budget.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    budget.category.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _BudgetValue(
                    label: 'Limit',
                    value: DashboardFormatters.currency(budget.limitAmount),
                  ),
                ),
                Expanded(
                  child: _BudgetValue(
                    label: 'Harcanan',
                    value: DashboardFormatters.currency(budget.spentAmount),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      key: Key('budget-progress-${budget.id}'),
                      value: visualProgress,
                      minHeight: 8,
                      color: color,
                      backgroundColor: AppColors.border,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '%${DashboardFormatters.percent(budget.usagePercent)}',
                  key: Key('budget-usage-${budget.id}'),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Düzenle'),
                ),
                if (isDeleting)
                  const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    tooltip: 'Bütçeyi sil',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetValue extends StatelessWidget {
  const _BudgetValue({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

class _EmptyBudgets extends StatelessWidget {
  const _EmptyBudgets({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 44,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Bu dönem için henüz bütçe oluşturulmamış.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Bütçe Ekle'),
          ),
        ],
      ),
    ),
  );
}
