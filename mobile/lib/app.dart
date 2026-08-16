import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/auth_service.dart';
import 'services/bill_service.dart';
import 'services/budget_service.dart';
import 'services/ai_categorization_service.dart';
import 'services/category_service.dart';
import 'services/dashboard_service.dart';
import 'services/expense_service.dart';
import 'services/income_service.dart';
import 'services/recurring_rule_service.dart';
import 'storage/secure_storage_service.dart';
import 'widgets/loading_view.dart';

class SmartBudgetApp extends StatefulWidget {
  const SmartBudgetApp({
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
  State<SmartBudgetApp> createState() => _SmartBudgetAppState();
}

class _SmartBudgetAppState extends State<SmartBudgetApp> {
  @override
  void initState() {
    super.initState();
    widget.authService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartBudget AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AnimatedBuilder(
        animation: widget.authService,
        builder: (context, _) => switch (widget.authService.status) {
          AuthStatus.checking => const Scaffold(body: LoadingView()),
          AuthStatus.unauthenticated => LoginScreen(
            authService: widget.authService,
          ),
          AuthStatus.authenticated => MainShell(
            authService: widget.authService,
            dashboardService: widget.dashboardService,
            expenseService: widget.expenseService,
            incomeService: widget.incomeService,
            categoryService: widget.categoryService,
            budgetService: widget.budgetService,
            billService: widget.billService,
            aiCategorizationService: widget.aiCategorizationService,
            recurringRuleService: widget.recurringRuleService,
            tutorialStorage: widget.tutorialStorage,
          ),
        },
      ),
    );
  }
}
