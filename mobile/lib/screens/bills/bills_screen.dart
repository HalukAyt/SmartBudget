import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../config/dashboard_formatters.dart';
import '../../config/transaction_formatters.dart';
import '../../models/bill_models.dart';
import '../../models/recurring_models.dart';
import '../../services/bill_service.dart';
import '../../services/recurring_rule_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/app_help_button.dart';
import 'add_bill_screen.dart';
import 'bills_view_model.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({
    required this.service,
    required this.recurringRuleService,
    this.onHelp,
    this.tutorialAddKey,
    this.onFinancialDataChanged,
    super.key,
  });
  final BillDataService service;
  final RecurringRuleDataService recurringRuleService;
  final VoidCallback? onHelp;
  final GlobalKey? tutorialAddKey;
  final VoidCallback? onFinancialDataChanged;
  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  late final BillsViewModel _viewModel;
  @override
  void initState() {
    super.initState();
    _viewModel = BillsViewModel(
      service: widget.service,
      recurringRuleService: widget.recurringRuleService,
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
      title: const Text('Faturalar'),
      actions: [
        if (widget.onHelp != null) AppHelpButton(onPressed: widget.onHelp!),
      ],
    ),
    floatingActionButton: KeyedSubtree(
      key: widget.tutorialAddKey,
      child: FloatingActionButton.extended(
        key: const Key('add-bill'),
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Fatura Ekle'),
      ),
    ),
    body: SafeArea(
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isListLoading && _viewModel.bills.isEmpty) {
            return const LoadingView(message: 'Faturalar yükleniyor…');
          }
          if (_viewModel.listError != null && _viewModel.bills.isEmpty) {
            return ErrorView(
              message: _viewModel.listError!,
              onRetry: _viewModel.loadBills,
            );
          }
          return RefreshIndicator(
            onRefresh: _viewModel.refresh,
            child: ListView(
              key: const Key('bills-list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                _BillFilters(viewModel: _viewModel),
                const SizedBox(height: 18),
                if (_viewModel.visibleBills.isEmpty)
                  _EmptyBills(onAdd: _openCreate)
                else
                  ..._viewModel.visibleBills.map(
                    (bill) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BillCard(
                        bill: bill,
                        deleting: _viewModel.isDeleting(bill.id),
                        onDelete: () => _confirmDelete(bill),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                _PlannedBillsSection(
                  viewModel: _viewModel,
                  onRealize: _realizeBillRule,
                ),
                const SizedBox(height: 12),
                _TrendSection(viewModel: _viewModel),
              ],
            ),
          );
        },
      ),
    ),
  );

  Future<void> _openCreate() async {
    final outcome = await Navigator.of(context).push<AddRecordOutcome>(
      MaterialPageRoute(
        builder: (_) => AddBillScreen(
          service: widget.service,
          recurringRuleService: widget.recurringRuleService,
        ),
      ),
    );
    if (outcome == null || !mounted) return;
    if (outcome == AddRecordOutcome.created) {
      await _viewModel.refresh();
      widget.onFinancialDataChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fatura başarıyla oluşturuldu.')),
        );
      }
    } else {
      // A fixed-amount Bill rule due today may already have been
      // auto-realized (Bill + linked Expense) by the backend at create
      // time, so refresh the bill list and Dashboard here too, not just
      // the recurring rules list.
      widget.onFinancialDataChanged?.call();
      await _viewModel.refresh();
      await _viewModel.loadRecurringRules();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Planlanan fatura oluşturuldu.')),
        );
      }
    }
  }

  Future<void> _realizeBillRule(RecurringRuleListItem rule) async {
    final now = DateTime.now();
    final entered = await showDialog<({double amount, double? consumption})>(
      context: context,
      builder: (context) => _RealizeBillDialog(rule: rule, now: now),
    );
    if (entered == null || !mounted) return;

    final message = await _viewModel.realizeRecurringRule(
      rule,
      year: now.year,
      month: now.month,
      amount: entered.amount,
      consumptionValue: entered.consumption,
    );
    if (message == null) {
      widget.onFinancialDataChanged?.call();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Fatura başarıyla oluşturuldu.')),
      );
    }
  }

  Future<void> _confirmDelete(BillListItem bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Faturayı Sil'),
        content: const Text(
          'Bu fatura kaydını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            key: const Key('confirm-bill-delete'),
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final message = await _viewModel.deleteBill(bill);
    if (message == null) widget.onFinancialDataChanged?.call();
    if (message != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _BillFilters extends StatelessWidget {
  const _BillFilters({required this.viewModel});
  final BillsViewModel viewModel;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: BillFilter.values
          .map((filter) {
            final label = switch (filter) {
              BillFilter.all => 'Tümü',
              BillFilter.electricity => 'Elektrik',
              BillFilter.water => 'Su',
              BillFilter.naturalGas => 'Doğalgaz',
            };
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: Key('bill-filter-${filter.name}'),
                label: Text(label),
                selected: viewModel.filter == filter,
                onSelected: (_) => viewModel.selectFilter(filter),
              ),
            );
          })
          .toList(growable: false),
    ),
  );
}

class _BillCard extends StatelessWidget {
  const _BillCard({
    required this.bill,
    required this.deleting,
    required this.onDelete,
  });
  final BillListItem bill;
  final bool deleting;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Card(
    key: Key('bill-${bill.id}'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.primary,
            child: Icon(_iconFor(bill.billType)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.billType.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(TransactionFormatters.date(bill.billingDate)),
                const SizedBox(height: 5),
                Text(
                  bill.consumptionValue == null
                      ? 'Tüketim bilgisi yok'
                      : '${_formatNumber(bill.consumptionValue!)} ${bill.consumptionUnit}',
                  key: Key('bill-consumption-${bill.id}'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                TransactionFormatters.currency(bill.amount),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (deleting)
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  tooltip: 'Faturayı sil',
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

class _RealizeBillDialog extends StatefulWidget {
  const _RealizeBillDialog({required this.rule, required this.now});

  final RecurringRuleListItem rule;
  final DateTime now;

  @override
  State<_RealizeBillDialog> createState() => _RealizeBillDialogState();
}

class _RealizeBillDialogState extends State<_RealizeBillDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _amountController = TextEditingController(
    text: widget.rule.amount == null
        ? ''
        : widget.rule.amount!.toStringAsFixed(2),
  );
  final _consumptionController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _consumptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = TransactionFormatters.parseAmount(_amountController.text)!;
    final consumptionText = _consumptionController.text.trim();
    final consumption = consumptionText.isEmpty
        ? null
        : TransactionFormatters.parseAmount(consumptionText);
    Navigator.pop(context, (amount: amount, consumption: consumption));
  }

  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;
    return AlertDialog(
      title: Text('${rule.billType?.label ?? 'Fatura'} - Faturayı Gir'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DashboardFormatters.monthName(widget.now.month)} ${widget.now.year}',
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('realize-bill-amount'),
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Gerçek Tutar'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final amount = TransactionFormatters.parseAmount(value ?? '');
                if (amount == null || amount <= 0) {
                  return 'Geçerli bir tutar girin.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('realize-bill-consumption'),
              controller: _consumptionController,
              decoration: InputDecoration(
                labelText: rule.billType == null
                    ? 'Tüketim (opsiyonel)'
                    : 'Tüketim (${rule.billType!.defaultUnit}, opsiyonel)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final amount = TransactionFormatters.parseAmount(value);
                if (amount == null || amount <= 0) {
                  return 'Geçerli bir tüketim miktarı girin.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        TextButton(
          key: const Key('confirm-realize-bill'),
          onPressed: _submit,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

class _PlannedBillsSection extends StatelessWidget {
  const _PlannedBillsSection({
    required this.viewModel,
    required this.onRealize,
  });

  final BillsViewModel viewModel;
  final ValueChanged<RecurringRuleListItem> onRealize;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isRecurringLoading && viewModel.recurringBillRules.isEmpty) {
      return const SizedBox.shrink();
    }
    if (viewModel.recurringBillRules.isEmpty &&
        viewModel.recurringErrorMessage == null) {
      return const SizedBox.shrink();
    }
    final now = DateTime.now();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Planlanan Faturalar',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (viewModel.recurringErrorMessage != null)
              Text(viewModel.recurringErrorMessage!)
            else
              ...viewModel.recurringBillRules.map(
                (rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PlannedBillCard(
                    rule: rule,
                    isDue: rule.isDueFor(now),
                    isRealizing: viewModel.isRealizingRule(rule.id),
                    onRealize: () => onRealize(rule),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlannedBillCard extends StatelessWidget {
  const _PlannedBillCard({
    required this.rule,
    required this.isDue,
    required this.isRealizing,
    required this.onRealize,
  });

  final RecurringRuleListItem rule;
  final bool isDue;
  final bool isRealizing;
  final VoidCallback onRealize;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('recurring-bill-rule-${rule.id}'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(_iconFor(rule.billType ?? BillType.unknown)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rule.billType?.label ?? 'Fatura',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                rule.isActive
                    ? 'Her ayın ${rule.startDate.day}. günü'
                    : 'Her ayın ${rule.startDate.day}. günü (pasif)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (rule.isRealizedThisMonth)
          const Text(
            'Bu ay oluşturuldu',
            style: TextStyle(color: AppColors.success, fontSize: 12),
          )
        // A known template amount auto-realizes on the backend; only an
        // unknown amount needs the user to manually enter the real bill.
        else if (rule.amount != null)
          const Text(
            'Bekleniyor',
            style: TextStyle(color: AppColors.warning, fontSize: 12),
          )
        else if (isDue)
          isRealizing
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : OutlinedButton(
                  key: Key('realize-bill-rule-${rule.id}'),
                  onPressed: onRealize,
                  child: const Text('Faturayı Gir'),
                )
        else
          const Text(
            'Dönem dışı',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
      ],
    ),
  );
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.viewModel});
  final BillsViewModel viewModel;
  @override
  Widget build(BuildContext context) {
    final visibleTrend = viewModel.visibleTrend;
    final hasTrendData = visibleTrend.any(
      (point) => point.totalAmount != 0 || point.totalConsumption != null,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Son 6 Ay Fatura ve Tüketim Trendi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final type in const [
                  BillType.electricity,
                  BillType.water,
                  BillType.naturalGas,
                ])
                  ChoiceChip(
                    key: Key('trend-type-${type.name}'),
                    label: Text(type.label),
                    selected: viewModel.trendType == type,
                    onSelected: (_) => viewModel.selectTrendType(type),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (viewModel.isTrendLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (viewModel.trendError != null)
              Column(
                children: [
                  Text(viewModel.trendError!),
                  TextButton(
                    key: const Key('retry-bill-trend'),
                    onPressed: viewModel.loadTrend,
                    child: const Text('Trendi Tekrar Dene'),
                  ),
                ],
              )
            else if (!hasTrendData)
              const Text('Son 6 ay için fatura verisi yok.')
            else
              ...visibleTrend.map((point) => _TrendRow(point: point)),
          ],
        ),
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.point});
  final BillTrendPoint point;
  @override
  Widget build(BuildContext context) => Padding(
    key: Key('trend-${point.billType.name}-${point.year}-${point.month}'),
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            DashboardFormatters.monthName(point.month).substring(0, 3),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(TransactionFormatters.currency(point.totalAmount)),
              Text(
                point.totalConsumption == null
                    ? 'Tüketim verisi yok'
                    : '${_formatNumber(point.totalConsumption!)} ${point.consumptionUnit}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Text('${point.year}'),
      ],
    ),
  );
}

class _EmptyBills extends StatelessWidget {
  const _EmptyBills({required this.onAdd});
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
            'Henüz fatura kaydın bulunmuyor.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Fatura Ekle'),
          ),
        ],
      ),
    ),
  );
}

IconData _iconFor(BillType type) => switch (type) {
  BillType.electricity => Icons.bolt_outlined,
  BillType.water => Icons.water_drop_outlined,
  BillType.naturalGas => Icons.local_fire_department_outlined,
  BillType.unknown => Icons.receipt_outlined,
};

String _formatNumber(double value) {
  final text = value.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '');
  return text.replaceFirst(RegExp(r'\.$'), '').replaceAll('.', ',');
}
