class DeviceInfoManager {
  static final DeviceInfoManager _instance = DeviceInfoManager._internal();
  
  factory DeviceInfoManager() {
    return _instance;
  }
  
  DeviceInfoManager._internal();

  // Maps to store device information indexed by device ID
  final Map<String, int> _deviceRam = {};
  final Map<String, int> _deviceRom = {};
  final Map<String, String> _deviceAdminApps = {};
  final Map<String,bool>_oemLock={};
  final Map<String,bool>_isJailBreak={};
  final Map<String,bool> _isMDMmanaged={};

  // Getters
  int getRam(String deviceId) => _deviceRam[deviceId] ?? 0;
  int getRom(String deviceId) => _deviceRom[deviceId] ?? 0;
  bool? getOemSLockStatus(String deviceId) => _oemLock[deviceId] ;
  bool? getJailBreak(String deviceId) => _isJailBreak[deviceId] ;
  bool? getMDMmanaged(String deviceId) => _isMDMmanaged[deviceId] ;


  String getAdminApps(String deviceId) => _deviceAdminApps[deviceId] ?? "";

  // Setters
  void setDeviceInfo(String deviceId, int ram, int rom, String adminApps) {
    _deviceRam[deviceId] = ram;
    _deviceRom[deviceId] = rom;
    _deviceAdminApps[deviceId] = adminApps;
  }

   void setLockInfo(String deviceId, bool isJailBreak, bool oemLock, bool mdm) {
    _isJailBreak[deviceId] = isJailBreak;
    _oemLock[deviceId] = oemLock;
    _isMDMmanaged[deviceId] = mdm;
  }

  // Clear device info
  void clearDeviceInfo(String deviceId) {
    _deviceRam.remove(deviceId);
    _deviceRom.remove(deviceId);
    _deviceAdminApps.remove(deviceId);
  }
}