import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart';
import 'package:warehouse_phase_1/presentation/pages/guidelines/AndroidHelp.dart';
import 'package:warehouse_phase_1/presentation/pages/guidelines/help.dart';
import 'package:warehouse_phase_1/presentation/pages/guidelines/ios_help.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/manual_entry.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/wifi_QR.dart';
import 'package:warehouse_phase_1/presentation/pages/login_page.dart';
import 'package:warehouse_phase_1/service_class/current_internet_status.dart';
import 'package:warehouse_phase_1/src/helpers/log_cat.dart';
import 'package:warehouse_phase_1/src/helpers/sql_helper.dart';
import '../../DeviceListPage/device_list_page.dart';

class SideNavigation extends StatefulWidget {
  const SideNavigation({super.key});

  @override
  _SideNavigationState createState() => _SideNavigationState();
}

class _SideNavigationState extends State<SideNavigation> {
  bool _isHoveringCompleted = false;
  bool _isHoveringIOSHelp = false;
  bool _isHoveringHelp = false;
  bool _isHoveringLogout = false;
  bool _isHoveringDiagnosticQR = false; // New hover state for Diagnostic App QR
  bool _isHoveringWifiQR = false;
  bool _isHoveringManualQC = false;
  InternetStatusChecker internetStatus = InternetStatusChecker();
  PreferencesHelper pref = PreferencesHelper();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color sidebarColor = theme.colorScheme.secondary;

    return Drawer(
      backgroundColor: sidebarColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  icon: Icons.check_circle,
                  text: "Completed",
                  isHovering: _isHoveringCompleted,
                  onEnter: () => setState(() => _isHoveringCompleted = true),
                  onExit: () => setState(() => _isHoveringCompleted = false),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DeviceListPage()),
                    );
                  },
                ),
                const SizedBox(height: 28),
                 _buildNavItem(
                  icon: Icons.build,
                  text: "Manual QC",
                  isHovering: _isHoveringManualQC,
                  onEnter: () => setState(() => _isHoveringManualQC = true),
                  onExit: () => setState(() => _isHoveringManualQC = false),
                  onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => DiagnosticForm(),
                  );
                  },
                ),
                const SizedBox(height: 28),
                _buildNavItem(
                  icon: Icons.qr_code,
                  text: "Diagnostic App QR",
                  isHovering: _isHoveringDiagnosticQR,
                  onEnter: () => setState(() => _isHoveringDiagnosticQR = true),
                  onExit: () => setState(() => _isHoveringDiagnosticQR = false),
                  onTap: () {
                    _showDiagnosticQRDialog(context);
                  },
                ),
                const SizedBox(height: 28),
                _buildNavItem(
                  icon: Icons.apple,
                  text: "iOS Help",
                  isHovering: _isHoveringIOSHelp,
                  onEnter: () => setState(() => _isHoveringIOSHelp = true),
                  onExit: () => setState(() => _isHoveringIOSHelp = false),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const IosHelp(),
                    );
                  },
                ),
                const SizedBox(height: 28),
                _buildNavItem(
                  icon: Icons.android,
                  text: "Android Help",
                  isHovering: _isHoveringHelp,
                  onEnter: () => setState(() => _isHoveringHelp = true),
                  onExit: () => setState(() => _isHoveringHelp = false),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AndroidHelp(),
                    );
                  },
                ),
                const SizedBox(height: 28),

                /// The above Dart code snippet is defining a method `_buildNavItem` that creates a
                /// navigation item with an icon, text, and functionality for handling hover, tap, and
                /// exit events.
                _buildNavItem(
                  icon: Icons.qr_code,
                  text: "Wifi QR",
                  isHovering: _isHoveringWifiQR,
                  onEnter: () => setState(() => _isHoveringWifiQR = true),
                  onExit: () => setState(() => _isHoveringWifiQR = false),
                  onTap: () {
                    _showWifiQRDialog(context);
                  },
                ),
                  const SizedBox(height: 28),
                  //manual QC
                // _buildNavItem(
                //   icon: Icons.build,
                //   text: "Manual QC",
                //   isHovering: _isHoveringManualQC,
                //   onEnter: () => setState(() => _isHoveringManualQC = true),
                //   onExit: () => setState(() => _isHoveringManualQC = false),
                //   onTap: () {
                //   showDialog(
                //     context: context,
                //     builder: (context) => DiagnosticForm(),
                //   );
                //   },
                // ),
                // const SizedBox(height: 28),
                _buildNavItem(
                  icon: Icons.logout,
                  text: "Logout",
                  isHovering: _isHoveringLogout,
                  onEnter: () => setState(() => _isHoveringLogout = true),
                  onExit: () => setState(() => _isHoveringLogout = false),
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Center(
        child: Column(
          children: const [
            Icon(
              Icons.person,
              color: Colors.white,
              size: 50,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String text,
    required bool isHovering,
    required Function() onEnter,
    required Function() onExit,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      onHover: (hovering) {
        if (hovering) {
          onEnter();
        } else {
          onExit();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isHovering
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isHovering
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSecondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                children: [
                  Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isHovering
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDiagnosticQRDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DefaultTabController(
          length: 2,
          initialIndex: 0, // iOS tab selected by default
          child: Builder(
            builder: (BuildContext newContext) {
              return AlertDialog(
                title: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Diagnostic App QR Code'),
                    SizedBox(height: 16),
                    TabBar(
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.apple),
                              SizedBox(width: 8),
                              Text('iOS'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.android),
                              SizedBox(width: 8),
                              Text('Android'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 300,
                  height: 300,
                  child: TabBarView(
                    children: [
                      // iOS QR Code with credentials displayed as text
                      Column(
                        children: [
                          Image.asset(
                            'assets/ios_QR.png',
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: const [
                              Icon(Icons.email, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Apple ID: tester28022000@gmail.com',
                                  style: TextStyle(
                                    fontSize: 15,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: const [
                              Icon(Icons.lock, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Password: Warehouse@123',
                                  style: TextStyle(
                                    fontSize: 15,
                                  )),
                            ],
                          ),
                        ],
                      ),
                      // Android QR Code (unchanged)
                      Image.asset(
                        'assets/app_Qr.png',
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Download'),
                    onPressed: () {
                      final tabIndex =
                          DefaultTabController.of(newContext).index;
                      if (tabIndex == 0) {
                        _downloadQR(context, 'ios');
                      } else if (tabIndex == 1) {
                        _downloadQR(context, 'android');
                      }
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _downloadQR(BuildContext context, String platform) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      String filePath;
      String assetPath;

      if (platform == 'ios') {
        filePath = '${directory.path}/ios_QR.png';
        assetPath = 'assets/ios_QR.png';
      } else {
        filePath = '${directory.path}/app_Qr.png';
        assetPath = 'assets/app_Qr.png';
      }

      // Simulate a download by copying the asset to the file path
      final byteData = await rootBundle.load(assetPath);
      final buffer = byteData.buffer;
      await File(filePath).writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );

      // Show success notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('$platform QR code downloaded successfully to $filePath'),
          backgroundColor: Colors.green,
        ),
      );

      print('$platform QR code downloaded to $filePath');
    } catch (e) {
      // Show error notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download $platform QR code: $e')),
      );
    }
  }

  void _showWifiQRDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Wifi QR Code'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: Card(
              // margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: WifiQRGenerator(
                  size: 100.0,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Method to show the logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () async {
                bool isConnected = await internetStatus
                    .checkInternetStatus(); // Check internet status

                if (isConnected) {
                  // Show a dialog with a circular progress indicator
                  showDialog(
                    context: context,
                    barrierDismissible:
                        false, // Prevent the dialog from being closed
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Syncing Devices'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const <Widget>[
                            CircularProgressIndicator(),
                            SizedBox(height: 20),
                            Text('Please wait while we sync all devices...'),
                          ],
                        ),
                      );
                    },
                  );

                  // Check for unsynced devices every 2 seconds
                  Timer.periodic(const Duration(seconds: 2), (timer) async {
                    // Query for unsynced devices
                    // await SqlHelper.deleteAllItems();
                    List<Map<String, dynamic>> unSyncedDevices =
                        await SqlHelper.getUnsyncedItems();

                    if (unSyncedDevices.isEmpty) {
                      // All devices are synced, close the dialog and log out
                      await LogCat.deleteAllJsonFiles();
                      await SqlHelper.deleteAllItems();
                      Navigator.of(context).pop(); // Close the syncing dialog
                      timer.cancel(); // Stop the timer

                      // Navigate to the LoginPage
                      Navigator.of(context)
                          .pop(); // Close the logout confirmation dialog

                      //clear the session
                      await PreferencesHelper.clearSession();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    } else {
                      // You can print or log the number of remaining unsynced devices for debugging
                      print(
                          'Unsynced devices remaining: ${unSyncedDevices.length}');
                    }
                  });
                } else {
                  // Show a pop-up indicating no internet connection
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('No Internet'),
                        content: const Text(
                            'Please make sure you are connected to the internet!'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('OK'),
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
//   void _showLogoutDialog(BuildContext context) {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: const Text('Logout'),
//         content: const Text('Are you sure you want to logout?'),
//         actions: <Widget>[
//           TextButton(
//             child: const Text('No'),
//             onPressed: () {
//               Navigator.of(context).pop(); // Close the dialog
//             },
//           ),
//           TextButton(
//             child: const Text('Yes'),
//             onPressed: () async {
//               // Clear the session
//              // await PreferencesHelper.clearSession();

//               // Close the logout confirmation dialog
//               Navigator.of(context).pop();

//               // Navigate to the LoginPage
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const LoginPage(),
//                 ),
//               );
//             },
//           ),
//         ],
//       );
//     },
//   );
// }
}
