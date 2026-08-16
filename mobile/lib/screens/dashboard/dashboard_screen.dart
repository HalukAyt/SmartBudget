import 'package:flutter/material.dart';

import '../../config/dashboard_formatters.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/app_help_button.dart';
import 'dashboard_view_model.dart';
import 'dashboard_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.service,
    this.onHelp,
    this.tutorialSummaryKey,
    this.tutorialAiAnalysisKey,
    super.key,
  });
  final DashboardDataService service;
  final VoidCallback? onHelp;
  final GlobalKey? tutorialSummaryKey;
  final GlobalKey? tutorialAiAnalysisKey;

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  late final DashboardViewModel _viewModel;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel(service: widget.service)..loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> revealTutorialTarget({required bool aiAnalysis}) async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      aiAnalysis ? _scrollController.position.maxScrollExtent : 0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final targetContext =
        (aiAnalysis ? widget.tutorialAiAnalysisKey : widget.tutorialSummaryKey)
            ?.currentContext;
    if (targetContext != null && targetContext.mounted) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 120),
        alignment: 0.5,
      );
    }
  }

  Future<void> refreshFinancialData() => _viewModel.refresh();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Ana Sayfa'),
      actions: [
        if (widget.onHelp != null) AppHelpButton(onPressed: widget.onHelp!),
      ],
    ),
    body: SafeArea(
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          final dashboard = _viewModel.data;
          if (_viewModel.isLoading && dashboard == null) {
            return const LoadingView(message: 'Dashboard yükleniyor…');
          }
          if (_viewModel.errorMessage != null && dashboard == null) {
            return ErrorView(
              message: _viewModel.errorMessage!,
              onRetry: _viewModel.retry,
            );
          }
          if (dashboard == null) {
            return ErrorView(
              message: 'Dashboard verileri yüklenemedi.',
              onRetry: _viewModel.retry,
            );
          }

          return RefreshIndicator(
            onRefresh: _viewModel.refresh,
            child: ListView(
              key: const Key('dashboard-list'),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Finansal durumun',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Backend tarafından hesaplanan aylık özet',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: PeriodSelector(
                        year: dashboard.year,
                        month: dashboard.month,
                        onPressed: () =>
                            _showPeriodPicker(dashboard.year, dashboard.month),
                      ),
                    ),
                  ],
                ),
                if (_viewModel.isLoading) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                const SizedBox(height: 20),
                if (dashboard.hasNoFinancialData) ...[
                  const EmptyFinancialDataBanner(),
                  const SizedBox(height: 14),
                ],
                KeyedSubtree(
                  key: widget.tutorialSummaryKey,
                  child: KeyedSubtree(
                    key: const Key('tutorial-target-dashboard-summary'),
                    child: FinancialSummaryCard(dashboard: dashboard),
                  ),
                ),
                const SizedBox(height: 14),
                CategoryExpensesCard(items: dashboard.categoryExpenses),
                const SizedBox(height: 14),
                BudgetUsagesCard(items: dashboard.budgetUsages),
                const SizedBox(height: 14),
                DashboardInsightsCard(dashboard: dashboard),
                const SizedBox(height: 14),
                MonthlyTrendCard(points: dashboard.lastSixMonthsTrend),
                const SizedBox(height: 14),
                KeyedSubtree(
                  key: widget.tutorialAiAnalysisKey,
                  child: KeyedSubtree(
                    key: const Key('tutorial-target-dashboard-ai'),
                    child: AiInsightCard(
                      response: _viewModel.analysis,
                      errorMessage: _viewModel.aiErrorMessage,
                      isLoading: _viewModel.isAiLoading,
                      onGenerate: _viewModel.generateAnalysis,
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

  Future<void> _showPeriodPicker(int initialYear, int initialMonth) async {
    var selectedYear = initialYear;
    var selectedMonth = initialMonth;
    final selection = await showModalBottomSheet<({int year, int month})>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Raporlama Dönemi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: const Key('month-dropdown'),
                        initialValue: selectedMonth,
                        decoration: const InputDecoration(labelText: 'Ay'),
                        items: [
                          for (var month = 1; month <= 12; month++)
                            DropdownMenuItem(
                              value: month,
                              child: Text(DashboardFormatters.monthName(month)),
                            ),
                        ],
                        onChanged: (value) => setModalState(
                          () => selectedMonth = value ?? selectedMonth,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: const Key('year-dropdown'),
                        initialValue: selectedYear,
                        decoration: const InputDecoration(labelText: 'Yıl'),
                        items: [
                          for (var year = 2000; year <= 2100; year++)
                            DropdownMenuItem(value: year, child: Text('$year')),
                        ],
                        onChanged: (value) => setModalState(
                          () => selectedYear = value ?? selectedYear,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('apply-period'),
                    onPressed: () => Navigator.of(
                      context,
                    ).pop((year: selectedYear, month: selectedMonth)),
                    child: const Text('Dönemi Göster'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selection != null && mounted) {
      await _viewModel.selectPeriod(
        year: selection.year,
        month: selection.month,
      );
    }
  }
}
