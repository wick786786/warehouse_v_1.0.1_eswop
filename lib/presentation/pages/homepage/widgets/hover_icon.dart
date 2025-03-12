import 'package:flutter/material.dart';

class HoverIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Widget? child;

  const HoverIcon({super.key, required this.icon, this.onPressed, this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (event) => {},
        onExit: (event) => {},
        child: child ?? Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}