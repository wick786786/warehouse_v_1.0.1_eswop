import 'dart:io';

class IPhoneAppInstaller {
  /// Installs an app on the iPhone using its UDID.
  ///
  /// [udid] - The UDID of the iPhone.
  /// [appPath] - The file path of the app (.ipa) to be installed.
  /// Returns a `Future<String>` with the command output or an error message.
  Future<String> installApp(String udid, String appPath) async {
    try {
      // Ensure the app file exists
      if (!File(appPath).existsSync()) {
        return 'Error: App file not found at $appPath';
      }

      // Execute the `ideviceinstaller` command
      final result = await Process.run(
        'ideviceinstaller',
        ['-u', udid, '-i', appPath],
      );

      if (result.exitCode == 0) {
        return 'App installed successfully on device with UDID: $udid\n${result.stdout}';
      } else {
        return 'Error during installation: ${result.stderr}';
      }
    } catch (e) {
      return 'Exception occurred: $e';
    }
  }

  /// Checks if the `ideviceinstaller` command is available.
  Future<bool> isIdeviceInstallerAvailable() async {
    try {
      final result = await Process.run('ideviceinstaller', ['--help']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
