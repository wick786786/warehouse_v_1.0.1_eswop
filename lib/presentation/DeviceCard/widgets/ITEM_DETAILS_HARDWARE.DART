class DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const DetailItem({
    Key? key,
    required this.label,
    required this.value,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label section
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.0,
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              // Value section
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14.0,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            height: 1,
          ),
      ],
    );
  }
}