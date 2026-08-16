import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/models/dashboard_models.dart';
import 'package:smartbudget_mobile/screens/dashboard/dashboard_view_model.dart';
import 'package:smartbudget_mobile/services/api_client.dart';

import 'helpers/fakes.dart';

void main() {
  test('initial load calls default monthly endpoint state', () async {
    final service = FakeDashboardService();
    final model = DashboardViewModel(service: service);

    await model.loadInitial();

    expect(service.monthlyCalls, [(year: null, month: null)]);
    expect(model.data?.year, 2026);
    expect(model.isLoading, isFalse);
  });

  test(
    'loading and error states are controlled and retry calls dashboard',
    () async {
      final completer = Completer<MonthlyDashboard>();
      var attempt = 0;
      final service = FakeDashboardService(
        monthlyHandler: ({year, month}) {
          attempt++;
          if (attempt == 1) return completer.future;
          return Future.value(sampleDashboard());
        },
      );
      final model = DashboardViewModel(service: service);

      final load = model.loadInitial();
      expect(model.isLoading, isTrue);
      completer.completeError(
        const ApiException(ApiErrorType.network, 'Bağlantı kurulamadı.'),
      );
      await load;
      expect(model.errorMessage, 'Bağlantı kurulamadı.');

      await model.retry();
      expect(model.data, isNotNull);
      expect(service.monthlyCalls, hasLength(2));
    },
  );

  test('selected period is used by dashboard and AI requests', () async {
    final service = FakeDashboardService(
      monthlyHandler: ({year, month}) =>
          Future.value(sampleDashboard(year: year!, month: month!)),
    );
    final model = DashboardViewModel(service: service);

    await model.selectPeriod(year: 2025, month: 12);
    await model.generateAnalysis();

    expect(service.monthlyCalls.single, (year: 2025, month: 12));
    expect(service.analysisCalls.single, (year: 2025, month: 12));
  });

  test(
    'AI is not called during dashboard load and loading is isolated',
    () async {
      final aiCompleter = Completer<MonthlyAnalysisResponse>();
      final service = FakeDashboardService(
        analysisHandler: ({year, month}) => aiCompleter.future,
      );
      final model = DashboardViewModel(service: service);
      await model.loadInitial();
      expect(service.analysisCalls, isEmpty);

      final analysis = model.generateAnalysis();
      expect(model.isAiLoading, isTrue);
      expect(model.isLoading, isFalse);
      expect(model.data, isNotNull);
      aiCompleter.completeError(Exception('provider failure'));
      await analysis;
      expect(model.aiErrorMessage, isNotNull);
      expect(model.errorMessage, isNull);
    },
  );

  test('double AI submit is ignored while first request is pending', () async {
    final completer = Completer<MonthlyAnalysisResponse>();
    final service = FakeDashboardService(
      analysisHandler: ({year, month}) => completer.future,
    );
    final model = DashboardViewModel(service: service);
    await model.loadInitial();

    final first = model.generateAnalysis();
    await model.generateAnalysis();
    expect(service.analysisCalls, hasLength(1));

    completer.completeError(Exception('failure'));
    await first;
  });

  test('refresh reloads dashboard without automatically calling AI', () async {
    final service = FakeDashboardService();
    final model = DashboardViewModel(service: service);
    await model.loadInitial();
    await model.generateAnalysis();

    await model.refresh();

    expect(service.monthlyCalls, hasLength(2));
    expect(service.analysisCalls, hasLength(1));
    expect(model.analysis, isNotNull);
  });
}
