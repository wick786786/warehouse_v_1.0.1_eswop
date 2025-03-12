import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/model/subs_shared_pref.dart';
//import 'package:newrelic_mobile/newrelic_mobile.dart';
import 'package:http/http.dart' as http;
import 'package:warehouse_phase_1/service_class/current_internet_status.dart';
class SubscriptionManager extends ChangeNotifier {
  int _currentSubscriptions = 0;
  int _maxAddLimit = 1000;
   InternetStatusChecker internetStatus = InternetStatusChecker();
  SubscriptionManager() {
    _loadInitialSubscriptionCount();
  }

  int get currentSubscriptions => _currentSubscriptions;
  int get maxAddLimit => _maxAddLimit;

  Future<void> _loadInitialSubscriptionCount() async {
    String? userId = await PreferencesHelper.getUserId();
    int? savedCount = await SubscriptionSharedPref.getSubscription(userId);
    if (savedCount != null) {
      _currentSubscriptions = savedCount;
      notifyListeners();
    }
  }
 Future<Map<String, dynamic>> AddSubscription(int scount) async {
    if (!await internetStatus.checkInternetStatus()) {
      return {
        'success': false,
        'message': 'Please connect to internet before adding license'
      };
    }

    String? userId = await PreferencesHelper.getUserId();
    print('Sending request for user: $userId'); // Debug log
    
    final url = Uri.parse('https://getinstacash.in/warehouse/v1/public/requestSubscription');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'userName': 'whtest',
          'apiKey': '202cb962ac59075b964b07152d234b70',
          'userId': userId,
          'sCount': scount.toString(),
        },
      );

      print('Response status code: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': responseData['status'].toString().toLowerCase() == 'true',
          'message': responseData['msg'] ?? 'Success'
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Network error: $e'); // Debug log
      return {
        'success': false,
        'message': 'Network error occurred: $e'
      };
    }
  }


     Future<bool> addSubscriptions(int count) async {
    if (count <= 0 || count > _maxAddLimit || _currentSubscriptions + count > _maxAddLimit) {
      return false;
    }

    // Check subscription status first
    final subscriptionResponse = await AddSubscription(count);
    print('API Response: $subscriptionResponse'); // Debug log
    
    if (!subscriptionResponse['success']) {
      print('Failed with message: ${subscriptionResponse['message']}'); // Debug log
      return false;
    }

    try {
      // If successful, proceed with adding subscriptions
      String? userId = await PreferencesHelper.getUserId();
      int newCount = _currentSubscriptions + count;
      await SubscriptionSharedPref.saveSubscription(userId ?? 'n/a', newCount);
      _currentSubscriptions = newCount;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating local subscription: $e'); // Debug log
      return false;
    }
  }
  Future<void> removeSubscriptions(int count) async {
    if (count <= 0 || count > _currentSubscriptions) {
      throw Exception('Invalid subscription count');
    }
    String? userId = await PreferencesHelper.getUserId();
    int newCount = _currentSubscriptions - count;
    await SubscriptionSharedPref.saveSubscription(userId ?? 'n/a', newCount);
    _currentSubscriptions = newCount;
    notifyListeners();
  }

  Future<void> resetSubscriptions() async {
    String? userId = await PreferencesHelper.getUserId();
    await SubscriptionSharedPref.saveSubscription(userId ?? 'n/a', 0);
    _currentSubscriptions = 0;
    notifyListeners();
  }

  Future<void> useSubscription() async {
    if (_currentSubscriptions > 0) {
      await removeSubscriptions(1);
    } else {
      throw Exception('No subscriptions available');
    }
  }
}
Future<String> releaseSubscription(int scount) async {
  String? userId = await PreferencesHelper.getUserId();
  final url = Uri.parse('https://getinstacash.in/warehouse/v1/public/releaseSubscription');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'userName': 'whtest',
      'apiKey': '202cb962ac59075b964b07152d234b70',
      'userId': userId,
      'scount': scount,
    },
  );

  if (response.statusCode == 200) {
    // Decode the response body
    final responseData = json.decode(response.body);
    print('Status: ${responseData['status']}');
    print('Timestamp: ${responseData['timeStamp']}');
    print('Message: ${responseData['msg']}');
    
    return responseData['status'];

  } else {
    print('Failed to send request. Status code: ${response.statusCode}');
    return 'error';
  }
}


class SubscriptionManagerWidget extends StatelessWidget {
  final SubscriptionManager subscriptionManager;

  const SubscriptionManagerWidget({Key? key, required this.subscriptionManager}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showSubscriptionDialog(context),
      child: Text('Manage Licenses'),
    );
  }

  void _showSubscriptionDialog(BuildContext context) {
    final TextEditingController licenseController = TextEditingController();
    bool isAddMode = true;
    String errorMessage = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void clearError() {
              setState(() {
                errorMessage = '';
              });
            }

            void validateAndSubmit() async {
              String input = licenseController.text.trim();
              if (input.isEmpty) {
                setState(() {
                  errorMessage = 'Please enter a number';
                });
                return;
              }

              int? number = int.tryParse(input);
              if (number == null) {
                setState(() {
                  errorMessage = 'Please enter a valid number';
                });
                return;
              }

              if (number <= 0) {
                setState(() {
                  errorMessage = 'Please enter a positive number';
                });
                return;
              }

              try {
                if (isAddMode) {
                  await subscriptionManager.addSubscriptions(number);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully added $number license(s)')),
                  );
                } else {
                  
                  await subscriptionManager.removeSubscriptions(number);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully released $number license(s)')),
                  );
                   Navigator.of(context).pop();
                
                
                }
               
              } catch (e) {
                setState(() {
                  errorMessage = e.toString();
                });
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
              child: Container(
                width: 400,
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'License Management',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                    Divider(height: 24),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.key, size: 16, color: Colors.grey[600]),
                          SizedBox(width: 8),
                          Text(
                            'Current Licenses: ${subscriptionManager.currentSubscriptions}',
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  isAddMode = true;
                                  clearError();
                                  licenseController.clear();
                                });
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: isAddMode ? Colors.blue.withOpacity(0.1) : null,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Add License',
                                style: TextStyle(
                                  color: isAddMode ? Colors.blue : Colors.grey[600],
                                  fontWeight: isAddMode ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          VerticalDivider(width: 1, thickness: 1),
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  isAddMode = false;
                                  clearError();
                                  licenseController.clear();
                                });
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: !isAddMode ? Colors.blue.withOpacity(0.1) : null,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Release License',
                                style: TextStyle(
                                  color: !isAddMode ? Colors.blue : Colors.grey[600],
                                  fontWeight: !isAddMode ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: licenseController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isAddMode ? 'Number of Licenses to Add' : 'Number of Licenses to Release',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                        errorText: errorMessage.isNotEmpty ? errorMessage : null,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (value) => clearError(),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                          child: Text('Cancel'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: validateAndSubmit,
                          style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                          child: Text(isAddMode ? 'Add' : 'Release'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) => licenseController.dispose());
  }
}