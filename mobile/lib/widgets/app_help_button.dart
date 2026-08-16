import 'package:flutter/material.dart';

class AppHelpButton extends StatelessWidget {
  const AppHelpButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('tutorial-help-button'),
    tooltip: 'Yardım',
    onPressed: onPressed,
    icon: const Icon(Icons.help_outline),
  );
}
