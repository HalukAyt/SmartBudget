import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

const _steps = <({String title, String body, IconData icon})>[
  (
    title: "SmartBudget AI'ye Hoş Geldiniz",
    body:
        'Gelir, gider, bakiye ve bütçe durumunuzu Ana Sayfa üzerinden takip edebilirsiniz.',
    icon: Icons.home_outlined,
  ),
  (
    title: 'Gelir ve Giderlerinizi Ekleyin',
    body: 'Gelir ve gider kayıtlarınızı buradan ekleyebilirsiniz.',
    icon: Icons.swap_horiz,
  ),
  (
    title: 'AI ile Kategori Önerisi',
    body:
        "Gider açıklamanıza göre AI'dan kategori önerisi alabilirsiniz. Öneriyi kabul etmek veya değiştirmek sizin kontrolünüzdedir.",
    icon: Icons.auto_awesome_outlined,
  ),
  (
    title: 'Bütçenizi Kontrol Edin',
    body:
        'Kategorilere aylık bütçe belirleyebilir ve kullanım oranınızı buradan takip edebilirsiniz.',
    icon: Icons.account_balance_wallet_outlined,
  ),
  (
    title: 'Faturalarınızı Takip Edin',
    body:
        'Elektrik, su ve doğalgaz faturalarınızı buradan ekleyebilir ve son 6 aylık trendleri takip edebilirsiniz.',
    icon: Icons.receipt_long_outlined,
  ),
  (
    title: 'AI Aylık Analizi',
    body:
        'Aylık finansal verilerinize göre AI harcama analizini istediğiniz zaman buradan çalıştırabilirsiniz.',
    icon: Icons.insights_outlined,
  ),
];

Future<void> showTutorialDialog(
  BuildContext context, {
  required Future<void> Function(int) onStepChanged,
  required List<GlobalKey> targetKeys,
  required Future<void> Function() onFinished,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: false,
  barrierLabel: 'Tutorial',
  barrierColor: const Color(0x08000000),
  transitionDuration: const Duration(milliseconds: 120),
  pageBuilder: (_, _, _) => _TutorialCoachMark(
    onStepChanged: onStepChanged,
    targetKeys: targetKeys,
    onFinished: onFinished,
  ),
  transitionBuilder: (_, animation, _, child) =>
      FadeTransition(opacity: animation, child: child),
);

class _TutorialCoachMark extends StatefulWidget {
  const _TutorialCoachMark({
    required this.onStepChanged,
    required this.targetKeys,
    required this.onFinished,
  });

  final Future<void> Function(int) onStepChanged;
  final List<GlobalKey> targetKeys;
  final Future<void> Function() onFinished;

  @override
  State<_TutorialCoachMark> createState() => _TutorialCoachMarkState();
}

class _TutorialCoachMarkState extends State<_TutorialCoachMark>
    with WidgetsBindingObserver {
  int _index = 0;
  Rect? _targetRect;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTarget());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTarget());
  }

  Future<void> _measureTarget() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final targetBox =
        widget.targetKeys[_index].currentContext?.findRenderObject()
            as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (targetBox == null || overlayBox == null || !targetBox.hasSize) {
      if (_targetRect != null) setState(() => _targetRect = null);
      return;
    }
    final topLeft = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final nextRect = topLeft & targetBox.size;
    if (mounted && nextRect != _targetRect) {
      setState(() => _targetRect = nextRect);
    }
  }

  Future<void> _goToStep(int index) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _index = index;
      _targetRect = null;
    });
    await widget.onStepChanged(index);
    await _measureTarget();
    if (mounted) setState(() => _isBusy = false);
  }

  Future<void> _finish() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    await widget.onFinished();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_index];
    final screenSize = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);
    final targetRect = _targetRect == null
        ? null
        : _inflateAndClamp(_targetRect!, screenSize);
    final cardAtTop =
        targetRect != null && targetRect.center.dy > screenSize.height * 0.5;

    return PopScope(
      canPop: false,
      child: Material(
        key: const Key('tutorial-dialog'),
        type: MaterialType.transparency,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ModalBarrier(
                dismissible: false,
                color: Colors.transparent,
              ),
            ),
            if (targetRect != null)
              Positioned.fromRect(
                rect: targetRect,
                child: IgnorePointer(
                  child: Container(
                    key: Key('tutorial-highlight-step-$_index'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              top: cardAtTop ? safePadding.top + 12 : null,
              bottom: cardAtTop ? null : safePadding.bottom + 20,
              child: Align(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 520,
                    maxHeight: screenSize.height * 0.4,
                  ),
                  child: Material(
                    key: const Key('tutorial-card'),
                    color: AppColors.surface,
                    elevation: 6,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(step.icon, color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          step.title,
                                          key: const Key('tutorial-title'),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ),
                                      TextButton(
                                        key: const Key('tutorial-skip'),
                                        onPressed: _isBusy ? null : _finish,
                                        child: const Text('Atla'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(step.body),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Semantics(
                                label:
                                    'Tutorial adımı ${_index + 1} / ${_steps.length}',
                                child: Text(
                                  '${_index + 1} / ${_steps.length}',
                                  key: const Key('tutorial-progress'),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              const Spacer(),
                              if (_index > 0)
                                TextButton(
                                  key: const Key('tutorial-back'),
                                  onPressed: _isBusy
                                      ? null
                                      : () => _goToStep(_index - 1),
                                  child: const Text('Geri'),
                                ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 88,
                                child: ElevatedButton(
                                  key: Key(
                                    _index == _steps.length - 1
                                        ? 'tutorial-start'
                                        : 'tutorial-next',
                                  ),
                                  onPressed: _isBusy
                                      ? null
                                      : _index == _steps.length - 1
                                      ? _finish
                                      : () => _goToStep(_index + 1),
                                  child: Text(
                                    _index == _steps.length - 1
                                        ? 'Başla'
                                        : 'İleri',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Rect _inflateAndClamp(Rect rect, Size screenSize) {
  final inflated = rect.inflate(10);
  return Rect.fromLTRB(
    inflated.left.clamp(4.0, screenSize.width - 4),
    inflated.top.clamp(4.0, screenSize.height - 4),
    inflated.right.clamp(4.0, screenSize.width - 4),
    inflated.bottom.clamp(4.0, screenSize.height - 4),
  );
}
