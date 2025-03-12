

import 'package:flutter/material.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/model/subs_shared_pref.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/subscriptionManager.dart';
import 'package:warehouse_phase_1/presentation/pages/login_page.dart';

class SubscriptionScreen extends StatefulWidget {
  final SubscriptionManager subscriptionManager;

  const SubscriptionScreen({
    Key? key,
    required this.subscriptionManager,
  }) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final TextEditingController subscriptionController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Subscription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await PreferencesHelper.clearSession();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_rounded,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Active Subscriptions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please add subscriptions to continue using the application',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
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
                            // Get current userId
                            String? userId = await PreferencesHelper.getUserId();
                            if (userId == null) {
                              throw Exception('User ID not found');
                            }

                            final result = await widget.subscriptionManager.addSubscriptions(amount);
                            
                            if (result == true) {
                              // Update the local subscription count
                              await SubscriptionSharedPref.saveSubscription(userId, amount);
                              
                              // Clear the input
                              subscriptionController.clear();
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('added' ?? 'Subscriptions added successfully')),
                                );
                              }
                              
                              // Notify listeners of the change
                              widget.subscriptionManager.notifyListeners();
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('failed' ?? 'Failed to add subscriptions')),
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
                    padding: const EdgeInsets.all(16),
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Add Subscriptions'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 

  @override
  void dispose() {
    subscriptionController.dispose();
    super.dispose();
  }
}