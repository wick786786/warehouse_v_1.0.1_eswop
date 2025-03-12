import 'package:flutter/material.dart';

class UnderProcess extends StatefulWidget {
  const UnderProcess({super.key});

  @override
  State<UnderProcess> createState() => _UnderProcessState();
}

class _UnderProcessState extends State<UnderProcess> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          )
          ),
      body:const Center(child: Text('This page is under process please visit after sometime'),)
    );
  }
}