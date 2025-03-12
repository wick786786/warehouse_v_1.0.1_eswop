import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_localizations/flutter_localizations.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart';
import 'package:warehouse_phase_1/presentation/pages/login_page.dart';
import 'package:warehouse_phase_1/service_class/connectivity_check.dart';
import 'src/helpers/sql_helper.dart';
import 'presentation/pages/homepage/home_page.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:warehouse_phase_1/src/core/constants.dart';
// import 'presentation/pages/login_page.dart';
// import 'package:window_manager/window_manager.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:firebase_core/firebase_core.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SqlHelper.initializeDatabaseFactory();
  
  // Initialize the background connectivity service
  // final connectivityService = ConnectivityService();
  
  // // Listen to connectivity changes in the background
  // connectivityService.connectionStream.listen((isConnected) {
  //   if (kDebugMode) {
  //     //print('Connection status changed: ${isConnected ? "Connected" : "Disconnected"}');
  //     if(isConnected)
  //     {
          
  //        print("Internet connected");
  //     }
  //     else{
  //       print("not connected");
  //     }
  //   }
  //   // You can add any global actions here when connectivity changes
  // });
  //SqlHelper.deleteDatabase();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
 // Locale _locale = const Locale('en', 'US');
  bool _isDarkMode = false;
  bool _isSessionValid=false;
  @override
  void initState() {
    super.initState();
    _checkSession(); // Call session check on app start
  }
   // Method to check session validity
  Future<void> _checkSession() async {
    // Assume you have a method `isSessionValid()` to check session validity
    _isSessionValid = await PreferencesHelper.isSessionValid();

    setState(() {}); // Trigger rebuild after session check
  }
  // void _setLocale(Locale locale) {
  //   setState(() {
  //     _locale = locale;
  //   });
  // }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkMode ? AppThemes.darkMode : AppThemes.lightMode,
      //locale: _locale,
      // supportedLocales: const [
      //   Locale('en', 'US'),
      //   Locale('es', 'ES'),
      // ],
      // localizationsDelegates: const [
      //   AppLocalizations.delegate,
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      home:// Check session validity to decide the initial page
        _isSessionValid
          ? MyHomePage(
              title: 'Warehouse Application',
             // onLocaleChange: _setLocale,
              onThemeToggle: _toggleTheme,
            )
          : LoginPage(
              title: 'Warehouse Application',
            //  onLocaleChange: _setLocale,
              onThemeToggle: _toggleTheme,
            ),
    );
  }
}