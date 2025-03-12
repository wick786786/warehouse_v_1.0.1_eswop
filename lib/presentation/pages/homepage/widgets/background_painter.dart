import 'package:flutter/material.dart';

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple.shade100.withOpacity(0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Create geometric patterns
    final path = Path();
    final spacing = 30.0;
    
    for (double i = 0; i < size.width + size.height; i += spacing) {
      path.moveTo(0, i);
      path.lineTo(i, 0);
    }

    // Draw circles
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(
          size.width * (0.2 + i * 0.15),
          size.height * (0.3 + (i % 2) * 0.2),
        ),
        50 + i * 20,
        paint,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}