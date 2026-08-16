import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/config/app_theme.dart';
import 'package:smartbudget_mobile/models/dashboard_models.dart';
import 'package:smartbudget_mobile/screens/dashboard/dashboard_screen.dart';
import 'package:smartbudget_mobile/screens/dashboard/dashboard_widgets.dart';
import 'package:smartbudget_mobile/services/api_client.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('initial dashboard displays loading then backend period', (
    tester,
  ) async {
    final completer = Completer<MonthlyDashboard>();
    final service = FakeDashboardService(
      monthlyHandler: ({year, month}) => completer.future,
    );

    await _pumpDashboard(tester, service);
    expect(find.text('Dashboard yükleniyor…'), findsOneWidget);
    expect(service.monthlyCalls.single, (year: null, month: null));

    completer.complete(sampleDashboard());
    await tester.pumpAndSettle();
    expect(find.text('Ağustos 2026'), findsOneWidget);
  });

  testWidgets('error view retries only dashboard load', (tester) async {
    var attempt = 0;
    final service = FakeDashboardService(
      monthlyHandler: ({year, month}) async {
        attempt++;
        if (attempt == 1) {
          throw const ApiException(
            ApiErrorType.network,
            'Bağlantı kurulamadı.',
          );
        }
        return sampleDashboard();
      },
    );
    await _pumpDashboard(tester, service);
    await tester.pumpAndSettle();

    expect(find.text('Bağlantı kurulamadı.'), findsOneWidget);
    await tester.tap(find.text('Tekrar Dene'));
    await tester.pumpAndSettle();
    expect(find.text('Finansal Özet'), findsOneWidget);
    expect(service.analysisCalls, isEmpty);
  });

  testWidgets('empty financial data is a successful state', (tester) async {
    final service = FakeDashboardService(
      monthlyHandler: ({year, month}) => Future.value(
        sampleDashboard(
          totalIncome: 0,
          totalExpense: 0,
          balance: 0,
          includeCategories: false,
          includeBudgets: false,
          includeHighestSpending: false,
          includeHighestIncrease: false,
        ),
      ),
    );
    await _pumpDashboard(tester, service);
    await tester.pumpAndSettle();

    expect(
      find.text('Bu ay için henüz finansal kayıt bulunmuyor.'),
      findsOneWidget,
    );
    expect(find.text('₺0,00'), findsNWidgets(3));
  });

  testWidgets(
    'financial values, categories and budget statuses use backend values',
    (tester) async {
      await _pumpDashboard(tester, FakeDashboardService());
      await tester.pumpAndSettle();

      expect(find.text('₺5.000,00'), findsOneWidget);
      expect(find.text('₺6.250,00'), findsOneWidget);
      expect(find.text('-₺1.250,00'), findsOneWidget);
      expect(find.text('Market'), findsWidgets);

      await _scrollTo(tester, find.text('Limit Aşıldı'));
      expect(find.text('Limit Aşıldı'), findsOneWidget);
      expect(find.text('Limite Yakın'), findsOneWidget);
      expect(find.text('%135'), findsOneWidget);
    },
  );

  testWidgets(
    'previous month null and missing insight categories are explicit',
    (tester) async {
      final dashboard = sampleDashboard(
        previousChange: null,
        includeHighestSpending: false,
        includeHighestIncrease: false,
      );
      await tester.pumpWidget(
        _widget(DashboardInsightsCard(dashboard: dashboard)),
      );

      expect(
        find.text('Önceki aya göre karşılaştırma için yeterli veri yok.'),
        findsOneWidget,
      );
      expect(
        find.text('Bu ay için en yüksek harcama kategorisi bulunmuyor.'),
        findsOneWidget,
      );
      expect(find.text('Pozitif kategori artışı bulunmuyor.'), findsOneWidget);
    },
  );

  testWidgets(
    'positive, negative and zero previous month changes are rendered',
    (tester) async {
      for (final scenario in <(double, String)>[
        (12.5, 'Önceki aya göre giderler %12,5 arttı.'),
        (-8.25, 'Önceki aya göre giderler %8,25 azaldı.'),
        (0, 'Önceki aya göre gider değişimi yok.'),
      ]) {
        await tester.pumpWidget(
          _widget(
            DashboardInsightsCard(
              dashboard: sampleDashboard(previousChange: scenario.$1),
            ),
          ),
        );
        expect(find.text(scenario.$2), findsOneWidget);
      }
    },
  );

  testWidgets('all six backend trend points render in supplied order', (
    tester,
  ) async {
    final points = sampleDashboard().lastSixMonthsTrend;
    await tester.pumpWidget(
      _widget(SingleChildScrollView(child: MonthlyTrendCard(points: points))),
    );

    for (final point in points) {
      expect(
        find.byKey(Key('trend-${point.year}-${point.month}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('all-zero expense trend shows an empty state without rows', (
    tester,
  ) async {
    final points = List.generate(
      6,
      (index) => MonthlyTrendPoint(
        year: 2026,
        month: index + 1,
        totalIncome: 0,
        totalExpense: 0,
        balance: 0,
      ),
    );

    await tester.pumpWidget(_widget(MonthlyTrendCard(points: points)));

    expect(find.text('Son 6 ay için veri yok.'), findsOneWidget);
    expect(find.byKey(const Key('trend-2026-1')), findsNothing);
  });

  testWidgets('one positive expense keeps all six trend rows visible', (
    tester,
  ) async {
    final points = List.generate(
      6,
      (index) => MonthlyTrendPoint(
        year: 2026,
        month: index + 1,
        totalIncome: 0,
        totalExpense: index == 3 ? 100 : 0,
        balance: index == 3 ? -100 : 0,
      ),
    );

    await tester.pumpWidget(
      _widget(SingleChildScrollView(child: MonthlyTrendCard(points: points))),
    );

    expect(find.text('Son 6 ay için veri yok.'), findsNothing);
    for (final point in points) {
      expect(
        find.byKey(Key('trend-${point.year}-${point.month}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('AI is manual, isolated and successful response is displayed', (
    tester,
  ) async {
    final aiCompleter = Completer<MonthlyAnalysisResponse>();
    final service = FakeDashboardService(
      analysisHandler: ({year, month}) => aiCompleter.future,
    );
    await _pumpDashboard(tester, service);
    await tester.pumpAndSettle();
    expect(service.analysisCalls, isEmpty);

    final button = find.text('AI Analizini Oluştur');
    await _scrollTo(tester, button);
    await tester.tap(button);
    await tester.pump();
    expect(service.analysisCalls, hasLength(1));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('dashboard-list')), findsOneWidget);

    aiCompleter.complete(
      const MonthlyAnalysisResponse(
        success: true,
        year: 2026,
        month: 8,
        analysis: 'Backend verilerine dayalı kontrollü yorum.',
        requiresManualReview: false,
        message: 'Analiz oluşturuldu.',
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Backend verilerine dayalı kontrollü yorum.'),
      findsOneWidget,
    );
  });

  testWidgets('AI controlled failure does not replace dashboard data', (
    tester,
  ) async {
    final service = FakeDashboardService(
      analysisHandler: ({year, month}) async => MonthlyAnalysisResponse(
        success: false,
        year: year ?? 2026,
        month: month ?? 8,
        analysis: null,
        requiresManualReview: true,
        message: 'Kontrollü fallback.',
      ),
    );
    await _pumpDashboard(tester, service);
    await tester.pumpAndSettle();
    final button = find.text('AI Analizini Oluştur');
    await _scrollTo(tester, button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ai-fallback')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-list')), findsOneWidget);
  });

  testWidgets('AI double submit is blocked', (tester) async {
    final completer = Completer<MonthlyAnalysisResponse>();
    final service = FakeDashboardService(
      analysisHandler: ({year, month}) => completer.future,
    );
    await _pumpDashboard(tester, service);
    await tester.pumpAndSettle();
    final button = find.text('AI Analizini Oluştur');
    await _scrollTo(tester, button);
    await tester.tap(button);
    await tester.tap(button, warnIfMissed: false);
    expect(service.analysisCalls, hasLength(1));
    completer.completeError(Exception('failure'));
    await tester.pumpAndSettle();
  });

  testWidgets('pull to refresh reloads dashboard without AI call', (
    tester,
  ) async {
    final service = FakeDashboardService();
    await _pumpDashboard(tester, service);
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('dashboard-list')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();

    expect(service.monthlyCalls, hasLength(2));
    expect(service.analysisCalls, isEmpty);
  });
}

Future<void> _pumpDashboard(WidgetTester tester, FakeDashboardService service) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: DashboardScreen(service: service),
    ),
  );
}

Widget _widget(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: SafeArea(child: child)),
);

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}
