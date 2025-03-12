import 'package:flutter/material.dart';

class EmptyDeviceCard extends StatelessWidget {
  const EmptyDeviceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 6,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: Icon(
            Icons.usb,
            size: 50.0,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
