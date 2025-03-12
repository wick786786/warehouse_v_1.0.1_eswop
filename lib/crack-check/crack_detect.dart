import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:process_run/shell.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Add this import

class CrackCheck{

  //executing app inside the mobile phone 
  static Future<void> executeAdbDevicesCommand() async {
    var shell = Shell();
    try {
      var result = await shell.run('adb shell am start -n com.example.camerax/com.example.camerax.MainActivity');
      // Print the result to console or handle it as needed
      print(result.outText);
       
       //set timeout of 25 seconds
      await Future.delayed(const Duration(seconds:25));

      //call the function to pull latest video

      await _pullLatestVideo();

    } catch (e) {
      // Handle any errors
      print('Error: $e');
    }
  }
// Function to pull the most recent video
 static Future<void> _pullLatestVideo() async {
  var shell = Shell();
  try {
    // Find the most recent video file
    var fileNameResult = await shell.run('adb shell ls -t /sdcard/Movies/CameraX-Video/ | head -n 1');
    print('fileNameResult: $fileNameResult');
    var fileName = fileNameResult.outText.trim();
    print('fileName: $fileName');

    // Use your specified desktop path
    const desktopPath = 'C:\\Users\\thesa\\OneDrive\\Desktop';

    print('Desktop path: $desktopPath');

    // Create warehouse directory on desktop
    final warehouseDir = Directory('$desktopPath\\warehouse');
    if (!warehouseDir.existsSync()) {
      warehouseDir.createSync(recursive: true);
    }

    print('Warehouse directory created at: ${warehouseDir.path}');

    // Get the device's IMEI
    var imeiResult = await shell.run('adb shell dumpsys iphonesubinfo | grep DeviceID | cut -d \':\' -f2');
    var imei = imeiResult.outText.trim().replaceAll('\n', '').replaceAll(' ', '');
    print('IMEI: $imei');

    // Create a folder with the IMEI number
    final imeiDir = Directory('${warehouseDir.path}\\$imei');
    if (!imeiDir.existsSync()) {
      imeiDir.createSync();
    }

    print('IMEI directory created at: ${imeiDir.path}');

    // Create a folder for videos within the IMEI directory
    final videoDir = Directory('${imeiDir.path}\\videos');
    if (!videoDir.existsSync()) {
      videoDir.createSync();
    }

    print('Video directory created at: ${videoDir.path}');

    // Pull the video file to the video directory
    var pullResult = await shell.run('adb pull /sdcard/Movies/CameraX-Video/$fileName ${videoDir.path}');
    // Print the result to console or handle it as needed
    print(pullResult.outText);

    // Optionally clear the phone's CameraX-Video directory
    // await _clearVideoFilesPhone();

    // Upload video to the server
    await _uploadVideo();

  } catch (e) {
    // Handle any errors
    print('Error: $e');
  }
}

 static Future<void> _uploadVideo() async
  {
     final videoFolderPath = Directory(r'D:\flutter_project\demo_app\videos');

  if (!videoFolderPath.existsSync()) {
    throw Exception('Video folder does not exist.');
  }

  final videoFiles = videoFolderPath.listSync().where((file) {
    final extname = path.extension(file.path).toLowerCase();
    return extname == '.mp4' || extname == '.avi' || extname == '.mov';
  }).toList();

  if (videoFiles.isEmpty) {
    throw Exception('No video files found in the folder.');
  }

  final filePath = videoFiles.first.path;
  print('file path: $filePath');
  final filename = path.basename(filePath);

  try {
    const url = 'https://crackapi.getinstacash.in/video-crack/upload';
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['Authorization'] =
        'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTY3ODQ0NDcxNywianRpIjoiYmRmMTFmZjgtMjIzMS00ODE3LTlhMjItMDkxOWNjNGVhZGI4IiwidHlwZSI6ImFjY2VzcyIsInN1YiI6InByYXRlZWtnb2VsIiwibmJmIjoxNjc4NDQ0NzE3LCJleHAiOjE3NDE1MTY3MTd9.ZOuYfpVwYZZ_jxnwzppNOfnWznpHQiOVsD8u5i1zoIM'; // Your token here

    // Determine the MIME type based on file extension
    String ext = path.extension(filePath).toLowerCase().substring(1);
    String mimeType;
    switch (ext) {
      case 'mp4':
        mimeType = 'video/mp4';
        break;
      case 'avi':
        mimeType = 'video/x-msvideo';
        break;
      case 'mov':
        mimeType = 'video/quicktime';
        break;
      default:
        mimeType = 'application/octet-stream';
    }

    // Add the file with the appropriate content type
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      filePath,
      contentType: MediaType.parse(mimeType),
    ));

    print(request.headers);
    print(request.files);

    final response = await request.send();
    final streamResponse = await http.Response.fromStream(response);
    if (streamResponse.statusCode == 200) {
      print('Upload Success');
      // Add your deleteVideo(filename) function here if needed
      print('Video uploaded successfully!');
    } else {
      print("post request response: ${streamResponse.body}");
      throw Exception('Failed to upload video.');
    }
  } catch (e) {
    print('Error uploading video: $e');
    throw Exception('Failed to upload video.');
  }

  
}
  
  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: const Color.fromARGB(255, 17, 16, 16),
  //     body: Center(
  //       child: ElevatedButton(
  //         onPressed: _executeAdbDevicesCommand,
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: const Color.fromARGB(255, 25, 98, 207), // Dark blue color
  //           padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
  //         ),
  //         child: const Text(
  //           'Start Analysis',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.white,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
