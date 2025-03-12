import 'package:flutter/material.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/model/subs_shared_pref.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/subscriptionManager.dart';

class SubscriptionDialog extends StatefulWidget {
  final SubscriptionManager subscriptionManager;

  const SubscriptionDialog({
    Key? key,
    required this.subscriptionManager,
  }) : super(key: key);

  @override
  State<SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<SubscriptionDialog> {
  final TextEditingController subscriptionController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Subscription'),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_rounded,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Active Subscriptions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please add subscriptions to continue using the application',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: subscriptionController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Number of Subscriptions',
                border: const OutlineInputBorder(),
                hintText: 'Enter number between 1 and ${widget.subscriptionManager.maxAddLimit}',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  if (subscriptionController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter subscription amount')),
                    );
                    return;
                  }

                  int? amount = int.tryParse(subscriptionController.text);
                  if (amount == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid number')),
                    );
                    return;
                  }

                  if (amount <= 0 || amount > widget.subscriptionManager.maxAddLimit) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please enter a number between 1 and ${widget.subscriptionManager.maxAddLimit}'
                        ),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    isLoading = true;
                  });

                  try {
                    String? userId = await PreferencesHelper.getUserId();
                    if (userId == null) {
                      throw Exception('User ID not found');
                    }

                    final result = await widget.subscriptionManager.addSubscriptions(amount);
                    
                    if (result == true) {
                      await SubscriptionSharedPref.saveSubscription(userId, amount);
                      subscriptionController.clear();
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Subscriptions added successfully')),
                        );
                        Navigator.of(context).pop(); // Close the dialog
                      }
                      
                      widget.subscriptionManager.notifyListeners();
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to add subscriptions')),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  } finally {
                    setState(() {
                      isLoading = false;
                    });
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add Subscriptions'),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    subscriptionController.dispose();
    super.dispose();
  }
}