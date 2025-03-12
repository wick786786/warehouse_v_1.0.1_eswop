import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path_provider/path_provider.dart'; // To get the temporary directory
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:warehouse_phase_1/src/helpers/installStream.dart';


class LaunchApp {
  Future<File> extractApkFromAssets() async {
    ByteData data = await rootBundle.load('assets/warehouse.apk');
    Directory tempDir = await getTemporaryDirectory();
    String apkPath = path.join(tempDir.path, 'Warehouse.apk');
    File apkFile = File(apkPath);
    await apkFile.writeAsBytes(data.buffer.asUint8List());
    return apkFile;
  }

  Future<void> launchApplication(String deviceId, String packageName, String mainActivity) async {
    try {
      installationLaunchStream.updateStatus(deviceId, "Extracting APK...");
      File apkFile = await extractApkFromAssets();

      if (!apkFile.existsSync()) {
        installationLaunchStream.updateStatus(deviceId, "Failed to extract APK file.");
        return;
      }

      String apkPath = apkFile.path;

      // Check if app is installed
      installationLaunchStream.updateStatus(deviceId, "Checking if app is installed...");
      ProcessResult checkResult = await Process.run('adb', ['-s', deviceId, 'shell', 'pm', 'list', 'packages', packageName]);

      if (checkResult.stdout.toString().contains(packageName)) {
        installationLaunchStream.updateStatus(deviceId, "App is already installed.");
      } else {
        installationLaunchStream.updateStatus(deviceId, "Installing app...");
        ProcessResult installResult = await Process.run('adb', ['-s', deviceId, 'install', apkPath]);
        if (installResult.exitCode != 0) {
          installationLaunchStream.updateStatus(deviceId, "Installation failed: ${installResult.stderr}");
          return;
        }
        installationLaunchStream.updateStatus(deviceId, "Installation successful.");
      }

      // Check if the app is running
      installationLaunchStream.updateStatus(deviceId, "Checking if app is running...");
      ProcessResult runningResult = await Process.run('adb', ['-s', deviceId, 'shell', 'pidof', packageName]);

      if (runningResult.stdout.toString().isNotEmpty) {
        installationLaunchStream.updateStatus(deviceId, "App is already running.");
        return;
      }

      // Launch the app
      installationLaunchStream.updateStatus(deviceId, "Launching app...");
      ProcessResult launchResult = await Process.run('adb', ['-s', deviceId, 'shell', 'am', 'start', '-n', '$packageName/$mainActivity']);

      if (launchResult.exitCode != 0) {
        installationLaunchStream.updateStatus(deviceId, "Launch failed: ${launchResult.stderr}");
        return;
      }

      installationLaunchStream.updateStatus(deviceId, "App launched successfully!");
    } catch (e) {
      installationLaunchStream.updateStatus(deviceId, "Error launching app: $e");
    }
  }




  @override
  Widget build(BuildContext context) 
  {
    return const Placeholder();
  }
}
