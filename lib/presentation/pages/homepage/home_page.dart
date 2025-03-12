import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:warehouse_phase_1/GlobalVariables/singelton_class.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/icard/saveresultIphone.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/model/globels.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/widgets/mdm_status.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/model/subs_shared_pref.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/webcam/webcam_home.dart';
import 'package:http/http.dart' as http;
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/background_painter.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/device_event.dart';
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/device_list_widget.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/device_manage.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/error_widget.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/hover_icon.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/ios_tracking.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/saveresults.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/subs_screen.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/subscriptionManager.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/subscription_dialog.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/waiting_widget.dart';
import 'package:warehouse_phase_1/presentation/pages/homepage/widgets/wifi_QR.dart';
import 'package:warehouse_phase_1/service_class/connectivity_check.dart';
import 'package:warehouse_phase_1/service_class/current_internet_status.dart';
import 'package:warehouse_phase_1/src/helpers/api_services.dart';
import 'package:warehouse_phase_1/src/helpers/ilogcat.dart';
import 'package:warehouse_phase_1/src/helpers/log_cat.dart';
import 'package:warehouse_phase_1/src/helpers/sql_helper.dart';
import 'package:window_manager/window_manager.dart';
import '../../../src/helpers/adb_client.dart';

import '../../../src/helpers/iphone_device_info.dart';
import 'widgets/side_navigation.dart';

import '../../../src/helpers/launch_app.dart';
//import 'package:clipboard/clipboard.dart';
import '../drop_down.dart';
 // Import the global variable

class MyHomePage extends StatefulWidget {
  final String title;
  // final Function(Locale) onLocaleChange;
  final VoidCallback onThemeToggle;
  // final userId;

  const MyHomePage(
      {super.key,
      required this.title,
      // required this.userId,
      //  required this.onLocaleChange,
      required this.onThemeToggle});

  @override
  _MyHomePageState createState() => _MyHomePageState();
   // Add this method to get the state instance
  static _MyHomePageState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyHomePageState>();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final AdbClient adbClient = AdbClient();

  int subscriptionCount = 0;
  bool addLicenseSelected = true;
  TextEditingController licenseController = TextEditingController();
  //int subscriptionCount = 0;
  Map<String?, double> deviceProgress = {};
  Map<String?, int> blacklist = {};
  Map<String, Map<String, String>> connectedDevices = {}; // Updated to Map
  Set<String> deviceSet = {};
  final LaunchApp launch =  LaunchApp();
  StreamSubscription<Process>? adbStream;
  String adbError = '';
  bool previouslyDiagnosed = false;
  Map<String, StreamSubscription<int>> progressSubscriptions =
      {}; // To store subscriptions per device
  Map<String, bool> resultsSaved = {}; // Track if results are saved per device
  String? connectedIp;
  String? connectedPort;
  Set<String> blacklistCheckedDevices =
      {}; // Tracks devices that have been checked for blacklist
  int currentSubscriptions = 0;

  final SubscriptionManager subscriptionManager = SubscriptionManager();
  // Keep track of devices that are currently being synced
  final Map<String, bool> _currentlySyncing = {};

  //variables for ios
  final iosUtils = IOSDeviceUtils();
   //connectedIosDevices = {};
  // Add these class-level variables
  Map<String, bool> deviceAppInstallStatus =
      {}; // Track app installation status per device
  Map<String, bool> deviceAppLaunchStatus =
      {}; // Track app launch status per device

  // Add these variables for iOS tracking
  Timer? _iosDeviceTimer;
  Set<String> previousIosDevices = {};
  final Map<String, DateTime> _lastSeenDevices = {};
  ApiServices apiServices = ApiServices();
  static const Duration deviceTimeout = Duration(seconds: 5);
  @override
  @override
  void initState() {
    super.initState();
    _loadInitialSubscriptionCount();
    asyncFunction();
    _startIOSDeviceTracking(); // Add this line
    fetch_physicalQuestion(); // Add this line
    fetch_profile_tests();
  }

  Future<void> fetch_physicalQuestion() async {
    try {
      await apiServices.fetchPhysicalQuestion();
    } catch (e) {
      print('Error fetching physical question: $e');
    }
  }

  Future<void> fetch_profile_tests() async {
    try {
      await apiServices.fetchTestProfiles();
      String? testProfile = GlobalUser().testProfile;
     // FlutterClipboard.copy('Hello, World!');
      print('testProfile in home page $testProfile');
      fetch_profile_length();
    } catch (e) {
      print('Error fetching physical question: $e');
    }
  }

  void fetch_profile_length() async {
    try {
      //await apiServices.fetchTestProfiles();
      String? testProfile = GlobalUser().testProfile;
      if (testProfile != null) {
        Map<String, dynamic> profileMap = jsonDecode(testProfile);
        List<dynamic> profileList = jsonDecode(profileMap['profile']);
        int profileLength = profileList.length;
        GlobalUser().progressLength = (100 / profileLength).floor();
        print('Number of tests in profile: $profileLength');
        print('progress  in profile: ${GlobalUser().progressLength}');
      }
    } catch (e) {
      print('Error fetching profile length: $e');
    }
  }

  Future<void> _loadInitialSubscriptionCount() async {
    String? userId = await PreferencesHelper.getUserId();
    int? savedCount = await SubscriptionSharedPref.getSubscription(userId);
    if (savedCount != null) {
      setState(() {
        currentSubscriptions = savedCount;
      });
    }
  }


  void _startIOSDeviceTracking() {
    // Cancel existing timer if any
    // Cancel existing timer if any
    _iosDeviceTimer?.cancel();

    // Start immediate first check
    _checkIOSDevices();

    // Set up periodic timer every 2 seconds
    _iosDeviceTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkIOSDevices();
    });
  }

  Future<void> _checkIOSDevices() async {
  if (!mounted) return;

  try {
    final currentDevices = await iosUtils.getConnectedDevices();
    final now = DateTime.now();

    // Update last seen time for current devices
    for (var id in currentDevices) {
      _lastSeenDevices[id] = now;
    }

    // Remove devices that haven't been seen for the timeout period
    _lastSeenDevices.removeWhere(
        (id, lastSeen) => now.difference(lastSeen) > deviceTimeout);

    final validDevices = _lastSeenDevices.keys.toSet();

    // Handle disconnected devices
    Set<String> disconnectedDevices = previousIosDevices.difference(validDevices);
    for (var id in disconnectedDevices) {
      setState(() {
        connectedIosDevices.remove(id);
      });
    }

    // Handle new devices
    for (var id in validDevices) {
      if (!connectedIosDevices.containsKey(id)) {
        _fetchIOSDeviceDetails(id);
      }
    }

    previousIosDevices = validDevices;
  } catch (e) {
    print('Error checking iOS devices: $e');
  }
}

Future<void> _fetchIOSDeviceDetails(String id) async {
  try {
    // Initial check
    var specs = await iosUtils.getBasicDeviceInfo(id);

    // If device details are missing, keep polling until trust is granted
    if (specs.isEmpty || specs['serialNumber'] == null) {
      print('Device $id is untrusted. Waiting for trust...');
      _waitForTrust(id);
      return;
    }

    final carrierLock = await iosUtils.isDeviceCarrierLocked(id) ? 'locked' : 'unlocked';
    specs['carrier_lock'] = carrierLock;
    specs['icloudLock'] = await iosUtils.getICloudLockStatus(id);
    specs['udid'] = id;

    if (mounted) {
      setState(() {
        connectedIosDevices[id] = specs;
      });
    }

    // Start log reading
  //  _startLogCatIphone(id, specs['serialNumber']);
  } catch (e) {
    print('Error fetching iOS device details: $e');
  }
}

void _waitForTrust(String id) async {
  int retries = 10; // Max retries before stopping (adjust as needed)
  while (retries > 0) {
    await Future.delayed(Duration(seconds: 3)); // Poll every 3 seconds

    try {
      var specs = await iosUtils.getBasicDeviceInfo(id);
      if (specs.isNotEmpty && specs['serialNumber'] != null) {
        print('Device $id is now trusted!');
        _fetchIOSDeviceDetails(id);
        return;
      }
    } catch (e) {
      print('Error while waiting for trust: $e');
    }

    retries--;
  }

  print('Trust timeout exceeded for device $id');
}
  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(' Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                SystemNavigator.pop(); // Close the app
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startAdbDaemon() async {
    try {
      // Start the ADB daemon server
      ProcessResult result = await Process.run('adb', ['start-server']);

      if (result.exitCode == 0) {
        print("ADB daemon started successfully.");
      } else {
        print("Failed to start ADB daemon: ${result.stderr}");
        if (mounted) {
          setState(() {
            adbError = 'Failed to start ADB daemon: ${result.stderr}';
          });
        }
      }
    } catch (e) {
      print("Exception while starting ADB daemon: $e");
      if (mounted) {
        setState(() {
          adbError = 'Exception while starting ADB daemon: $e';
        });
      }
    }
  }

  Future<void> asyncFunction() async {
    // await setSubscription();

    await _startAdbDaemon(); // Start the ADB daemon first
    _startTrackingDevices();
  }

  @override
  void dispose() {
    _iosDeviceTimer?.cancel();
    iosUtils.stopDeviceMonitoring();
    adbStream?.cancel();
    super.dispose();
  }

  // Function to show manual launch dialog
  void _showManualLaunchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Launch Failed'),
          content: Text(
              'The application could not be launched. Please install and launch it manually if not installed.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog on OK
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red, // Error color
      duration: Duration(seconds: 3), // Duration the SnackBar is visible
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _startTrackingDevices() async {
    Set<String> previousDeviceSet = Set.from(deviceSet);

    try {
      adbStream = Process.start('adb', ['track-devices']).asStream().listen(
        (Process process) {
          // Handle standard output
          process.stdout.transform(utf8.decoder).listen((String output) {
            _handleDeviceOutput(output, previousDeviceSet);
          });

          // Handle standard error
          process.stderr.transform(utf8.decoder).listen((String error) {
            _logAdbError('ADB Error: $error');
          });
        },
        onError: (e) {
          _logAdbError('Failed to start adb process: $e');
        },
      );
    } catch (e) {
      _logAdbError('Failed to initiate device tracking: $e');
    }
  }

  void _handleDeviceOutput(String output, Set<String> previousDeviceSet) async {
    try {
      List<String> lines = output.split('\n');
      List<String> devices = await adbClient.listDevices();
      Map<String, Map<String, String>> deviceDetailsMap = {};
      Set<String> currentDeviceSet = {};

      for (String deviceId in devices) {
        try {
          Map<String, String> details =
              await adbClient.getDeviceDetails(deviceId);
          details['id'] = deviceId;
          deviceDetailsMap[deviceId] = details;
          currentDeviceSet.add(deviceId);

          if (!deviceSet.contains(deviceId)) {
            _handleNewDevice(deviceId, details);
          }

          // Perform blacklist check in a separate microtask
         // scheduleMicrotask(() => _checkBlacklist(deviceId, details));
        } catch (deviceError) {
          _logAdbError('Error processing device $deviceId: $deviceError');
        }
      }

      _handleDisconnectedDevices(previousDeviceSet, currentDeviceSet);
      previousDeviceSet = Set.from(currentDeviceSet);

      if (mounted) {
        setState(() {
          connectedDevices = deviceDetailsMap;
          deviceSet = currentDeviceSet;
        });
      }
    } catch (e) {
      _logAdbError('Error handling device output: $e');
    }
  }

  void _handleNewDevice(String deviceId, Map<String, String> details) async {
    try {
      double savedProgress = await DeviceProgressManager.getProgress(deviceId);
      deviceProgress[deviceId] = savedProgress;

    
      _launchApplication(deviceId, details);
      
    } catch (e) {
      _logAdbError('Error handling new device $deviceId: $e');
    }
  }

  void _handleDisconnectedDevices(
      Set<String> previousDeviceSet, Set<String> currentDeviceSet) {
    try {
      Set<String> disconnectedDevices =
          previousDeviceSet.difference(currentDeviceSet);

      for (String deviceId in disconnectedDevices) {
        print("Device disconnected: $deviceId");
        LogCat.stopLogCat(deviceId);
        progressSubscriptions[deviceId]?.cancel();
        deviceSet.remove(deviceId);
        resultsSaved.remove(deviceId);
      }
    } catch (e) {
      _logAdbError('Error handling disconnected devices: $e');
    }
  }

 
void _launchApplication(String deviceId, Map<String, String> details) async {
  try {
    String packageName = 'com.getinstacash.warehouse';
    String mainActivity = 'com.getinstacash.warehouse.ui.activity.SplashActivity';

    await launch.launchApplication(deviceId, packageName, mainActivity);
    print('App launched successfully.');
    _startLogCat(deviceId);
  } catch (e) {
    _logAdbError('Error launching application on $deviceId: $e');
    _showManualLaunchDialog(context);
  }
}

  void _checkBlacklist(String deviceId, Map<String, String> details) async {
    if (blacklistCheckedDevices.contains(deviceId)) return;

    try {
      final Uri apiUrl = Uri.parse(
          'https://getinstacash.in/warehouse/v1/public/checkBlacklist');
      final Map<String, String> requestBody = {
        'userName': 'whtest',
        'apiKey': '202cb962ac59075b964b07152d234b70',
        'IMEINumber': details['imeiOutput'] ?? 'N/A',
      };

      final String encodedBody = requestBody.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final http.Response response = await http.post(
        apiUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: encodedBody,
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        if (responseData['status'] == true) {
          blacklistCheckedDevices.add(deviceId);
          blacklist[details['id']] = responseData['isBlacklist'];
          if (responseData['isBlacklist'] == 1) {
            Map<String, dynamic>? Presentdevice =
                await SqlHelper.getItemDetails(deviceId);
            if (Presentdevice == null) {
              await saveResults(deviceId);
            }
          }
        } else {
          print('Failed: ${responseData['msg']}');
        }
      } else {
        print(
            'Blacklist check failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      _logAdbError('Error during blacklist check for $deviceId: $e');
    }
  }

  void _logAdbError(String message) {
    print(message);
    if (mounted) {
      setState(() {
        adbError = message;
      });
    }
  }

  void _startLogCatIphone(String deviceId, String? sno) async {
    try {
      print("before back to home page ios ");
      List<Map<String, dynamic>> items = await SqlHelper.getItems();
      print('items in db ${items}');
      await ILogcat.startLogCat(deviceId, sno);
      print("after back to home page ios ");
      StreamSubscription<int> subscription =
          ILogcat.getProgressStream(deviceId).listen((progress) async {
        print("new progress in homepage ${progress}");

        double newProgress = progress / 100;

        if (mounted) {
          setState(() {
            deviceProgress[deviceId] = min(1, newProgress);
          });
        }
        // Save progress
        // await DeviceProgressManager.saveProgress(deviceId, newProgress);

        // Get the saved crack check result
        Map<String, dynamic>? presentDevice =
            await SqlHelper.getItemDetails(deviceId);

        if (newProgress >= 1.0 && presentDevice == null) {
          // Save results for the current device
          //await saveResultsIphone(deviceId);
          //IOSDeviceService().saveResultsIphone(deviceId, connectedIosDevices);


          // Check if we're already syncing devices
          if (!_currentlySyncing.containsKey(deviceId)) {
            _currentlySyncing[deviceId] = true;

            try {
              List<Map<String, dynamic>> unSyncedDevices =
                  await SqlHelper.getUnsyncedItems();

              if (unSyncedDevices.isNotEmpty) {
                print("Syncing ${unSyncedDevices.length} unsynced devices");
                await saveResultApi(unSyncedDevices);
              }
            } finally {
              // Clean up after sync attempt, whether it succeeded or failed
              _currentlySyncing.remove(deviceId);
            }
          } else {
            print("Sync already in progress for device $deviceId");
          }
        }
      }, onError: (error) {
        print('Error in LogCat stream: $error');
        _currentlySyncing.remove(deviceId);
      }, onDone: () {
        print('LogCat stream completed for device $deviceId');
        _currentlySyncing.remove(deviceId);
      });

      // Save the subscription to cancel it later if needed
      progressSubscriptions[deviceId] = subscription;
    } catch (e) {
      print('Error starting LogCat: $e');
      String modelName =
          connectedDevices[deviceId]?['model'] ?? 'Unknown Model';
      if (mounted) {
        setState(() {
          adbError = 'Error starting LogCat for $modelName: $e';
        });
      }
      _currentlySyncing.remove(deviceId);
    }
  }

  void _startLogCat(String deviceId) async {
    try {
      LogCat.startLogCat(deviceId);

      StreamSubscription<int> subscription =
          LogCat.getProgressStream(deviceId).listen((progress) async {
        if (deviceSet.contains(deviceId)) {
          double newProgress = progress / 100;
          if (mounted) {
            setState(() {
              deviceProgress[deviceId] = min(1, newProgress);
            });
          }
          // Save progress
          await DeviceProgressManager.saveProgress(deviceId, newProgress);

          // Get the saved crack check result
          Map<String, dynamic>? presentDevice =
              await SqlHelper.getItemDetails(deviceId);

          if (newProgress >= 1.0 && presentDevice == null) {
            // Save results for the current device
            await saveResults(deviceId);

            // Check if we're already syncing devices
            if (!_currentlySyncing.containsKey(deviceId)) {
              _currentlySyncing[deviceId] = true;

              try {
                List<Map<String, dynamic>> unSyncedDevices =
                    await SqlHelper.getUnsyncedItems();

                if (unSyncedDevices.isNotEmpty) {
                  print("Syncing ${unSyncedDevices.length} unsynced devices");
                  await saveResultApi(unSyncedDevices);
                }
              } finally {
                // Clean up after sync attempt, whether it succeeded or failed
                _currentlySyncing.remove(deviceId);
              }
            } else {
              print("Sync already in progress for device $deviceId");
            }
          }
        }
      }, onError: (error) {
        print('Error in LogCat stream: $error');
        _currentlySyncing.remove(deviceId);
      }, onDone: () {
        print('LogCat stream completed for device $deviceId');
        _currentlySyncing.remove(deviceId);
      });

      // Save the subscription to cancel it later if needed
      progressSubscriptions[deviceId] = subscription;
    } catch (e) {
      print('Error starting LogCat: $e');
      String modelName =
          connectedDevices[deviceId]?['model'] ?? 'Unknown Model';
      if (mounted) {
        setState(() {
          adbError = 'Error starting LogCat for $modelName: $e';
        });
      }
      _currentlySyncing.remove(deviceId);
    }
  }
  Future<void> saveResultApi(List<Map<String, dynamic>> unSyncedDevices) async {
    try {
      String? userId = await PreferencesHelper.getUserId();
      int currentCount =
          await SubscriptionSharedPref.getSubscription(userId ?? 'n/a') ?? 0;
      int newCount = currentCount > 0 ? currentCount - 1 : 0;
      await SubscriptionSharedPref.saveSubscription(userId ?? 'n/a', newCount);
      await subscriptionManager.removeSubscriptions(unSyncedDevices.length);
      // Update the UI

      // // Call the subscription change handler
      // _handleSubscriptionChange(newCount);

      print("Subscription count remaining: $newCount");
      // Start listening for connectivity changes

      final internetStatuschecker = InternetStatusChecker();
      bool response = await internetStatuschecker.checkInternetStatus();
      print("homepage mai internet staatus  $response ");
      if (response == true) {
        await internetStatuschecker.saveResults();
      }
    } catch (e) {
      print('Error saving results: $e');
    }
  }


  Future<void> saveResults(String deviceId) async {
    final resultSaver = DeviceResultSaver(connectedDevices);

    await resultSaver.saveResults(deviceId);
  }

  String formatBytes(int bytes) {
    if (bytes <= 0) return "0B";

    const int oneKB = 1024;
    const int oneMB = oneKB * 1024;
    const int oneGB = oneMB * 1024;

    if (bytes >= oneGB) {
      // Convert bytes to GB and round to the nearest integer
      return "${(bytes / oneGB).round()}GB";
    } else if (bytes >= oneMB) {
      return "${(bytes / oneMB).round()}MB";
    } else if (bytes >= oneKB) {
      return "${(bytes / oneKB).round()}KB";
    } else {
      return "${bytes}B";
    }
  }

 Future<void> saveResultsIphone(String deviceId) async {
    try {
      final deviceInfo = DeviceInfoManager();
      final ram = deviceInfo.getRam(deviceId);
      final rom = deviceInfo.getRom(deviceId);
      final adminApps = deviceInfo.getAdminApps(deviceId);
      print('ram and rom int homepage: ${ram}  ${rom}');
      final jailBreak = deviceInfo.getJailBreak(deviceId);
      final oemLock = deviceInfo.getOemSLockStatus(deviceId) == false
          ? 'Inactive'
          : 'Active';
      final mdm =
          deviceInfo.getMDMmanaged(deviceId) == false ? 'Inactive' : 'Active';

      print("jail break : ${jailBreak}  oemLock : ${oemLock} mdm: ${mdm}");

      String ramString = formatBytes(ram);
      String romString = "${rom} GB";
      print('ram and rom String homepage: ${ram}  ${rom}');
      // Save to local database
      await SqlHelper.createItem(
        'Apple',
        connectedIosDevices[deviceId]?['modelIdentifier'] ?? '',
        connectedIosDevices[deviceId]?['imei'] ?? '',
        connectedIosDevices[deviceId]?['serialNumber'] ?? '',
        ramString,
        mdm ?? '',
        oemLock ?? '',
        romString,
        connectedIosDevices[deviceId]?['carrier_lock'] ?? '',
        connectedIosDevices[deviceId]?['iOSVersion'] ?? '',
        connectedIosDevices[deviceId] != null ? '0' : '',
      );

      // Save log file
      await ILogcat.createJsonFile(
          deviceId, connectedIosDevices[deviceId]?['serialNumber']);
      print(
          "iphone result saved ${connectedIosDevices[deviceId]?['serialNumber']} ");
    } catch (e) {
      print('Error saving results: $e');
    }
  }

  
  void resetPercent(String deviceId) async {
    if (mounted) {
      setState(() {
        deviceProgress[deviceId] = 0;
      });
    }
    await DeviceProgressManager.deleteProgress(deviceId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: subscriptionManager,
      builder: (context, _) {
        if (subscriptionManager.currentSubscriptions <
            connectedDevices.length) {
          Future.microtask(() {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return SubscriptionDialog(
                  subscriptionManager: subscriptionManager,
                );
              },
            );
          });
        }

        final ThemeData theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surface,
            actions: [
              SubscriptionManagerWidget(
                  subscriptionManager: subscriptionManager),
              const SizedBox(width: 20),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    width: constraints.maxWidth * 0.125,
                    child: SideNavigation(),
                  ),
                  Expanded(
                    child: Container(
                      color: theme.colorScheme.surface,
                      child: Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: adbError.isNotEmpty
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 50,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          adbError,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(color: Colors.red),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    )
                                  : connectedDevices.isEmpty &&
                                          connectedIosDevices.isEmpty
                                      ? WaitingWidget()
                                      : DeviceListWidget(
                                          connectedDevices: connectedDevices,
                                          connectedIosDevices:
                                              connectedIosDevices,
                                          deviceProgress: deviceProgress,
                                          blacklist: blacklist,
                                          constraints: constraints,
                                        ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
