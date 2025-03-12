import 'package:flutter/material.dart';

class ErrorWidgetView extends StatelessWidget {
  final String adbError;

  const ErrorWidgetView({super.key, required this.adbError});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, color: theme.colorScheme.error, size: 60),
        const SizedBox(height: 20),
        Text(
          adbError,
          style: TextStyle(color: theme.colorScheme.error, fontSize: 16),
        ),
      ],
    );
  }
}
