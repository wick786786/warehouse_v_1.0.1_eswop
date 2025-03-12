import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';

class WifiQRGenerator extends StatefulWidget {
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  const WifiQRGenerator({
    Key? key,
    this.size = 100.0,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
  }) : super(key: key);

  @override
  State<WifiQRGenerator> createState() => _WifiQRGeneratorState();
}

class _WifiQRGeneratorState extends State<WifiQRGenerator> {
  final NetworkInfo _networkInfo = NetworkInfo();
  String? _ssid;
  String? _password;
  bool _isLoading = true;
  bool _isError = false;
  bool _showPassword = true;

  @override
  void initState() {
    super.initState();
    _getWifiInfo();
  }

  Future<void> _getWifiInfo() async {
    try {
      final ssid = await _networkInfo.getWifiName();
      
      // Check if no WiFi is connected
      if (ssid == null || ssid.isEmpty) {
        setState(() {
          _isLoading = false;
          _ssid = null;
          _password = null;
        });
        return;
      }

      final password = await getCurrentWifiPassword();
      print('password: $password');
      
      setState(() {
        _ssid = ssid.replaceAll('"', '');
        _password = password;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  static Future<String?> getCurrentWifiPassword() async {
    try {
      if (Platform.isWindows) {
        return await _getWindowsWifiPassword();
      } else if (Platform.isMacOS) {
        return await _getMacOSWifiPassword();
      } else if (Platform.isLinux) {
        return await _getLinuxWifiPassword();
      }
      return null;
    } catch (e) {
      print('Error getting WiFi password: $e');
      return null;
    }
  }

  static Future<String?> _getWindowsWifiPassword() async {
    // First get the SSID
    var result = await Process.run('netsh', ['wlan', 'show', 'interfaces']);
    String output = result.stdout.toString();
    
    // Extract SSID
    RegExp ssidRegex = RegExp(r'SSID\s+:\s(.+)');
    var match = ssidRegex.firstMatch(output);
    if (match == null) return null;
    String ssid = match.group(1)?.trim() ?? '';

    // Get password for this SSID
    result = await Process.run(
      'netsh',
      ['wlan', 'show', 'profile', 'name=$ssid', 'key=clear']
    );
    output = result.stdout.toString();
    
    // Extract password
    RegExp passwordRegex = RegExp(r'Key Content\s+:\s(.+)');
    match = passwordRegex.firstMatch(output);
    return match?.group(1)?.trim();
  }

  static Future<String?> _getMacOSWifiPassword() async {
    // First get the SSID
    var result = await Process.run('/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport', ['-I']);
    String output = result.stdout.toString();
    
    RegExp ssidRegex = RegExp(r' SSID: (.+)');
    var match = ssidRegex.firstMatch(output);
    if (match == null) return null;
    String ssid = match.group(1)?.trim() ?? '';

    // Get password from Keychain
    result = await Process.run('security', [
      'find-generic-password',
      '-D',
      'AirPort network password',
      '-a',
      ssid,
      '-w'
    ]);
    
    return result.stdout.toString().trim();
  }

  static Future<String?> _getLinuxWifiPassword() async {
    // Try to get from NetworkManager
    var result = await Process.run('sudo', [
      'cat',
      '/etc/NetworkManager/system-connections/*.nmconnection'
    ]);
    
    String output = result.stdout.toString();
    RegExp passwordRegex = RegExp(r'psk=(.+)');
    var match = passwordRegex.firstMatch(output);
    return match?.group(1)?.trim();
  }

  String _generateWifiQRString() {
    return 'WIFI:T:WPA;S:${_ssid ?? ''};P:${_password ?? ''};;';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    if (_isError) {
      return const Text('Error getting WiFi information');
    }

    // Show message when no WiFi is connected
    if (_ssid == null) {
      return const Center(
        child: Text(
          'NO WiFi connected',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Network: $_ssid'),
        const SizedBox(height: 16),
        if (_password != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Password: ${_showPassword ? _password! : '•' * _password!.length}',
                style: const TextStyle(fontSize: 16),
              ),
              IconButton(
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
            ],
          ),
        const SizedBox(height: 16),
        if (_password != null && _password!.isNotEmpty)
          QrImageView(
            data: _generateWifiQRString(),
            size: widget.size,
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
          ),
      ],
    );
  }
}