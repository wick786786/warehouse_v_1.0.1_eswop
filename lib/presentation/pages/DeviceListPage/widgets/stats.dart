import 'package:flutter/material.dart';

class StatsCard extends StatefulWidget {
  final String title;
  final String color;
  final String devices;

  const StatsCard({
    required this.title,
    required this.color,
    required this.devices,
    super.key,
  });

  @override
  _StatsCardState createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    switch (widget.color.toLowerCase()) {
      case 'red':
        cardColor = const Color(0xFFff7452);
        break;
      case 'yellow':
        cardColor = const Color(0xff2684ff);
        break;
      case 'blue':
        cardColor = const Color(0xff57d9a3);
        break;
      case 'green':
      default:
        cardColor = const Color(0XFFffc400);
        break;
    }

    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(_isHovered ? 0.9 : 1.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 4,
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.smartphone, color: Colors.white, size: 30),
                  const SizedBox(height: 6),
                  Text(
                    widget.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.devices,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
