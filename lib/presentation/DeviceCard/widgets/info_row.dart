import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.max, // Ensures the row takes full width
        children: [
          Expanded( // Use Expanded to allow the text to wrap
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded( // Wrap value in Expanded
            child: Text(
              value,
              softWrap: true, // Allow soft wrap
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 16,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
