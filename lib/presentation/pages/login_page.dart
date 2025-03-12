import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:warehouse_phase_1/GlobalVariables/singelton_class.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart';

import 'package:warehouse_phase_1/presentation/pages/homepage/home_page.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/model/subs_shared_pref.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/subscriptionManager.dart';
import 'package:warehouse_phase_1/service_class/connectivity_check.dart';
import 'package:warehouse_phase_1/service_class/current_internet_status.dart';
import 'package:warehouse_phase_1/src/helpers/sql_helper.dart';

class LoginPage extends StatefulWidget {
  final String? title;
  final Function(Locale)? onLocaleChange;
  final VoidCallback? onThemeToggle;
  const LoginPage(
      {super.key, this.title, this.onLocaleChange, this.onThemeToggle});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Variables to store input values
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController subscriptionController = TextEditingController();
  String emptySubscription = ''; // Add this line
  String emptyusername = "";
  String emptypassword = "";
  String successLogin = "";
  String failureLogin = "";
  Locale _locale = const Locale('en', 'US');
  bool _isDarkMode = false;
  // String userId="";
  final connectivityService = ConnectivityService();
  InternetStatusChecker internetStatusChecker = InternetStatusChecker();
  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  // Utility function to show a "No Internet" dialog
  void showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("No Internet Connection"),
          content: Text("Please connect to the internet to continue."),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

// Utility function to show an error dialog
  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
Future<void> loginfun(BuildContext context, String username, String password,
    String subscription) async {
  setState(() {
    // Reset error messages
    emptyusername = "";
    emptypassword = "";
    emptySubscription = "";
    failureLogin = "";
  });

  // Check for empty fields
  if (username.isEmpty) {
    setState(() {
      emptyusername = "Please enter username";
    });
  }

  if (password.isEmpty) {
    setState(() {
      emptypassword = "Please enter password";
    });
  }

  if (subscription.isEmpty) {
    setState(() {
      emptySubscription = "Please enter subscription count";
    });
  }

  // Proceed only if all fields are filled
  if (username.isNotEmpty && password.isNotEmpty) {
    try {
      // Show the loading dialog
      showLoadingDialog(context);

      bool isConnected = await internetStatusChecker.checkInternetStatus();
      if (!isConnected) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('No Internet Connection'),
              content: Text(
                  'Please check your internet connection and try again.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        return;
      }

      final Uri loginUrl = Uri.parse(
          'https://getinstacash.in/warehouse/v1/public/login');

      final Map<String, String> loginRequestBody = {
        'userName': 'whtest',
        'apiKey': '202cb962ac59075b964b07152d234b70',
        'loginUserName': username,
        'loginPassword': password,
      };

      final String loginEncodedBody = loginRequestBody.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final http.Response loginResponse = await http
          .post(
            loginUrl,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: loginEncodedBody,
          )
          .timeout(const Duration(seconds: 15));

      // Dismiss the loading dialog before showing any other dialogs
      Navigator.of(context).pop(); // Remove loading dialog

      if (loginResponse.statusCode == 200) {
        var loginData = jsonDecode(loginResponse.body);

        if (loginData['status'] == true) {
          String userId = loginData['userId'];
          
          // Get current subscription count
          final subscriptionManager = SubscriptionManager();

          //----------get subscription from api---------------------
          int? currentSubs = await SubscriptionSharedPref.getSubscription(userId) ?? 0;
          print('current subs after login $currentSubs');
          
          print('before saving loginsession $userId');
          await PreferencesHelper.saveLoginSession(userId);
          //await   SqlHelper.deleteAllItems();
          print('after saving loginsession $userId');
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MyHomePage(
                title: 'Warehouse Application',
                onThemeToggle: _toggleTheme,
              ),
            ),
          );
        } else {
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Login Failed'),
                content: Text('Incorrect username or password.'),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
          setState(() {
            failureLogin = "Login failed. Incorrect username or password.";
          });
        }
      } else {
        setState(() {
          failureLogin = "Login failed. Please try again.";
        });
      }
    } catch (e) {
      // Dismiss the loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      setState(() {
        failureLogin = "An error occurred. Please try again.";
      });
    }
  }
}

  @override
  void dispose() {
    // Dispose of controllers when no longer needed
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Transparent background
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(), // Loading indicator
                const SizedBox(height: 10),
                const Text(
                  "Logging in...",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primaryColor = theme.colorScheme.primary;
    final Color onPrimaryColor = theme.colorScheme.onPrimary;

    return Scaffold(
      body: Stack(
        children: [
          // Background image with color filter
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/background_4.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.primary.withOpacity(0.6),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          // Overlay
          Container(
            color: theme.colorScheme.surface.withOpacity(0.8),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: "Phone Diagnostic made ",
                              style: TextStyle(
                                fontFamily:
                                    'Poppins, "Segoe UI", Tahoma, Geneva, Verdana, sans-serif',
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                fontSize: 72,
                                height: 1,
                              ),
                            ),
                            TextSpan(
                              text: "faster.",
                              style: TextStyle(
                                fontFamily:
                                    'Poppins, "Segoe UI", Tahoma, Geneva, Verdana, sans-serif',
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8A2BE2),
                                fontSize: 72,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                        width: 400,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 4,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 60,
                              color: primaryColor,
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: usernameController,
                              decoration: InputDecoration(
                                prefixIcon:
                                    Icon(Icons.person, color: primaryColor),
                                labelText: 'Username',
                                labelStyle: TextStyle(
                                    color: theme.colorScheme.onSurface),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            if (emptyusername.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  emptyusername,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                prefixIcon:
                                    Icon(Icons.lock, color: primaryColor),
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                    color: theme.colorScheme.onSurface),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            if (emptypassword.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  emptypassword,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            const SizedBox(height: 20),
                            // New subscription TextField
                            // TextField(
                            //   controller: subscriptionController,
                            //   keyboardType: TextInputType.number,
                            //   decoration: InputDecoration(
                            //     prefixIcon: Icon(Icons.subscriptions, color: primaryColor),
                            //     labelText: 'Subscription Count',
                            //     labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                            //     border: OutlineInputBorder(
                            //       borderRadius: BorderRadius.circular(10),
                            //     ),
                            //   ),
                            // ),
                            // if (emptySubscription.isNotEmpty)
                            //   Padding(
                            //     padding: const EdgeInsets.only(top: 5),
                            //     child: Text(
                            //       emptySubscription,
                            //       style: const TextStyle(color: Colors.red),
                            //     ),
                            //   ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                loginfun(
                                    context,
                                    usernameController.text,
                                    passwordController.text,
                                    subscriptionController.text);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 50, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: onPrimaryColor,
                                ),
                              ),
                            ),
                            if (failureLogin.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  failureLogin,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 16),
                                ),
                              ),
                          ],
                        )),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
