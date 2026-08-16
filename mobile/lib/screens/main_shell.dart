import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/bill_service.dart';
import '../services/budget_service.dart';
import '../services/ai_categorization_service.dart';
import '../services/category_service.dart';
import '../services/dashboard_service.dart';
import '../services/expense_service.dart';
import '../services/income_service.dart';
import '../services/recurring_rule_service.dart';
import '../storage/secure_storage_service.dart';
import '../widgets/app_bottom_navigation.dart';
import 'bills/bills_screen.dart';
import 'budgets/budgets_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'profile/profile_screen.dart';
import 'transactions/transactions_screen.dart';
import 'tutorial/tutorial_dialog.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.authService,
    required this.dashboardService,
    required this.expenseService,
    required this.incomeService,
    required this.categoryService,
    required this.budgetService,
    required this.billService,
    required this.aiCategorizationService,
    required this.recurringRuleService,
    required this.tutorialStorage,
    super.key,
  });

  final AuthService authService;
  final DashboardDataService dashboardService;
  final ExpenseDataService expenseService;
  final IncomeDataService incomeService;
  final CategoryDataService categoryService;
  final BudgetDataService budgetService;
  final BillDataService billService;
  final AiCategorizationDataService aiCategorizationService;
  final RecurringRuleDataService recurringRuleService;
  final TutorialStorage tutorialStorage;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _tutorialTabIndexes = [0, 1, 1, 2, 3, 0];

  final _dashboardScreenKey = GlobalKey<DashboardScreenState>();
  final _transactionsScreenKey = GlobalKey<TransactionsScreenState>();
  final _dashboardSummaryKey = GlobalKey();
  final _transactionAddKey = GlobalKey();
  final _transactionAiCategoryKey = GlobalKey();
  final _budgetAddKey = GlobalKey();
  final _billAddKey = GlobalKey();
  final _dashboardAiKey = GlobalKey();

  int _currentIndex = 0;
  bool _tutorialCheckStarted = false;
  bool _isTutorialOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showFirstTutorial());
  }

  Future<void> _showFirstTutorial() async {
    if (_tutorialCheckStarted) return;
    _tutorialCheckStarted = true;
    final email = widget.authService.email;
    if (email == null || await widget.tutorialStorage.hasSeenTutorial(email)) {
      return;
    }
    if (mounted) await _openTutorial();
  }

  Future<void> _openTutorial() async {
    final email = widget.authService.email;
    if (email == null || !mounted || _isTutorialOpen) return;
    _isTutorialOpen = true;
    await _selectTutorialStep(0);
    if (!mounted) {
      _isTutorialOpen = false;
      return;
    }
    try {
      await showTutorialDialog(
        context,
        onStepChanged: _selectTutorialStep,
        targetKeys: [
          _dashboardSummaryKey,
          _transactionAddKey,
          _transactionAiCategoryKey,
          _budgetAddKey,
          _billAddKey,
          _dashboardAiKey,
        ],
        onFinished: () => widget.tutorialStorage.markTutorialSeen(email),
      );
    } finally {
      _transactionsScreenKey.currentState?.hideTutorialExpensePreview();
      _isTutorialOpen = false;
    }
  }

  Future<void> _selectTutorialStep(int stepIndex) async {
    if (!mounted) return;
    if (stepIndex != 2) {
      _transactionsScreenKey.currentState?.hideTutorialExpensePreview();
    }
    final tabIndex = _tutorialTabIndexes[stepIndex];
    if (_currentIndex != tabIndex) {
      setState(() => _currentIndex = tabIndex);
    }
    await WidgetsBinding.instance.endOfFrame;
    if (stepIndex == 2) {
      await _transactionsScreenKey.currentState?.showTutorialExpensePreview();
      await WidgetsBinding.instance.endOfFrame;
    }
    if (stepIndex == 0 || stepIndex == 5) {
      await _dashboardScreenKey.currentState?.revealTutorialTarget(
        aiAnalysis: stepIndex == 5,
      );
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  void _onFinancialDataChanged() {
    _dashboardScreenKey.currentState?.refreshFinancialData();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        key: _dashboardScreenKey,
        service: widget.dashboardService,
        onHelp: _openTutorial,
        tutorialSummaryKey: _dashboardSummaryKey,
        tutorialAiAnalysisKey: _dashboardAiKey,
      ),
      TransactionsScreen(
        key: _transactionsScreenKey,
        expenseService: widget.expenseService,
        incomeService: widget.incomeService,
        categoryService: widget.categoryService,
        aiService: widget.aiCategorizationService,
        recurringRuleService: widget.recurringRuleService,
        onHelp: _openTutorial,
        tutorialAddKey: _transactionAddKey,
        tutorialAiCategoryKey: _transactionAiCategoryKey,
        onFinancialDataChanged: _onFinancialDataChanged,
      ),
      BudgetsScreen(
        budgetService: widget.budgetService,
        categoryService: widget.categoryService,
        onHelp: _openTutorial,
        tutorialAddKey: _budgetAddKey,
      ),
      BillsScreen(
        service: widget.billService,
        recurringRuleService: widget.recurringRuleService,
        onHelp: _openTutorial,
        tutorialAddKey: _billAddKey,
        onFinancialDataChanged: _onFinancialDataChanged,
      ),
      ProfileScreen(authService: widget.authService, onHelp: _openTutorial),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
