import 'package:flutter/material.dart';

class NumberCircle extends StatelessWidget {
  final int number;
  final double size;
  final Color color;
  final Color textColor;

  const NumberCircle({
    super.key,
    required this.number,
    this.size = 30.0,
    this.color = Colors.blue,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString(),
        style: TextStyle(
          color: textColor,
          fontSize: size * 0.4, // Font size relative to the circle size
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
