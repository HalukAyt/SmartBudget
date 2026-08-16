import 'package:flutter/material.dart';

import 'app.dart';
import 'config/api_config.dart';
import 'services/api_client.dart';
import 'services/ai_categorization_service.dart';
import 'services/auth_service.dart';
import 'services/bill_service.dart';
import 'services/budget_service.dart';
import 'services/category_service.dart';
import 'services/dashboard_service.dart';
import 'services/expense_service.dart';
import 'services/income_service.dart';
import 'services/recurring_rule_service.dart';
import 'storage/secure_storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = SecureStorageService();
  final apiClient = ApiClient(
    baseUrl: ApiConfig.baseUrl,
    tokenStorage: storage,
  );
  final authService = AuthService(apiClient: apiClient, tokenStorage: storage);
  final dashboardService = DashboardService(apiClient: apiClient);
  final expenseService = ExpenseService(apiClient: apiClient);
  final incomeService = IncomeService(apiClient: apiClient);
  final categoryService = CategoryService(apiClient: apiClient);
  final budgetService = BudgetService(apiClient: apiClient);
  final billService = BillService(apiClient: apiClient);
  final aiCategorizationService = AiCategorizationService(apiClient: apiClient);
  final recurringRuleService = RecurringRuleService(apiClient: apiClient);

  runApp(
    SmartBudgetApp(
      authService: authService,
      dashboardService: dashboardService,
      expenseService: expenseService,
      incomeService: incomeService,
      categoryService: categoryService,
      budgetService: budgetService,
      billService: billService,
      aiCategorizationService: aiCategorizationService,
      recurringRuleService: recurringRuleService,
      tutorialStorage: storage,
    ),
  );
}
