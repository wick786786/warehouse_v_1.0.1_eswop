import 'package:flutter/material.dart';

class MdmStatus extends StatelessWidget {
  const MdmStatus({super.key, required this.status});
  final String? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      child: status == "true"
          ?  Icon(Icons.lock_open,color:theme.colorScheme.primary,)
          : const Icon(Icons.lock_open,color:Colors.red), // Fixed the icon here
    );
  }
}
