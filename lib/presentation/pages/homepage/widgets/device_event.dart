import 'package:flutter/material.dart';

enum DeviceType { android, ios }

// Device event classes
enum DeviceEventType { connected, disconnected }

class DeviceEvent {
  final DeviceEventType type;
  final String deviceId;
  final DeviceType deviceType;

  DeviceEvent({
    required this.type,
    required this.deviceId,
    required this.deviceType,
  });
}

class DeviceInfo {
  final String id;
  final String name;
  final Map<String, String> details;
  final DeviceType type;
  final DateTime lastUpdated;

  DeviceInfo({
    required this.id,
    required this.name,
    required this.details,
    required this.type,
    required this.lastUpdated,
  });
}

