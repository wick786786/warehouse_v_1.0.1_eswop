import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SecureDataWipeUtility {
  /// Secure data wipe strategy
  /// 
  /// Provides methods to securely delete sensitive data across different platforms
  /// with a focus on iOS-like security practices
  static Future<bool> wipeFile(File file) async {
    try {
      // Check file exists
      if (!await file.exists()) {
        print('File does not exist');
        return false;
      }

      // Get file size
      final fileLength = await file.length();

      // Perform three-pass secure wipe
      for (int pass = 0; pass < 3; pass++) {
        await _overwriteFileContents(file, pass, fileLength);
      }

      // Delete the file after secure overwrite
      await file.delete();
      
      return true;
    } catch (e) {
      print('Secure wipe error: $e');
      return false;
    }
  }

  /// Overwrite file contents with different patterns
  static Future<void> _overwriteFileContents(File file, int pass, int fileLength) async {
    // Open file for writing
    final randomAccessFile = await file.open(mode: FileMode.write);

    try {
      // Different overwrite patterns for each pass
      final data = _generateOverwriteData(pass, fileLength);
      
      // Write data to file
      await randomAccessFile.writeFrom(data);
      
      // Ensure data is flushed to storage
      await randomAccessFile.flush();
    } finally {
      // Always close the file
      await randomAccessFile.close();
    }
  }

  /// Generate overwrite data based on pass number
  static Uint8List _generateOverwriteData(int pass, int length) {
    switch (pass) {
      case 0:
        // First pass: Zero out
        return Uint8List(length);
      case 1:
        // Second pass: Fill with 0xFF
        return Uint8List.fromList(List.filled(length, 0xFF));
      case 2:
        // Third pass: Random data
        final random = Random.secure();
        return Uint8List.fromList(
          List.generate(length, (_) => random.nextInt(256))
        );
      default:
        throw ArgumentError('Invalid pass number');
    }
  }

  /// Wipe entire directory
  static Future<bool> wipeDirectory(Directory directory) async {
    try {
      // Check directory exists
      if (!await directory.exists()) {
        print('Directory does not exist');
        return false;
      }

      // List all files in directory
      final files = await directory.list(recursive: true).toList();

      // Wipe each file
      for (var entity in files) {
        if (entity is File) {
          await wipeFile(entity);
        }
      }

      // Optionally delete directory after wiping contents
      await directory.delete(recursive: true);

      return true;
    } catch (e) {
      print('Directory wipe error: $e');
      return false;
    }
  }

  /// Get secure file paths for different platforms
  static Future<File> getSecureFilePath(String filename) async {
    try {
      // Request necessary permissions
      await _requestPermissions();

      // Platform-specific document directories
      late Directory directory;
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Create file in secure directory
      return File('${directory.path}/$filename');
    } catch (e) {
      print('Error getting secure file path: $e');
      rethrow;
    }
  }

  /// Request necessary file access permissions
  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Request storage permissions on Android
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted) {
        throw Exception('Storage permissions not granted');
      }
    }
    // iOS typically doesn't require explicit storage permissions
  }
}