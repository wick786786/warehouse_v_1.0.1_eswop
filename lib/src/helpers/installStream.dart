import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class InstallationLaunchStream {
  final Map<String, StreamController<String>> _deviceControllers = {};

  /// Get the stream for a specific device
  Stream<String> getStream(String deviceId) {
    _deviceControllers.putIfAbsent(deviceId, () => StreamController<String>.broadcast());
    return _deviceControllers[deviceId]!.stream;
  }

  /// Update the status for a specific device
  void updateStatus(String deviceId, String status) {
    if (_deviceControllers.containsKey(deviceId)) {
      _deviceControllers[deviceId]!.sink.add(status);
    }
  }

  /// Dispose of a specific device stream
  void dispose(String deviceId) {
    _deviceControllers[deviceId]?.close();
    _deviceControllers.remove(deviceId);
  }
}

/// Global instance to use in the app
final installationLaunchStream = InstallationLaunchStream();
