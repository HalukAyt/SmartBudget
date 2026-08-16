import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../config/dashboard_formatters.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/primary_button.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    required this.year,
    required this.month,
    required this.onPressed,
    super.key,
  });
  final int year;
  final int month;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Raporlama dönemini değiştir',
    child: InkWell(
      key: const Key('period-selector'),
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                DashboardFormatters.period(year, month),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    ),
  );
}

class FinancialSummaryCard extends StatelessWidget {
  const FinancialSummaryCard({required this.dashboard, super.key});
  final MonthlyDashboard dashboard;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Finansal Özet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryValue(
                label: 'Toplam Gelir',
                value: DashboardFormatters.currency(dashboard.totalIncome),
                color: AppColors.success,
                icon: Icons.south_west,
              ),
              _SummaryValue(
                label: 'Toplam Gider',
                value: DashboardFormatters.currency(dashboard.totalExpense),
                color: AppColors.error,
                icon: Icons.north_east,
              ),
              _SummaryValue(
                label: 'Bakiye',
                value: DashboardFormatters.currency(dashboard.balance),
                color: dashboard.balance < 0
                    ? AppColors.error
                    : AppColors.primary,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 140),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(
              value,
              key: Key('summary-$label'),
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ],
    ),
  );
}

class CategoryExpensesCard extends StatelessWidget {
  const CategoryExpensesCard({required this.items, super.key});
  final List<CategoryExpenseSummary> items;

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Kategori Harcamaları',
    child: items.isEmpty
        ? const _EmptySectionText('Bu ay kategori harcaması bulunmuyor.')
        : Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _CategoryExpenseRow(item: items[index]),
                if (index != items.length - 1) const SizedBox(height: 14),
              ],
            ],
          ),
  );
}

class _CategoryExpenseRow extends StatelessWidget {
  const _CategoryExpenseRow({required this.item});
  final CategoryExpenseSummary item;

  @override
  Widget build(BuildContext context) {
    final visualProgress = (item.percentageOfTotalExpense / 100).clamp(
      0.0,
      1.0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.categoryName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Text(DashboardFormatters.currency(item.amount)),
            const SizedBox(width: 8),
            Text(
              '%${DashboardFormatters.percent(item.percentageOfTotalExpense)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: visualProgress,
            backgroundColor: AppColors.primaryLight,
          ),
        ),
      ],
    );
  }
}

class BudgetUsagesCard extends StatelessWidget {
  const BudgetUsagesCard({required this.items, super.key});
  final List<BudgetUsageSummary> items;

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Bütçe Durumu',
    child: items.isEmpty
        ? const _EmptySectionText('Bu ay için tanımlı bütçe bulunmuyor.')
        : Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _BudgetUsageRow(item: items[index]),
                if (index != items.length - 1) const Divider(height: 28),
              ],
            ],
          ),
  );
}

class _BudgetUsageRow extends StatelessWidget {
  const _BudgetUsageRow({required this.item});
  final BudgetUsageSummary item;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (item.alertStatus) {
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
    final visualProgress = (item.usagePercent / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.category.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
        const SizedBox(height: 8),
        Text(
          '${DashboardFormatters.currency(item.spentAmount)} / ${DashboardFormatters.currency(item.limitAmount)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: visualProgress,
                  color: color,
                  backgroundColor: AppColors.border,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '%${DashboardFormatters.percent(item.usagePercent)}',
              key: Key('budget-percent-${item.budgetId}'),
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

class DashboardInsightsCard extends StatelessWidget {
  const DashboardInsightsCard({required this.dashboard, super.key});
  final MonthlyDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final change = dashboard.previousMonthExpenseChangePercent;
    final changeText = switch (change) {
      null => 'Önceki aya göre karşılaştırma için yeterli veri yok.',
      0 => 'Önceki aya göre gider değişimi yok.',
      > 0 =>
        'Önceki aya göre giderler %${DashboardFormatters.percent(change)} arttı.',
      _ =>
        'Önceki aya göre giderler %${DashboardFormatters.percent(change.abs())} azaldı.',
    };
    final spending = dashboard.highestSpendingCategory;
    final increase = dashboard.highestIncreaseCategory;
    return _SectionCard(
      title: 'Aylık İçgörüler',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InsightLine(icon: Icons.compare_arrows, text: changeText),
          const SizedBox(height: 12),
          _InsightLine(
            icon: Icons.local_fire_department_outlined,
            text: spending == null
                ? 'Bu ay için en yüksek harcama kategorisi bulunmuyor.'
                : 'En çok harcama: ${spending.categoryName} (${DashboardFormatters.currency(spending.amount)})',
          ),
          const SizedBox(height: 12),
          _InsightLine(
            icon: Icons.trending_up,
            text: increase == null
                ? 'Pozitif kategori artışı bulunmuyor.'
                : 'En fazla artış: ${increase.categoryName} (${DashboardFormatters.currency(increase.increaseAmount)})',
          ),
        ],
      ),
    );
  }
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(child: Text(text)),
    ],
  );
}

class MonthlyTrendCard extends StatelessWidget {
  const MonthlyTrendCard({required this.points, super.key});
  final List<MonthlyTrendPoint> points;
  @override
  Widget build(BuildContext context) {
    final hasExpenseData = points.any((point) => point.totalExpense > 0);
    return _SectionCard(
      title: 'Son 6 Ay Trendi',
      child: hasExpenseData
          ? Column(
              children: [
                for (var index = 0; index < points.length; index++) ...[
                  _TrendRow(point: points[index]),
                  if (index != points.length - 1) const Divider(height: 22),
                ],
              ],
            )
          : const _EmptySectionText('Son 6 ay için veri yok.'),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.point});
  final MonthlyTrendPoint point;
  @override
  Widget build(BuildContext context) => Row(
    key: Key('trend-${point.year}-${point.month}'),
    children: [
      SizedBox(
        width: 72,
        child: Text(
          '${DashboardFormatters.monthName(point.month).substring(0, 3)} ${point.year}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      Expanded(
        child: Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _TrendValue(
              label: 'Gelir',
              value: point.totalIncome,
              color: AppColors.success,
            ),
            _TrendValue(
              label: 'Gider',
              value: point.totalExpense,
              color: AppColors.error,
            ),
            _TrendValue(
              label: 'Bakiye',
              value: point.balance,
              color: point.balance < 0 ? AppColors.error : AppColors.primary,
            ),
          ],
        ),
      ),
    ],
  );
}

class _TrendValue extends StatelessWidget {
  const _TrendValue({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    '$label: ${DashboardFormatters.currency(value)}',
    style: TextStyle(fontSize: 12, color: color),
  );
}

class AiInsightCard extends StatelessWidget {
  const AiInsightCard({
    required this.response,
    required this.errorMessage,
    required this.isLoading,
    required this.onGenerate,
    super.key,
  });
  final MonthlyAnalysisResponse? response;
  final String? errorMessage;
  final bool isLoading;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final analysis = response?.analysis?.trim();
    final isSuccess =
        response?.success == true &&
        response?.requiresManualReview == false &&
        analysis != null &&
        analysis.isNotEmpty;
    final hasControlledFailure = response != null && !isSuccess;
    return _SectionCard(
      title: 'AI Aylık Analiz',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSuccess) ...[
            Text(analysis),
            const SizedBox(height: 10),
            Text(
              'Bu yorum mevcut finansal verilerine göre oluşturulmuştur.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else if (errorMessage != null || hasControlledFailure) ...[
            const Text(
              'AI analizi şu anda oluşturulamadı. Daha sonra tekrar deneyebilirsin.',
              key: Key('ai-fallback'),
            ),
          ] else ...[
            const Text(
              'Backend tarafından hesaplanan aylık finansal özetini AI desteğiyle yorumlatabilirsin.',
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: isSuccess || hasControlledFailure || errorMessage != null
                ? 'Analizi Yeniden Oluştur'
                : 'AI Analizini Oluştur',
            isLoading: isLoading,
            onPressed: isLoading ? null : onGenerate,
          ),
        ],
      ),
    );
  }
}

class EmptyFinancialDataBanner extends StatelessWidget {
  const EmptyFinancialDataBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline, color: AppColors.primary),
        SizedBox(width: 10),
        Expanded(child: Text('Bu ay için henüz finansal kayıt bulunmuyor.')),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}

class _EmptySectionText extends StatelessWidget {
  const _EmptySectionText(this.message);
  final String message;
  @override
  Widget build(BuildContext context) =>
      Text(message, style: Theme.of(context).textTheme.bodySmall);
}
