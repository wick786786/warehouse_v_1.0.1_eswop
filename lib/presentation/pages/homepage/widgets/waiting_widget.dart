import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class WaitingWidget extends StatelessWidget {
  const WaitingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LoadingAnimationWidget.threeArchedCircle(
          color: theme.colorScheme.primary,
          size: 60,
        ),
        const SizedBox(height: 20),
        Text(
          'waiting for the device to be connected ',
          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
        ),
      ],
    );
  }
}